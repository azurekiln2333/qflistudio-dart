# 草稿中文散文修订报告 B（181..238，五章）

> 本文件是本次修订的交付文档，第 3 版。
> 只改中文散文。未改代码块、答案块、程序输出、`id` / `chapter` / `level`、导出列表、`import`、生成资产。
> 本轮未运行 Dart / SDK / Flutter / analyze / build / device / controls。本轮未做 git 或 core 操作。
> 状态：已冻结。未经新指令不再改写这 5 个文件。
> 第 3 版按根的明确规则拆分了全部真实动作串（含 hint / prompt 步骤）。
> 第 1..13 节是历史快照，记述本报告冻结时的状态。根随后接管 16 章，见第 14 节。

## 1. 范围与归属

| 文件 | 章节 key | lesson id | 课数 | 程序块 | 输出 |
| --- | --- | --- | --- | --- | --- |
| `curriculum/chapters/math_stats.dart` | math-stats | 181..192 | 12 | 24 | 12 |
| `curriculum/chapters/oop_modeling.dart` | oop-modeling | 193..204 | 12 | 24 | 12 |
| `curriculum/chapters/enum_states.dart` | enum-states | 205..215 | 11 | 22 | 11 |
| `curriculum/chapters/errors_resilience.dart` | errors-resilience | 216..226 | 11 | 22 | 11 |
| `curriculum/chapters/json_modeling.dart` | json-modeling | 227..238 | 12 | 24 | 12 |

合计 58 课、116 个程序块（58 段 `code` + 58 段 `answer`）、58 段 `output`、174 行身份字段。

### 1.1 可改字段（白名单，已更正）

`title`、`summary`、`explain`、`objective`、`prerequisites`、`pitfalls`、`exampleTitle`、`exampleSummary`、`prompt`、`hint`。

**`concepts` 不在白名单。** 第 1 版报告错误地把 `concepts` 列入白名单。本版已删除。

依据根提供的工具源码 `.dart_tool/pi-briefs-20261025/editorial_tool.py`：

```python
EDITABLE = (
    'title', 'summary', 'explain', 'objective', 'prerequisites', 'pitfalls',
    'exampleTitle', 'exampleSummary', 'prompt', 'hint',
)
# Fields the audit counted as prose but the task does NOT allow editing.
NOT_EDITABLE_PROSE = ('concepts',)
```

### 1.2 `concepts` 改动已回滚

第 1 轮曾误改 2 行 `concepts`。已按本地原始快照逐字恢复。

| 文件 | 行 | 第 1 轮误改 | 已恢复为 |
| --- | --- | --- | --- |
| `math_stats.dart` | 380 | `维度检查` | `维度校验` |
| `json_modeling.dart` | 714 | `结构检查` | `结构校验` |

逐行审计确认：当前改动行的字段分布中已无 `concepts`。

| 文件 | 改动行数 | 字段分布 |
| --- | --- | --- |
| math_stats.dart | 26 | explain 12, pitfalls 5, hint 4, prompt 3, summary 1, exampleSummary 1 |
| oop_modeling.dart | 20 | explain 12, pitfalls 3, hint 3, objective 1, prompt 1 |
| enum_states.dart | 28 | explain 11, hint 4, prompt 4, summary 3, pitfalls 3, exampleSummary 3 |
| errors_resilience.dart | 37 | explain 11, prompt 9, hint 7, summary 3, pitfalls 3, exampleSummary 3, objective 1 |
| json_modeling.dart | 34 | explain 12, hint 8, summary 4, exampleSummary 4, objective 2, pitfalls 2, prompt 2 |

合计 145 行，全部在白名单内。`title`、`exampleTitle`、`prerequisites` 未动。

## 2. 人工规则（依据）

来源：`AGENTS.md` 与 `.trellis/spec/guides/controlled-chinese.md`。

