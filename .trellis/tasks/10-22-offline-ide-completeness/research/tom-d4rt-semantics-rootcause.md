# tom_d4rt 1.229.0 semantics failures: root causes and minimal general fix design

Scope: read-only investigation of the production engine
(`D:/AppData/Local/Pub/Cache/hosted/pub.dev/tom_d4rt-1.229.0`) plus bounded probes
in `.dart_tool/tom-semantics-probe/` (probes only). **No pubspec, `lib/`, or core
edits. No curriculum content or expected-output changes.**

Baseline under test: `.dart_tool/tom-engine-probe/check.dart`
(analyzer override 8.4.1) — 240 units, **220 pass / 20 fail**; every failing id has
a paired lesson+example, i.e. **10 distinct defects**.

Targets assigned: 033 (generic `whereType` → nulls), 038 (static ctor counter),
052 (covariance), 048 / 078 (dynamic generic / `runtimeType`). All five reproduce
exactly; each is now traced to a specific line. Every claim below was produced by
running code, not by reading alone.

---

## 0. Summary

| # | Lesson | Symptom | Root cause (one line) | Fix locus | Probe-verified |
| --- | --- | --- | --- | --- | --- |
| 1 | 033 | `whereType<int>()` returns `[1, null, 3, null, 5]` | `whereType`/`cast` adapters **drop the `typeArguments` argument** — deliberate stub returning the receiver unfiltered | `stdlib/core/iterable.dart`, `stdlib/core/list.dart` | **Yes — 7/7 fixed** |
| 2 | 038 | `Counter.total` stays 0 | `++`/`--` never writes `InterpretedClass.staticFields`; qualified `C.n++` throws, bare `n++` writes nothing | `interpreter_visitor.dart` postfix/prefix visitors | Yes, isolated |
| 3 | 052 | `List<int>` accepts `1.5` through a `List<num>` view; no `_TypeError` | No element-type enforcement on native lists: viewed as `List<num>`, the same native `List` is mutated unchecked | list `add`/`[]=` bridge + widened-view construction | Yes, isolated |
| 4 | 048 | `Pair<dynamic, dynamic>` from `swap()` | **Constructor type-argument inference is absent**; explicit args work, inferred always `dynamic` | instance-creation inference in `interpreter_visitor.dart` | Yes, isolated |
| 5 | 078 | `Future<Object?>` | `Object.runtimeType` bridge returns the **host `Type`**, bypassing `Environment.getRuntimeType` / `AppliedRuntimeType` | `stdlib/core/object.dart` `runtimeType` getter | Yes, isolated |

Two structural observations worth carrying into the design:

- **The machinery already exists.** `BridgedMethodAdapter` already receives
  `List<RuntimeType>? typeArguments`; `AppliedRuntimeType`,
  `Environment.getRuntimeType`, `Environment.appliedRuntimeTypeOf` and
  `_homogeneousElementType` are all implemented and already used for generic
  *return-type* checks. Every fix below **reuses** these instead of adding a new
  type system.
- **dart_eval and tom_d4rt fail the same lessons for opposite reasons.** dart_eval
  fails 033 by not supporting the construct at all; tom_d4rt supports the syntax
  and returns a *wrong value*. A wrong value is the more dangerous failure, and it
  is what makes 033/038/052/048/078 unfixable by content rewriting.

---

## 1. Lessons 033 / 033-example — generic `whereType` returns nulls

### 1.1 Reproduction

```
EXP: [1, 3, 5] / 9 / 0 / 2
ACT: [1, null, 3, null, 5]  then  Unsupported operator (PLUS) for types int and null
```

`whereType<int>()` is an **identity function**: it returns the receiver unchanged.

### 1.2 Root cause

`lib/src/stdlib/core/iterable.dart:257`:

```dart
'whereType': (visitor, target, positionalArgs, namedArgs, _) {
  return (target as Iterable).whereType();
},
```

`lib/src/stdlib/core/list.dart:254`:

```dart
'whereType': (visitor, target, positionalArgs, namedArgs, _) {
  // Mirrors the Iterable bridge: returns the list contents
  // unfiltered (Iterable<dynamic>); the per-call type argument is
  // not used yet. Adding this entry stops scripts that call
  // `someList.whereType<Widget>()` from failing the bridge lookup.
  return (target as List).whereType();
},
```

