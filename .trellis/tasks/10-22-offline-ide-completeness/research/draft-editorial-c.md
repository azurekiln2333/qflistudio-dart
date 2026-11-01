# 草稿受控中文改写（C 组，6 文件 / 第 239–300 课）

本报告记录 6 个章节草稿的散文改写。改写只动文本，不动程序。

> 时态说明：第 1 至 8 章是 C 组冻结时的快照，保留当时措辞。根已接管 16 章并改了部分用词。当前状态见第 9 章。

## 1 范围与硬约束

本次改写的 6 个文件位于第 239–300 课范围内。

| 文件 | 课数 | 程序块 | 输出行 |
|---|---|---|---|
| `curriculum/chapters/dates_money.dart` | 11 | 22 | 11 |
| `curriculum/chapters/collection_reporting.dart` | 12 | 24 | 12 |
| `curriculum/chapters/formatting_output.dart` | 11 | 22 | 11 |
| `curriculum/chapters/async_patterns.dart` | 11 | 22 | 11 |
| `curriculum/chapters/apis_contracts.dart` | 11 | 22 | 11 |
| `curriculum/chapters/mini_apps.dart` | 6 | 12 | 6 |
| 合计 | 62 | 124 | 62 |

允许改写的字段只有 10 个。

`title`、`summary`、`explain`、`objective`、`prerequisites`、`pitfalls`、`exampleTitle`、`exampleSummary`、`prompt`、`hint`。

禁止改动的对象全部未动。

`code`、`answer`、`output`、`id`、`chapter`、`level`、`concepts`、导出列表、导入语句。

本次没有运行任何构建命令。

未运行 Dart、Flutter、SDK、Hvigor、HDC、模拟器和 git。

## 2 人工改写规则

改写依据 `AGENTS.md` 与 `.trellis/spec/guides/controlled-chinese.md`。

逐条落实的规则如下。

1. 一句一个动作。原句用逗号串多个动作时拆成多句。见第 4.4 节。
2. 说明句 ≤ 40 字。指令句、题干、提示句、目标句 ≤ 25 字。
3. 用主动语态。把 `被抛弃` `被发现` `被拒绝` 这类写法改成有施事的句子。
4. 一词一义。同一概念全篇只用一个词，取舍见第 5 节。
5. 删全角分号。分号两侧的动作改成两句。
6. 删虚动词与套话。例如 `进行分析` `需要注意的是`。
7. 删营销形容词与含糊词。例如 `无缝` `强大` `若干` `一些`。
8. 技术词保持原样。`pow`、`Future.wait`、`String.length`、`startsWith`、`DateTime.utc`、`Completer`、`rethrow`、`isolate` 均未改名。
9. 情态词不动。见第 6 节。
10. 教学含义不动。限制说明与技术边界原意保留。

## 3 机械首查的误报与真实违规

首查工具是 `scripts/ste-lint-zh.py`。

### 3.1 分号误报

工具的 `SEMICOLON_RE` 是 `[；;]`。它同时匹配全角分号和 ASCII 分号。

Dart 代码每行结尾都是 ASCII 分号。直接对整文件跑首查，工具会把代码里的 `;` 算成硬违规。

本组 6 个文件现在的 ASCII 分号计数是 979 个。改写前散文里的全角分号是 59 个。

因此整文件首查会报出约 1038 条 `semicolon`。真实散文问题只有 59 条。

`research/draft-controlled-chinese-audit.md` 第 13、32、44 行记录的 4064 条属于同类误报。该数字覆盖 16 个文件。

### 3.2 多行 output 误报（审计修正）

审计脚本 `reconstruct()` 只屏蔽以 `output:` 开头的行。它没有屏蔽多行输出值的续行。

续行形如 `        "0:true 剩余1\n...",`。工具把这类续行当成散文，于是报出长句。

审计列表里有两处属于这个缺陷。

- `mini_apps.dart:44:10`，命中「45 字」。
- `apis_contracts.dart:404:10`，命中「41 字」。

这两条都是程序输出，不是散文。本次工具按字段定位，把它们排除在外。这两条不计入任何改写工作量。

### 3.3 真实违规来源

真实违规集中在三类。

- `explain` 超长句，多数是 41–69 字。
- `explain` 与 `pitfalls` 的全角分号。
- `synonym-rotation` 近义词轮换。

## 4 逐文件前后对比

统计口径：只统计 10 个可写字段。工具为 `ste.analyze`，`max_chars=40`。