1. 一句只写一个动作。
2. 用主动语态。删掉无施事的 `被…`。
3. 同一概念只用一个术语。
4. 不用分号连接动作。全角 `；` 改句号或拆句。
5. 说明句每条最多 40 字。
6. 指令、练习 `prompt`、`hint`、`objective` 每句最多 25 字。
7. 删虚动词名词化（`进行` / `加以` + 名词）。
8. 删套话。
9. 删营销形容词。
10. 用具体对象替换含糊词。
11. 保留情态词（`可能` / `也许` / `大概` / `倾向于`）。置信度是内容。
12. 代码块不是散文。
13. 分清动作与技术因果。属性 / 因果 / 规则句保留，并从动作串计数排除。
14. 祈使句允许省略主语。省略主语不是残句。

术语一致不等于机械统一。见第 7 节。

## 3. 方法与工具局限

### 3.1 机械首查

```powershell
python scripts/ste-lint-zh.py curriculum/chapters/math_stats.dart curriculum/chapters/oop_modeling.dart curriculum/chapters/enum_states.dart curriculum/chapters/errors_resilience.dart curriculum/chapters/json_modeling.dart
```

修订前（整文件，含代码）：

| 规则 | 条数 |
| --- | --- |
| semicolon | 1379 |
| long-sentence | 35 |
| synonym-rotation | 38 |
| passive-voice | 21 |
| vague-word | 3 |
| compound-aspect | 1 |
| 合计 | 1477 |

修订后（整文件，含代码）：

| 规则 | 条数 |
| --- | --- |
| semicolon | 1360 |
| synonym-rotation | 9 |
| long-sentence | 2 |
| passive-voice | 1 |
| 合计 | 1372 |

### 3.2 检查器没有 Dart 语法感知

检查器把任何 `;` / `；` 判为 semicolon。Dart 每行都有 ASCII `;`，所以整文件跑会大面积误报。

证据：整文件 semicolon 1360 条，散文中只有 0 条。差额 1360 条是 Dart 代码的 `;`。

整文件与散文范围的差额：1372 − 8 = 1364 条。其中 1360 条是分号，另 4 条落在代码行（long-sentence 2、passive-voice 1、synonym-rotation 1）。

结论：整文件结果只能当首查。判定必须用散文范围。

### 3.3 散文范围与相邻字面量

散文范围：只取白名单字段的字面量内容，跳过 `code` / `answer` 的 `r'''` 块与 `output` 行，保持原行号。

关于「相邻字符串拼接」，本轮专门做了检查，结论如下。

- Dart 隐式拼接是 `"a" "b"`（中间无逗号）。本轮 5 个文件里，**标量字段没有任何一处是多字面量拼接**（扫描结果：`MULTI-LITERAL SCALAR FIELDS: 0`）。
- `<String>["a", "b", "c"]` 是列表，元素之间是逗号，**不是**拼接。把列表元素连起来会制造假长句。第一版脚本曾这样错连 116 处，已修正为按元素分别检查。
- 因此本组不存在「拼接后才超长」的隐藏长句。

### 3.4 逐句人工修订

检查器只报位置。先导出每处命中所在整句，再逐句改写。替换按「原文恰好出现一次」断言，且只允许落在白名单字段的字面量内。

| 轮次 | 替换数 | 说明 |
| --- | --- | --- |
| 第 1 轮 | 141 | 分号、长句、含糊词、被动、同义词 |
| 第 2 轮 | 45 | 见第 4 节 |
| 第 3 轮 | 61 | 真实动作串（55 个唯一句，见第 4.4 节） |
| 合计 | 247 | 落在 145 行上 |

### 3.5 三种长度口径

| 口径 | 说明 | 用途 |
| --- | --- | --- |
| 检查器 `count_chars` | 汉字算 1，连续拉丁字母 / 数字算 1，不含标点 | 项目机械标准 |
| 根等同语义检查 | 同上，`objective` / `prompt` / `hint` 限 25，其余限 40 | 根的工具口径 |
| 含标点口径 | 汉字 + 拉丁串 + 标点 | 人工复核，比机械口径更严 |

第 1 版只用了机械口径，所以漏掉 lesson 181 那句 42 字（含标点）的说明句。第 2 轮补上含标点口径。

