# 草稿中文散文修订报告 A（121..180，五章）

> 本文件是本组修订的交付文档。
> 只改中文散文。未改代码块、答案块、程序输出、`id` / `chapter` / `level`、导出列表、`import`、`concepts`、生成资产。
> 本轮未调用 Dart / Flutter / SDK / analyze / build / device。
> 本轮未做 git 或 core 操作。
> 状态：已冻结。未经新指令不再改写这 5 个文件。

## 1. 结论摘要

| 项目 | 结果 |
| --- | --- |
| 散文范围硬违规 | 190 → **0** |
| 语义长度（`objective` / `prompt` / `hint` 超 25） | 36 → **0** |
| 真实动作串 | 76 处 → **0** |
| 情态词增删 | **0** |
| 可执行内容改动 | **0** |
| 改动的字段数 | 97（全部在白名单内） |

可执行内容的证明不是「我检查过」。证明是四重检查加一次逐字节重放。见第 8 节。

## 2. 范围与归属

| 文件 | 章节 key | lesson id | 课数 | 程序块 | 输出 | 行数 |
| --- | --- | --- | --- | --- | --- | --- |
| `curriculum/chapters/numbers_strings.dart` | numbers-strings | 121..132 | 12 | 24 | 12 | 697 |
| `curriculum/chapters/text_processing.dart` | text-processing | 133..144 | 12 | 24 | 12 | 865 |
| `curriculum/chapters/algorithms_basic.dart` | algorithms-basic | 145..156 | 12 | 24 | 12 | 867 |
| `curriculum/chapters/algorithms_advanced.dart` | algorithms-advanced | 157..168 | 12 | 24 | 12 | 881 |
| `curriculum/chapters/data_structures.dart` | data-structures | 169..180 | 12 | 24 | 12 | 1156 |

合计 60 课。120 个程序块（60 段 `code` + 60 段 `answer`）。60 段 `output`。每个文件 168 个字段。

修订前后行数完全一致：697 / 865 / 867 / 881 / 1156。拆句在字面量内部改标点，不新增行。

## 3. 可改字段白名单

`title`、`summary`、`explain`、`objective`、`prerequisites`、`pitfalls`、`exampleTitle`、`exampleSummary`、`prompt`、`hint`。

依据 `.dart_tool/pi-briefs-20261025/editorial_tool.py`：

```python
EDITABLE = (
    'title', 'summary', 'explain', 'objective', 'prerequisites', 'pitfalls',
    'exampleTitle', 'exampleSummary', 'prompt', 'hint',
)
NOT_EDITABLE_PROSE = ('concepts',)
```

`concepts` 不在白名单。本轮未改一个字符。

本轮实际改动的字段种类：`explain`、`summary`、`objective`、`prompt`、`hint`、`pitfalls`。
`title`、`exampleTitle`、`exampleSummary`、`prerequisites` 未动。

## 4. 人工规则

来源：`AGENTS.md` 与 `.trellis/spec/guides/controlled-chinese.md`。

1. 一句只写一个动作。
2. 用主动语态。删无施事的 `被…`。
3. 同一概念只用一个术语。
4. 不用分号连接动作。
5. 说明句每条最多 40 字。
6. `objective`、`prompt`、`hint` 每句最多 25 字。
7. 删虚动词名词化（`进行` / `加以` + 名词）。
8. 删套话、营销形容词、含糊词。
9. 保留情态词。`可能` / `也许` 是内容，不是冗余。
10. 代码块不是散文。
11. 分清动作与技术因果。属性、因果、规则、目的句保留，并从动作串计数排除。

第 4 条对应报告 B 的 `一句一动作`。短于 25 字不能替代这条规则。

## 5. 工具与口径局限

### 5.1 检查器没有 Dart 语法感知

检查器把任何 `;` 与 `;` 判为 semicolon。Dart 每行都有 ASCII `;`。整文件跑必然大面积误报。

整文件实测：

| 文件 | 命中 | 硬化 | 规则 | `r'''` 块内 | Dart 结构行 | 散文 |
| --- | --- | --- | --- | --- | --- | --- |
| numbers_strings.dart | 137 | 137 | semicolon | 135 | 2 | **0** |
| text_processing.dart | 272 | 272 | semicolon | 270 | 2 | **0** |
| algorithms_basic.dart | 320 | 320 | semicolon | 318 | 2 | **0** |
| algorithms_advanced.dart | 340 | 340 | semicolon | 338 | 2 | **0** |
| data_structures.dart | 510 | 510 | semicolon | 508 | 2 | **0** |
| 合计 | 1579 | 1579 | semicolon | 1569 | 10 | **0** |