| 文件 | 改写前 hard | 改写前 total | 改写后 hard | 改写后 total |
|---|---|---|---|---|
| `dates_money.dart` | 28 | 32 | 0 | 0 |
| `collection_reporting.dart` | 30 | 34 | 0 | 0 |
| `formatting_output.dart` | 27 | 30 | 0 | 0 |
| `async_patterns.dart` | 29 | 37 | 1 | 1 |
| `apis_contracts.dart` | 34 | 43 | 0 | 0 |
| `mini_apps.dart` | 15 | 17 | 0 | 0 |
| 合计 | 163 | 193 | 1 | 1 |

剩下的 1 条是有意保留。见第 5.4 节。

改写前数字来自 `.dart_tool/pi-briefs-20261025/lint_before.txt`。

### 4.1 句长复核

除 linter 外，另做了一次独立句长复核。规则是说明句 40 字、指令句与目标句 25 字。6 个文件的可写字段现在 0 条超限。

### 4.2 第二次复查：`objective` 句长

复查发现的输入是 `.dart_tool/pi-briefs-20261025/semantic-prose-findings.json`。

该复查把 `objective` 按指令口径算，上限 25 字。它用相邻字符串拼接后的整句计数。本组的 8 个目标句超过上限。

这 8 句都是「能 A，并 B」结构。它们把两个动作塞进一句。整改办法是按「一句一动作」拆成两句。

| 文件 | 行 | 改前 | 改前字数 | 改后 | 改后字数 |
|---|---|---|---|---|---|
| `dates_money` | L339 | 能把重复比例增长写成公式与循环，并区分计算精度和输出精度 | 27 | 能把重复比例增长写成公式与循环。能区分计算精度与输出精度。 | 15 / 12 |
| `collection_reporting` | L55 | 能编写有明确并列规则的排名，并安全处理 N 超过数据量的情况 | 27 | 能编写有明确并列规则的排名。能安全处理 N 超过数据量的情况。 | 13 / 14 |
| `async_patterns` | L331 | 能把多项异步读取收束为清楚的汇总接口，并定义空输入行为 | 26 | 能把多项异步读取收束为清楚的汇总接口。能定义空输入行为。 | 18 / 8 |
| `apis_contracts` | L112 | 能收集批量数据的所有可定位错误，并保持验证阶段没有副作用 | 27 | 能收集批量数据的所有可定位错误。能保持验证阶段没有副作用。 | 15 / 12 |
| `apis_contracts` | L215 | 能把受限版本约束转换成明确上下界，并识别零版本的特殊规则 | 27 | 能把受限版本约束转换成明确上下界。能识别零版本的特殊规则。 | 16 / 11 |
| `apis_contracts` | L318 | 能用可注入时间编写确定性的固定窗口限流，并说明边界突发特点 | 28 | 能用可注入时间编写确定性的固定窗口限流。能说明边界突发特点。 | 19 / 9 |
| `mini_apps` | L237 | 能把队列搜索、访问标记和路径回溯组合成可解释的寻路程序 | 26 | 能把队列搜索、访问标记和路径回溯组合成寻路程序。 | 22 |
| `mini_apps` | L308 | 能实现带词法验证、括号和优先级的双栈求值器，并拒绝不完整表达式 | 29 | 能实现带词法验证、括号和优先级的双栈求值器。能拒绝不完整表达式。 | 20 / 9 |

拆句保留原意与三个技术概念。`mini_apps` L237 只是去掉含糊限定语「可解释的」，并把三个动作保留在并列结构中。

整改后本组目标句 0 条超限。程序块仍与基线逐字节一致。

### 4.4 第三次复查：操作串拆句

前两轮只按句长改。一句一动作是独立规则，本轮补上。

检查范围：6 个文件的 `prompt` 与 `hint`。共拆 31 条，其中 26 条拆成两句，5 条拆成三句。

拆句规则：每句只留一个动作。句长不变，只是把逗号与「并」换成句号。技术词、约束和验收目标全部保留。

#### `dates_money.dart`（4 条，全为 hint）

| 行 | 改前 | 改后 |
|---|---|---|
| L86 | 对月和日各补两位，再直接连接。 | 对月和日各补两位。再直接连接。 |
| L207 | 只在工作日打印人员后递增独立的排班计数。 | 只在工作日打印人员。每次打印后递增独立的排班计数。 |
| L260 | 每天先向后移动一天，只有星期一至五才减少剩余数量。 | 每天先向后移动一天。只有星期一至五才减少剩余数量。 |
| L312 | 先计算商和余数，索引小于余数的份额加一。 | 先计算商和余数。索引小于余数的份额加一。 |