## 4. 第 2、3 轮修订（45 + 61 处）

### 4.1 类别 A：含标点超 40 字（39 处）

| 字段 | 处数 | 处理 |
| --- | --- | --- |
| explain | 26 | 拆成两句 |
| prompt | 7 | 拆成两句，或拆后各自 ≤25 字 |
| hint | 6 | 拆句，或删填充词（如 `一个`） |

分布：math 6、oop 8、enum 7、errors 12、json 6。

代表例（lesson 181，根点名的那句）：

- 前：`欧几里得算法不断把较大问题换成余数更小的问题，直到余数为零，因此不需要枚举所有因子。`（39 汉字，含标点 42）
- 后：`欧几里得算法不断把较大问题换成余数更小的问题，直到余数为零。因此不需要枚举所有因子。`

hint 的短化例（不拆句，删填充词）：

- 前：`分别检查横纵坐标误差的绝对值是否小于一个很小的阈值。`（含标点 26）
- 后：`分别检查横纵坐标误差的绝对值是否小于很小的阈值。`（含标点 24）

### 4.2 类别 B：三步动作串（5 处）

针对根点名的 `本例先检查记录结构，再处理商品编号和数量，最后识别规范化后的重复编号。`

| 文件 | 行 | 处理 |
| --- | --- | --- |
| math_stats | 265 | 拆 4 句 |
| enum_states | 132 | 拆 3 句 |
| errors_resilience | 490 | 拆 3 句 |
| errors_resilience | 638 | 拆 3 句 |
| json_modeling | 715 | 拆 3 句 |

json 715 结果：

- 前：`本例先检查记录结构，再处理商品编号和数量，最后识别规范化后的重复编号。`
- 后：`本例先检查记录结构。程序再处理商品编号和数量。最后识别规范化后的重复编号。`

### 4.3 类别 C：本组唯一一条语义长度（1 处）

根提供的 `.dart_tool/pi-briefs-20261025/semantic-prose-findings.json` 中，本组只有 1 条：

```json
{ "path": "curriculum\\chapters\\json_modeling.dart", "line": 717, "field": "objective",
  "rule": "semantic-length", "count": 26, "limit": 25 }
```

处理：

- 前：`能建立有顺序的清洗规则，并让接受数与拒绝数对应原始记录`（26）
- 后：`能建立有序的清洗规则，让接受数与拒绝数对应原始记录`（24）

`有顺序` → `有序`，删除 `并`。含义不变。

### 4.4 第 3 轮：真实动作串（61 处，55 个唯一句）

根明确一条规则（无需再问许可）：

1. `一句一动作`。短于 25 字不能代替这句规则。
2. `hint` / `prompt` 必须拆清实际步骤。祈使句允许省略主语，不是残句。
3. 属性 / 因果句保留，并从动作串计数排除。例：`均值使用所有数值，容易受极端值影响。`
4. 两个动作的对照句要拆。例：`成功推进关卡，失败扣除机会。` → `成功时推进关卡。失败时扣除机会。`

依此扫描全组 142 个候选。分类：

| 类别 | 条数 | 处理 |
| --- | --- | --- |
| 真实动作串 | 61 处（55 个唯一句） | 拆分 |
| 属性 / 因果 / 规则 / 目的 | 81 句 | 保留 |

拆分例（根的原文）：

- `先记录长度，再 removeWhere，最后比较长度。` → `先记录长度。再调用 removeWhere。最后比较长度。`
- `成功推进关卡，失败扣除机会，任何终态收到后续结果都保持不变。` → `成功时推进关卡。失败时扣除机会。任何终态收到后续结果都保持不变。`

hint / prompt 拆分例：

- `先处理分母符号，再把分子分母同时除以 gcd。` → `先处理分母符号。再把分子分母同时除以 gcd。`
- `增加总条数参数，并校验页码是否超过最后一页。` → `增加总条数参数。同时校验页码是否超过最后一页。`