「Dart 结构行」指每文件 2 行：`import '../dart_lesson.dart';` 与末尾的 `];`。

结论：整文件 1579 条硬化全部落在 Dart 代码，散文为 0。整文件结果只能做首查，判定必须用散文范围。

### 5.2 散文范围

散文范围只取白名单字段的字面量内容。跳过 `code` / `answer` 的 `r'''` 块与 `output` 行。

相邻字符串拼接按 Dart 规则处理：`"a" "b"` 中间没有逗号时算同一段文本。`<String>["a", "b"]` 是列表，元素分别检查，不连成一句。

### 5.3 三种长度口径

| 口径 | 说明 | 用途 |
| --- | --- | --- |
| 项目 `count_chars` | 汉字算 1，连续拉丁字母或数字算 1，标点不计 | 项目机械标准 |
| 根等同语义检查 | 同上。`objective` / `prompt` / `hint` 限 25，其余限 40 | 根的工具口径 |
| 含标点 | 汉字 + 拉丁串 + 标点 | 人工复核 |

三种口径本轮都没有报出散文违规。

## 6. 三轮修订

### 6.1 轮次总表

| 轮次 | 目标 | 改动字段 | 净增句号 |
| --- | --- | --- | --- |
| 第 1 轮 | 语义长度超限 | 36 | 41 |
| 第 2 轮 | `先…，再…` 类动作串 | 39 | 47 |
| 第 3 轮 | `…，并…` / `…，同时…` 动作串 | 29 | 38 |
| 合计 | — | 97（去重后） | 126 |

第 1 轮 36 个字段全部是 `objective` / `prompt` / `hint`：`objective` 26 个、`prompt` 6 个、`hint` 4 个。

### 6.2 第 1 轮：语义长度（36 条）

来源：`.dart_tool/pi-briefs-20261025/semantic-prose-findings.json`。本组 36 条，全部超 25 字。

| 文件 | 条数 |
| --- | --- |
| numbers_strings | 5 |
| text_processing | 4 |
| algorithms_basic | 5 |
| algorithms_advanced | 5 |
| data_structures | 17 |

处理办法：在语义边界拆成两句。不删信息，不改技术含义。

代表例：

- 前：`能分别控制金额小数位与编号宽度，并保留原始数值用于计算`（26）
- 后：`能分别控制金额小数位与编号宽度。能保留原始数值用于计算。`（15 / 12）

- 前：`能按明确的英文单词规则进行标题化，并处理空输入和重复空格`（27）
- 后：`能按明确的英文单词规则标题化。能处理空输入和重复空格。`（14 / 11）

第二例顺带删了 `进行标题化` 的名词化。改成 `标题化`。

- 前：`依次输出 [4, 2, 5, 1] 的长度 1 到 4 的每个前缀的排序结果，观察有序集合增长`（32）
- 后：`依次输出 [4, 2, 5, 1] 长度 1 到 4 的前缀排序结果。观察有序集合如何增长。`（20 / 10）

- 前：`每张工单都必须出队，再用 Set.contains 决定是否服务，避免取消项堵在队首`（28）
- 后：`每张工单都必须出队。再用 Set.contains 决定是否服务。避免取消项堵在队首。`（9 / 9 / 9）

- 前：`visited.add 的布尔返回值可以同时完成是否新发现的判断和登记，自环无需特殊删除`（33）
- 后：`visited.add 的布尔返回值同时完成发现判断和登记。自环无需特殊删除。`（17 / 9）

### 6.3 第 2 轮：`先…，再…` 动作串（39 个字段，47 处）

扫描口径：散文范围内含 `，先` / `，再` / `，最后` / `，然后` / `，接着` 的句子。

处理：把顺序标记前的逗号改句号。两个动作各自成句。

排除项：`，再次` 不是顺序标记。例如 `第二，再次排序结果相同` 里的 `再次` 是副词「又」，不拆。

代表例：

- 前：`程序先计算单价乘数量，再格式化合计。`
- 后：`程序先计算单价乘数量。再格式化合计。`

- 前：`每轮先假设后缀第一个元素最小，再扫描剩余位置更新最小索引，最后将该元素交换到前缀边界。`
- 后：`每轮先假设后缀第一个元素最小。再扫描剩余位置更新最小索引。最后将该元素交换到前缀边界。`