The fifth adapter parameter **is** `typeArguments` (see
`bridge/registration.dart`, `typedef BridgedMethodAdapter`:

```dart
Object? Function(InterpreterVisitor, Object target,
    List<Object?> positionalArguments, Map<String, Object?> namedArguments,
    List<RuntimeType>? typeArguments);
```

). Both adapters bind it to `_` and call host `whereType()` with **no type
argument**, which Dart resolves to `whereType<dynamic>()` → keeps everything,
including `null`. `cast` is the same stub (`iterable.dart:262`), so
`xs.cast<int>()` is also unfiltered.

The engine's own comment confirms this was a lookup-unblocking stub, not a
semantic decision.

### 1.3 Why the fix is available for free

The canonical predicates already exist:

- `Environment.getRuntimeType(value)` (`environment.dart:2277`) resolves a value
  to a `RuntimeType` **exactly as `is` does** — interpreted instances, bridged
  instances, enums (bridged and interpreted), functions, records, natives.
- `RuntimeType.isSubtypeOf(other, {value})` is the single shared subtype test;
  `interpreter_visitor.dart:12807` uses precisely
  `getRuntimeType(v)?.isSubtypeOf(target, value: v)` for `is`.

### 1.4 Proposed fix (general, no hardcoding)

```dart
// iterable.dart + list.dart, both 'whereType' and 'cast' adapters
Iterable<Object?> _whereType(D4 visitor, Iterable src, List<RuntimeType>? args) {
  if (args == null || args.isEmpty) return src;          // stay permissive
  final target = args.first;
  final env = visitor.environment;
  return src.where((e) =>
      e != null && (env.getRuntimeType(e)?.isSubtypeOf(target, value: e) ?? false));
}
```

`cast` differs only in being lazy **and throwing** on a non-conforming element
(`type 'X' is not a subtype of type 'T' in type cast`), which the covariance
lesson depends on.

### 1.5 Verification

9-case probe (`.dart_tool/tom-semantics-probe/results-wt-*.json`), stock vs
patched, same programs:

| case | baseline | patched |
| --- | --- | --- |
| lesson033 exact shape | FAIL `[1, null, 3, null, 5]` | **PASS** `[1, 3, 5]` / `9` / `0` / `2` |
| `<Object>` mixed `int`/`String` | FAIL | **PASS** |
| `whereType<String>` with null | FAIL | **PASS** |
| `.length` equivalence | FAIL (3) | **PASS** (2) |
| `num` → `int` / `double` / `num` | FAIL (all pass through) | **PASS** |
| nested `List<int>` | FAIL (3) | **PASS** (2) |
| plain `Iterable<int>` receiver | FAIL | **PASS** |
| `cast<int>` on `[1,'a',2]` | silently `[1, a, 2]` | throws, as Dart does |

**7/7 previously failing cases fixed; the one remaining "NO" is the probe's own
expectation being un-Dart-like** (`cast<int>().toList()` must throw), i.e. the
patched engine is now *more* correct than the expectation.

Bonus: this fix also closes the dart_eval gap for `whereType`, meaning lesson 033
can become dual-engine if desired.

---

## 2. Lesson 038 — static counter never increments

### 2.1 Reproduction

```
EXP: 3 / 共创建了 3 个计数器
ACT: 0 / 共创建了 0 个计数器        (no error — silent)
```

### 2.2 Root cause — three separate defects around `++` on statics

Minimal probe matrix (`results-st.json`, `results-p2.json`):

| program | result |
| --- | --- |
| `total = total + 1` in ctor | **PASS** |
| `n += 5` in ctor | **PASS** |
| `static int n; n++` in ctor | **FAIL, silent 0** |
| `static int n; ++n` in ctor | **FAIL: Assigning to undefined variable 'n'** |
| `static int n; static void bump(){ n++; }` | **FAIL, silent 0** |
| `C.n++` (qualified) | **FAIL: Cannot increment/decrement property on non-instance object of type 'InterpretedClass'** |
| instance field `n++` | **PASS** |
| top-level `n++` | **PASS** |
| local `n++` | **PASS** |

The decisive case:

```dart
class C {
  static int n = 0;
  C() { n++; print('inside=$n'); }   // prints inside=1
}
print('outside=${C.n}');             // prints outside=0
```

`n++` **returns and displays the incremented value but never commits it** to the
static slot. Read path is therefore fine; only the write-back target is wrong.

`interpreter_visitor.dart:10156 visitPostfixExpression` (and the `++`/`--` part of
`visitPrefixExpression:9472`) handle exactly two assignment targets:

1. **instance field** — via `environment.get('this')` → `thisInstance.set(...)`;
2. **lexical variable** — `environment.assign(name, newValue)`.