#### `collection_reporting.dart`（9 条）

| 行 | 字段 | 改前 | 改后 |
|---|---|---|---|
| L29 | prompt | 忽略空白分类，并把大小写不同的同名分类归在一起。 | 忽略空白分类。把大小写不同的同名分类归在一起。 |
| L30 | hint | 先 trim、转小写，再判断是否为空。 | 先 trim。再转小写。最后判断是否为空。 |
| L75 | prompt | 过滤不足八十分的记录，再输出全部合格者排名。 | 过滤不足八十分的记录。再输出全部合格者排名。 |
| L121 | hint | 先判断 score >= 60，再累加对应计数。 | 先判断 score >= 60。再累加对应计数。 |
| L170 | prompt | 为每个地区增加合计列，并输出全表总数。 | 为每个地区增加合计列。再输出全表总数。 |
| L171 | hint | 遍历行内 values 求和，再累计每一行合计。 | 遍历行内 values 求和。再累计每一行合计。 |
| L402 | hint | 先分别合并总分和人数，再做一次除法。 | 先分别合并总分和人数。再做一次除法。 |
| L444 | prompt | 记录整个流水中的最低余额，并打印它首次出现的事件编号。 | 记录整个流水中的最低余额。再打印它首次出现的事件编号。 |
| L493 | hint | 先算 current - baseline，再独立判断百分比是否有定义。 | 先算 current - baseline。再独立判断百分比是否有定义。 |

#### `formatting_output.dart`（6 条）

| 行 | 字段 | 改前 | 改后 |
|---|---|---|---|
| L37 | hint | 先比较文本长度，再选择 padLeft 或星号列表。 | 先比较文本长度。再选择 padLeft 或星号列表。 |
| L76 | prompt | 让编号从二十七开始，并在每条内容前显示方括号编号。 | 让编号从二十七开始。在每条内容前显示方括号编号。 |
| L217 | hint | 可把输出行重新用空格连接，与归一化后的输入比较。 | 可把输出行重新用空格连接。再与归一化后的输入比较。 |
| L361 | hint | 先识别 ## 加空格，再识别 # 加空格。 | 先识别 ## 加空格。再识别 # 加空格。 |
| L413 | hint | 先重复内部引号，再包围外部引号。 | 先重复内部引号。再包围外部引号。 |
| L452 | prompt | 将千分位分隔符作为参数，并输出用下划线分组的 123456789。 | 将千分位分隔符作为参数。再输出用下划线分组的 123456789。 |

#### `async_patterns.dart`（6 条）

| 行 | 字段 | 改前 | 改后 |
|---|---|---|---|
| L89 | hint | 解析后立即检查范围，使用 try/await/catch 验证错误。 | 解析后立即检查范围。使用 try/await/catch 验证错误。 |
| L140 | prompt | 遇到读取值超过五时停止循环，并打印已经累计的总数。 | 遇到读取值超过五时停止循环。再打印已经累计的总数。 |
| L141 | hint | await 得到值后先判断是否 break，再更新总数。 | await 得到值后先判断是否 break。再更新总数。 |
| L196 | prompt | 将批大小改为三，并输出每批处理的编号列表。 | 将批大小改为三。再输出每批处理的编号列表。 |
| L306 | prompt | 为超时包装提供 onTimeout 默认值，再等待原 Future 验证它仍可完成。 | 为超时包装提供 onTimeout 默认值。再等待原 Future。验证它仍可完成。 |
| L404 | hint | 先等待初值，再等待延迟变换，最后格式化。 | 先等待初值。再等待延迟变换。最后格式化。 |

#### `apis_contracts.dart`（4 条）

| 行 | 字段 | 改前 | 改后 |
|---|---|---|---|
| L135 | hint | 每行开始时记录错误列表长度，结束后比较增量。 | 每行开始时记录错误列表长度。结束后比较增量。 |
| L472 | hint | 先明确空键合法，再对每个实现运行相同检查。 | 先明确空键合法。再对每个实现运行相同检查。 |
| L519 | prompt | 增加年龄上限一百三十，并报告拒绝记录的原始行号。 | 增加年龄上限一百三十。再报告拒绝记录的原始行号。 |
| L576 | hint | 先验证每个已提供字段非空，再决定是否兼容合并。 | 先验证每个已提供字段非空。再决定是否兼容合并。 |