保留例（属性 / 因果）：

- `均值使用所有数值，容易受极端值影响。`
- `外推远离观测范围时，线性关系可能不再成立。`（`可能` 保留）

一处用词修正：拆分后 `再一次返回完整问题列表` 改成 `再一次性返回完整问题列表`，避免读成「再返回一次」。

## 5. 修订结果

### 5.1 散文范围前后对比

| 文件 | 前·总 | 后·总 | 前·分号 | 后·分号 | 前·长句 | 后·长句 | 前·同义 | 后·同义 | 前·被动 | 后·被动 | 前·含糊 | 后·含糊 | 前·>25 | 后·>25 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| math_stats.dart | 24 | 1 | 9 | 0 | 5 | 0 | 5 | 1 | 3 | 0 | 1 | 0 | 1 | 0 |
| oop_modeling.dart | 20 | 2 | 1 | 0 | 6 | 0 | 11 | 2 | 1 | 0 | 1 | 0 | 0 | 0 |
| enum_states.dart | 25 | 1 | 3 | 0 | 9 | 0 | 7 | 1 | 5 | 0 | 1 | 0 | 0 | 0 |
| errors_resilience.dart | 20 | 2 | 3 | 0 | 7 | 0 | 6 | 2 | 4 | 0 | 0 | 0 | 2 | 0 |
| json_modeling.dart | 25 | 2 | 3 | 0 | 6 | 0 | 9 | 2 | 7 | 0 | 0 | 0 | 1 | 0 |
| 合计 | 114 | 8 | 19 | 0 | 33 | 0 | 38 | 8 | 20 | 0 | 3 | 0 | 4 | 0 |

说明：`前·总` 不含最右的 `>25` 列，含 comp-aspect（仅 math 1 条）。`后·总` 等于同义列。

- 全角分号：19 → 0。
- 超长说明句（机械口径）：33 → 0。
- 含糊词：3 → 0。
- 被动语态：20 → 0。
- 复合体貌：1 → 0。
- `prompt` / `hint` 超 25：4 → 0。
- 同义轮换：38 → 8。其中 2 条在 `concepts`，按指令不可改。

### 5.2 三种口径的最终数

| 口径 | 修订前 | 修订后 |
| --- | --- | --- |
| 检查器散文范围 | 114 | 8 |
| 检查器硬违规 | 90 | 8 |
| 根等同语义检查 | 1（仅 json 717） | **0** |
| 含标点 > 限额 | 39 | **0** |

### 5.3 改写原则

拆分：在语义边界改句号，不删信息。

主动：补出施事或改陈述。

- 前：`数据传输对象常在边界处接收一张映射，但保存原映射引用会让外部代码继续修改对象内容。`
- 后：`数据传输对象常在边界处接收一张映射。如果保存原映射引用，外部代码会继续修改对象内容。`

含糊词具体化（第 1 轮）。

术语统一（第 1 轮）。

不硬换词的地方改述：

| 位置 | 原词 | 处理 | 原因 |
| --- | --- | --- | --- |
| math 191 | `相关性` | `变量间的关联` | 统计术语，不是含糊词 |
| errors 559 | `执行策略` | `重试策略` | 名词短语有确定含义 |
| enum 562 | `执行边界` | `动作边界` | 不为统一而扭曲 |
| enum 565 | `执行层授权` | `底层授权` | 同上 |
| json 492 | `路径生成` | `路径结构` | `路径建立` 不自然 |

## 6. 根等同语义检查（自建，非破坏）

用根的工具逻辑复算，只写自己的文件 `.dart_tool/expansion-b/_semantic_check.json`，不覆盖根的 `semantic-prose-findings.json`。

结果：

```json
{"counts": {"math_stats": 0, "oop_modeling": 0, "enum_states": 0,
            "errors_resilience": 0, "json_modeling": 0}, "total": 0}
```

本组 0 条。修订前为 1 条（json 717）。

## 7. 保留的合理区分（8 条同义轮换）

检查器按「同组出现两个以上成员」报轮换。以下 8 条保留，并写明理由。