- 前：`每轮先保存 next，再把 current.next 指向 previous，最后让两个游标前进。`
- 后：`每轮先保存 next。再把 current.next 指向 previous。最后让两个游标前进。`

- 前：`账户有 1000 分，先支付 275 分，再支付 360 分。`
- 后：`账户有 1000 分。先支付 275 分。再支付 360 分。`

- 前：`非交换运算需要先弹出右操作数，再弹出左操作数。`
- 后：`非交换运算需要先弹出右操作数。再弹出左操作数。`

### 6.4 第 3 轮：`…，并…` / `…，同时…` 动作串（29 个字段，38 处）

承接报告 B 的判定：`增加总条数参数，并校验页码是否超过最后一页` 属于动作串，必须拆。

本组第 3 轮只拆程序性字段：`explain`、`hint`、`prompt`、`summary`。

代表例：

- 前：`程序将中文逗号统一成英文逗号，拆分后逐项 trim，并过滤空项。`
- 后：`程序将中文逗号统一成英文逗号。拆分后逐项 trim。同时过滤空项。`

- 前：`插入时沿比较结果递归下降，遇到空位置才创建节点，并把返回的子树根重新接回原节点。`
- 后：`插入时沿比较结果递归下降。遇到空位置才创建节点。再把返回的子树根重新接回原节点。`

- 前：`union 先求两个根，已经相同就返回 false，否则把较小集合接到较大集合，并只更新新根的规模。`
- 后：`union 先求两个根。两个根相同就返回 false。否则把较小集合接到较大集合。最后只更新新根的规模。`

`已经相同` 改成 `两个根相同`。补出主语，避免读成「已经」。

- 前：`find 沿父引用找到根，并把沿途节点直接接到根上，这种路径压缩会让后续查询更短。`
- 后：`find 沿父引用找到根。再把沿途节点直接接到根上。这种路径压缩会让后续查询更短。`

- 前：`筛选一组标题中的回文：level、paper、noon、robot，并保留原有顺序。`
- 后：`筛选一组标题中的回文：level、paper、noon、robot。结果保留原有顺序。`

`prompt` 并列两个步骤时，第二个步骤保留独立成句。祈使句允许省略主语，不是残句。

### 6.5 保留的句子类型

以下类型不拆，并从动作串计数排除。

| 类型 | 例 |
| --- | --- |
| 属性 / 并列属性（`既…也…`） | `时间和空间既取决于元素数量，也取决于最大最小值之间的范围。` |
| 因果（`让` / `使得` / `因此`） | `先处理小预算可以避免负下标，也让空预算自然返回空字符串。` |
| 否定（`并不` / `不能` / `并不是`） | `字符编辑距离只描述形式差异，并不衡量词语含义是否接近。` |
| 条件 / 规则 | `比较相邻元素逐轮归位，并在一轮没有交换时停止。` |
| 能力（`能…并…`） | `能实现带输入限幅的线性映射，并拒绝零宽度量程。` |

`objective` 全部属于「能力」类型。本轮未拆 `objective` 的 `能…并…` 结构。

## 7. 修订结果

### 7.1 散文范围

| 文件 | 起始命中 | 起始硬化 | 终态命中 | 终态硬化 |
| --- | --- | --- | --- | --- |
| numbers_strings.dart | 38 | 34 | 0 | 0 |
| text_processing.dart | 36 | 29 | 0 | 0 |
| algorithms_basic.dart | 34 | 27 | 0 | 0 |
| algorithms_advanced.dart | 44 | 33 | 0 | 0 |
| data_structures.dart | 38 | 34 | 0 | 0 |
| 合计 | 190 | 157 | **0** | **0** |

### 7.2 分规则终态

| 规则 | 终态 |
| --- | --- |
| semicolon（散文） | 0 |
| long-sentence | 0 |
| synonym-rotation | 0 |
| passive-voice | 0 |
| vague-word | 0 |
| compound-aspect | 0 |
| 超 25 字（`objective` / `prompt` / `hint`） | 0 |

同义轮换为 0，是整文件的结论，不只散文范围。

### 7.3 改写原则

拆分：在语义边界改句号。不删信息，不换词序。

补主语：`已经相同就返回 false` → `两个根相同就返回 false`。

去名词化：`进行标题化` → `标题化`。

不硬换词而改述的地方：