A static field is neither. Inside a method/ctor, `environment.get('n')` fails
lexically, `this` is an `InterpretedInstance`, so the value is read through
`thisInstance.get('n')` — which resolves the class-level static — but the
write-back goes to `thisInstance.set('n', ...)` / `environment.assign('n', ...)`,
**never to `klass.staticFields['n']`**. The `PropertyAccess` form (`C.n++`,
`postincrement-on-qualified-static`) instead hits the prefix/property branch,
which rejects any non-`InterpretedInstance` target — `InterpretedClass` is one —
with `Cannot increment/decrement property on non-instance object`.

`+=` and `=` are unaffected because `visitAssignmentExpression` has a static-aware
target resolution that `++`/`--` never got.

Also note `Environment.staticFieldSnapshotOwner` (`environment.dart:305`) is
declared and never read — the vestige of an abandoned attempt at this.

### 2.3 Proposed fix (general)

Give `++`/`--` the same assignment-target resolution that `=`/`+=` already use,
rather than the two-branch approximation. Concretely, factor the target resolver
already inside `visitAssignmentExpression` into a helper returning a
`(read, write)` pair covering: lexical slot, instance field, **static field of the
enclosing class**, getter/setter pair, and indexed element; then have
`visitPostfixExpression` / `visitPrefixExpression` use it. Static write goes to
`klass.setStaticField(name, value)` (which already exists,
`runtime_types.dart:465`), and `PropertyAccess` on an `InterpretedClass` target
routes to the same static path instead of throwing.

This is a *single* behavioural rule — "increment is a read plus the same write that
`=` would perform" — not four special cases, and it removes the
`InterpretedClass` rejection rather than papering over 038.

`whereType` fix (§1) is independent of this one; 038 needs only §2.

---

## 3. Lesson 052 — covariance write barrier missing

### 3.1 Reproduction

```
EXP: 6 / 写入失败：_TypeError / [1, 2, 3, 1.5]
ACT: 6 / [1, 2, 3, 1.5, 1.5]                       (no throw at all)
```

### 3.2 Root cause

`List<int>` widened to `List<num>` is **the same native `List` object**, and no
element-type check exists on `add` or `[]=`:

```dart
final List<int> ints = <int>[1, 2, 3];
final List<num> nums = ints;
nums.add(1.5);          // accepted
print(ints);            // [1, 2, 3, 1.5]   ← List<int> now holds a double
print(ints[1] is int);  // false
```

Probe evidence (`results-g.json`): `add(1.5)` → accepted; `nums[0] = 9.5` →
accepted and mutates `ints`; `list-int-add-double-caught` → prints `no throw`, and
the `catch` block never executes — which is exactly why lesson 052's
`e.runtimeType` line never runs.

So 052 has **two** dependencies:
1. the missing write barrier (no exception is thrown), and
2. `e.runtimeType` inside the catch would then render `Instance of 'BridgedClass'`
   rather than `_TypeError` unless §5's `runtimeType` fix also lands and the SDK
   error surface reports `_TypeError`.

Note the substrate is present but unused here: `Environment.appliedRuntimeTypeOf`
(`environment.dart`) already derives `AppliedRuntimeType` for **homogeneous**
collections, and `_homogeneousElementType` exists. The gap is that it is only
consulted for generic *return-type* checking, never on element writes.

### 3.3 Proposed fix (general, staged)

**Stage A — barrier at the write.** When a list widens (assignment of `List<S>` to
`List<T>` with `S <: T`), record the *narrowest declared element type* as a hidden
element-type tag on the value (or, without tagging, carry it on the widened view).
`add`/`addAll`/`insert`/`[]=`/`fillRange` then ask the single existing predicate
`isSubtypeOf` before storing, and throw the standard
`type 'double' is not a subtype of type 'int' in type cast` on failure. Where a tag
is unavailable, derive it once from the declared type annotation
(`AppliedRuntimeType(base, [S])`).

**Stage B — reporting.** `e.runtimeType` for an engine-raised type error must yield
`_TypeError`, i.e. the SDK error type name, not the bridge class.

Stage A alone makes `nums.add(1.5)` throw; the lesson's expected text needs Stage
A + §5. If Stage A is considered too invasive for a first cut, 052 must remain
classified "needs engine work" rather than being rewritten — rewriting it would
require hardcoding `_TypeError`, which this task forbids.

---

## 4. Lesson 048 — generic type arguments lost on inference

### 4.1 Reproduction

```
EXP: Box<int>(42) / Pair<int, String>(18, age)
ACT: Box<int>(42) / Pair<dynamic, dynamic>(18, age)
```

`Box<int>(42)` is fine. Only `swap()`'s `Pair(value, key)` is wrong.

### 4.2 Root cause