#### `mini_apps.dart`（2 条）

| 行 | 字段 | 改前 | 改后 |
|---|---|---|---|
| L101 | hint | 注册与普通库存变更分开，先检查再写入 Map。 | 注册与普通库存变更分开。先检查。再写入 Map。 |
| L210 | prompt | 添加停用词集合，过滤 help 后重新计算有效词数。 | 添加停用词集合。过滤 help。再重新计算有效词数。 |

#### 保留的句子

以下 7 句含「，并」，但第二分句是验收目标或约束，不是第二个操作。按授权保留。

| 位置 | 内容 | 保留理由 |
|---|---|---|
| `dates_money` L462 | 写一个拒绝三位小数的检查，并验证三种输入 | 动作 + 验收目标 |
| `collection_reporting` L120 | 将分箱改为两组，并验证六十分属于及格组 | 动作 + 验收目标 |
| `collection_reporting` L307 | 把冲突策略改为保留较大库存，并验证新键仍能加入 | 动作 + 验收目标 |
| `async_patterns` L403 | 把链改写成 async/await，并保持计算顺序和结果 | 动作 + 约束 |
| `async_patterns` L495 | 为每个追踪组增加结束标记，并检查编号独立 | 动作 + 验收目标 |
| `apis_contracts` L40 | 使用完整匹配的正则，并把新规则放在长度检查之后 | 动作 + 约束 |
| `mini_apps` L48 | 撤销金额与原记录互为相反数，并保留两条记录 | 属性 + 约束 |

因果与属性句同样保留。例：`formatting_output` L166「格数向下取整，百分比四舍五入，两者不必同值」。这是属性对照，不是步骤，本轮未动。

#### 改后残留的真正动作串

只统计 `prompt` 与 `hint`。

| 判据 | 改后 |
|---|---|
| 单句含 ≥ 2 个时序标记（先/再/然后/最后/接着/随后） | 0 |
| 单句用「，并」「，再」「，然后」拼接两个动作 | 7 |

残留的 7 条全部落在上表的保留清单里。按授权不计为待修。

两条副产物需说明。`collection_reporting` L30 原来把三个动作写成「先 A、B，再 C」，拆开后为三句。`async_patterns` L89 保留原词「使用」，只拆句，没有换词。

本轮未动 `explain`。该字段段落长，拆句需逐段重写，不在本次授权范围内。

### 4.3 一次迟到的修正

终验时发现 `formatting_output.dart` 还有 2 处 `展示`。这两处是早前把 `呈现` 统一成 `展示` 时留下的。

该文件的 keeper 是 `显示`。现已改回 `显示`。这说明终验不能只看自己上一轮的结论。

## 5 术语统一决策

选择 keeper 的规则是：文件内出现次数最多者。次数相同则按 `SYNONYM_GROUPS` 顺序。

### 5.1 已统一

| 文件 | 组 | 保留 | 改掉 | 理由 |
|---|---|---|---|---|
| `apis_contracts` | `检查` `校验` `核对` | `检查` | `校验` 12 处、`核对` 1 处 | 三者同义，非技术区分 |
| `apis_contracts` | `创建` `新建` `建立` `生成` | `生成` | `创建` 2 处 | 同义 |
| `apis_contracts` | `错误` `异常` `报错` `故障` | `错误` | `报错` 3 处 | `报错` 属口语，`错误` 属名词 |
| `apis_contracts` | `显示` `展示` `呈现` | `展示` | `显示` 1 处 | 同义 |
| `apis_contracts` | `运行` `执行` | `运行` | `执行` 6 处 | 同义 |
| `apis_contracts` | `修改` `更改` `变更` | `修改` | `更改` 1 处 | 同义 |
| `mini_apps` | `检查` `校验` `核对` | `检查` | `核对` 3 处、`校验` 3 处 | 同义 |
| `mini_apps` | `显示` `展示` `呈现` | `展示` | `显示` 1 处 | 同义 |
| `mini_apps` | `运行` `执行` | `运行` | `执行` 2 处 | 同义 |
| `formatting_output` | `显示` `展示` `呈现` | `显示` | `展示` 2 处 | 同义 |
| 其余 4 文件 | 各同义组 | 计数最高者 | 其余成员 | 同义 |

### 5.2 一处主动避开近义词组

`mini_apps.dart` 第 295 课原文用 `界面和存储`。该文件的 keeper 是 `保存`。