| 位置 | 原写法 | 处理 | 原因 |
| --- | --- | --- | --- |
| data_structures 965 | `已经相同就返回` | `两个根相同就返回` | 补主语，消除歧义 |
| algorithms_basic 165 | `先假设…最小` | 保留 | 算法步骤描述，拆后会割裂一轮循环 |
| text_processing 726 | `并把简单驼峰标识转换为可读单词` | 拆成 `再…` | 两个独立操作 |

## 8. 可执行内容未改动的证明

四重检查，全部通过。

### 8.1 基线逐字比对

`.dart_tool/pi-briefs-20261025/draft-editorial-baseline.json` 保存了 120 段程序文本与 60 段输出。

检查结果（每文件一致）：

```
programs=True(24/24)  outputs=True(12/12)  ids=12  chapter1=1  level1=3
ALL_OK
```

24 段程序 = 12 段 `code` + 12 段 `answer`。全部逐字节等于基线。

### 8.2 结构快照

改动前先取结构快照：`id` / `chapter` / `level` 值、`import` 行、导出列表、`const List<...>` 声明、程序块与输出块的位置。

改动后复验：`FAILED files: 0`。

### 8.3 字段级差异

逐字段比较「改动前备份」与「当前文件」。

```
numbers_strings      fields=168 changed={'explain': 9, 'objective': 5, 'hint': 4, 'summary': 4, 'prompt': 1}
text_processing      fields=168 changed={'explain': 6, 'prompt': 2, 'hint': 3, 'objective': 4, 'summary': 1}
algorithms_basic     fields=168 changed={'explain': 3, 'objective': 4, 'hint': 3, 'prompt': 2, 'summary': 2}
algorithms_advanced  fields=168 changed={'summary': 2, 'explain': 3, 'objective': 5, 'prompt': 1}
data_structures      fields=168 changed={'summary': 3, 'explain': 9, 'pitfalls': 1, 'prompt': 6, 'hint': 6, 'objective': 8}
TOTAL_CHANGED_FIELDS 97
ILLEGAL 0
```

`ILLEGAL` 统计白名单外的字段改动。任何一处改动落在 `concepts` / `code` / `answer` / `output` / `id` / `chapter` / `level` 都计入。结果为 0。

### 8.4 逐字节重放

从改动前备份出发，按第 1、2、3 轮的操作序列重放。

重放结果与当前文件**逐字节相等**。

```
numbers_strings      r1_fields=5  dPeriod=5  | r2_fields=15 dPeriod=17 | r3_fixes=5  dPeriod=7  | equal=True
text_processing      r1_fields=4  dPeriod=4  | r2_fields=9  dPeriod=10 | r3_fixes=4  dPeriod=4  | equal=True
algorithms_basic     r1_fields=5  dPeriod=5  | r2_fields=4  dPeriod=5  | r3_fixes=5  dPeriod=5  | equal=True
algorithms_advanced  r1_fields=5  dPeriod=5  | r2_fields=2  dPeriod=2  | r3_fixes=5  dPeriod=5  | equal=True
data_structures      r1_fields=17 dPeriod=22 | r2_fields=9  dPeriod=13 | r3_fixes=10 dPeriod=17 | equal=True
TOTAL r1_fields=36 dPeriod=41 | r2_fields=39 dPeriod=47 | r3_fixes=29 dPeriod=38
REPLAY_EXACT True
```

这条证明最强。它说明改动集合恰好等于申报的 97 个字段，没有隐藏改动。

净增句号 41 + 47 + 38 = 126。与直接测量的差值 126 一致。

### 8.5 整文件哈希

整文件 sha256 已变化。这是散文改动的必然结果，不是缺陷。

现行哈希：

| 文件 | sha256（前 16 位） |
| --- | --- |
| numbers_strings.dart | 0173319669614E3A |
| text_processing.dart | BB631C9DBC8031C1 |
| algorithms_basic.dart | A8877305B29ED36F |
| algorithms_advanced.dart | CFF927D758F139BB |
| data_structures.dart | 4EFEA8E5FAED4A72 |

## 9. 情态保留

追踪 10 个情态与限定词：`可能`、`也许`、`若`、`如果`、`除非`、`不能`、`并非`、`并不`、`默认`、`通常`。

逐文件比较「改动前备份」与「当前文件」的计数。

结果：`MODALITY_DELTA_ISSUES 0`。

没有删除真实的不确定性，也没有新增原本不存在的不确定性。`也许` 原本为 0，本轮仍为 0。

保留例：