### 7.1 `错误` / `异常` / `故障`（5 条）

| 文件 | 条数 | 说明 |
| --- | --- | --- |
| oop_modeling | 1 | `格式异常` 指 Dart `Exception` |
| enum_states | 1 | `用异常向调用者报告拒绝` 指 `Exception` |
| errors_resilience | 2 | 整章讲异常处理；`异常` 指 `Exception`，`错误` 指 `Error` / 错误码，`故障` 指运行时故障 |
| json_modeling | 1 | `抛出格式异常` 指 `Exception` |
| （合计） | 5 | — |

`错误` 与 `异常` 在 Dart 里是不同概念。`Exception` 可预期、可捕获。`Error` 多指程序缺陷。统一成一个词会让教程说错。

`故障` 指运行期失败，与错误码不同。第 224 课 `把临时故障和永久拒绝分开处理` 保留 `故障`。

### 7.2 `配置` / `设定`（1 条，同课 3 句）

oop 第 198 课讲温控器。

- `温度设定值` 是控制领域的设定点（setpoint），是业务数值。
- `配置` 是配置对象。

两者不是同一概念。保留 `设定值`。

### 7.3 `检查` / `校验`（2 条，均在 `concepts`）

| 文件 | 行 | 文本 | 状态 |
| --- | --- | --- | --- |
| math_stats | 380 | `维度校验` | `concepts`，不可改，已恢复 |
| json_modeling | 714 | `结构校验` | `concepts`，不可改，已恢复 |

这 2 条位于不可编辑字段。按指令回滚后必然重现。它们不属于本轮散文缺陷。

### 7.4 小结

- 白名单散文内的同义轮换：6 条，全部是第 7.1 / 7.2 节的技术区分。
- `concepts` 内：2 条，不可改。
- 合计 8 条，与检查器一致。

## 8. 动作串剩余数（第 3 轮后）

### 8.1 真实动作串：0 条

第 3 轮按根规则扫描全组候选 142 条，拆分真实动作串 61 处（55 个唯一句）。

拆分后重新扫描：候选 83 条。逐条人工分类后，**真实动作串 0 条**，其余 83 条全部是属性 / 因果 / 规则 / 目的句，按根规则保留并从计数排除。

| 字段 | 拆分前候选 | 拆分后候选 |
| --- | --- | --- |
| explain | 85 | 62 |
| pitfalls | 16 | 14 |
| hint | 18 | 1 |
| prompt | 6 | 1 |
| summary | 7 | 1 |
| exampleSummary | 7 | 1 |
| objective | 3 | 3 |
| 合计 | 142 | 83 |

`hint` 从 18 降到 1，`prompt` 从 6 降到 1，`summary` / `exampleSummary` 从 7 降到 1。指令类字段的步骤已拆清。

剩余 83 条的判定示例：

| 句 | 判定 |
| --- | --- |
| `再用除法缩小乘数，能避免直接把两个大整数相乘。` | 动作 + 目的 |
| `读者可以比较标记工作与最终输出，理解…思路。` | 动作 + 目的 |
| `本例用有序插入的映射记录因子和指数，既保留计算结构，也能生成可读分解式。` | 动作 + 能力 |
| `外推远离观测范围时，线性关系可能不再成立。` | 因果（`可能` 保留） |
| `两个对象即使内容相同，引用通常也不相等，不能直接比较两个列表。` | 属性 |
| `关键顺序是先验证再提交，不能先写入后发现错误。` | 规则（描述顺序，不是执行步骤） |

清单在 `.dart_tool/expansion-b/_chains_after.txt`。

### 8.2 其余

| 项 | 数量 | 说明 |
| --- | --- | --- |
| 真实动作串 | 0 | 第 3 轮已拆完 |
| 属性 / 因果 / 规则句 | 83 | 按根规则保留 |
| 检查器硬违规（散文） | 8 | 全部为第 7 节的技术区分 |
| 根等同语义违规 | 0 | — |
| 含标点超长句 | 0 | — |
| 全角分号 | 0 | — |
| 含糊词 | 0 | — |
| 被动语态 | 0 | — |
| `prompt` / `hint` / `objective` 超 25 | 0 | — |
| `concepts` 越权改动 | 0 | 已回滚 |