`界面和保存` 读起来不通顺。改写改为 `界面与持久化`。

这样做既没有制造新的轮换，也保住了原意。

### 5.3 一处概念区分主动修正

`dates_money.dart` 有一个 objective 用 `显示精度`。原文正文说的是只在输出时保留两位小数。

计算精度和输出精度是两件事。改写改为「输出精度」。这是唯一一次主动区分，不是统一。

### 5.4 有意保留的区分：`错误` 与 `异常`

`async_patterns.dart` 保留 1 条 `synonym-rotation`，命中 `异常`。

该文件 `错误` 出现 16 次，`异常` 出现 13 次。两者不是同义词。

- `错误` 指泛指失败与编程错误。例：`所有异常都重试可能放大不可恢复错误`。
- `异常` 指 Dart 的 `Exception` 类型。正文出现 `TimeoutException`、`DataUnavailable`、`throw`、`rethrow`。

把这些位置改成 `错误` 会削弱类型信息。所以保留双词，并在此备案。

这条违规是唯一残留。它属于工具局限，不属于草稿缺陷。

## 6 情态保全

linter 没有情态规则。它自己的自检用例断言「情态永不标记（可能已失败）」。

本次没有新增、删除或弱化任何情态词。

改写前后情态句共 22 条，全部仍在原位。清单见附录 B。

改写手法上没有把「可能」换成「会」，也没有把「可能」换成「必然」。

## 7 程序块不变证明

### 7.1 与基线逐字节比对

基线文件是 `.dart_tool/pi-briefs-20261025/draft-editorial-baseline.json`。该文件只读，未写入。

比对方法：从每个章节文件抽出 `r'''…'''` 程序块与 `output:` 行，与基线逐字节比较。

比对命令见附录 A。输出如下。

```
dates_money            programs=True(22) outputs=True(11/11)
collection_reporting   programs=True(24) outputs=True(12/12)
formatting_output      programs=True(22) outputs=True(11/11)
async_patterns         programs=True(22) outputs=True(11/11)
apis_contracts         programs=True(22) outputs=True(11/11)
mini_apps              programs=True(12) outputs=True(6/6)
ALL_OK
```

全库基线是 360 个程序块与 180 条输出。本组覆盖其中 124 个程序块与 62 条输出。

### 7.2 标识行比对

基线另存 `id`、`chapter`、`level` 的原始行。本组 186 行全部一致。

```
dates_money            identity_lines exp=33 got=33 identical=True
collection_reporting   identity_lines exp=36 got=36 identical=True
formatting_output      identity_lines exp=33 got=33 identical=True
async_patterns         identity_lines exp=33 got=33 identical=True
apis_contracts         identity_lines exp=33 got=33 identical=True
mini_apps              identity_lines exp=18 got=18 identical=True
ALL_IDENTITIES_IDENTICAL= True
```

### 7.3 concepts 的说明

`concepts` 字段不在基线里，也没有做过比对。

本次没有任何一次编辑以 `concepts` 行作为定位锚点。该字段按构造未动。

### 7.4 未做的验证

没有运行任何程序。上面的 `output` 只是原文文本，未经运行确认。

本报告不主张教学示例的输出正确性。输出正确性由实际运行与维护者判定。

## 8 未完成与边界

- 未运行 SDK、Flutter、Dart、Hvigor、构建、设备。
- 未做 git 操作。
- 未改动核心库 `qfli_studio_core`。
- 未处理本组 6 个文件之外的任何章节。
- 未对 `concepts` 做机械比对。
- 未对散文做语义审校之外的正确性验证。

## 附录 A 复现命令

```powershell
cd D:\MyNewProjects\qfli_dart
$env:PYTHONIOENCODING='utf-8'
python -X utf8 .dart_tool/pi-briefs-20261025/editorial_tool.py verify
```

逐文件 lint 需每个文件单独一个进程。linter 的近义词计数是进程级的，同一进程内跑多个文件会串数。

```powershell
python -X utf8 -c "import sys; sys.path.insert(0,'.dart_tool/pi-briefs-20261025'); import editorial_tool as et; n='mini_apps'; ste=et.load_ste(); text=et.read(n); fields=et.parse(text); masked=et.mask_text(text, fields, set(et.EDITABLE)); fs=ste.analyze(masked, n, ste.Options(max_chars=40)); print(len(fs), [(f.rule, f.match) for f in fs])"
```

标识行比对与基线比对脚本同在 `.dart_tool/pi-briefs-20261025/`。