- `外推远离观测范围时，线性关系可能不再成立。`
- `原样透传字符若与编码字符重合，也会造成解码歧义。`
- `默认零初值表示可以留空，并不代表每个容量都能恰好装满。`

拆句不弱化这类限定。改句号只分隔动作，不改置信度。

## 10. 术语与有意的技术区分

本组散文范围同义轮换为 0。以下区分仍然保留，并有理由。

| 组 | 本组用法 | 说明 |
| --- | --- | --- |
| `错误` | 5 个文件都用 `错误` | 指 `Error` 与错误码。本组未出现 `异常`。 |
| `检查` / `校验` | 4 个文件用 `检查`，text_processing 用 `校验`（34 次） | 单个文件内各自统一。跨组统一由根在冻结后处理。 |
| `展示` | 5 个文件都用 `展示` | `显示` 出现 0 次。原轮换已消除。 |
| `保存` | 5 个文件都用 `保存` | `存储` 出现 0 次。 |
| `删除` | 4 个文件用 `删除` | `移除` 出现 0 次。 |
| `创建` / `建立` | algorithms_basic、data_structures 用 `创建`。algorithms_advanced 用 `建立` | 单文件内统一。`建立状态` 与 `创建节点` 语义不同。 |

`concepts` 字段不在白名单，未改。`concepts` 内的用词差异不属本轮缺陷。

## 11. 剩余候选分类

第 3 轮后重新扫描：散文范围含 `，并` / `，同时` / `，也` / `，从而` / `，使得` 的句子共 53 条。

逐条分类结果：

| 类别 | 条数 | 处理 |
| --- | --- | --- |
| 能力句（`objective` 的 `能…并…`） | 26 | 保留 |
| 属性 / 并列（`既…也…`、`也`） | 14 | 保留 |
| 否定（`并不` / `不能` / `并不是`） | 6 | 保留 |
| 因果 / 目的（`让` / `使得` / `帮助`） | 5 | 保留 |
| 条件 / 规则 | 2 | 保留 |
| **真实动作串** | **0** | — |

`，先` / `，再` / `，最后` / `，然后` / `，接着` 的复扫结果为 0 处。

结论：真实动作串 0 条。其余 53 条按第 6.5 节分类保留。

## 12. 未执行的操作

- 未调用 Dart、Flutter、SDK、`dart analyze`、`dart compile`、build、device 命令。
- 未做 git 操作：无 stage、commit、push、checkout、stash。
- 未改 `core` 与 SDK。
- 未写 `.dart_tool/pi-briefs-20261025/` 下任何文件。该目录全程只读。
- 未使用 lint 抑制：无 `--disable`，无 `--baseline`，未削弱任何规则。
- 未改 `concepts`、程序块、输出块、身份字段。
- 临时检查脚本放在仓库外的系统临时目录，不在仓库内。

## 13. 冻结

5 个章节文件的散文修订已完成并冻结。

- 散文范围硬化：0。
- 语义长度超限：0。
- 真实动作串：0。
- 可执行内容改动：0（四重检查 + 逐字节重放）。
- 情态增删：0。

未经新指令不再改写这 5 个文件。

跨组同义词统一（如 `检查` 与 `校验`）留给根在冻结后统一处理。本组单文件内已各自一致。

## 14. 冻结后接管记录（快照时态）

本报告正文记录本组冻结时刻的状态。正文不改写，保留原快照时态。本节只追加冻结之后的变更。

接管情况：

- 根已接管全部 16 章，并开始新的源码冻结批次。
- 本组已停止章节写入。5 个章节文件此后由根维护。
- 本报告的结论只对冻结时刻成立。

根在冻结后做了两项统一：

| 项目 | 内容 | 对本组 5 个文件的影响 |
| --- | --- | --- |
| 用词 | 10 个白名单字段内 `展示` 统一改 `显示` | 有。白名单散文现为 `展示` 0 次，`显示` 17 / 4 / 3 / 0 / 1 次 |
| 拆句 | `运行并观察` 拆成 `运行示例`。`观察` | 无。本组 5 个文件两种写法都是 0 处 |

第 10 节表格里 `展示` 一行是冻结时快照。该行只作历史记录，不代表当前文本。

根的保护检查结果：

- 360 个程序块未变。
- 180 段输出未变。
- 身份字段未变。
- 相邻字符串语义长度超限 0 处。
- 分号 0 处。

本组不再改动任何章节文件。后续只读等待。即使检查失败需要重试，也不恢复章节旧编辑任务。

未做 git、core、SDK 操作。