**本组真实动作串已清零。** 保留的 83 条是属性 / 因果 / 规则句，不是动作串。

## 9. 情态与置信度

检查器永不标记情态词。本轮统计 `可能` / `也许` / `大概` / `倾向于`。

| 文件 | 前 | 后 |
| --- | --- | --- |
| math_stats.dart | 4 | 4 |
| oop_modeling.dart | 4 | 4 |
| enum_states.dart | 3 | 3 |
| errors_resilience.dart | 5 | 5 |
| json_modeling.dart | 4 | 4 |
| 合计 | 20 | 20 |

情态数前后一致。修订没有把可能性改成确定事实。第 2 轮的拆分句完整保留 `可以` / `会` / `可能` / `应`。

例（`可能` 保留，未改成确定事实）：

- enum 323 pitfalls：`循环结束后仍可能有尚未输出的词。`
- errors 220 pitfalls：`发布模式可能关闭 assert，不能用它独自验证不可信输入。`
- json 229 explain：`嵌套 JSON 的每一层都可能是不同结构，不能因为顶层是映射，就假定更深字段也符合预期。`

拆分句也未删掉 `可以` / `会` / `应` 这类语气词。

## 10. 可执行块不变检查

### 10.1 根基线（只读）

`.dart_tool/pi-briefs-20261025/draft-editorial-baseline.json` 只读，未修改。

| 文件 | 程序块 | 一致 | 输出 | 一致 | 身份行 | 一致 |
| --- | --- | --- | --- | --- | --- | --- |
| math_stats.dart | 24/24 | 是 | 12/12 | 是 | 36/36 | 是 |
| oop_modeling.dart | 24/24 | 是 | 12/12 | 是 | 36/36 | 是 |
| enum_states.dart | 22/22 | 是 | 11/11 | 是 | 33/33 | 是 |
| errors_resilience.dart | 22/22 | 是 | 11/11 | 是 | 33/33 | 是 |
| json_modeling.dart | 24/24 | 是 | 12/12 | 是 | 36/36 | 是 |

合计 116 程序块、58 输出、174 身份行，逐字未变。

基线对跨行 `output` 只存首行。本轮另用修订前本地快照逐字节比对完整 `output`，全部一致（`snap=True`）。

### 10.2 结构与行尾

| 文件 | 行数 | 未变 | CRLF | CRLF 未变 |
| --- | --- | --- | --- | --- |
| math_stats.dart | 748 | 是 | 748 | 是 |
| oop_modeling.dart | 800 | 是 | 800 | 是 |
| enum_states.dart | 760 | 是 | 760 | 是 |
| errors_resilience.dart | 780 | 是 | 780 | 是 |
| json_modeling.dart | 791 | 是 | 791 | 是 |

课数 / `code` / `answer` / `output` / `DartExercise` 计数：12/12/11/11/12 全部保留。

编码 UTF-8，行尾 CRLF，未混用。

### 10.3 结论与边界

代码块、答案块、输出、身份字段逐字未变。散文修订没有泄露到可执行块。

这一条证明**字节未变**，不证明输出仍是真实 stdout。见第 11 节。

## 11. 未验证的门（本窗口不做）

| 门 | 状态 | 原因 |
| --- | --- | --- |
| `dart run tool/build_dart_content.dart` | 未运行 | 无 Dart 授权 |
| `dart run tool/verify_dart_content.dart` | 未运行 | 无 Dart 授权 |
| `dart run tool/verify_portable_content.dart` | 未运行 | 无 Dart 授权 |
| `flutter analyze --no-pub` | 未运行 | 无 Flutter 授权 |
| `flutter test --no-pub` | 未运行 | 无 Flutter 授权 |
| `dart format --set-exit-if-changed` | 未运行 | 无 Dart 授权 |
| 安装包 / OHOS 设备验收 | 未运行 | 无 device 授权 |