**Constructor type-argument inference is not implemented.** Explicit arguments
work; inferred ones always collapse to `dynamic`

Probe matrix (`results-sw.json`, `results-inf.json`):

| program | result |
| --- | --- |
| `Pair<V, K>(value, key)` (explicit) | **PASS** `K=int,V=String` |
| `Pair(value, key)` (inferred, in generic method) | **FAIL** `K=dynamic,V=dynamic` |
| `W<T>(v)` explicit | **PASS** |
| `W(1)` inferred | **FAIL** `dynamic` |
| `L(<int>[1])` inferred | **FAIL** `dynamic` |
| `M(<String,int>{})` inferred | **FAIL** `dynamic,dynamic` |

So the defect is *only* inference; the substitution machinery for explicit
arguments (`Pair<V, K>`) is correct, including swapped order and nesting.

Lesson 048 is therefore **fixable by the engine alone** — its own text
`Pair<V, K> swap() => Pair(value, key)` is idiomatic Dart and must keep working as
written; no content change is acceptable.

### 4.3 Proposed fix (general, scoped)

Implement the constructor-inference step in
`visitInstanceCreationExpression` (`interpreter_visitor.dart:13196`):

1. If the `NamedType` carries explicit type arguments → current behaviour (already
   correct).
2. Else, if a **declared context type** is available (return type of the enclosing
   generic method, the declaration's annotated type, or the assignment target),
   unify its type arguments against the constructor's parameters to solve `T`,
   `K`, `V`;
3. Else fall back to `dynamic` **as today** (permissive, no regression).

Step 2 for the 048 shape needs only: declared return type `Pair<V, K>` → positional
constructor parameters `(K, V)` → constraints `K := V`, `V := K` → substitute the
method's own arguments. The unification helper is small and the resolver used by
`_checkAppliedGenericReturn` (`interpreter_visitor.dart:13182`,
`_resolveTypeAnnotationWithEnvironment` + `AppliedRuntimeType`) is directly
reusable.

This one change also fixes the whole `Box(1)` / `L([1])` / `M({})` inference family,
so it is the highest leverage of the five.

---

## 5. Lesson 078 — `runtimeType` reports the host type

### 5.1 Reproduction

```
EXP: Future<int> / 10 / 20
ACT: Future<Object?> / 10 / 20
```

### 5.2 Root cause

`lib/src/stdlib/core/object.dart:317`:

```dart
'runtimeType': (visitor, target) => target.runtimeType,
```

That is the **host** `Type` of the bridged native object, so every generic native
type loses its arguments (`results-rt.json`):

| expression | actual | Dart |
| --- | --- | --- |
| `<int>[]` | `List<Object?>` | `List<int>` |
| `<String,int>{}` | `_Map<Object?, Object?>` | `Map<String, int>` |
| `<int>[1,2]` | `List<Object?>` | `List<int>` |
| `Future<int>` | `Future<Object?>` | `Future<int>` |
| `Box<int>(1)` | `<class Box>` | `Box<int>` |
| `1`, `1.5`, `'a'`, `true` | correct | correct |
| `null.runtimeType` | **throws** | `Null` |

The engine is not lacking the capability — it has `AppliedRuntimeType` (with a
correct `name`, e.g. `List<int>`) and `Environment.appliedRuntimeTypeOf` which
already returns `AppliedRuntimeType` for homogeneous native `List`/`Set`/`Map` and
for `InterpretedInstance` value types. The getter simply bypasses both, and the
`print`/interpolation path follows it. `null.runtimeType` throwing is a second,
smaller defect in the same getter.

### 5.3 Proposed fix (general)

```dart
'runtimeType': (visitor, target) {
  if (target == null) return visitor.environment.getRuntimeType(null)!; // 'Null'
  final applied = visitor.environment.appliedRuntimeTypeOf(target);
  return applied ?? visitor.environment.getRuntimeType(target) ?? target.runtimeType;
},
```

`appliedRuntimeTypeOf` already returns `List<int>`, `Map<String,int>`, and
`InterpretedInstance` applied types; otherwise `getRuntimeType` gives the bridge
class whose `name` is `Future`/`Box`; the host `Type` remains only as a last
resort. For `Future<int>` the missing piece is the *declared* type argument, which
again comes from §4's inference/annotation machinery — so §4 and §5 share one
prerequisite and should land together.

Two adjacent items surfaced but out of scope for the five targets:
`'$T'` for a type-parameter value renders `Instance of 'BridgedClass'` while
`T.toString()` and `T == int` are correct (`results-t.json`) — a separate
`toString` bridge gap for `BridgedClass`; and lesson 080 (`unawaited`) / 093
(`Isolate.spawn`) are unimplemented-feature stubs, not semantics bugs.

---

## 6. Minimal general fix design (what to change, in order)

Nothing here encodes lesson ids or expected strings. Each item is a
single behavioural rule expressed through machinery the engine already has.

| P | Change | File(s) | Fixes | Risk |
| --- | --- | --- | --- | --- |
| **P0** | `whereType`/`cast` honour `typeArguments` via `getRuntimeType(...).isSubtypeOf(...)`; `cast` throws lazily | `stdlib/core/iterable.dart`, `stdlib/core/list.dart` | 033 | **Low — proven**, +6 cases, no regressions observed |
| **P1** | `++`/`--` reuse the assignment-target resolver; add static-field target; allow `InterpretedClass` on `PropertyAccess` increments | `interpreter_visitor.dart` (`visitPostfixExpression`, `visitPrefixExpression`, shared resolver) | 038 | Medium — touches a hot visitor; covered by P1 probe matrix |
| **P2** | Constructor type-argument inference from a declared context type; explicit args unchanged; `dynamic` fallback | `interpreter_visitor.dart` (`visitInstanceCreationExpression`) + small unifier reusing `_resolveTypeAnnotationWithEnvironment` | 048, and the `Box(1)`/`L([1])`/`M({})` family; prerequisite for 078 | Medium — inference must stay permissive on failure |
| **P3** | `Object.runtimeType` → `appliedRuntimeTypeOf` → `getRuntimeType` → host `Type`; `null.runtimeType == Null` | `stdlib/core/object.dart` | 078, and lets 052 report `_TypeError` | Low after P2 |
| **P4** | Element-type write barrier on widened `List` views using `isSubtypeOf` + `AppliedRuntimeType`; throw standard cast error | list write bridge + widened-view creation | 052 (Stage A) | **Highest** — needs a declared-element tag; do last and behind full 240-unit run |

Suggested landing order **P0 → P3 → P2 → P1 → P4**: P0 is proven and isolated; P3 is
one getter; P2 unlocks the largest family; P1 is a focused visitor repair; P4 is
the only one that adds a new enforcement mechanism.

Expected effect if all land: **20 failing units → 0**, on the *same* content and the
*same* expected outputs. If P4 is deferred, 052's two units stay the only
engine-blocked pair and must be reported as such — never satisfied by editing
`output`.

### 6.1 Invariants any patch must hold

1. No `typeArguments == null` behaviour change (stay permissive) — prevents
   regressing the 220 currently passing units.
2. One subtype predicate only: `getRuntimeType(v)?.isSubtypeOf(t, value: v)`. No
   new parallel `is`-logic.
3. Explicit type arguments keep working exactly as today (P2 must not touch them).
4. `cast`/`whereType` must remain lazy where they already are; `cast` must throw at
   iteration time, not at call time.
5. Error messages follow the SDK shapes already emitted elsewhere
   (`type 'X' is not a subtype of type 'Y' in type cast`) so `on TypeError` /
   `on Object` in script code matches.

### 6.2 Verification recipe (no content changes)

```powershell
# bounded probes (probes only, no pubspec/lib edits)
cd .dart_tool/tom-semantics-probe
dart run probe.dart cases-a.json results-a.json              # broader matrix
dart run probe_wheretype.dart baseline cases-wt.json b.json  # stock
dart run probe_wheretype.dart patched  cases-wt.json p.json  # P0 applied
dart run probe_fixes.dart baseline cases-g.json g-base.json  # 048/052/078 stock

# full gate, unchanged harness and unchanged expected outputs
cd .dart_tool/tom-engine-probe && dart run check.dart        # expect failures 20 -> 0
```

Gate for acceptance: the same `check.dart` run must go 20 → 0 **with
`assets/content/*.json` untouched** (`git diff --stat assets/content` empty).

---

## 7. Artefacts (probes only, uncommitted)

`.dart_tool/tom-semantics-probe/`:

- `probe.dart` — generic case runner (isolate + 15 s timeout, D4rt path identical
  to `check.dart`)
- `probe_wheretype.dart` — P0 prototype; `baseline` vs `patched` modes
- `probe_fixes.dart` — P0/P3 prototype harness
- `gen_*.dart` → `cases-{a,b,g,st,p2,t,sw,inf,rt,lessons,wt}.json`
- `results-*.json` — every case's actual stdout, error and verdict

Totals run this round: **≈120 independent programs**, of which the five lesson
shapes reproduce 5/5 and the P0 prototype flips 7/7 previously failing
`whereType` cases.