## 附录 B 情态句清单

`dates_money.dart`

- L17 pitfalls：不要依赖 `DateTime.now`，否则相同示例每天可能产生不同结果
- L341 pitfalls：逐期舍入与最后舍入可能得到不同结果

`collection_reporting.dart`

- L13 explain：一批工单可能包含重复分类
- L57 pitfalls：只比较分数可能让并列结果依赖原始输入顺序
- L282 explain：不同领域可能需要最大值、较新记录或错误提示

`formatting_output.dart`

- L18 pitfalls：直接 `substring` 可能截断表情代理对
- L189 explain：按固定位置切字符串可能把一个单词拆开
- L387 explain：字段本身可能包含逗号、双引号或换行
- L431 explain：不同地区可能使用空格或句点
- L481 pitfalls：最后一栏可能不足行数

`async_patterns.dart`

- L168 explain：一次启动所有异步任务可能占用过多资源
- L227 pitfalls（原文引用）：`所有异常都重试可能放大不可恢复错误`
- L282 explain：仅仅忽略超时后的结果可能仍然留下后台副作用
- L475 explain：真实实时日志仍可能交错

`apis_contracts.dart`

- L111 explain：用户可能看到错误消息
- L317 explain：固定窗口在边界附近可能短时放行两倍额度
- L436 explain：示例没有依赖可能在发布模式关闭的 assert
- L440 pitfalls：只比较两个实现的一次输出，可能让相同错误同时通过
- L441 pitfalls：发布模式可能关闭 assert
- L497 pitfalls：迁移时原地改旧 Map，失败后可能无法恢复原始输入
- L543 explain：接口升级期间可能同时遇到旧字段和新字段
- L547 pitfalls：无条件优先新字段可能掩盖上游同时发送的不一致数据

`mini_apps.dart`

- 无情态句。

合计 22 条。

## 9 交接与后续冻结批次

本章记录快照之后发生的事。前文保持当时快照时态，不重写。

### 9.1 接管

根已接管 16 章，并开启新的源码冻结批次。

C 组 6 章的写入权已交回根。本报告作者停止章节写入。

### 9.2 根在 10 个白名单字段上的改动

1. 统一 `展示` → `显示`。
2. 把「运行并观察」拆为「运行示例。观察」。

### 9.3 只读复核结果

本节数字为交接后重新测量，不是快照数字。

| 项 | 结果 |
|---|---|
| 16 文件程序块 | 360 个，与基线一致 |
| 16 文件输出 | 180 条，与基线一致 |
| `id`/`chapter`/`level` | 全部一致 |
| C 组 `显示` | 55 处 |
| C 组 `展示` | 0 处 |
| C 组「运行并观察」 | 0 处 |
| C 组「运行示例。观察」 | 0 处 |

C 组没有使用「运行并观察」句式。该组 `exampleSummary` 用的是「完整运行演示。」，所以第 2 项改动没有落到 C 组。

### 9.4 C 组当前状态

| 文件 | 硬违规 | 句长超限 | ≥2 时序标记句 | 「，并」拼接句 |
|---|---|---|---|---|
| `dates_money` | 0 | 0 | 0 | 1 |
| `collection_reporting` | 0 | 0 | 0 | 2 |
| `formatting_output` | 0 | 0 | 0 | 0 |
| `async_patterns` | 1 | 0 | 0 | 2 |
| `apis_contracts` | 0 | 0 | 0 | 1 |
| `mini_apps` | 0 | 0 | 0 | 1 |

唯一硬违规仍是 `async_patterns` 的 `异常`。这与第 5.4 节一致，属于有意保留的技术区分。

「，并」拼接句合计 7 条，全部是第 4.4 节保留清单里的验收目标与约束句。真正动作串仍为 0。

### 9.5 根改动后的过期记录

以下条目仅作历史记录，已不代表当前文本。

1. §4.3 记录把 `formatting_output` 的 `展示` 改回 `显示`。根现在已把这统一推广到 10 个白名单字段。
2. 第 4 轮只读复核报过组级分裂：5 文件用 `展示`，`formatting_output` 用 `显示`。该分裂已由根的全局统一消除。
3. §5.1 表格里的 `显示`/`展示` 统一决策，已升级为全 16 章口径。

### 9.6 边界

本轮只读，只写本报告。

未写章节文件，未复写根的改动，未运行任何程序。

后续只读等待。若后续步骤失败并重试，也不恢复章节旧编辑任务。