风险：

- 只改字符串常量内容，未增删行，未改缩进。`dart format` 预期不变，但未证明。
- `code` / `answer` / `output` 逐字未变，既有「输出等于真实 stdout」结论不受影响。本轮未重测。
- 未与 SDK 实际运行对照，不宣称运行时正确。

## 12. 复现

```powershell
# 1) 机械首查（会大量误报，仅作首查）
python scripts/ste-lint-zh.py curriculum/chapters/math_stats.dart curriculum/chapters/oop_modeling.dart curriculum/chapters/enum_states.dart curriculum/chapters/errors_resilience.dart curriculum/chapters/json_modeling.dart

# 2) 检查器自检
python scripts/ste-lint-zh.py --selftest    # -> selftest OK

# 3) 散文范围复检
python .dart_tool/expansion-b/_count.py

# 4) 根等同语义检查（非破坏，写自己的文件）
python .dart_tool/expansion-b/_semantic_check.py

# 5) 含标点长度
python .dart_tool/expansion-b/_strict.py

# 6) 可执行块不变
python .dart_tool/expansion-b/_verify.py     # -> ALL_OK

# 7) 字段级改动审计（白名单校验）
python .dart_tool/expansion-b/_audit_changes.py

# 8) 两动作句清单
python .dart_tool/expansion-b/_actions2.py
```

临时脚本与修订前备份在 `.dart_tool/expansion-b/`。该目录被 `.gitignore` 忽略。

## 13. 冻结声明

- 5 个文件已冻结。未收到新指令前不再改写。
- 程序块、答案块、输出、身份字段的字节未变。
- 未做 git / core / SDK / Dart / Flutter / build / device 操作。
- 散文硬违规剩余 8 条，全部是第 7 节的技术区分，其中 2 条在不可编辑的 `concepts`。
- 真实动作串剩余 0 条。候选 83 条均为属性 / 因果 / 规则句，按根规则保留。
- 第 3 轮拆分 61 处（55 个唯一句），含 hint / prompt 步骤。

## 14. 交接与只读状态（本窗只读记录）

> 本节记录章节交接。第 1..13 节是历史快照，不追平根的后续改写。

- 本窗未写任何章节文件。只做源码 / 文档只读检查。
- 根已接管 16 章，开始新的源码冻结批次。
- 根在 10 个白名单字段统一 `展示` → `显示`。
- 根把 `运行并观察` 拆为 `运行示例。观察`。新形式例：`运行示例。观察集中转换配送状态的显示文字，保持业务值与界面文案分离。`
- 根保护检查数字：360 程序块、180 输出、身份不变。

### 14.1 只读复核根的数字（16 个草稿章）

| 项 | 只读计数 | 根的数字 | 一致 |
| --- | --- | --- | --- |
| 课 | 180 | 180 | 是 |
| 程序块 | 360（180 `code` + 180 `answer`） | 360 | 是 |
| 输出 | 180 | 180 | 是 |
| 练习 | 180 | — | — |

### 14.2 只读复核 `展示` / `显示` / `运行并观察`

| 项 | 16 章 | 本组 5 章 |
| --- | --- | --- |
| `展示` | 4 | 1 |
| `显示` | 117 | — |
| `运行并观察` | 0 | 0 |
| `运行示例` | 58 | — |

16 章的 4 处 `展示` 全在 `concepts`：`enum_states:11`、`numbers_strings:11`、`dates_money:336`、`formatting_output:143`。10 个白名单字段内 `展示` 为 0。

本组 5 章的 1 处在 `enum_states.dart:11` 的 `concepts`，不在白名单。

这与其余 3 处的归属一致：根只改白名单字段，未改 `concepts`。

### 14.3 后续

- 只读等待。任何失败重试都不恢复旧的章节编辑任务。
- 本报告第 1..13 节是历史记录，不改写。
- 未运行 SDK / core / git；未复写根的修改。
