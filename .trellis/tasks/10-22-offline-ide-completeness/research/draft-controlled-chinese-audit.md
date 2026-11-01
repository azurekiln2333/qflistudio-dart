# 受控中文审计：180 篇扩展草稿（dart-lesson-121..300）

> 只读审计。本文件是唯一产出。未改源码，未改工具。未运行 Dart / SDK / Flutter / build / device。未做 git 操作。

## 范围

- 16 个草稿章节文件，lesson id 121..300，共 180 课。每课 1 个配对示例、1 个独立练习（prompt/hint/answer）。
- 生产旧内容（001..120）不在范围，也未改动。
- 统计口径：`id:` 180、`output:` 180、`code: r'''` 180、`answer: r'''` 180、`prompt:` 180。

## 结论摘要

1. 机械首查把 Dart 全文当散文，误报极大：原始 4422 条，其中 semicolon 4064 条。那些是代码里的 ASCII 分号 `;`，不是中文句子。
   直接对 Dart 全文跑该 linter 不可用，只能当首查，不能当结论。
2. 只保留中文散文字段（跳过 `code` / `answer` 的 `r'''` 代码块与 `output` 程序输出）后，同一批规则得到 501 条真实候选。
3. 硬违规：semicolon 146、long-sentence 180、synonym-rotation 88。
4. 建议类：passive-voice 68、vague-word 11、compound-aspect 8。
5. 0 条 nominalization / marketing-adjective / empty-phrase / halfwidth-punct / dash-join。
6. 情态词（可能 / 也许 / 大概 / 倾向于）0 条被标记。置信度没有被风格规则改动。

## 方法

1. 机械首查：对 16 个文件直接跑 `python scripts/ste-lint-zh.py --json <files>`。
2. 散文范围：逐行保留散文字段（title / summary / concepts / explain / objective / prerequisites / pitfalls / exampleTitle / exampleSummary / prompt / hint）的字符串内容，
   跳过 `code:` / `answer:` 的 `r'''` 代码块与 `output:` 行；保持原行号，再交给 linter 的 `analyze`。
3. 逐条判定“真实问题 / 待确认”。判定见附录 A 的“判定”列。

## 原始 vs 散文（逐规则）

| 规则 | 严重度 | 原始全文 | 散文范围 | 判定 |
| --- | --- | --- | --- | --- |
| `semicolon` | hard | 4064 | 146 | 真实问题 |
| `long-sentence` | hard | 180 | 180 | 真实问题 |
| `synonym-rotation` | hard | 89 | 88 | 待人工确认 |
| `passive-voice` | advisory | 69 | 68 | 多为真实，需人工确认 |
| `vague-word` | advisory | 11 | 11 | 真实问题 |
| `compound-aspect` | advisory | 8 | 8 | 酌情保留 |
| `nominalization` | hard | 0 | 0 | 真实问题 |
| `marketing-adjective` | hard | 0 | 0 | 真实问题 |
| `empty-phrase` | hard | 0 | 0 | 真实问题 |
| `halfwidth-punct` | advisory | 1 | 0 | 真实问题 |
| `dash-join` | advisory | 0 | 0 | 真实问题 |

原始 semicolon 4064 条里，散文只有 146 条；差额是 Dart 代码的 `;`。
long-sentence 原始与散文都是 180 条，说明它本来就来自散文。

## 逐规则判定

### semicolon（硬，散文 146）—— 真实问题
全部是中文全角 `；`（散文范围内 ASCII `;` 为 0）。AGENTS 要求一句一动作、不用分号连接动作。
建议：把 `；` 改成 `。`，或拆成两句。
### long-sentence（硬，散文 180）—— 真实问题，且系统性
恰好每课 1 条，长度 41..69 字，来自长 `explain` 句。AGENTS 说明上限 40 字。
建议：每课 explain 拆成 2..3 句，每句 ≤40 字。
### synonym-rotation（硬，散文 88）—— 待人工确认
同一章内同义混用。建议按组内最高频词统一。部分组（如 运行/执行、错误/异常、创建/生成）在技术语境可能确实有区分，需逐条确认。
### passive-voice（建议，散文 68）—— 多为真实
`被...` 结构。AGENTS 要主动语态。建议补出施事并改主动；施事未知或无关时保留。
### vague-word（建议，散文 11）—— 真实问题
命中 相关 / 若干 / 一些 / 适当 / 必要时 / 等等 / 之类 / 大致 / 差不多 / 一定程度。AGENTS 点名 若干 / 一些 / 相关。
建议：给出数量、范围或条件。
### compound-aspect（建议，散文 8）—— 酌情保留
`已经...了` / `正在...中`。建议简化体貌；表达当前相关性时保留并标注。

## 字段分布（散文发现落在哪个字段）

| 规则 | - |
| --- | --- | --- | --- | --- |
| `semicolon` | explain×119 | hint×17 | prompt×7 | pitfalls×3 |
| `long-sentence` | explain×173 | pitfalls×4 | prompt×3 | - |
| `synonym-rotation` | explain×50 | summary×11 | pitfalls×8 | hint×5 |
| `passive-voice` | explain×48 | pitfalls×9 | prompt×5 | exampleSummary×2 |
| `vague-word` | explain×9 | hint×2 | - | - |
| `compound-aspect` | explain×7 | pitfalls×1 | - | - |
| `nominalization` | - | - | - | - |
| `marketing-adjective` | - | - | - | - |
| `empty-phrase` | - | - | - | - |
| `halfwidth-punct` | - | - | - | - |
| `dash-join` | - | - | - | - |

## 文件分布

| 文件 | semicolon | long | synonym | passive | vague | compound |
| --- | --- | --- | --- | --- | --- | --- |
| numbers_strings.dart | 12 | 16 | 5 | 4 | 0 | 0 |
| text_processing.dart | 10 | 14 | 5 | 6 | 1 | 0 |
| algorithms_basic.dart | 14 | 10 | 3 | 4 | 2 | 1 |
| algorithms_advanced.dart | 14 | 16 | 3 | 8 | 2 | 1 |
| data_structures.dart | 18 | 12 | 4 | 3 | 0 | 1 |
| math_stats.dart | 9 | 5 | 5 | 3 | 1 | 1 |
| oop_modeling.dart | 1 | 6 | 11 | 1 | 1 | 0 |
| enum_states.dart | 3 | 9 | 7 | 5 | 1 | 0 |
| errors_resilience.dart | 3 | 8 | 6 | 4 | 0 | 0 |
| json_modeling.dart | 3 | 7 | 9 | 7 | 0 | 0 |
| dates_money.dart | 12 | 14 | 3 | 1 | 2 | 1 |
| collection_reporting.dart | 12 | 12 | 6 | 2 | 0 | 2 |
| formatting_output.dart | 10 | 14 | 3 | 2 | 1 | 0 |
| async_patterns.dart | 10 | 14 | 5 | 7 | 0 | 1 |
| apis_contracts.dart | 10 | 17 | 8 | 9 | 0 | 0 |
| mini_apps.dart | 5 | 6 | 5 | 2 | 0 | 0 |

<!-- EXAMPLES -->

## 落地清单

- 真实问题、可机械改：semicolon 146、long-sentence 180、vague-word 11。
- 需人工确认：synonym-rotation 88、passive-voice 68、compound-aspect 8。
- 散文范围内工具误报：0。原始 4064 条代码分号属于工具局限，不属于草稿问题。

## 工具局限（必须声明）

- 无 Dart 语法感知：任何 `;` 都判 semicolon；必须先用散文范围屏蔽代码。
- 句切分基于物理行与 `。！？`，不理解 Dart 相邻字符串拼接。因此一行一个字面量 = 一句。
- 拉丁标识符按 1 个词计入句长（`toStringAsFixed` 算 1），与“按词算”一致。
- 同义轮换按单文件统计，正确；但它不知道技术语境里的真区分。
- 单引号与双引号两种写法的散文字符串都处理；`code` / `answer` / `output` 已排除。

## 未验证 / 边界

- 未运行 Dart / SDK / Flutter / analyze / build / device。
- 未改源码或工具。未做 git 操作。
- 只做静态文本审计；建议改写未落地。改写后需重跑本审计。

## 附录 A：全部 501 条散文发现

格式：`文件:行:列 · 规则 · 严重度 · 判定 · 命中「...」 · 行内散文「...」`

- `curriculum/chapters/numbers_strings.dart:13:21` · synonym-rotation · hard · 待人工确认 · 命中「显示」 · 散文「收银小票需要让金额始终显示两位小数，订单编号则需要补足固定宽度。」
- `curriculum/chapters/numbers_strings.dart:14:10` · long-sentence · hard · 真实问题 · 命中「43 字」 · 散文「这是两种不同的格式约束：toStringAsFixed 返回带指定小数位的字符串，padLeft 只负责在字符串左侧补字符，并不改变数值。」
- `curriculum/chapters/numbers_strings.dart:17:39` · semicolon · hard · 真实问题 · 命中「；」 · 散文「这里的小数格式用于界面显示，并不承诺十进制金额运算完全精确；」
- `curriculum/chapters/numbers_strings.dart:24:37` · synonym-rotation · hard · 待人工确认 · 命中「存储」 · 散文「toStringAsFixed 会舍入显示值，不能代替金额存储策略。」
- `curriculum/chapters/numbers_strings.dart:66:47` · synonym-rotation · hard · 待人工确认 · 命中「异常」 · 散文「tryParse 把失败表示为 null，调用者可以先验证再计算，而不必用异常控制每一条正常分支。」
- `curriculum/chapters/numbers_strings.dart:67:29` · semicolon · hard · 真实问题 · 命中「；」 · 散文「程序对数量先 trim，再要求结果非负；」
- `curriculum/chapters/numbers_strings.dart:68:53` · passive-voice · advisory · 多为真实，需人工确认 · 命中「被解析」 · 散文「单价使用 double.tryParse，并额外排除 NaN 和无穷大，因为它们虽然能被解析，却不适合进入账目。」
- `curriculum/chapters/numbers_strings.dart:71:23` · synonym-rotation · hard · 待人工确认 · 命中「校验」 · 散文「本例只使用内置文本，解析和校验都能离线重复执行。」
- `curriculum/chapters/numbers_strings.dart:98:43` · semicolon · hard · 真实问题 · 命中「；」 · 散文「统计三条记录中可计价的条数：数量 2、空字符串、0；单价都为 1.5，零数量也算有效。」
- `curriculum/chapters/numbers_strings.dart:131:10` · long-sentence · hard · 真实问题 · 命中「52 字」 · 散文「程序以颜色通道为例，将零到二百五十五之间的值转换成八位二进制和两位十六进制，再把十六进制文本按 radix 十六解析回来。」
- `curriculum/chapters/numbers_strings.dart:132:28` · semicolon · hard · 真实问题 · 命中「；」 · 散文「补位发生在转换之后，因此不会改变数值；」
- `curriculum/chapters/numbers_strings.dart:135:10` · long-sentence · hard · 真实问题 · 命中「46 字」 · 散文「需要特别区分十进制文本中的十与十六进制文本中的十，解析时显式指定基数，才能让编码和解码的契约一致。」
- `curriculum/chapters/numbers_strings.dart:191:10` · long-sentence · hard · 真实问题 · 命中「42 字」 · 散文「把组数、余量和比率分别命名，能使单位和业务含义保持清楚，减少看起来数值正确却解释错误的结果。」
- `curriculum/chapters/numbers_strings.dart:239:18` · passive-voice · advisory · 多为真实，需人工确认 · 命中「被保留」 · 散文「标签内部的空格会被保留，因此双词名称不会被误合并。」
- `curriculum/chapters/numbers_strings.dart:239:30` · passive-voice · advisory · 多为真实，需人工确认 · 命中「被误合并」 · 散文「标签内部的空格会被保留，因此双词名称不会被误合并。」
- `curriculum/chapters/numbers_strings.dart:241:31` · semicolon · hard · 真实问题 · 命中「；」 · 散文「这里没有自动去重，因为去重是另一项业务决定；」
- `curriculum/chapters/numbers_strings.dart:292:10` · long-sentence · hard · 真实问题 · 命中「48 字」 · 散文「这里规定所有词都标题化，不引入冠词或品牌缩写的特殊规则，因此输入 API 会得到 Api，这是规则选择而不是语言保证。」
- `curriculum/chapters/numbers_strings.dart:293:26` · semicolon · hard · 真实问题 · 命中「；」 · 散文「示例只面向由普通英文词构成的标题；」
- `curriculum/chapters/numbers_strings.dart:294:10` · long-sentence · hard · 真实问题 · 命中「45 字」 · 散文「真实多语言排版还需要处理字素簇、连字符和专有名称，不能把本课函数直接当作完整的语言学标题转换器。」
- `curriculum/chapters/numbers_strings.dart:352:43` · semicolon · hard · 真实问题 · 命中「；」 · 散文「本例使用 ASCII 名称，字符串长度与常见等宽终端的显示列数一致；」
- `curriculum/chapters/numbers_strings.dart:402:10` · long-sentence · hard · 真实问题 · 命中「56 字」 · 散文「本例把三个点也算进总预算：原文不超长时直接返回，预算不大于三个字符时只输出相应数量的点，其余情况预留三个位置再截取正文。」
- `curriculum/chapters/numbers_strings.dart:405:41` · semicolon · hard · 真实问题 · 命中「；」 · 散文「这里按 UTF-16 代码单元计长度，只用于 ASCII 摘要；」
- `curriculum/chapters/numbers_strings.dart:406:10` · long-sentence · hard · 真实问题 · 命中「46 字」 · 散文「真实界面若包含 emoji，截断位置可能落在代理对中间，应使用字素簇感知工具，而不能靠 substring 的索引冒充可见字符数。」
- `curriculum/chapters/numbers_strings.dart:459:10` · long-sentence · hard · 真实问题 · 命中「44 字」 · 散文「程序以大写 A 的代码单元为起点，逐次加偏移生成货架列号，再把小写字母转换成同一范围内的大写字母。」
- `curriculum/chapters/numbers_strings.dart:517:46` · semicolon · hard · 真实问题 · 命中「；」 · 散文「程序先用 clamp 限制超量程读数，保证表盘不会显示负刻度或超过最大值；」
- `curriculum/chapters/numbers_strings.dart:520:10` · long-sentence · hard · 真实问题 · 命中「42 字」 · 散文「映射与舍入也是不同步骤，本例保留连续刻度，到最后展示时才控制小数位，避免在中途损失有用精度。」
- `curriculum/chapters/numbers_strings.dart:570:61` · semicolon · hard · 真实问题 · 命中「；」 · 散文「floor 总是朝负无穷方向取整，ceil 总是朝正无穷方向取整，truncate 则朝零丢掉小数部分；」
- `curriculum/chapters/numbers_strings.dart:573:10` · long-sentence · hard · 真实问题 · 命中「44 字」 · 散文「程序把正数、负数和半整数放在一起，按固定列输出四种结果，帮助区分数轴方向与日常口语中的舍去小数。」
- `curriculum/chapters/numbers_strings.dart:574:10` · long-sentence · hard · 真实问题 · 命中「48 字」 · 散文「实际业务应先确定要求：预算上限可能需要 ceil，按完整时段计费可能需要 floor，但退款或负余额未必可以沿用正数规则。」
- `curriculum/chapters/numbers_strings.dart:594:18` · long-sentence · hard · 真实问题 · 命中「41 字」 · 散文「按每小时一个名额分配工位，把 1.2、2.0、2.1 小时的需求向上取整，并比较按完整小时计数的结果。」
- `curriculum/chapters/numbers_strings.dart:613:35` · synonym-rotation · hard · 待人工确认 · 命中「核对」 · 散文「观察二进制小数误差，再用整数分累计一份可核对的账本。」
- `curriculum/chapters/numbers_strings.dart:616:10` · long-sentence · hard · 真实问题 · 命中「52 字」 · 散文「计算机常用二进制浮点表示小数，十进制的零点一无法被这种表示精确容纳，因此两笔小数相加的结果可能带有很小的尾差。」
- `curriculum/chapters/numbers_strings.dart:616:34` · passive-voice · advisory · 多为真实，需人工确认 · 命中「被这种表示精确」 · 散文「计算机常用二进制浮点表示小数，十进制的零点一无法被这种表示精确容纳，因此两笔小数相加的结果可能带有很小的尾差。」
- `curriculum/chapters/numbers_strings.dart:619:10` · long-sentence · hard · 真实问题 · 命中「47 字」 · 散文「若金额规则限定到分，就应在数据进入系统时确定整数单位，后续加减始终使用 int，最后把商和余数组合为展示值。」
- `curriculum/chapters/numbers_strings.dart:620:29` · semicolon · hard · 真实问题 · 命中「；」 · 散文「本例仅处理非负分值，以保持符号规则清楚；」
- `curriculum/chapters/numbers_strings.dart:621:10` · long-sentence · hard · 真实问题 · 命中「42 字」 · 散文「折扣、税率和退款还需要单独约定舍入时点以及负号位置，不能依赖最后一刻格式化来弥补累计误差。」
- `curriculum/chapters/numbers_strings.dart:644:47` · semicolon · hard · 真实问题 · 命中「；」 · 散文「账户有 1000 分，先支付 275 分再支付 360 分；输出每次支付后的余额并确认没有负余额。」
- `curriculum/chapters/text_processing.dart:9:18` · synonym-rotation · hard · 待人工确认 · 命中「检查」 · 散文「双指针回文检查」
- `curriculum/chapters/text_processing.dart:16:14` · synonym-rotation · hard · 待人工确认 · 命中「创建」 · 散文「这样不必创建一份反转后的字符串，归一化之外的额外空间为常数。」
- `curriculum/chapters/text_processing.dart:18:10` · long-sentence · hard · 真实问题 · 命中「56 字」 · 散文「需要注意过滤规则决定问题含义：本例会移除中文和其他符号，所以只适合给定的 ASCII 文本任务，不能声称实现所有语言的通用回文检查。」
- `curriculum/chapters/text_processing.dart:18:28` · synonym-rotation · hard · 待人工确认 · 命中「移除」 · 散文「需要注意过滤规则决定问题含义：本例会移除中文和其他符号，所以只适合给定的 ASCII 文本任务，不能声称实现所有语言的通用回文检查。」
- `curriculum/chapters/text_processing.dart:81:41` · semicolon · hard · 真实问题 · 命中「；」 · 散文「本例将文本转小写并保留英文字母，再排序所有字符，得到稳定的签名；」
- `curriculum/chapters/text_processing.dart:85:52` · semicolon · hard · 真实问题 · 命中「；」 · 散文「该方法的时间开销主要来自排序，长度为 n 的输入通常需要 O(n log n) 比较；」
- `curriculum/chapters/text_processing.dart:139:10` · long-sentence · hard · 真实问题 · 命中「42 字」 · 散文「程序先转小写，再将连续的非英文字母数字替换为空格，这样 Dart 后面的逗号与句号不会生成不同词条。」
- `curriculum/chapters/text_processing.dart:141:10` · long-sentence · hard · 真实问题 · 命中「50 字」 · 散文「统计表的插入顺序来自首次出现的位置，而报告需要独立的字母排序，因此将键复制到列表后排序输出，不修改词频本身。」
- `curriculum/chapters/text_processing.dart:142:34` · passive-voice · advisory · 多为真实，需人工确认 · 命中「被拆开」 · 散文「该方法适用于本课的英文日志片段，带撇号的缩写也会被拆开，真实语料应重新设计分词规则。」
- `curriculum/chapters/text_processing.dart:143:27` · synonym-rotation · hard · 待人工确认 · 命中「核对」 · 散文「示例输出总词数与每个词的次数，方便核对分词和累计是否同时正确。」
- `curriculum/chapters/text_processing.dart:202:10` · long-sentence · hard · 真实问题 · 命中「45 字」 · 散文「本例选择 runes 遍历码点，再用 String.fromCharCode 将每个码点还原成统计键，因此常见单码点 emoji 和中文都能作为完整的键累计。」
- `curriculum/chapters/text_processing.dart:203:13` · synonym-rotation · hard · 待人工确认 · 命中「建立」 · 散文「频率表建立后复制并排序键，输出每个键及次数，同时检查所有次数之和等于输入的码点数量。」
- `curriculum/chapters/text_processing.dart:205:43` · passive-voice · advisory · 多为真实，需人工确认 · 命中「被拆开」 · 散文「码点统计也不等于完整字素统计，带组合音标或多个码点组成的图案仍可能被拆开；」
- `curriculum/chapters/text_processing.dart:205:46` · semicolon · hard · 真实问题 · 命中「；」 · 散文「码点统计也不等于完整字素统计，带组合音标或多个码点组成的图案仍可能被拆开；」
- `curriculum/chapters/text_processing.dart:270:10` · long-sentence · hard · 真实问题 · 命中「50 字」 · 散文「程序固定输入字母表为大写 ASCII 字母，外层索引指向当前片段起点，内层索引寻找第一个不同字符，两个索引之差就是次数。」
- `curriculum/chapters/text_processing.dart:273:42` · semicolon · hard · 真实问题 · 命中「；」 · 散文「编码并不保证缩短文本，所有字符都不相同时，附加的次数会使结果变长；」
- `curriculum/chapters/text_processing.dart:340:10` · long-sentence · hard · 真实问题 · 命中「52 字」 · 散文「本课约定每个片段由一个大写字母和一段正整数次数组成，解码时先读取字母，再连续读取所有数字，最后才把次数解析为 int。」
- `curriculum/chapters/text_processing.dart:341:26` · passive-voice · advisory · 多为真实，需人工确认 · 命中「被清楚地区分」 · 散文「这样 A12 与 A1B2 可以被清楚地区分。」
- `curriculum/chapters/text_processing.dart:343:40` · semicolon · hard · 真实问题 · 命中「；」 · 散文「程序给次数设置上限，是为了防止很短的编码要求分配巨量输出内存；」
- `curriculum/chapters/text_processing.dart:380:29` · semicolon · hard · 真实问题 · 命中「；」 · 散文「解码后遍历字符累计 Map；两个非相邻的 X 片段在频率表中应相加。」
- `curriculum/chapters/text_processing.dart:416:28` · vague-word · advisory · 真实问题 · 命中「若干」 · 散文「凯撒移位把字母在固定字母表上向前移动若干位置，越过 Z 时从 A 重新开始。」
- `curriculum/chapters/text_processing.dart:417:10` · long-sentence · hard · 真实问题 · 命中「44 字」 · 散文「本例分别识别大小写 ASCII 字母的区间，将字母换成零到二十五的偏移，累加位移后对二十六取模，再转回字符。」
- `curriculum/chapters/text_processing.dart:418:27` · passive-voice · advisory · 多为真实，需人工确认 · 命中「被破坏」 · 散文「数字和标点原样保留，因此文本结构不被破坏。」
- `curriculum/chapters/text_processing.dart:421:36` · semicolon · hard · 真实问题 · 命中「；」 · 散文「必须说明这种变换只有极少的密钥选择，轻易就能枚举破解；」
- `curriculum/chapters/text_processing.dart:478:10` · long-sentence · hard · 真实问题 · 命中「45 字」 · 散文「程序逐字符查 Map，命中时使用替换值，未命中则原样保留，并用一张逆表恢复只由指定字母和空格组成的示例。」
- `curriculum/chapters/text_processing.dart:479:10` · long-sentence · hard · 真实问题 · 命中「50 字」 · 散文「逆表能够正确建立的前提是每个目标字符都唯一，否则两个原字符会竞争同一个反向键，恢复时无法知道原来是哪一个。」
- `curriculum/chapters/text_processing.dart:481:10` · long-sentence · hard · 真实问题 · 命中「42 字」 · 散文「即使替换表自身没有重复，原样保留的字符也可能与目标字符重合，因此往返保证还依赖输入字符域。」
- `curriculum/chapters/text_processing.dart:543:10` · long-sentence · hard · 真实问题 · 命中「43 字」 · 散文「算法从最右边的校验位开始向左扫描，每隔一位将数字加倍，若结果超过九则减九，最后把所有贡献相加。」
- `curriculum/chapters/text_processing.dart:544:13` · passive-voice · advisory · 多为真实，需人工确认 · 命中「被十整除时通过」 · 散文「总和能被十整除时通过校验。」
- `curriculum/chapters/text_processing.dart:545:46` · semicolon · hard · 真实问题 · 命中「；」 · 散文「程序先去除允许的空格并拒绝其他非数字，保证字符码减四十八得到的是合法数字；」
- `curriculum/chapters/text_processing.dart:621:55` · semicolon · hard · 真实问题 · 命中「；」 · 散文「该检查器不理解注释、原始字符串或完整 Dart 语法，只用来学习小型扫描器如何组合状态和栈；」
- `curriculum/chapters/text_processing.dart:698:10` · long-sentence · hard · 真实问题 · 命中「47 字」 · 散文「缩写生成和驼峰拆分是两种方向不同的命名转换：前者从多个单词提取首字母，后者根据大写字母恢复单词边界。」
- `curriculum/chapters/text_processing.dart:699:38` · semicolon · hard · 真实问题 · 命中「；」 · 散文「本例先为词组统一多余空格，再取每个词的第一个字母并转大写；」
- `curriculum/chapters/text_processing.dart:702:10` · long-sentence · hard · 真实问题 · 命中「41 字」 · 散文「这里没有把连续大写缩写作为整体识别，因此 HTTP 会被分成多个字母，这正是规则适用范围的一部分。」
- `curriculum/chapters/text_processing.dart:702:37` · passive-voice · advisory · 多为真实，需人工确认 · 命中「被分成多个字母」 · 散文「这里没有把连续大写缩写作为整体识别，因此 HTTP 会被分成多个字母，这正是规则适用范围的一部分。」
- `curriculum/chapters/text_processing.dart:764:10` · long-sentence · hard · 真实问题 · 命中「44 字」 · 散文「本例用游标逐段扫描左花括号与对应的右花括号，把中间内容当作字段名，仅替换原模板中出现的占位符。」
- `curriculum/chapters/algorithms_basic.dart:14:10` · long-sentence · hard · 真实问题 · 命中「44 字」 · 散文「本例同时寻找目标的首次和末次位置：首次位置只有在尚未找到时才写入，末次位置则在每次命中后更新。」
- `curriculum/chapters/algorithms_basic.dart:15:27` · compound-aspect · advisory · 酌情保留 · 命中「已经检查过」 · 散文「扫描到任意下标时，两个变量都只描述已经检查过的前缀，这就是理解算法正确性的循环不变量。」
- `curriculum/chapters/algorithms_basic.dart:16:31` · semicolon · hard · 真实问题 · 命中「；」 · 散文「未找到用负一表示，因为合法列表索引从零开始；」
- `curriculum/chapters/algorithms_basic.dart:19:10` · long-sentence · hard · 真实问题 · 命中「42 字」 · 散文「返回值是位置而不是目标值，调用者应先确认它不为负一，再用来访问列表，避免把失败哨兵误当索引。」
- `curriculum/chapters/algorithms_basic.dart:48:43` · semicolon · hard · 真实问题 · 命中「；」 · 散文「为目标 3 输出所有命中索引，而不是只返回首末位置；数据为 [3, 1, 3, 3, 2]。」
- `curriculum/chapters/algorithms_basic.dart:86:34` · semicolon · hard · 真实问题 · 命中「；」 · 散文「本例先复制输入，避免排序函数意外改动调用者的数据；」
- `curriculum/chapters/algorithms_basic.dart:123:34` · semicolon · hard · 真实问题 · 命中「；」 · 散文「验证排序的两个属性：输入列表不变；对排序结果再次排序得到同样的顺序。」
- `curriculum/chapters/algorithms_basic.dart:164:42` · synonym-rotation · hard · 待人工确认 · 命中「核对」 · 散文「程序在副本上操作，既展示一次交换完成一轮归位，也保留原始输入用于核对。」
- `curriculum/chapters/algorithms_basic.dart:165:46` · semicolon · hard · 真实问题 · 命中「；」 · 散文「无论输入是否已经有序，这种写法都需要扫描各个后缀，所以比较次数仍是平方级；」
- `curriculum/chapters/algorithms_basic.dart:167:10` · long-sentence · hard · 真实问题 · 命中「42 字」 · 散文「普通选择排序还可能改变相等键元素的相对顺序，不能把它自动当成稳定排序来处理带标签的记录。」
- `curriculum/chapters/algorithms_basic.dart:198:36` · semicolon · hard · 真实问题 · 命中「；」 · 散文「先排序副本，再按相同索引比较原值和结果值；最后一个元素可能原本就在正确位置。」
- `curriculum/chapters/algorithms_basic.dart:236:10` · long-sentence · hard · 真实问题 · 命中「43 字」 · 散文「程序先暂存当前值，再从已排序前缀的右端向左比较，将所有更大的值依次右移，最后把暂存值写入空位。」
- `curriculum/chapters/algorithms_basic.dart:240:10` · long-sentence · hard · 真实问题 · 命中「43 字」 · 散文「示例包含重复值和负数，展示算法不依赖数值范围，也让读者可以观察前缀如何逐步成为整个有序列表。」
- `curriculum/chapters/algorithms_basic.dart:246:24` · passive-voice · advisory · 多为真实，需人工确认 · 命中「被反复移过」 · 散文「若把大于改成大于等于，相等记录会被反复移过，稳定性会改变。」
- `curriculum/chapters/algorithms_basic.dart:305:39` · semicolon · hard · 真实问题 · 命中「；」 · 散文「本课使用包含左右端点的闭区间，循环条件是左边界不大于右边界；」
- `curriculum/chapters/algorithms_basic.dart:310:10` · long-sentence · hard · 真实问题 · 命中「47 字」 · 散文「重复值的具体命中位置在本函数中不作最左保证，若业务要求首次位置，需要继续缩小到左半区而不是立即返回。」
- `curriculum/chapters/algorithms_basic.dart:378:10` · long-sentence · hard · 真实问题 · 命中「41 字」 · 散文「为了支持负数，程序先扫描最小值和最大值，再用值减最小值作为桶索引，恢复时将索引加回最小值。」
- `curriculum/chapters/algorithms_basic.dart:380:20` · semicolon · hard · 真实问题 · 命中「；」 · 散文「空输入直接返回空列表；」
- `curriculum/chapters/algorithms_basic.dart:382:22` · vague-word · advisory · 真实问题 · 命中「有关」 · 散文「时间和空间不仅与元素数量有关，也与最大最小值之间的范围有关，通常写作 O(n+k)。」
- `curriculum/chapters/algorithms_basic.dart:382:37` · vague-word · advisory · 真实问题 · 命中「有关」 · 散文「时间和空间不仅与元素数量有关，也与最大最小值之间的范围有关，通常写作 O(n+k)。」
- `curriculum/chapters/algorithms_basic.dart:454:10` · long-sentence · hard · 真实问题 · 命中「44 字」 · 散文「分别保存左右游标，每次取当前较小的一项加入结果，并且只推进取值的一侧，就能保证结果前缀始终有序。」
- `curriculum/chapters/algorithms_basic.dart:458:25` · synonym-rotation · hard · 待人工确认 · 命中「存储」 · 散文「输入列表保持不变，结果则新分配存储。」
- `curriculum/chapters/algorithms_basic.dart:459:36` · semicolon · hard · 真实问题 · 命中「；」 · 散文「需要注意，本函数的正确性来自两个输入都已排序这一前提；」
- `curriculum/chapters/algorithms_basic.dart:523:50` · semicolon · hard · 真实问题 · 命中「；」 · 散文「对自定义对象应用同一策略时，正确性还依赖相等运算和 hashCode 的一致契约；」
- `curriculum/chapters/algorithms_basic.dart:549:45` · passive-voice · advisory · 多为真实，需人工确认 · 命中「被发现重复的时」 · 散文「找出至少重复一次的值，每个重复值只输出一次，顺序按首次被发现重复的时刻决定。」
- `curriculum/chapters/algorithms_basic.dart:550:48` · passive-voice · advisory · 多为真实，需人工确认 · 命中「被输出多次」 · 散文「用 seen 判断曾出现，用 reported 防止同一个重复值被输出多次。」
- `curriculum/chapters/algorithms_basic.dart:578:19` · synonym-rotation · hard · 待人工确认 · 命中「建立」 · 散文「从首元素建立真实初值，同时计算最小值、最大值和极差。」
- `curriculum/chapters/algorithms_basic.dart:582:10` · long-sentence · hard · 真实问题 · 命中「42 字」 · 散文「程序只扫描列表一次，每个新元素同时与当前最小值和最大值比较，因此无需排序就能获得三项结果。」
- `curriculum/chapters/algorithms_basic.dart:583:48` · semicolon · hard · 真实问题 · 命中「；」 · 散文「两个聚合变量从首元素开始初始化，避免把零错误地当成所有数据都能比较的默认边界；」
- `curriculum/chapters/algorithms_basic.dart:646:27` · semicolon · hard · 真实问题 · 命中「；」 · 散文「左指针先取最小值，右指针先取最大值；」
- `curriculum/chapters/algorithms_basic.dart:656:29` · passive-voice · advisory · 多为真实，需人工确认 · 命中「被使用两次」 · 散文「left <= right 会允许同一元素被使用两次，不符合两数配对契约。」
- `curriculum/chapters/algorithms_basic.dart:748:44` · semicolon · hard · 真实问题 · 命中「；」 · 散文「用全负数 [-5, -2, -9] 验证不能返回空段；输出最佳和与实际选中的元素。」
- `curriculum/chapters/algorithms_basic.dart:782:10` · long-sentence · hard · 真实问题 · 命中「41 字」 · 散文「快速排序的分治思想是先选择一个基准，把问题拆成两个规模更小的排序任务，再把结果组合起来。」
- `curriculum/chapters/algorithms_basic.dart:786:33` · semicolon · hard · 真实问题 · 命中「；」 · 散文「示例选中间位置的值作基准，但这不保证每次都均衡；」
- `curriculum/chapters/algorithms_advanced.dart:15:10` · long-sentence · hard · 真实问题 · 命中「44 字」 · 散文「程序分别实现递归与迭代：递归把 n 的结果归约为 n 乘更小问题，迭代则从一开始维护已处理前缀的乘积。」
- `curriculum/chapters/algorithms_advanced.dart:18:27` · semicolon · hard · 真实问题 · 命中「；」 · 散文「递归会占用调用栈，迭代只保存累积值；」
- `curriculum/chapters/algorithms_advanced.dart:19:10` · long-sentence · hard · 真实问题 · 命中「48 字」 · 散文「两者都不能忽略普通 int 的表示范围，大规模精确阶乘需要选择 BigInt 等适合的数据表示，而不是假设乘积可以无限增长。」
- `curriculum/chapters/algorithms_advanced.dart:41:39` · passive-voice · advisory · 多为真实，需人工确认 · 命中「被明确拒绝」 · 散文「比较零到八的两种阶乘实现，并验证负数输入会被明确拒绝。」
- `curriculum/chapters/algorithms_advanced.dart:42:29` · semicolon · hard · 真实问题 · 命中「；」 · 散文「every 可汇总对照结果；负数边界使用 on ArgumentError 捕获，不把失败当作数值。」
- `curriculum/chapters/algorithms_advanced.dart:73:10` · long-sentence · hard · 真实问题 · 命中「41 字」 · 散文「程序保留这种直观定义，再加入只保存相邻两项的滚动迭代，以及把已求结果存进 Map 的记忆化版本。」
- `curriculum/chapters/algorithms_advanced.dart:74:33` · passive-voice · advisory · 多为真实，需人工确认 · 命中「被完整展开多次」 · 散文「记忆化不会改变数学递推式，而是避免同一个 n 被完整展开多次；」
- `curriculum/chapters/algorithms_advanced.dart:74:40` · semicolon · hard · 真实问题 · 命中「；」 · 散文「记忆化不会改变数学递推式，而是避免同一个 n 被完整展开多次；」
- `curriculum/chapters/algorithms_advanced.dart:78:10` · long-sentence · hard · 真实问题 · 命中「57 字」 · 散文「缓存只能用于相同定义和输入条件的问题，如果递推规则也可变化，就必须把相关条件纳入缓存键，否则复用的可能是另一个问题的答案。」
- `curriculum/chapters/algorithms_advanced.dart:78:44` · vague-word · advisory · 真实问题 · 命中「相关」 · 散文「缓存只能用于相同定义和输入条件的问题，如果递推规则也可变化，就必须把相关条件纳入缓存键，否则复用的可能是另一个问题的答案。」
- `curriculum/chapters/algorithms_advanced.dart:112:23` · semicolon · hard · 真实问题 · 命中「；」 · 散文「缓存放在循环外；生成列表时记录求值结果，再用索引核对迭代版本。」
- `curriculum/chapters/algorithms_advanced.dart:112:24` · synonym-rotation · hard · 待人工确认 · 命中「生成」 · 散文「缓存放在循环外；生成列表时记录求值结果，再用索引核对迭代版本。」
- `curriculum/chapters/algorithms_advanced.dart:112:40` · synonym-rotation · hard · 待人工确认 · 命中「核对」 · 散文「缓存放在循环外；生成列表时记录求值结果，再用索引核对迭代版本。」
- `curriculum/chapters/algorithms_advanced.dart:152:33` · semicolon · hard · 真实问题 · 命中「；」 · 散文「零级台阶应设为一种方案，表示什么都不做的空行动；」
- `curriculum/chapters/algorithms_advanced.dart:153:25` · passive-voice · advisory · 多为真实，需人工确认 · 命中「被正确计入」 · 散文「这样从地面直接走两阶的情况才能被正确计入。」
- `curriculum/chapters/algorithms_advanced.dart:156:10` · long-sentence · hard · 真实问题 · 命中「45 字」 · 散文「该建模还可扩展到禁用某一级台阶或改变允许步长，但每一种约束都需要重新检查状态转移是否仍然有效。」
- `curriculum/chapters/algorithms_advanced.dart:181:38` · semicolon · hard · 真实问题 · 命中「；」 · 散文「禁用级的方案数保持零，其余位置按相同前驱相加；零级仍为一。」
- `curriculum/chapters/algorithms_advanced.dart:214:10` · long-sentence · hard · 真实问题 · 命中「46 字」 · 散文「零钱兑换的最少枚数不总能靠先拿最大硬币解决，例如面值一、三、四兑换六时，两枚三元比四元加两个一元更好。」
- `curriculum/chapters/algorithms_advanced.dart:247:22` · vague-word · advisory · 真实问题 · 命中「若干」 · 散文「贪心用整除取若干枚并取余，但最后仍要输出 DP 结果，观察两种策略差异。」
- `curriculum/chapters/algorithms_advanced.dart:281:10` · long-sentence · hard · 真实问题 · 命中「50 字」 · 散文「程序外层逐个引入面值，内层金额从小到大推进，当前状态只把已经引入的面值组合起来，避免按最后一步重复计算排列。」
- `curriculum/chapters/algorithms_advanced.dart:283:33` · compound-aspect · advisory · 酌情保留 · 命中「已经更新过」 · 散文「同一面值可以无限使用，所以内层允许读到当前面值已经更新过的较小金额。」
- `curriculum/chapters/algorithms_advanced.dart:284:28` · passive-voice · advisory · 多为真实，需人工确认 · 命中「被当作不同类别」 · 散文「输入面值必须去除重复，否则相同面值会被当作不同类别重复计数。」
- `curriculum/chapters/algorithms_advanced.dart:345:35` · semicolon · hard · 真实问题 · 命中「；」 · 散文「末尾字符相同时，可以在去掉双方末尾的最佳长度上加一；」
- `curriculum/chapters/algorithms_advanced.dart:348:16` · synonym-rotation · hard · 待人工确认 · 命中「创建」 · 散文「程序为每一行创建独立列表，防止多行共享同一个可变数组。」
- `curriculum/chapters/algorithms_advanced.dart:350:31` · semicolon · hard · 真实问题 · 命中「；」 · 散文「本例处理普通英文字符，输出长度而非具体序列；」
- `curriculum/chapters/algorithms_advanced.dart:379:30` · semicolon · hard · 真实问题 · 命中「；」 · 散文「同一对文本交换参数应结果相同；增加前缀长度不会使最优长度减少。」
- `curriculum/chapters/algorithms_advanced.dart:410:10` · long-sentence · hard · 真实问题 · 命中「41 字」 · 散文「本例把状态定义为以某个位置结尾的最长严格递增长度，每个元素至少能独立形成长度一的序列。」
- `curriculum/chapters/algorithms_advanced.dart:411:41` · semicolon · hard · 真实问题 · 命中「；」 · 散文「对当前位置，检查所有更早且数值更小的前驱，尝试把它们的长度加一；」
- `curriculum/chapters/algorithms_advanced.dart:415:35` · semicolon · hard · 真实问题 · 命中「；」 · 散文「双重循环需要 O(n²) 时间，适合先理解状态含义；」
- `curriculum/chapters/algorithms_advanced.dart:484:10` · long-sentence · hard · 真实问题 · 命中「43 字」 · 散文「状态记录给定容量目前能达到的最佳价值，引入一件物品时比较不选它与为它腾出重量后的价值加成。」
- `curriculum/chapters/algorithms_advanced.dart:485:10` · long-sentence · hard · 真实问题 · 命中「59 字」 · 散文「一维压缩省去了物品维度，但也让更新方向变成正确性的关键：容量从大到小遍历，读取的较小容量仍属于上一轮，当前物品就不会被重复使用。」
- `curriculum/chapters/algorithms_advanced.dart:485:68` · passive-voice · advisory · 多为真实，需人工确认 · 命中「被重复使用」 · 散文「一维压缩省去了物品维度，但也让更新方向变成正确性的关键：容量从大到小遍历，读取的较小容量仍属于上一轮，当前物品就不会被重复使用。」
- `curriculum/chapters/algorithms_advanced.dart:540:33` · passive-voice · advisory · 多为真实，需人工确认 · 命中「被重复使用的压」 · 散文「通过倒序容量保证物品不被重复使用的压缩背包。」
- `curriculum/chapters/algorithms_advanced.dart:551:10` · long-sentence · hard · 真实问题 · 命中「54 字」 · 散文「程序用一行数组压缩二维状态：更新前的 dp[j] 是上一行同列的结果，更新后的 dp[j-1] 是本行左侧结果，取较小者再加当前格子代价。」
- `curriculum/chapters/algorithms_advanced.dart:555:26` · semicolon · hard · 真实问题 · 命中「；」 · 散文「示例输出累计代价，不保存具体路线；」
- `curriculum/chapters/algorithms_advanced.dart:624:10` · long-sentence · hard · 真实问题 · 命中「41 字」 · 散文「编辑距离衡量把一段文本变成另一段文本所需的最少操作次数，本课把插入、删除和替换都计为一。」
- `curriculum/chapters/algorithms_advanced.dart:626:10` · long-sentence · hard · 真实问题 · 命中「45 字」 · 散文「当前字符相同时沿用左上状态，不同时分别考虑删除一侧末尾、插入另一侧字符或替换，然后取最小代价加一。」
- `curriculum/chapters/algorithms_advanced.dart:696:10` · long-sentence · hard · 真实问题 · 命中「49 字」 · 散文「滚动数组初始仅给起点方向放入一种空路径，每个普通格子累计上方和左方的方案，遇到障碍则立即将该列状态清零。」
- `curriculum/chapters/algorithms_advanced.dart:697:39` · passive-voice · advisory · 多为真实，需人工确认 · 命中「被封闭时自然得」 · 散文「清零能够阻止上一行路径穿过障碍继续向下传播，也让起点或终点被封闭时自然得到零。」
- `curriculum/chapters/algorithms_advanced.dart:699:27` · semicolon · hard · 真实问题 · 命中「；」 · 散文「计数依赖网格为矩形以及障碍约定一致；」
- `curriculum/chapters/algorithms_advanced.dart:701:34` · passive-voice · advisory · 多为真实，需人工确认 · 命中「被封闭的起点和」 · 散文「能将障碍转成不可达状态，并正确处理被封闭的起点和终点。」
- `curriculum/chapters/algorithms_advanced.dart:763:10` · long-sentence · hard · 真实问题 · 命中「44 字」 · 散文「本例统计有向无环图中每个节点到终点的路线数：终点贡献一种完成路径，其他节点把后继的方案数相加。」
- `curriculum/chapters/algorithms_advanced.dart:764:10` · long-sentence · hard · 真实问题 · 命中「41 字」 · 散文「自顶向下版本只搜索实际可达的状态并缓存结果，active 集合单独记录当前递归链，用来识别循环依赖；」
- `curriculum/chapters/algorithms_advanced.dart:764:59` · semicolon · hard · 真实问题 · 命中「；」 · 散文「自顶向下版本只搜索实际可达的状态并缓存结果，active 集合单独记录当前递归链，用来识别循环依赖；」
- `curriculum/chapters/data_structures.dart:14:10` · long-sentence · hard · 真实问题 · 命中「42 字」 · 散文「本课用整数列表封装 push、pop、peek 与 isEmpty，只在列表尾部添加和移除元素，让内部存储细节不会散落到调用处。」
- `curriculum/chapters/data_structures.dart:14:53` · synonym-rotation · hard · 待人工确认 · 命中「移除」 · 散文「本课用整数列表封装 push、pop、peek 与 isEmpty，只在列表尾部添加和移除元素，让内部存储细节不会散落到调用处。」
- `curriculum/chapters/data_structures.dart:14:61` · synonym-rotation · hard · 待人工确认 · 命中「存储」 · 散文「本课用整数列表封装 push、pop、peek 与 isEmpty，只在列表尾部添加和移除元素，让内部存储细节不会散落到调用处。」
- `curriculum/chapters/data_structures.dart:53:23` · semicolon · hard · 真实问题 · 命中「；」 · 散文「遇到数字就压栈；遇到运算符先取 right，再取 left，计算 left-right 或 left*right。」
- `curriculum/chapters/data_structures.dart:100:10` · long-sentence · hard · 真实问题 · 命中「53 字」 · 散文「这个实现适合解释语义，但每次删除头部都需要移动后续元素，单次出队是线性成本，长队列连续清空可能累计到平方级工作量。」
- `curriculum/chapters/data_structures.dart:136:54` · semicolon · hard · 真实问题 · 命中「；」 · 散文「将 A01、A02、A03、A04 入队，取消集合为 A02 与 A04；按到达顺序只服务未取消的工单。」
- `curriculum/chapters/data_structures.dart:181:10` · long-sentence · hard · 真实问题 · 命中「50 字」 · 散文「未满时把新值写到起点加长度的位置，满后直接覆盖起点并把起点向前移动，所有物理下标都通过取模回到容量范围内。」
- `curriculum/chapters/data_structures.dart:183:45` · passive-voice · advisory · 多为真实，需人工确认 · 命中「被误丢弃」 · 散文「空槽使用零初始化，但是否有效只由 length 决定，真实的零读数不会被误丢弃。」
- `curriculum/chapters/data_structures.dart:228:43` · semicolon · hard · 真实问题 · 命中「；」 · 散文「snapshot 返回实际有效记录，求和后除以它的长度；尚未写满时也不能固定除以三。」
- `curriculum/chapters/data_structures.dart:283:53` · semicolon · hard · 真实问题 · 命中「；」 · 散文「append 从入口向后寻找尾部，insertAfter 在第一个匹配值之后插入新节点；」
- `curriculum/chapters/data_structures.dart:286:28` · semicolon · hard · 真实问题 · 命中「；」 · 散文「没有尾指针时，每次追加都需要线性扫描；」
- `curriculum/chapters/data_structures.dart:288:10` · long-sentence · hard · 真实问题 · 命中「49 字」 · 散文「这里按值匹配仅操作第一次出现的位置，若业务要求精确选择重复值中的某个节点，应改为传递节点引用或额外标识。」
- `curriculum/chapters/data_structures.dart:339:18` · synonym-rotation · hard · 待人工确认 · 命中「建立」 · 散文「建立值为 2、2、3 的链表，在第一个 2 后插入 9，并验证找不到目标 8 时链表保持相同内容。」
- `curriculum/chapters/data_structures.dart:397:10` · long-sentence · hard · 真实问题 · 命中「42 字」 · 散文「本课维护 previous、current 和 next 三个引用：previous 是已经反转完成的部分，current 是尚未处理的入口，next 临时保存原来的后继。」
- `curriculum/chapters/data_structures.dart:399:47` · semicolon · hard · 真实问题 · 命中「；」 · 散文「结束时 current 为 null，previous 就是新链表的头节点；」
- `curriculum/chapters/data_structures.dart:400:26` · passive-voice · advisory · 多为真实，需人工确认 · 命中「被置空」 · 散文「旧头节点的 next 已在第一轮被置空，因此自然成为尾部。」
- `curriculum/chapters/data_structures.dart:444:35` · semicolon · hard · 真实问题 · 命中「；」 · 散文「保存第一次反转的返回值作为第二次的输入；用 identical 检查引用身份。」
- `curriculum/chapters/data_structures.dart:491:10` · long-sentence · hard · 真实问题 · 命中「48 字」 · 散文「Floyd 方法让慢指针每轮走一步、快指针走两步：无环时快指针会先到达尾部，有环时二者进入环后会在有限轮次内相遇。」
- `curriculum/chapters/data_structures.dart:494:27` · semicolon · hard · 真实问题 · 命中「；」 · 散文「算法只保存两个引用，额外空间为常数；」
- `curriculum/chapters/data_structures.dart:570:23` · semicolon · hard · 真实问题 · 命中「；」 · 散文「前序先记录根，再遍历左和右；」
- `curriculum/chapters/data_structures.dart:571:22` · semicolon · hard · 真实问题 · 命中「；」 · 散文「中序把根放在两个子树之间；」
- `curriculum/chapters/data_structures.dart:574:10` · long-sentence · hard · 真实问题 · 命中「45 字」 · 散文「示例使用不对称的树，避免仅凭对称形状误以为三种遍历相同，输出列表也能直观看出每个节点只访问一次。」
- `curriculum/chapters/data_structures.dart:576:10` · long-sentence · hard · 真实问题 · 命中「41 字」 · 散文「普通二叉树的中序结果并不保证有序，只有额外满足二叉搜索树的大小关系时才能作出这种判断。」
- `curriculum/chapters/data_structures.dart:581:19` · synonym-rotation · hard · 待人工确认 · 命中「新建」 · 散文「递归输出容器应由调用处新建，避免多次遍历意外混合旧结果。」
- `curriculum/chapters/data_structures.dart:661:47` · semicolon · hard · 真实问题 · 命中「；」 · 散文「本例把重复键视为已经存在，直接保留原树，因此实现的是整数集合而不是多重集合；」
- `curriculum/chapters/data_structures.dart:707:33` · semicolon · hard · 真实问题 · 命中「；」 · 散文「containsKey 判断缺失项；中序结果可用于遍历求和，但不要依赖节点对象的默认字符串。」
- `curriculum/chapters/data_structures.dart:760:10` · long-sentence · hard · 真实问题 · 命中「42 字」 · 散文「开始一层时记录当前队列长度作为 end，本层只处理 head 到 end 之间的节点，期间加入的孩子会留给下一轮。」
- `curriculum/chapters/data_structures.dart:763:19` · compound-aspect · advisory · 酌情保留 · 命中「已经处理过」 · 散文「这个教学实现会保留已经处理过的引用直到函数结束，空间为节点总数；」
- `curriculum/chapters/data_structures.dart:763:41` · semicolon · hard · 真实问题 · 命中「；」 · 散文「这个教学实现会保留已经处理过的引用直到函数结束，空间为节点总数；」
- `curriculum/chapters/data_structures.dart:805:43` · semicolon · hard · 真实问题 · 命中「；」 · 散文「构造 A 的左右孩子为 B、C，B 的左孩子为 D；根据层序结果计算树高与最大层宽。」
- `curriculum/chapters/data_structures.dart:855:41` · semicolon · hard · 真实问题 · 命中「；」 · 散文「插入时寻找第一个不大于新键的位置，并把新任务放在同级旧任务之前；」
- `curriculum/chapters/data_structures.dart:858:10` · long-sentence · hard · 真实问题 · 命中「43 字」 · 散文「这个结构使用有序列表，不是二叉堆：寻找插入点和移动元素都可能花线性时间，而取最小项为常数时间。」
- `curriculum/chapters/data_structures.dart:897:18` · long-sentence · hard · 真实问题 · 命中「42 字」 · 散文「先加入优先级为二的甲与乙，取走甲后加入优先级为一的急件与优先级为二的丙，输出剩余服务顺序。」
- `curriculum/chapters/data_structures.dart:898:34` · semicolon · hard · 真实问题 · 命中「；」 · 散文「新急件应先于乙，同级乙应先于后到的丙；动态插入也必须保持同级稳定性。」
- `curriculum/chapters/data_structures.dart:991:18` · long-sentence · hard · 真实问题 · 命中「44 字」 · 散文「处理五个站点的连接 0-1、1-2、0-2、3-4，统计有多少条边连接了原本已经连通的端点，并输出最终分量数。」
- `curriculum/chapters/data_structures.dart:992:42` · semicolon · hard · 真实问题 · 命中「；」 · 散文「union 返回 false 表示这条边没有改变分组；把这种返回值计入冗余边数量。」
- `curriculum/chapters/data_structures.dart:1045:38` · semicolon · hard · 真实问题 · 命中「；」 · 散文「递归 DFS 在进入节点时登记并立即深入第一个未访问邻居；」
- `curriculum/chapters/data_structures.dart:1046:31` · passive-voice · advisory · 多为真实，需人工确认 · 命中「被多个前驱重复」 · 散文「BFS 在邻居入队时登记，保证同一节点不会被多个前驱重复加入队列。」
- `curriculum/chapters/math_stats.dart:16:55` · semicolon · hard · 真实问题 · 命中「；」 · 散文「不要先乘再除，较大的中间乘积没有必要。 最大公约数非负；两个输入都为零时本例返回零。」
- `curriculum/chapters/math_stats.dart:83:63` · passive-voice · advisory · 多为真实，需人工确认 · 命中「被误判」 · 散文「一不是质数，必须在进入试除循环前排除。 边界要包含平方根，否则四十九会被误判。」
- `curriculum/chapters/math_stats.dart:135:43` · synonym-rotation · hard · 待人工确认 · 命中「建立」 · 散文「如果要列出一段连续区间的全部质数，逐个试除会重复检查相同因子。筛法建立一个布尔表，每遇到尚未标记的整数，就把它的倍数标为合数。从该整数的平方开始标记，是因为更小的倍数已经被较小」
- `curriculum/chapters/math_stats.dart:135:93` · compound-aspect · advisory · 酌情保留 · 命中「已经被较小因子处理过」 · 散文「如果要列出一段连续区间的全部质数，逐个试除会重复检查相同因子。筛法建立一个布尔表，每遇到尚未标记的整数，就把它的倍数标为合数。从该整数的平方开始标记，是因为更小的倍数已经被较小」
- `curriculum/chapters/math_stats.dart:135:95` · passive-voice · advisory · 多为真实，需人工确认 · 命中「被较小因子处理」 · 散文「如果要列出一段连续区间的全部质数，逐个试除会重复检查相同因子。筛法建立一个布尔表，每遇到尚未标记的整数，就把它的倍数标为合数。从该整数的平方开始标记，是因为更小的倍数已经被较小」
- `curriculum/chapters/math_stats.dart:200:61` · semicolon · hard · 真实问题 · 命中「；」 · 散文「质因数分解回答一个整数由哪些质数相乘构成。发现一个可整除的因子后，要持续除到不能整除，才能得到它的指数；只除一次会漏掉重复因子。每次缩小剩余数，又使后续搜索范围收缩。当试除结束」
- `curriculum/chapters/math_stats.dart:203:49` · semicolon · hard · 真实问题 · 命中「；」 · 散文「结束循环后的剩余数不能丢弃。 一的分解为空；零没有有限的质因数分解。」
- `curriculum/chapters/math_stats.dart:266:67` · synonym-rotation · hard · 待人工确认 · 命中「创建」 · 散文「杨辉三角每行的两端为一，中间的数等于上一行相邻两项之和。这种只依赖前一层的结构，是理解动态规划的直观入口。本例每轮创建一张新列表，先填边界，再填中间，最后把整行加入结果。不能反」
- `curriculum/chapters/math_stats.dart:266:120` · passive-voice · advisory · 多为真实，需人工确认 · 命中「被改变」 · 散文「杨辉三角每行的两端为一，中间的数等于上一行相邻两项之和。这种只依赖前一层的结构，是理解动态规划的直观入口。本例每轮创建一张新列表，先填边界，再填中间，最后把整行加入结果。不能反」
- `curriculum/chapters/math_stats.dart:380:41` · synonym-rotation · hard · 待人工确认 · 命中「校验」 · 散文「矩阵乘法 点积 维度校验」
- `curriculum/chapters/math_stats.dart:448:28` · long-sentence · hard · 真实问题 · 命中「41 字」 · 散文「一组数据的典型大小并非只有一种说法。均值使用所有数值，容易受极端值影响；中位数查看排序后的中间位置；众数则强调出现最频繁的值。本例选取含有重复项和较大离群值的等待时间，同时计算」
- `curriculum/chapters/math_stats.dart:448:45` · semicolon · hard · 真实问题 · 命中「；」 · 散文「一组数据的典型大小并非只有一种说法。均值使用所有数值，容易受极端值影响；中位数查看排序后的中间位置；众数则强调出现最频繁的值。本例选取含有重复项和较大离群值的等待时间，同时计算」
- `curriculum/chapters/math_stats.dart:448:59` · semicolon · hard · 真实问题 · 命中「；」 · 散文「一组数据的典型大小并非只有一种说法。均值使用所有数值，容易受极端值影响；中位数查看排序后的中间位置；众数则强调出现最频繁的值。本例选取含有重复项和较大离群值的等待时间，同时计算」
- `curriculum/chapters/math_stats.dart:448:137` · semicolon · hard · 真实问题 · 命中「；」 · 散文「一组数据的典型大小并非只有一种说法。均值使用所有数值，容易受极端值影响；中位数查看排序后的中间位置；众数则强调出现最频繁的值。本例选取含有重复项和较大离群值的等待时间，同时计算」
- `curriculum/chapters/math_stats.dart:508:32` · long-sentence · hard · 真实问题 · 命中「42 字」 · 散文「均值相同的两组测量结果，稳定性可能完全不同。方差把各观测与均值的差平方后求平均，避免正负偏差抵消；标准差再开平方，把单位还原到原观测量。本例比较两组平均温度相同的读数，并输出标」
- `curriculum/chapters/math_stats.dart:508:58` · semicolon · hard · 真实问题 · 命中「；」 · 散文「均值相同的两组测量结果，稳定性可能完全不同。方差把各观测与均值的差平方后求平均，避免正负偏差抵消；标准差再开平方，把单位还原到原观测量。本例比较两组平均温度相同的读数，并输出标」
- `curriculum/chapters/math_stats.dart:508:189` · synonym-rotation · hard · 待人工确认 · 命中「执行」 · 散文「均值相同的两组测量结果，稳定性可能完全不同。方差把各观测与均值的差平方后求平均，避免正负偏差抵消；标准差再开平方，把单位还原到原观测量。本例比较两组平均温度相同的读数，并输出标」
- `curriculum/chapters/math_stats.dart:565:44` · long-sentence · hard · 真实问题 · 命中「41 字」 · 散文「移动平均每次只查看最近固定数量的观测，可以减弱偶然尖峰对趋势的影响。若每个窗口重新求和，窗口越宽重复工作越多；保存当前窗口总和后，只需减去离开的值并加上新值。本例采用满窗口才输」
- `curriculum/chapters/math_stats.dart:565:64` · semicolon · hard · 真实问题 · 命中「；」 · 散文「移动平均每次只查看最近固定数量的观测，可以减弱偶然尖峰对趋势的影响。若每个窗口重新求和，窗口越宽重复工作越多；保存当前窗口总和后，只需减去离开的值并加上新值。本例采用满窗口才输」
- `curriculum/chapters/math_stats.dart:565:189` · synonym-rotation · hard · 待人工确认 · 命中「核对」 · 散文「移动平均每次只查看最近固定数量的观测，可以减弱偶然尖峰对趋势的影响。若每个窗口重新求和，窗口越宽重复工作越多；保存当前窗口总和后，只需减去离开的值并加上新值。本例采用满窗口才输」
- `curriculum/chapters/math_stats.dart:627:33` · long-sentence · hard · 真实问题 · 命中「50 字」 · 散文「线性回归用一条直线概括两个数值变量之间的关系。先计算横纵坐标均值，再把同一观测的中心化乘积求和，除以横坐标平方偏差和即可得到斜率；截距保证直线经过均值点。本例使用工时和产量的固」
- `curriculum/chapters/math_stats.dart:627:74` · semicolon · hard · 真实问题 · 命中「；」 · 散文「线性回归用一条直线概括两个数值变量之间的关系。先计算横纵坐标均值，再把同一观测的中心化乘积求和，除以横坐标平方偏差和即可得到斜率；截距保证直线经过均值点。本例使用工时和产量的固」
- `curriculum/chapters/math_stats.dart:627:155` · vague-word · advisory · 真实问题 · 命中「相关」 · 散文「线性回归用一条直线概括两个数值变量之间的关系。先计算横纵坐标均值，再把同一观测的中心化乘积求和，除以横坐标平方偏差和即可得到斜率；截距保证直线经过均值点。本例使用工时和产量的固」
- `curriculum/chapters/math_stats.dart:707:124` · long-sentence · hard · 真实问题 · 命中「44 字」 · 散文「界面和题目常使用角度，而标准三角函数接收弧度。两者之间通过圆周率换算：一百八十度等于圆周率弧度。本例先把九十度转换成弧度，再对平面中的点应用旋转公式，分别计算新的横纵坐标。最后」
- `curriculum/chapters/oop_modeling.dart:13:79` · synonym-rotation · hard · 待人工确认 · 命中「生成」 · 散文「两个位置对象只要行列相同，就应代表同一个网格位置，而不必是同一次构造的对象。值对象把这种业务相等性写进相等运算符，并用参与比较的同一组字段生成哈希值。本例使用不可变坐标，分别比」
- `curriculum/chapters/oop_modeling.dart:76:80` · long-sentence · hard · 真实问题 · 命中「45 字」 · 散文「默认的对象输出只能说明它属于哪个类，往往不足以定位业务数据问题。重写字符串表示时，可以选择少量最有意义的字段，形成稳定且容易辨认的调试描述。本例把库存数量和预留数量封装为快照，」
- `curriculum/chapters/oop_modeling.dart:76:116` · synonym-rotation · hard · 待人工确认 · 命中「呈现」 · 散文「默认的对象输出只能说明它属于哪个类，往往不足以定位业务数据问题。重写字符串表示时，可以选择少量最有意义的字段，形成稳定且容易辨认的调试描述。本例把库存数量和预留数量封装为快照，」
- `curriculum/chapters/oop_modeling.dart:76:177` · synonym-rotation · hard · 待人工确认 · 命中「检查」 · 散文「默认的对象输出只能说明它属于哪个类，往往不足以定位业务数据问题。重写字符串表示时，可以选择少量最有意义的字段，形成稳定且容易辨认的调试描述。本例把库存数量和预留数量封装为快照，」
- `curriculum/chapters/oop_modeling.dart:135:41` · long-sentence · hard · 真实问题 · 命中「44 字」 · 散文「如果每个调用点都自行清理编号，某处漏做一步就可能创建非法对象。工厂构造提供统一入口：先去掉外侧空格并转换大小写，再检查完整格式，最后调用私有构造器保存合法值。本例要求商品编号由」
- `curriculum/chapters/oop_modeling.dart:135:143` · synonym-rotation · hard · 待人工确认 · 命中「异常」 · 散文「如果每个调用点都自行清理编号，某处漏做一步就可能创建非法对象。工厂构造提供统一入口：先去掉外侧空格并转换大小写，再检查完整格式，最后调用私有构造器保存合法值。本例要求商品编号由」
- `curriculum/chapters/oop_modeling.dart:135:181` · synonym-rotation · hard · 待人工确认 · 命中「删掉」 · 散文「如果每个调用点都自行清理编号，某处漏做一步就可能创建非法对象。工厂构造提供统一入口：先去掉外侧空格并转换大小写，再检查完整格式，最后调用私有构造器保存合法值。本例要求商品编号由」
- `curriculum/chapters/oop_modeling.dart:136:18` · synonym-rotation · hard · 待人工确认 · 命中「建立」 · 散文「能建立只允许合法实例通过的构造入口。」
- `curriculum/chapters/oop_modeling.dart:208:68` · synonym-rotation · hard · 待人工确认 · 命中「存储」 · 散文「裸数字不能说明计量单位，构造入口的名字可以把单位写进调用代码。本例提供米和厘米两种命名构造，并让厘米入口重定向到以米存储的标准入口。内部只保存一种单位，后续相加不需要猜测来源，」
- `curriculum/chapters/oop_modeling.dart:208:131` · synonym-rotation · hard · 待人工确认 · 命中「显示」 · 散文「裸数字不能说明计量单位，构造入口的名字可以把单位写进调用代码。本例提供米和厘米两种命名构造，并让厘米入口重定向到以米存储的标准入口。内部只保存一种单位，后续相加不需要猜测来源，」
- `curriculum/chapters/oop_modeling.dart:323:23` · synonym-rotation · hard · 待人工确认 · 命中「设定」 · 散文「在赋值前校验温度设定值，失败时保留原状态。」
- `curriculum/chapters/oop_modeling.dart:326:188` · synonym-rotation · hard · 待人工确认 · 命中「执行」 · 散文「公开字段允许调用方绕过所有业务规则，而受控的 setter 可以在真正写入前完成校验。本例把温控器的设定值保存为私有字段，只允许十六到三十度之间的值。合法赋值成功后读取新状态，」
- `curriculum/chapters/oop_modeling.dart:392:38` · long-sentence · hard · 真实问题 · 命中「43 字」 · 散文「结算流程只需要知道如何取得运费，不应关心每一种计价细节。抽象接口声明报价能力，两个实现分别提供固定运费和按距离运费，调用者通过接口类型统一使用它们。本例把两个实现放入同一列表，」
- `curriculum/chapters/oop_modeling.dart:455:41` · long-sentence · hard · 真实问题 · 命中「44 字」 · 散文「把所有操作塞进一个大接口，会迫使只需要读取的代码依赖写入能力。拆成较小的读取接口和追加接口后，一个对象可以同时实现两者，而不同函数只接收自己真正需要的能力。本例的内存便笺实现读」
- `curriculum/chapters/oop_modeling.dart:532:33` · passive-voice · advisory · 多为真实，需人工确认 · 命中「被修改」 · 散文「只给字段加 final 不能阻止其引用的 Map 被修改。」
- `curriculum/chapters/oop_modeling.dart:557:22` · synonym-rotation · hard · 待人工确认 · 命中「新建」 · 散文「每个列表也要新建并包装为只读，再包装外层 Map。」
- `curriculum/chapters/oop_modeling.dart:596:40` · semicolon · hard · 真实问题 · 命中「；」 · 散文「只读集合不能代替元素自身不可变；可变元素仍会泄漏状态。 快照每次复制有成本，应根据真实读取规模选择。」
- `curriculum/chapters/oop_modeling.dart:674:75` · long-sentence · hard · 真实问题 · 命中「41 字」 · 散文「只有一个计算动作的策略，不一定需要为每种变体建立一个新类。把函数保存为字段，可以让对象保留统一的调用入口，同时由外部注入不同算法。本例报价器接收一个以整数分为单位的计算函数，分」
- `curriculum/chapters/oop_modeling.dart:740:39` · long-sentence · hard · 真实问题 · 命中「41 字」 · 散文「对象式和函数式组织并非互斥选择，关键是状态和规则放在哪里。对象方法可以把相关数据和操作封装在一起，纯函数则把全部输入显式放在参数中，方便独立组合。本例为按重量收费提供一个计价对」
- `curriculum/chapters/oop_modeling.dart:740:46` · vague-word · advisory · 真实问题 · 命中「相关」 · 散文「对象式和函数式组织并非互斥选择，关键是状态和规则放在哪里。对象方法可以把相关数据和操作封装在一起，纯函数则把全部输入显式放在参数中，方便独立组合。本例为按重量收费提供一个计价对」
- `curriculum/chapters/enum_states.dart:13:111` · long-sentence · hard · 真实问题 · 命中「51 字」 · 散文「业务状态应使用一组封闭的值，而界面需要面向读者的文字。枚举定义合法状态，标签函数再把每个状态映射为中文，避免在各处散落字符串比较。本例逐项展示配送状态和对应标签，说明状态本身不」
- `curriculum/chapters/enum_states.dart:13:131` · passive-voice · advisory · 多为真实，需人工确认 · 命中「被发现」 · 散文「业务状态应使用一组封闭的值，而界面需要面向读者的文字。枚举定义合法状态，标签函数再把每个状态映射为中文，避免在各处散落字符串比较。本例逐项展示配送状态和对应标签，说明状态本身不」
- `curriculum/chapters/enum_states.dart:13:134` · semicolon · hard · 真实问题 · 命中「；」 · 散文「业务状态应使用一组封闭的值，而界面需要面向读者的文字。枚举定义合法状态，标签函数再把每个状态映射为中文，避免在各处散落字符串比较。本例逐项展示配送状态和对应标签，说明状态本身不」
- `curriculum/chapters/enum_states.dart:71:39` · long-sentence · hard · 真实问题 · 命中「42 字」 · 散文「当枚举声明顺序本身表达等级时，索引可以用于局部优先级比较。本例把普通、紧急和立即处理三个等级排成递增顺序，排序时反向比较索引，使最紧急的工单最先出现。相同等级再用编号排序，保证」
- `curriculum/chapters/enum_states.dart:130:27` · synonym-rotation · hard · 待人工确认 · 命中「显示」 · 散文「用封闭类别建立频数表，并显示没有出现过的类别。」
- `curriculum/chapters/enum_states.dart:136:30` · synonym-rotation · hard · 待人工确认 · 命中「创建」 · 散文「只在出现时创建键，会漏掉零频类别。 展示顺序最好按枚举或业务规则明确指定。」
- `curriculum/chapters/enum_states.dart:184:52` · long-sentence · hard · 真实问题 · 命中「46 字」 · 散文「订单流程不是任意状态之间都能跳转。例如待支付可以取消，已经发货则不能重新变为待支付。迁移表把允许的后继状态集中列出，查询时只检查当前状态对应的集合，比在多个按钮里重复条件更容易」
- `curriculum/chapters/enum_states.dart:184:104` · synonym-rotation · hard · 待人工确认 · 命中「执行」 · 散文「订单流程不是任意状态之间都能跳转。例如待支付可以取消，已经发货则不能重新变为待支付。迁移表把允许的后继状态集中列出，查询时只检查当前状态对应的集合，比在多个按钮里重复条件更容易」
- `curriculum/chapters/enum_states.dart:184:124` · passive-voice · advisory · 多为真实，需人工确认 · 命中「被允许的操作才」 · 散文「订单流程不是任意状态之间都能跳转。例如待支付可以取消，已经发货则不能重新变为待支付。迁移表把允许的后继状态集中列出，查询时只检查当前状态对应的集合，比在多个按钮里重复条件更容易」
- `curriculum/chapters/enum_states.dart:249:117` · long-sentence · hard · 真实问题 · 命中「50 字」 · 散文「交通灯是一个容易观察的有限状态机：绿灯结束后进入黄灯，黄灯结束后进入红灯，再返回绿灯。本例把下一状态和持续秒数分别写为函数，主循环只负责记录当前时刻并推进状态。这样增加日志或修」
- `curriculum/chapters/enum_states.dart:249:152` · semicolon · hard · 真实问题 · 命中「；」 · 散文「交通灯是一个容易观察的有限状态机：绿灯结束后进入黄灯，黄灯结束后进入红灯，再返回绿灯。本例把下一状态和持续秒数分别写为函数，主循环只负责记录当前时刻并推进状态。这样增加日志或修」
- `curriculum/chapters/enum_states.dart:320:39` · long-sentence · hard · 真实问题 · 命中「48 字」 · 散文「把字符串切成有意义的单元，需要记住刚才正在读取哪一种内容。本例把字符分成字母、数字、符号和空白四类：同类的字母或数字继续累积，类别改变时先输出缓冲区，符号则单独成词。空白只负责」
- `curriculum/chapters/enum_states.dart:402:10` · long-sentence · hard · 真实问题 · 命中「46 字」 · 散文「关卡流程同时包含当前位置和剩余机会，若只保存一个字符串状态，很容易在通关后继续扣生命或多推进一关。本例使用枚举表示进行中、全部完成和机会耗尽，关卡号与生命数保存具体进度。成功推」
- `curriculum/chapters/enum_states.dart:440:22` · vague-word · advisory · 真实问题 · 命中「相关」 · 散文「一次恢复所有相关字段，避免只修改枚举而保留旧进度。」
- `curriculum/chapters/enum_states.dart:483:21` · synonym-rotation · hard · 待人工确认 · 命中「校验」 · 散文「在状态改变前校验审核流程，并用异常向调用者报告拒绝。」
- `curriculum/chapters/enum_states.dart:483:30` · synonym-rotation · hard · 待人工确认 · 命中「异常」 · 散文「在状态改变前校验审核流程，并用异常向调用者报告拒绝。」
- `curriculum/chapters/enum_states.dart:486:42` · long-sentence · hard · 真实问题 · 命中「41 字」 · 散文「审核工作流需要防止从草稿直接发布，也需要保留已经发生的合法历史。本例把迁移检查封装进对象方法：只有后继表允许的目标状态才能写入，并且仅在成功后追加历史。非法操作抛出状态错误，调」
- `curriculum/chapters/enum_states.dart:486:128` · passive-voice · advisory · 多为真实，需人工确认 · 命中「被破坏」 · 散文「审核工作流需要防止从草稿直接发布，也需要保留已经发生的合法历史。本例把迁移检查封装进对象方法：只有后继表允许的目标状态才能写入，并且仅在成功后追加历史。非法操作抛出状态错误，调」
- `curriculum/chapters/enum_states.dart:486:132` · long-sentence · hard · 真实问题 · 命中「41 字」 · 散文「审核工作流需要防止从草稿直接发布，也需要保留已经发生的合法历史。本例把迁移检查封装进对象方法：只有后继表允许的目标状态才能写入，并且仅在成功后追加历史。非法操作抛出状态错误，调」
- `curriculum/chapters/enum_states.dart:486:142` · synonym-rotation · hard · 待人工确认 · 命中「核对」 · 散文「审核工作流需要防止从草稿直接发布，也需要保留已经发生的合法历史。本例把迁移检查封装进对象方法：只有后继表允许的目标状态才能写入，并且仅在成功后追加历史。非法操作抛出状态错误，调」
- `curriculum/chapters/enum_states.dart:520:38` · passive-voice · advisory · 多为真实，需人工确认 · 命中「被删除」 · 散文「增加审核退回草稿的路径，并说明历史是否应被删除。」
- `curriculum/chapters/enum_states.dart:521:36` · semicolon · hard · 真实问题 · 命中「；」 · 散文「允许 submitted 到 draft；保留原历史，再追加新的 draft。」
- `curriculum/chapters/enum_states.dart:562:41` · long-sentence · hard · 真实问题 · 命中「43 字」 · 散文「权限判断同时涉及角色和动作，散落在界面中的条件容易出现不一致。用两个枚举限定合法值，再通过角色到动作集合的映射集中表达允许关系，能让审查变成查看一张小表。本例为访客、编辑者和管」
- `curriculum/chapters/enum_states.dart:562:116` · synonym-rotation · hard · 待人工确认 · 命中「生成」 · 散文「权限判断同时涉及角色和动作，散落在界面中的条件容易出现不一致。用两个枚举限定合法值，再通过角色到动作集合的映射集中表达允许关系，能让审查变成查看一张小表。本例为访客、编辑者和管」
- `curriculum/chapters/enum_states.dart:618:110` · passive-voice · advisory · 多为真实，需人工确认 · 命中「被拒绝」 · 散文「只看最终状态无法解释过程，统计所有请求又可能把非法事件算成成功。本例使用当前状态和事件共同查询下一状态，同时分别记录收到次数与成功迁移次数。连接建立、就绪和断开形成正常路径，在」
- `curriculum/chapters/errors_resilience.dart:9:21` · synonym-rotation · hard · 待人工确认 · 命中「异常」 · 散文「携带业务上下文的异常」
- `curriculum/chapters/errors_resilience.dart:13:29` · long-sentence · hard · 真实问题 · 命中「44 字」 · 散文「业务失败往往需要比一段文字更多的信息。自定义异常可以把稳定的错误码和面向人的详情分别保存，调用方根据代码分类处理，展示层再使用详情。本例在库存不足时抛出包含商品编号、请求数量和」
- `curriculum/chapters/errors_resilience.dart:13:190` · synonym-rotation · hard · 待人工确认 · 命中「执行」 · 散文「业务失败往往需要比一段文字更多的信息。自定义异常可以把稳定的错误码和面向人的详情分别保存，调用方根据代码分类处理，展示层再使用详情。本例在库存不足时抛出包含商品编号、请求数量和」
- `curriculum/chapters/errors_resilience.dart:13:200` · synonym-rotation · hard · 待人工确认 · 命中「核对」 · 散文「业务失败往往需要比一段文字更多的信息。自定义异常可以把稳定的错误码和面向人的详情分别保存，调用方根据代码分类处理，展示层再使用详情。本例在库存不足时抛出包含商品编号、请求数量和」
- `curriculum/chapters/errors_resilience.dart:45:27` · synonym-rotation · hard · 待人工确认 · 命中「检查」 · 散文「保持同一个异常类型，先检查编号，再检查数量。」
- `curriculum/chapters/errors_resilience.dart:95:10` · long-sentence · hard · 真实问题 · 命中「45 字」 · 散文「批量导入常常包含少数坏记录，如果把整个循环包在一个异常处理块中，第一条失败就会阻止后面所有记录。本例把解析和范围检查放在每一轮的 try 中，成功数量累加，失败则记录行号和原因」
- `curriculum/chapters/errors_resilience.dart:95:58` · long-sentence · hard · 真实问题 · 命中「41 字」 · 散文「批量导入常常包含少数坏记录，如果把整个循环包在一个异常处理块中，第一条失败就会阻止后面所有记录。本例把解析和范围检查放在每一轮的 try 中，成功数量累加，失败则记录行号和原因」
- `curriculum/chapters/errors_resilience.dart:95:157` · passive-voice · advisory · 多为真实，需人工确认 · 命中「被接受」 · 散文「批量导入常常包含少数坏记录，如果把整个循环包在一个异常处理块中，第一条失败就会阻止后面所有记录。本例把解析和范围检查放在每一轮的 try 中，成功数量累加，失败则记录行号和原因」
- `curriculum/chapters/errors_resilience.dart:152:32` · synonym-rotation · hard · 待人工确认 · 命中「显示」 · 散文「用户输入不符合格式是常见情况，调用者往往只想显示原因并继续。结果对象把成功值和失败原因作为返回数据，让函数签名体现两种可能。本例为端口输入定义两个命名构造，保证成功时有值、失败」
- `curriculum/chapters/errors_resilience.dart:152:167` · passive-voice · advisory · 多为真实，需人工确认 · 命中「被随意转成普通」 · 散文「用户输入不符合格式是常见情况，调用者往往只想显示原因并继续。结果对象把成功值和失败原因作为返回数据，让函数签名体现两种可能。本例为端口输入定义两个命名构造，保证成功时有值、失败」
- `curriculum/chapters/errors_resilience.dart:217:10` · long-sentence · hard · 真实问题 · 命中「44 字」 · 散文「断言适合帮助开发者发现内部假设被破坏，却不能成为用户输入的唯一校验，因为发布模式可以关闭断言。本例的分页函数先使用参数错误拒绝非法页码和页大小，再用断言说明通过检查后的内部条件」
- `curriculum/chapters/errors_resilience.dart:217:25` · passive-voice · advisory · 多为真实，需人工确认 · 命中「被破坏」 · 散文「断言适合帮助开发者发现内部假设被破坏，却不能成为用户输入的唯一校验，因为发布模式可以关闭断言。本例的分页函数先使用参数错误拒绝非法页码和页大小，再用断言说明通过检查后的内部条件」
- `curriculum/chapters/errors_resilience.dart:243:33` · semicolon · hard · 真实问题 · 命中「；」 · 散文「先处理空数据，再用向上取整计算页数；业务检查仍使用显式 if。」
- `curriculum/chapters/errors_resilience.dart:345:72` · passive-voice · advisory · 多为真实，需人工确认 · 命中「被隐藏」 · 散文「降级不等于静默吞错，应该保留来源或原因。 不要捕获所有错误后都回退，否则调用代码缺陷也会被隐藏。」
- `curriculum/chapters/errors_resilience.dart:424:38` · long-sentence · hard · 真实问题 · 命中「44 字」 · 散文「重试可以应对临时失败，但无上限循环会让程序永远无法结束。本例定义一种明确可重试的异常，让重试函数最多调用指定次数，成功立即返回，最后一次失败则重新抛出。测试操作用本地计数器在前」
- `curriculum/chapters/errors_resilience.dart:491:181` · semicolon · hard · 真实问题 · 命中「；」 · 散文「资源清理应覆盖成功和失败两条路径，并按取得资源的相反顺序执行。本例先创建临时目录，再打开文件句柄写入真实内容，随后触发一个格式解析错误。内层 finally 关闭文件，外层捕获」
- `curriculum/chapters/errors_resilience.dart:556:18` · synonym-rotation · hard · 待人工确认 · 命中「故障」 · 散文「把临时故障和永久拒绝分开处理，避免无效重试。」
- `curriculum/chapters/errors_resilience.dart:559:92` · long-sentence · hard · 真实问题 · 命中「41 字」 · 散文「并非所有失败都有重试价值。临时索引忙可能稍后恢复，参数无效则无论重复多少次都不会成功。本例用枚举给操作失败分类，执行策略只对临时类别继续尝试，遇到永久拒绝立即停止。两组本地脚本」
- `curriculum/chapters/errors_resilience.dart:639:176` · semicolon · hard · 真实问题 · 命中「；」 · 散文「单条记录字段正确，不代表整个批次满足契约。导入还可能要求标识唯一、声明总量与实际合计一致。本例先逐条检查编号和数量，再维护已见编号集合识别重复，最后比较批次声明的总量。所有发现」
- `curriculum/chapters/errors_resilience.dart:720:93` · long-sentence · hard · 真实问题 · 命中「47 字」 · 散文「可扩展程序执行第三方回调时，某个回调失败不应必然阻止整个批次。Dart 允许抛出任意非空对象，因此只捕获 Exception 不能覆盖 Error 或旧式字符串抛出。本例先为已」
- `curriculum/chapters/errors_resilience.dart:754:10` · long-sentence · hard · 真实问题 · 命中「44 字」 · 散文「任务 1: 7\n任务 2: 已知格式问题\n任务 3: 程序错误\n任务 4: 其他抛出值\n任务 5: 9\n成功 2，失败 3\n」
- `curriculum/chapters/json_modeling.dart:13:48` · long-sentence · hard · 真实问题 · 命中「45 字」 · 散文「JSON 文本只保存通用的数据结构，读取后还需要确认每个字段在业务中的含义。本例把离线项目清单解码为字符串键映射，再分别取得名称、修订号、启用标记和功能列表，最后生成一行摘要。」
- `curriculum/chapters/json_modeling.dart:13:91` · synonym-rotation · hard · 待人工确认 · 命中「生成」 · 散文「JSON 文本只保存通用的数据结构，读取后还需要确认每个字段在业务中的含义。本例把离线项目清单解码为字符串键映射，再分别取得名称、修订号、启用标记和功能列表，最后生成一行摘要。」
- `curriculum/chapters/json_modeling.dart:13:137` · synonym-rotation · hard · 待人工确认 · 命中「校验」 · 散文「JSON 文本只保存通用的数据结构，读取后还需要确认每个字段在业务中的含义。本例把离线项目清单解码为字符串键映射，再分别取得名称、修订号、启用标记和功能列表，最后生成一行摘要。」
- `curriculum/chapters/json_modeling.dart:13:200` · synonym-rotation · hard · 待人工确认 · 命中「核对」 · 散文「JSON 文本只保存通用的数据结构，读取后还需要确认每个字段在业务中的含义。本例把离线项目清单解码为字符串键映射，再分别取得名称、修订号、启用标记和功能列表，最后生成一行摘要。」
- `curriculum/chapters/json_modeling.dart:66:85` · passive-voice · advisory · 多为真实，需人工确认 · 命中「被编码为转义序」 · 散文「序列化并不一定要把整个对象重新输出，修改文档可以只保留变化字段。本例比较任务修改前后的标量映射，收集值不同的键，再编码为紧凑 JSON。文本中的换行会被编码为转义序列，而不会破」
- `curriculum/chapters/json_modeling.dart:66:107` · semicolon · hard · 真实问题 · 命中「；」 · 散文「序列化并不一定要把整个对象重新输出，修改文档可以只保留变化字段。本例比较任务修改前后的标量映射，收集值不同的键，再编码为紧凑 JSON。文本中的换行会被编码为转义序列，而不会破」
- `curriculum/chapters/json_modeling.dart:96:45` · semicolon · hard · 真实问题 · 命中「；」 · 散文「遍历 before.keys，筛选 after 不包含的键；不要与显式 null 混淆。」
- `curriculum/chapters/json_modeling.dart:129:66` · synonym-rotation · hard · 待人工确认 · 命中「执行」 · 散文「标签输入经常包含外侧空格、大小写差异和重复项，直接保存会让后续筛选变复杂。本例先把解码后的数组转为字符串视图，再执行去空格、转小写、去空项、去重和排序。每一步对应一个独立规则，」
- `curriculum/chapters/json_modeling.dart:134:32` · passive-voice · advisory · 多为真实，需人工确认 · 命中「被当成不同标签」 · 散文「去重前先规范化，否则 Dart 和 dart 会被当成不同标签。」
- `curriculum/chapters/json_modeling.dart:178:65` · synonym-rotation · hard · 待人工确认 · 命中「设置」 · 散文「配置字段缺失并不总是错误，协议可以为可选项定义默认值。空合并只在左值为空时使用默认值，所以能够正确保留用户明确设置的 false 或零。本例读取几份不同完整度的显示配置，分别补」
- `curriculum/chapters/json_modeling.dart:178:78` · long-sentence · hard · 真实问题 · 命中「44 字」 · 散文「配置字段缺失并不总是错误，协议可以为可选项定义默认值。空合并只在左值为空时使用默认值，所以能够正确保留用户明确设置的 false 或零。本例读取几份不同完整度的显示配置，分别补」
- `curriculum/chapters/json_modeling.dart:178:90` · synonym-rotation · hard · 待人工确认 · 命中「显示」 · 散文「配置字段缺失并不总是错误，协议可以为可选项定义默认值。空合并只在左值为空时使用默认值，所以能够正确保留用户明确设置的 false 或零。本例读取几份不同完整度的显示配置，分别补」
- `curriculum/chapters/json_modeling.dart:351:147` · synonym-rotation · hard · 待人工确认 · 命中「变更」 · 散文「保存领域对象时，应明确哪些字段进入格式以及如何还原，而不是依赖调试字符串。本例为便笺条目定义映射导出和工厂导入，把对象列表编码成 JSON，再解码回新的对象列表。往返检查逐项比」
- `curriculum/chapters/json_modeling.dart:355:8` · synonym-rotation · hard · 待人工确认 · 命中「新建」 · 散文「新建对象通常不与旧对象引用相等，不能直接比较两个列表。」
- `curriculum/chapters/json_modeling.dart:424:47` · long-sentence · hard · 真实问题 · 命中「49 字」 · 散文「JSON 中的数字四和字符串形式的四是不同类型，类型断言不会替你解析文本。本例先尝试严格读取整数，观察字符串、小数和空值的失败；随后使用显式兼容函数，只接受整数或可解析的整数字」
- `curriculum/chapters/json_modeling.dart:424:73` · semicolon · hard · 真实问题 · 命中「；」 · 散文「JSON 中的数字四和字符串形式的四是不同类型，类型断言不会替你解析文本。本例先尝试严格读取整数，观察字符串、小数和空值的失败；随后使用显式兼容函数，只接受整数或可解析的整数字」
- `curriculum/chapters/json_modeling.dart:424:104` · passive-voice · advisory · 多为真实，需人工确认 · 命中「被拒绝」 · 散文「JSON 中的数字四和字符串形式的四是不同类型，类型断言不会替你解析文本。本例先尝试严格读取整数，观察字符串、小数和空值的失败；随后使用显式兼容函数，只接受整数或可解析的整数字」
- `curriculum/chapters/json_modeling.dart:492:41` · long-sentence · hard · 真实问题 · 命中「42 字」 · 散文「排查深层配置时，路径到值的平面表比反复展开嵌套对象更容易搜索。本例递归遍历映射和列表，把对象层级写成点号路径，把数组位置写成方括号索引，普通值则成为叶子。空对象和空数组没有子项」
- `curriculum/chapters/json_modeling.dart:520:34` · synonym-rotation · hard · 待人工确认 · 命中「异常」 · 散文「增加最大递归深度，超过时抛出格式异常。」
- `curriculum/chapters/json_modeling.dart:628:37` · passive-voice · advisory · 多为真实，需人工确认 · 命中「被修改」 · 散文「递归合并对象、整体替换数组，并保持默认配置不被修改。」
- `curriculum/chapters/json_modeling.dart:631:46` · long-sentence · hard · 真实问题 · 命中「46 字」 · 散文「简单的外层映射覆盖会把整个嵌套配置替换掉，连未修改的默认字段也一起丢失。本例规定对象递归合并、数组整体替换、标量和空值直接覆盖，再通过深复制避免结果与默认配置共享可变容器。输入」
- `curriculum/chapters/json_modeling.dart:706:49` · passive-voice · advisory · 多为真实，需人工确认 · 命中「被修改」 · 散文「运行并观察递归合并对象、整体替换数组，并保持默认配置不被修改。」
- `curriculum/chapters/json_modeling.dart:716:85` · long-sentence · hard · 真实问题 · 命中「48 字」 · 散文「导入不可信 JSON 时，清洗规则必须同时说明接受什么、如何规范化以及拒绝什么。本例先检查记录结构，再处理商品编号和数量，最后识别规范化后的重复编号。合法整数字符串被明确解析，」
- `curriculum/chapters/json_modeling.dart:716:92` · passive-voice · advisory · 多为真实，需人工确认 · 命中「被明确解析」 · 散文「导入不可信 JSON 时，清洗规则必须同时说明接受什么、如何规范化以及拒绝什么。本例先检查记录结构，再处理商品编号和数量，最后识别规范化后的重复编号。合法整数字符串被明确解析，」
- `curriculum/chapters/json_modeling.dart:716:109` · passive-voice · advisory · 多为真实，需人工确认 · 命中「被拒绝」 · 散文「导入不可信 JSON 时，清洗规则必须同时说明接受什么、如何规范化以及拒绝什么。本例先检查记录结构，再处理商品编号和数量，最后识别规范化后的重复编号。合法整数字符串被明确解析，」
- `curriculum/chapters/json_modeling.dart:749:10` · long-sentence · hard · 真实问题 · 命中「42 字」 · 散文「[{\"sku\":\"PEN\",\"qty\":2},{\"sku\":\"BOOK\",\"qty\":4}]\n空编号: 1\n结构错误: 1\n编号重复: 1\n数量」
- `curriculum/chapters/dates_money.dart:13:14` · compound-aspect · advisory · 酌情保留 · 命中「已经过了」 · 散文「周岁表示已经过了多少个完整周年，不能直接拿当前年份减出生年份。程序先得到年份差，再比较当前月份与日期是否早于生日，必要时减一。所有输入都使用固定 UTC 日期，使测试不依赖运行」
- `curriculum/chapters/dates_money.dart:13:67` · vague-word · advisory · 真实问题 · 命中「必要时」 · 散文「周岁表示已经过了多少个完整周年，不能直接拿当前年份减出生年份。程序先得到年份差，再比较当前月份与日期是否早于生日，必要时减一。所有输入都使用固定 UTC 日期，使测试不依赖运行」
- `curriculum/chapters/dates_money.dart:13:108` · long-sentence · hard · 真实问题 · 命中「61 字」 · 散文「周岁表示已经过了多少个完整周年，不能直接拿当前年份减出生年份。程序先得到年份差，再比较当前月份与日期是否早于生日，必要时减一。所有输入都使用固定 UTC 日期，使测试不依赖运行」
- `curriculum/chapters/dates_money.dart:13:151` · semicolon · hard · 真实问题 · 命中「；」 · 散文「周岁表示已经过了多少个完整周年，不能直接拿当前年份减出生年份。程序先得到年份差，再比较当前月份与日期是否早于生日，必要时减一。所有输入都使用固定 UTC 日期，使测试不依赖运行」
- `curriculum/chapters/dates_money.dart:66:32` · long-sentence · hard · 真实问题 · 命中「41 字」 · 散文「文件归档和日报标题经常需要统一的年月日标签。把月份直接插入字符串会得到一位和两位混杂的形式，按文本排序时也容易让十月排到二月前面。程序分别提取 UTC 日期的年、月、日，再补足」
- `curriculum/chapters/dates_money.dart:66:127` · synonym-rotation · hard · 待人工确认 · 命中「更改」 · 散文「文件归档和日报标题经常需要统一的年月日标签。把月份直接插入字符串会得到一位和两位混杂的形式，按文本排序时也容易让十月排到二月前面。程序分别提取 UTC 日期的年、月、日，再补足」
- `curriculum/chapters/dates_money.dart:66:204` · semicolon · hard · 真实问题 · 命中「；」 · 散文「文件归档和日报标题经常需要统一的年月日标签。把月份直接插入字符串会得到一位和两位混杂的形式，按文本排序时也容易让十月排到二月前面。程序分别提取 UTC 日期的年、月、日，再补足」
- `curriculum/chapters/dates_money.dart:106:171` · long-sentence · hard · 真实问题 · 命中「49 字」 · 散文「订单有效期通常讨论的是日历日期，而计时器讨论的是两个时刻的持续时间，这两件事需要分开。程序把输入限定为 UTC 午夜，利用 difference 得到 Duration，再读取」
- `curriculum/chapters/dates_money.dart:147:30` · vague-word · advisory · 真实问题 · 命中「若干」 · 散文「学习计划中的间隔复习适合表示为起始日期加若干天。程序把复习间隔保存在列表里，每次都从同一个起始日期计算目标，而不是在上一次结果上重复叠加，这能避免把累计间隔误当成增量。Date」
- `curriculum/chapters/dates_money.dart:147:34` · long-sentence · hard · 真实问题 · 命中「56 字」 · 散文「学习计划中的间隔复习适合表示为起始日期加若干天。程序把复习间隔保存在列表里，每次都从同一个起始日期计算目标，而不是在上一次结果上重复叠加，这能避免把累计间隔误当成增量。Date」
- `curriculum/chapters/dates_money.dart:147:134` · synonym-rotation · hard · 待人工确认 · 命中「显示」 · 散文「学习计划中的间隔复习适合表示为起始日期加若干天。程序把复习间隔保存在列表里，每次都从同一个起始日期计算目标，而不是在上一次结果上重复叠加，这能避免把累计间隔误当成增量。Date」
- `curriculum/chapters/dates_money.dart:147:147` · long-sentence · hard · 真实问题 · 命中「60 字」 · 散文「学习计划中的间隔复习适合表示为起始日期加若干天。程序把复习间隔保存在列表里，每次都从同一个起始日期计算目标，而不是在上一次结果上重复叠加，这能避免把累计间隔误当成增量。Date」
- `curriculum/chapters/dates_money.dart:147:165` · semicolon · hard · 真实问题 · 命中「；」 · 散文「学习计划中的间隔复习适合表示为起始日期加若干天。程序把复习间隔保存在列表里，每次都从同一个起始日期计算目标，而不是在上一次结果上重复叠加，这能避免把累计间隔误当成增量。Date」
- `curriculum/chapters/dates_money.dart:188:157` · long-sentence · hard · 真实问题 · 命中「55 字」 · 散文「Dart 的 weekday 从星期一的一开始计数，而列表索引从零开始，两者衔接时必须减一。程序用固定名称表显示星期，再用日期序号对值班人员数量取模，形成循环轮班。两种索引各自」
- `curriculum/chapters/dates_money.dart:188:186` · semicolon · hard · 真实问题 · 命中「；」 · 散文「Dart 的 weekday 从星期一的一开始计数，而列表索引从零开始，两者衔接时必须减一。程序用固定名称表显示星期，再用日期序号对值班人员数量取模，形成循环轮班。两种索引各自」
- `curriculum/chapters/dates_money.dart:235:159` · long-sentence · hard · 真实问题 · 命中「54 字」 · 散文「统计交付周期前，应先约定结束日是否计入。本例采用包含开始日、不包含结束日的半开区间，使连续两个区间拼接时不会重复计算边界。每轮先查看星期，再查询人工提供的休息日集合，两个条件都」
- `curriculum/chapters/dates_money.dart:235:187` · semicolon · hard · 真实问题 · 命中「；」 · 散文「统计交付周期前，应先约定结束日是否计入。本例采用包含开始日、不包含结束日的半开区间，使连续两个区间拼接时不会重复计算边界。每轮先查看星期，再查询人工提供的休息日集合，两个条件都」
- `curriculum/chapters/dates_money.dart:286:35` · long-sentence · hard · 真实问题 · 命中「41 字」 · 散文「分期表必须保证所有期次归还的本金恰好等于原始本金。程序把金额保存在分单位整数中，先求每期基础本金，最后一期归还全部剩余数，避免整除余数遗失。每期利息按本期开始前的剩余本金乘固定」
- `curriculum/chapters/dates_money.dart:286:112` · semicolon · hard · 真实问题 · 命中「；」 · 散文「分期表必须保证所有期次归还的本金恰好等于原始本金。程序把金额保存在分单位整数中，先求每期基础本金，最后一期归还全部剩余数，避免整除余数遗失。每期利息按本期开始前的剩余本金乘固定」
- `curriculum/chapters/dates_money.dart:286:150` · long-sentence · hard · 真实问题 · 命中「61 字」 · 散文「分期表必须保证所有期次归还的本金恰好等于原始本金。程序把金额保存在分单位整数中，先求每期基础本金，最后一期归还全部剩余数，避免整除余数遗失。每期利息按本期开始前的剩余本金乘固定」
- `curriculum/chapters/dates_money.dart:286:188` · semicolon · hard · 真实问题 · 命中「；」 · 散文「分期表必须保证所有期次归还的本金恰好等于原始本金。程序把金额保存在分单位整数中，先求每期基础本金，最后一期归还全部剩余数，避免整除余数遗失。每期利息按本期开始前的剩余本金乘固定」
- `curriculum/chapters/dates_money.dart:338:45` · long-sentence · hard · 真实问题 · 命中「42 字」 · 散文「固定比例连续增长时，每一期的基数是上一期的余额，因此多期结果包含乘方。程序一方面用 pow 计算闭式公式，另一方面在循环里逐年乘增长系数，打印每年余额并比较最终展示值。两条路径」
- `curriculum/chapters/dates_money.dart:338:147` · semicolon · hard · 真实问题 · 命中「；」 · 散文「固定比例连续增长时，每一期的基数是上一期的余额，因此多期结果包含乘方。程序一方面用 pow 计算闭式公式，另一方面在循环里逐年乘增长系数，打印每年余额并比较最终展示值。两条路径」
- `curriculum/chapters/dates_money.dart:338:165` · long-sentence · hard · 真实问题 · 命中「50 字」 · 散文「固定比例连续增长时，每一期的基数是上一期的余额，因此多期结果包含乘方。程序一方面用 pow 计算闭式公式，另一方面在循环里逐年乘增长系数，打印每年余额并比较最终展示值。两条路径」
- `curriculum/chapters/dates_money.dart:338:193` · semicolon · hard · 真实问题 · 命中「；」 · 散文「固定比例连续增长时，每一期的基数是上一期的余额，因此多期结果包含乘方。程序一方面用 pow 计算闭式公式，另一方面在循环里逐年乘增长系数，打印每年余额并比较最终展示值。两条路径」
- `curriculum/chapters/dates_money.dart:384:99` · passive-voice · advisory · 多为真实，需人工确认 · 命中「被重新提高单价」 · 散文「阶梯计费把总量划分为几个互不重叠的区间，每一档只处理属于本档的增量。程序依次计算前一百、接下来一百和超过两百的数量，分别乘上整数单价后累计。这样在跨档时只会增加新档费用，旧档不」
- `curriculum/chapters/dates_money.dart:384:165` · semicolon · hard · 真实问题 · 命中「；」 · 散文「阶梯计费把总量划分为几个互不重叠的区间，每一档只处理属于本档的增量。程序依次计算前一百、接下来一百和超过两百的数量，分别乘上整数单价后累计。这样在跨档时只会增加新档费用，旧档不」
- `curriculum/chapters/dates_money.dart:426:27` · synonym-rotation · hard · 待人工确认 · 命中「校验」 · 散文「正则校验 整数金额 符号分离」
- `curriculum/chapters/dates_money.dart:428:47` · long-sentence · hard · 真实问题 · 命中「41 字」 · 散文「精确累加账目时，先把金额文本转换成分单位整数，可以避免二进制小数累加误差。程序只接受带可选负号和最多两位小数的十进制格式，拆出整数部分与小数部分，再补足两位转换。输出函数先分离」
- `curriculum/chapters/dates_money.dart:428:181` · semicolon · hard · 真实问题 · 命中「；」 · 散文「精确累加账目时，先把金额文本转换成分单位整数，可以避免二进制小数累加误差。程序只接受带可选负号和最多两位小数的十进制格式，拆出整数部分与小数部分，再补足两位转换。输出函数先分离」
- `curriculum/chapters/dates_money.dart:485:57` · long-sentence · hard · 真实问题 · 命中「45 字」 · 散文「账期通常不一定从每月第一天开始。本例约定每月二十日开始新账期，十九日及之前属于上一个开始月份。程序根据日期选择当前月或前一月，再利用 DateTime.utc 对月份零自动归一」
- `curriculum/chapters/dates_money.dart:485:172` · long-sentence · hard · 真实问题 · 命中「46 字」 · 散文「账期通常不一定从每月第一天开始。本例约定每月二十日开始新账期，十九日及之前属于上一个开始月份。程序根据日期选择当前月或前一月，再利用 DateTime.utc 对月份零自动归一」
- `curriculum/chapters/dates_money.dart:485:193` · semicolon · hard · 真实问题 · 命中「；」 · 散文「账期通常不一定从每月第一天开始。本例约定每月二十日开始新账期，十九日及之前属于上一个开始月份。程序根据日期选择当前月或前一月，再利用 DateTime.utc 对月份零自动归一」
- `curriculum/chapters/collection_reporting.dart:13:83` · long-sentence · hard · 真实问题 · 命中「44 字」 · 散文「一批工单可能包含重复分类，报表需要先把相同分类汇总成数量。程序逐条读取分类，用 Map 中已有数量或零作为基础加一，不需要为每个分类预先声明变量。默认 Map 保留键首次插入的」
- `curriculum/chapters/collection_reporting.dart:13:209` · semicolon · hard · 真实问题 · 命中「；」 · 散文「一批工单可能包含重复分类，报表需要先把相同分类汇总成数量。程序逐条读取分类，用 Map 中已有数量或零作为基础加一，不需要为每个分类预先声明变量。默认 Map 保留键首次插入的」
- `curriculum/chapters/collection_reporting.dart:16:29` · synonym-rotation · hard · 待人工确认 · 命中「创建」 · 散文「不要每轮创建新的 Map，否则前面的统计会丢失。 Map 的插入顺序并不等于按数量排序。」
- `curriculum/chapters/collection_reporting.dart:54:37` · long-sentence · hard · 真实问题 · 命中「45 字」 · 散文「排行榜不仅需要找出最大值，还要定义分数相同时谁先出现。程序把 Map 的条目复制为列表，先按数值降序比较，相同分数再按名称升序比较，形成完整且可重现的排序规则。随后只取前 N 」
- `curriculum/chapters/collection_reporting.dart:54:137` · long-sentence · hard · 真实问题 · 命中「43 字」 · 散文「排行榜不仅需要找出最大值，还要定义分数相同时谁先出现。程序把 Map 的条目复制为列表，先按数值降序比较，相同分数再按名称升序比较，形成完整且可重现的排序规则。随后只取前 N 」
- `curriculum/chapters/collection_reporting.dart:54:160` · semicolon · hard · 真实问题 · 命中「；」 · 散文「排行榜不仅需要找出最大值，还要定义分数相同时谁先出现。程序把 Map 的条目复制为列表，先按数值降序比较，相同分数再按名称升序比较，形成完整且可重现的排序规则。随后只取前 N 」
- `curriculum/chapters/collection_reporting.dart:76:26` · semicolon · hard · 真实问题 · 命中「；」 · 散文「过滤应发生在排序之前；名次从过滤后的列表生成。」
- `curriculum/chapters/collection_reporting.dart:98:183` · semicolon · hard · 真实问题 · 命中「；」 · 散文「直方图先把连续数值放入区间，再统计各区间频数。程序用整除得到十分一档的索引，并把满分一百单独归入最后一档，避免生成不存在的第十一档。输入先验证为零到一百，非法分数不能因为索引计」
- `curriculum/chapters/collection_reporting.dart:145:199` · semicolon · hard · 真实问题 · 命中「；」 · 散文「单维分组只能回答每个地区有多少，透视表还要区分地区内部的产品。程序把地区映射到另一张产品数量表，读取一条记录时先获得地区行，再更新产品列。展示阶段使用明确的地区和产品清单，对没」
- `curriculum/chapters/collection_reporting.dart:146:18` · synonym-rotation · hard · 待人工确认 · 命中「建立」 · 散文「能建立二维聚合结构，并输出包含空组合的规则表格。」
- `curriculum/chapters/collection_reporting.dart:198:71` · compound-aspect · advisory · 酌情保留 · 命中「已经越过」 · 散文「分页接口常用从一开始的页码，而列表索引从零开始，因此开始位置应是页码减一再乘页大小。程序先拒绝非正参数，再判断开始位置是否已经越过数据尾部，最后把结束位置裁剪到实际长度。这样最」
- `curriculum/chapters/collection_reporting.dart:198:160` · long-sentence · hard · 真实问题 · 命中「54 字」 · 散文「分页接口常用从一开始的页码，而列表索引从零开始，因此开始位置应是页码减一再乘页大小。程序先拒绝非正参数，再判断开始位置是否已经越过数据尾部，最后把结束位置裁剪到实际长度。这样最」
- `curriculum/chapters/collection_reporting.dart:198:181` · semicolon · hard · 真实问题 · 命中「；」 · 散文「分页接口常用从一开始的页码，而列表索引从零开始，因此开始位置应是页码减一再乘页大小。程序先拒绝非正参数，再判断开始位置是否已经越过数据尾部，最后把结束位置裁剪到实际长度。这样最」
- `curriculum/chapters/collection_reporting.dart:242:173` · long-sentence · hard · 真实问题 · 命中「55 字」 · 散文「同步两个成员列表时，单看最终数量无法知道哪些人加入、哪些人离开。程序先把输入转换为集合去除重复，再用方向相反的差集得到新增和移除项，用交集得到保留项。差集有方向，因此 old.」
- `curriculum/chapters/collection_reporting.dart:242:203` · semicolon · hard · 真实问题 · 命中「；」 · 散文「同步两个成员列表时，单看最终数量无法知道哪些人加入、哪些人离开。程序先把输入转换为集合去除重复，再用方向相反的差集得到新增和移除项，用交集得到保留项。差集有方向，因此 old.」
- `curriculum/chapters/collection_reporting.dart:282:113` · long-sentence · hard · 真实问题 · 命中「43 字」 · 散文「Map 的展开语法默认让后面的同名键覆盖前面的值，但两家仓库合并库存时通常需要相加。程序先复制第一份映射，再遍历第二份，对已有键累加、对新键从零开始。这样冲突处理策略明确写在一」
- `curriculum/chapters/collection_reporting.dart:282:160` · long-sentence · hard · 真实问题 · 命中「54 字」 · 散文「Map 的展开语法默认让后面的同名键覆盖前面的值，但两家仓库合并库存时通常需要相加。程序先复制第一份映射，再遍历第二份，对已有键累加、对新键从零开始。这样冲突处理策略明确写在一」
- `curriculum/chapters/collection_reporting.dart:282:181` · semicolon · hard · 真实问题 · 命中「；」 · 散文「Map 的展开语法默认让后面的同名键覆盖前面的值，但两家仓库合并库存时通常需要相加。程序先复制第一份映射，再遍历第二份，对已有键累加、对新键从零开始。这样冲突处理策略明确写在一」
- `curriculum/chapters/collection_reporting.dart:283:40` · passive-voice · advisory · 多为真实，需人工确认 · 命中「被修改」 · 散文「能为相同键定义明确的累加策略，并保持输入集合不被修改。」
- `curriculum/chapters/collection_reporting.dart:332:64` · compound-aspect · advisory · 酌情保留 · 命中「已经见过」 · 散文「合并推荐标签时，重复项只需出现一次，但输出顺序通常要保留第一次出现的位置。程序让 Set 专门判断某个值是否已经见过，利用 add 的布尔返回值决定是否把它加入结果列表。列表负」
- `curriculum/chapters/collection_reporting.dart:332:158` · long-sentence · hard · 真实问题 · 命中「58 字」 · 散文「合并推荐标签时，重复项只需出现一次，但输出顺序通常要保留第一次出现的位置。程序让 Set 专门判断某个值是否已经见过，利用 add 的布尔返回值决定是否把它加入结果列表。列表负」
- `curriculum/chapters/collection_reporting.dart:332:181` · semicolon · hard · 真实问题 · 命中「；」 · 散文「合并推荐标签时，重复项只需出现一次，但输出顺序通常要保留第一次出现的位置。程序让 Set 专门判断某个值是否已经见过，利用 add 的布尔返回值决定是否把它加入结果列表。列表负」
- `curriculum/chapters/collection_reporting.dart:332:219` · synonym-rotation · hard · 待人工确认 · 命中「删除」 · 散文「合并推荐标签时，重复项只需出现一次，但输出顺序通常要保留第一次出现的位置。程序让 Set 专门判断某个值是否已经见过，利用 add 的布尔返回值决定是否把它加入结果列表。列表负」
- `curriculum/chapters/collection_reporting.dart:379:164` · long-sentence · hard · 真实问题 · 命中「44 字」 · 散文「计算每组均值时，最可靠的中间状态是总和与数量，而不是不断平均已经算出的平均值。程序为每个班级保存两张映射，一张记录总分，另一张记录人数，最后统一做除法并格式化展示。这样无论输入」
- `curriculum/chapters/collection_reporting.dart:379:173` · passive-voice · advisory · 多为真实，需人工确认 · 命中「被除以零」 · 散文「计算每组均值时，最可靠的中间状态是总和与数量，而不是不断平均已经算出的平均值。程序为每个班级保存两张映射，一张记录总分，另一张记录人数，最后统一做除法并格式化展示。这样无论输入」
- `curriculum/chapters/collection_reporting.dart:379:177` · semicolon · hard · 真实问题 · 命中「；」 · 散文「计算每组均值时，最可靠的中间状态是总和与数量，而不是不断平均已经算出的平均值。程序为每个班级保存两张映射，一张记录总分，另一张记录人数，最后统一做除法并格式化展示。这样无论输入」
- `curriculum/chapters/collection_reporting.dart:379:181` · synonym-rotation · hard · 待人工确认 · 命中「显示」 · 散文「计算每组均值时，最可靠的中间状态是总和与数量，而不是不断平均已经算出的平均值。程序为每个班级保存两张映射，一张记录总分，另一张记录人数，最后统一做除法并格式化展示。这样无论输入」
- `curriculum/chapters/collection_reporting.dart:382:64` · synonym-rotation · hard · 待人工确认 · 命中「执行」 · 散文「平均两个均值时若人数不同，必须按人数加权。 空组的均值没有定义，不应直接执行零除以零。」
- `curriculum/chapters/collection_reporting.dart:420:20` · synonym-rotation · hard · 待人工确认 · 命中「校验」 · 散文「流水余额与累计校验」
- `curriculum/chapters/collection_reporting.dart:472:30` · long-sentence · hard · 真实问题 · 命中「54 字」 · 散文「增长率的分母是对照期数值，不是本期数值。程序把变化率封装成返回可空结果的函数：当基线为零时返回 null，由展示层输出无基线，而不是给出无穷大或把它伪装成百分之百。非零基线则计」
- `curriculum/chapters/collection_reporting.dart:472:143` · long-sentence · hard · 真实问题 · 命中「62 字」 · 散文「增长率的分母是对照期数值，不是本期数值。程序把变化率封装成返回可空结果的函数：当基线为零时返回 null，由展示层输出无基线，而不是给出无穷大或把它伪装成百分之百。非零基线则计」
- `curriculum/chapters/collection_reporting.dart:472:174` · semicolon · hard · 真实问题 · 命中「；」 · 散文「增长率的分母是对照期数值，不是本期数值。程序把变化率封装成返回可空结果的函数：当基线为零时返回 null，由展示层输出无基线，而不是给出无穷大或把它伪装成百分之百。非零基线则计」
- `curriculum/chapters/collection_reporting.dart:516:140` · long-sentence · hard · 真实问题 · 命中「58 字」 · 散文「一个清晰的报表应先完成业务计算，再决定每列怎样对齐。程序把商品数量与单价相乘得到小计，累计总额，同时根据商品名和小计文本计算列宽。输出阶段只读取这些已确定的数据，名称左对齐，数」
- `curriculum/chapters/collection_reporting.dart:516:163` · semicolon · hard · 真实问题 · 命中「；」 · 散文「一个清晰的报表应先完成业务计算，再决定每列怎样对齐。程序把商品数量与单价相乘得到小计，累计总额，同时根据商品名和小计文本计算列宽。输出阶段只读取这些已确定的数据，名称左对齐，数」
- `curriculum/chapters/formatting_output.dart:13:44` · long-sentence · hard · 真实问题 · 命中「42 字」 · 散文「定宽表格需要所有行使用相同的列宽规则，不能为某一行临时多补几个空格。程序把单元格格式化封装成函数：文本较短时右侧补空格，超过宽度时截取前面部分并添加省略标记。表头、分隔线和每条」
- `curriculum/chapters/formatting_output.dart:13:134` · long-sentence · hard · 真实问题 · 命中「64 字」 · 散文「定宽表格需要所有行使用相同的列宽规则，不能为某一行临时多补几个空格。程序把单元格格式化封装成函数：文本较短时右侧补空格，超过宽度时截取前面部分并添加省略标记。表头、分隔线和每条」
- `curriculum/chapters/formatting_output.dart:13:163` · semicolon · hard · 真实问题 · 命中「；」 · 散文「定宽表格需要所有行使用相同的列宽规则，不能为某一行临时多补几个空格。程序把单元格格式化封装成函数：文本较短时右侧补空格，超过宽度时截取前面部分并添加省略标记。表头、分隔线和每条」
- `curriculum/chapters/formatting_output.dart:58:164` · long-sentence · hard · 真实问题 · 命中「45 字」 · 散文「编号列表跨过九到十时，若简单连接数字和文本，内容起点会向右移动。程序先根据最后一个编号计算所需宽度，再给所有编号左侧补空格，保证正文从同一列开始。起始编号作为独立输入，因此可以」
- `curriculum/chapters/formatting_output.dart:58:210` · synonym-rotation · hard · 待人工确认 · 命中「展示」 · 散文「编号列表跨过九到十时，若简单连接数字和文本，内容起点会向右移动。程序先根据最后一个编号计算所需宽度，再给所有编号左侧补空格，保证正文从同一列开始。起始编号作为独立输入，因此可以」
- `curriculum/chapters/formatting_output.dart:101:31` · synonym-rotation · hard · 待人工确认 · 命中「呈现」 · 散文「树形数据显示不仅要列出节点，还要把层级关系呈现出来。程序用名称到子节点列表的映射表示一棵小树，访问节点时先打印自己，再递归访问孩子，这就是前序遍历。缩进宽度由递归深度决定，根节」
- `curriculum/chapters/formatting_output.dart:101:36` · long-sentence · hard · 真实问题 · 命中「44 字」 · 散文「树形数据显示不仅要列出节点，还要把层级关系呈现出来。程序用名称到子节点列表的映射表示一棵小树，访问节点时先打印自己，再递归访问孩子，这就是前序遍历。缩进宽度由递归深度决定，根节」
- `curriculum/chapters/formatting_output.dart:101:159` · long-sentence · hard · 真实问题 · 命中「48 字」 · 散文「树形数据显示不仅要列出节点，还要把层级关系呈现出来。程序用名称到子节点列表的映射表示一棵小树，访问节点时先打印自己，再递归访问孩子，这就是前序遍历。缩进宽度由递归深度决定，根节」
- `curriculum/chapters/formatting_output.dart:101:169` · semicolon · hard · 真实问题 · 命中「；」 · 散文「树形数据显示不仅要列出节点，还要把层级关系呈现出来。程序用名称到子节点列表的映射表示一棵小树，访问节点时先打印自己，再递归访问孩子，这就是前序遍历。缩进宽度由递归深度决定，根节」
- `curriculum/chapters/formatting_output.dart:145:154` · synonym-rotation · hard · 待人工确认 · 命中「执行」 · 散文「进度条的格数和百分比来自同一份完成量，但两者的取整策略可以不同。程序先要求总量为正，再把完成量裁剪到零和总量之间，防止负数或重复回调造成超出边框。格数用整除向下取整，百分比使用」
- `curriculum/chapters/formatting_output.dart:145:157` · long-sentence · hard · 真实问题 · 命中「54 字」 · 散文「进度条的格数和百分比来自同一份完成量，但两者的取整策略可以不同。程序先要求总量为正，再把完成量裁剪到零和总量之间，防止负数或重复回调造成超出边框。格数用整除向下取整，百分比使用」
- `curriculum/chapters/formatting_output.dart:145:180` · semicolon · hard · 真实问题 · 命中「；」 · 散文「进度条的格数和百分比来自同一份完成量，但两者的取整策略可以不同。程序先要求总量为正，再把完成量裁剪到零和总量之间，防止负数或重复回调造成超出边框。格数用整除向下取整，百分比使用」
- `curriculum/chapters/formatting_output.dart:189:42` · long-sentence · hard · 真实问题 · 命中「59 字」 · 散文「按固定位置切字符串可能把一个单词拆开，因此本例采用逐词贪心折行。程序先把连续空白归一化为单词序列，再尝试将下一个单词接到当前行；如果候选长度超过宽度且当前行不为空，就先提交当前」
- `curriculum/chapters/formatting_output.dart:189:73` · semicolon · hard · 真实问题 · 命中「；」 · 散文「按固定位置切字符串可能把一个单词拆开，因此本例采用逐词贪心折行。程序先把连续空白归一化为单词序列，再尝试将下一个单词接到当前行；如果候选长度超过宽度且当前行不为空，就先提交当前」
- `curriculum/chapters/formatting_output.dart:189:180` · semicolon · hard · 真实问题 · 命中「；」 · 散文「按固定位置切字符串可能把一个单词拆开，因此本例采用逐词贪心折行。程序先把连续空白归一化为单词序列，再尝试将下一个单词接到当前行；如果候选长度超过宽度且当前行不为空，就先提交当前」
- `curriculum/chapters/formatting_output.dart:246:145` · long-sentence · hard · 真实问题 · 命中「62 字」 · 散文「文本框的边框应该由内容决定，而不是依靠人工数横线。程序先扫描所有行，得到最大长度，再生成上下边框，并把每行补到相同内宽。左右各留一格空白，使文字不会紧贴竖线。示例包含标题和较短」
- `curriculum/chapters/formatting_output.dart:246:172` · semicolon · hard · 真实问题 · 命中「；」 · 散文「文本框的边框应该由内容决定，而不是依靠人工数横线。程序先扫描所有行，得到最大长度，再生成上下边框，并把每行补到相同内宽。左右各留一格空白，使文字不会紧贴竖线。示例包含标题和较短」
- `curriculum/chapters/formatting_output.dart:289:157` · long-sentence · hard · 真实问题 · 命中「61 字」 · 散文「配置摘要既要便于阅读，也要避免无意打印敏感字段。程序先把键名复制出来排序，计算最长键名的宽度，再按键名逐行输出值。显示层针对名称为 token 的字段使用遮盖文本，原始配置值保」
- `curriculum/chapters/formatting_output.dart:289:181` · semicolon · hard · 真实问题 · 命中「；」 · 散文「配置摘要既要便于阅读，也要避免无意打印敏感字段。程序先把键名复制出来排序，计算最长键名的宽度，再按键名逐行输出值。显示层针对名称为 token 的字段使用遮盖文本，原始配置值保」
- `curriculum/chapters/formatting_output.dart:332:142` · passive-voice · advisory · 多为真实，需人工确认 · 命中「被错误套用标题」 · 散文「一个小型文本渲染器应先声明支持的语法，而不是把少量替换包装成完整 Markdown。程序逐行识别井号加空格开头的一级标题、短横线加空格开头的列表项，其余行原样保留。标题转成大写」
- `curriculum/chapters/formatting_output.dart:336:39` · passive-voice · advisory · 多为真实，需人工确认 · 命中「被误认标题」 · 散文「startsWith 的前缀必须包含空格，否则 #tag 也会被误认标题。」
- `curriculum/chapters/formatting_output.dart:387:60` · vague-word · advisory · 真实问题 · 命中「必要时」 · 散文「CSV 不能简单地把字段用逗号连接，因为字段本身可能包含逗号、双引号或换行。程序先检查这些特殊字符，必要时把字段放进双引号，并将内部每个双引号写成两个双引号。然后再连接已经转义」
- `curriculum/chapters/formatting_output.dart:387:102` · long-sentence · hard · 真实问题 · 命中「43 字」 · 散文「CSV 不能简单地把字段用逗号连接，因为字段本身可能包含逗号、双引号或换行。程序先检查这些特殊字符，必要时把字段放进双引号，并将内部每个双引号写成两个双引号。然后再连接已经转义」
- `curriculum/chapters/formatting_output.dart:387:149` · long-sentence · hard · 真实问题 · 命中「58 字」 · 散文「CSV 不能简单地把字段用逗号连接，因为字段本身可能包含逗号、双引号或换行。程序先检查这些特殊字符，必要时把字段放进双引号，并将内部每个双引号写成两个双引号。然后再连接已经转义」
- `curriculum/chapters/formatting_output.dart:387:176` · semicolon · hard · 真实问题 · 命中「；」 · 散文「CSV 不能简单地把字段用逗号连接，因为字段本身可能包含逗号、双引号或换行。程序先检查这些特殊字符，必要时把字段放进双引号，并将内部每个双引号写成两个双引号。然后再连接已经转义」
- `curriculum/chapters/formatting_output.dart:431:144` · long-sentence · hard · 真实问题 · 命中「65 字」 · 散文「千分位分隔符是一种展示规则，不应该污染用于计算的整数。程序先记录符号，对绝对值转换为十进制文本，再从右侧每次取三位加入分组列表。最后把分组反转后用逗号连接，并恢复负号。这个方向」
- `curriculum/chapters/formatting_output.dart:431:167` · semicolon · hard · 真实问题 · 命中「；」 · 散文「千分位分隔符是一种展示规则，不应该污染用于计算的整数。程序先记录符号，对绝对值转换为十进制文本，再从右侧每次取三位加入分组列表。最后把分组反转后用逗号连接，并恢复负号。这个方向」
- `curriculum/chapters/formatting_output.dart:478:68` · long-sentence · hard · 真实问题 · 命中「45 字」 · 散文「把一长串目录分成多栏时，要先决定阅读方向。本例按列从上到下填充，第一栏读完再读第二栏，因此索引是列号乘行数再加行号。程序先按条目总数和栏数向上取整得到行数，再分别计算每栏最长文」
- `curriculum/chapters/formatting_output.dart:478:162` · long-sentence · hard · 真实问题 · 命中「47 字」 · 散文「把一长串目录分成多栏时，要先决定阅读方向。本例按列从上到下填充，第一栏读完再读第二栏，因此索引是列号乘行数再加行号。程序先按条目总数和栏数向上取整得到行数，再分别计算每栏最长文」
- `curriculum/chapters/formatting_output.dart:478:178` · semicolon · hard · 真实问题 · 命中「；」 · 散文「把一长串目录分成多栏时，要先决定阅读方向。本例按列从上到下填充，第一栏读完再读第二栏，因此索引是列号乘行数再加行号。程序先按条目总数和栏数向上取整得到行数，再分别计算每栏最长文」
- `curriculum/chapters/async_patterns.dart:13:35` · passive-voice · advisory · 多为真实，需人工确认 · 命中「被等待的」 · 散文「异步函数遇到 await 时会把后续步骤挂起，直到被等待的 Future 完成，其他可运行工作仍可以继续。程序先启动一个带延迟的阶段，再在调用处记录已启动，最后等待该阶段完成。」
- `curriculum/chapters/async_patterns.dart:13:175` · long-sentence · hard · 真实问题 · 命中「48 字」 · 散文「异步函数遇到 await 时会把后续步骤挂起，直到被等待的 Future 完成，其他可运行工作仍可以继续。程序先启动一个带延迟的阶段，再在调用处记录已启动，最后等待该阶段完成。」
- `curriculum/chapters/async_patterns.dart:13:206` · semicolon · hard · 真实问题 · 命中「；」 · 散文「异步函数遇到 await 时会把后续步骤挂起，直到被等待的 Future 完成，其他可运行工作仍可以继续。程序先启动一个带延迟的阶段，再在调用处记录已启动，最后等待该阶段完成。」
- `curriculum/chapters/async_patterns.dart:14:21` · synonym-rotation · hard · 待人工确认 · 命中「执行」 · 散文「能从真实执行顺序理解 async 函数在第一个 await 前后的行为。」
- `curriculum/chapters/async_patterns.dart:61:128` · passive-voice · advisory · 多为真实，需人工确认 · 命中「被等待的链向上」 · 散文「数据流水线中的步骤往往存在依赖：没有解析结果就不能计算，没有计算结果就不能格式化。程序把三个阶段分别写成返回 Future 的函数，在 main 中逐步 await，并把得到的」
- `curriculum/chapters/async_patterns.dart:61:197` · long-sentence · hard · 真实问题 · 命中「42 字」 · 散文「数据流水线中的步骤往往存在依赖：没有解析结果就不能计算，没有计算结果就不能格式化。程序把三个阶段分别写成返回 Future 的函数，在 main 中逐步 await，并把得到的」
- `curriculum/chapters/async_patterns.dart:61:215` · semicolon · hard · 真实问题 · 命中「；」 · 散文「数据流水线中的步骤往往存在依赖：没有解析结果就不能计算，没有计算结果就不能格式化。程序把三个阶段分别写成返回 Future 的函数，在 main 中逐步 await，并把得到的」
- `curriculum/chapters/async_patterns.dart:88:24` · synonym-rotation · hard · 待人工确认 · 命中「校验」 · 散文「增加数量非负校验，让无效数据在计算阶段之前失败。」
- `curriculum/chapters/async_patterns.dart:120:26` · compound-aspect · advisory · 酌情保留 · 命中「已经改变了」 · 散文「把所有读取先启动再逐个 await，已经改变了启动顺序。」
- `curriculum/chapters/async_patterns.dart:168:178` · long-sentence · hard · 真实问题 · 命中「49 字」 · 散文「一次启动所有异步任务可能占用过多资源，而完全串行又不能利用独立任务的等待时间。程序把任务编号分成大小为二的批次，在批内构造多个 Future 并用 Future.wait 等待」
- `curriculum/chapters/async_patterns.dart:168:213` · semicolon · hard · 真实问题 · 命中「；」 · 散文「一次启动所有异步任务可能占用过多资源，而完全串行又不能利用独立任务的等待时间。程序把任务编号分成大小为二的批次，在批内构造多个 Future 并用 Future.wait 等待」
- `curriculum/chapters/async_patterns.dart:220:27` · synonym-rotation · hard · 待人工确认 · 命中「异常」 · 散文「异步异常 重试上限 rethrow」
- `curriculum/chapters/async_patterns.dart:222:192` · long-sentence · hard · 真实问题 · 命中「43 字」 · 散文「重试必须发生在真实失败之后，而不是用同步计数打印一串重试标签。程序的任务先经过异步等待，前两次实际抛出异常，第三次才返回成功。重试函数在 try 中 await 任务，catc」
- `curriculum/chapters/async_patterns.dart:222:215` · semicolon · hard · 真实问题 · 命中「；」 · 散文「重试必须发生在真实失败之后，而不是用同步计数打印一串重试标签。程序的任务先经过异步等待，前两次实际抛出异常，第三次才返回成功。重试函数在 try 中 await 任务，catc」
- `curriculum/chapters/async_patterns.dart:255:31` · semicolon · hard · 真实问题 · 命中「；」 · 散文「每次必须 await 真实任务；最后一次失败不要继续循环。」
- `curriculum/chapters/async_patterns.dart:282:122` · long-sentence · hard · 真实问题 · 命中「45 字」 · 散文「等待超时与任务取消是两件不同的事。程序启动一个真实延迟完成的操作，对它应用较短的 timeout，并捕获实际的 TimeoutException。随后再次等待原始 Future」
- `curriculum/chapters/async_patterns.dart:282:147` · semicolon · hard · 真实问题 · 命中「；」 · 散文「等待超时与任务取消是两件不同的事。程序启动一个真实延迟完成的操作，对它应用较短的 timeout，并捕获实际的 TimeoutException。随后再次等待原始 Future」
- `curriculum/chapters/async_patterns.dart:282:171` · long-sentence · hard · 真实问题 · 命中「41 字」 · 散文「等待超时与任务取消是两件不同的事。程序启动一个真实延迟完成的操作，对它应用较短的 timeout，并捕获实际的 TimeoutException。随后再次等待原始 Future」
- `curriculum/chapters/async_patterns.dart:330:10` · long-sentence · hard · 真实问题 · 命中「43 字」 · 散文「聚合函数可以把多个异步结果组织成稳定的数据结构，而不是让调用者猜列表中的每个位置代表什么。程序并发读取三个固定离线项目，等 Future.wait 全部完成后才求总和与最大值，」
- `curriculum/chapters/async_patterns.dart:330:55` · long-sentence · hard · 真实问题 · 命中「42 字」 · 散文「聚合函数可以把多个异步结果组织成稳定的数据结构，而不是让调用者猜列表中的每个位置代表什么。程序并发读取三个固定离线项目，等 Future.wait 全部完成后才求总和与最大值，」
- `curriculum/chapters/async_patterns.dart:330:143` · long-sentence · hard · 真实问题 · 命中「45 字」 · 散文「聚合函数可以把多个异步结果组织成稳定的数据结构，而不是让调用者猜列表中的每个位置代表什么。程序并发读取三个固定离线项目，等 Future.wait 全部完成后才求总和与最大值，」
- `curriculum/chapters/async_patterns.dart:330:146` · passive-voice · advisory · 多为真实，需人工确认 · 命中「被定义为」 · 散文「聚合函数可以把多个异步结果组织成稳定的数据结构，而不是让调用者猜列表中的每个位置代表什么。程序并发读取三个固定离线项目，等 Future.wait 全部完成后才求总和与最大值，」
- `curriculum/chapters/async_patterns.dart:330:181` · semicolon · hard · 真实问题 · 命中「；」 · 散文「聚合函数可以把多个异步结果组织成稳定的数据结构，而不是让调用者猜列表中的每个位置代表什么。程序并发读取三个固定离线项目，等 Future.wait 全部完成后才求总和与最大值，」
- `curriculum/chapters/async_patterns.dart:360:31` · synonym-rotation · hard · 待人工确认 · 命中「建立」 · 散文「初值用 null，读取第一项时建立真实最大值。」
- `curriculum/chapters/async_patterns.dart:384:77` · passive-voice · advisory · 多为真实，需人工确认 · 命中「被链自动展平」 · 散文「除了 async/await，Future.then 也能表达数据依赖。回调可以直接返回普通值，也可以返回另一个 Future，后者会被链自动展平，后续回调等待它完成。程序先取」
- `curriculum/chapters/async_patterns.dart:384:145` · passive-voice · advisory · 多为真实，需人工确认 · 命中「被」 · 散文「除了 async/await，Future.then 也能表达数据依赖。回调可以直接返回普通值，也可以返回另一个 Future，后者会被链自动展平，后续回调等待它完成。程序先取」
- `curriculum/chapters/async_patterns.dart:384:171` · long-sentence · hard · 真实问题 · 命中「48 字」 · 散文「除了 async/await，Future.then 也能表达数据依赖。回调可以直接返回普通值，也可以返回另一个 Future，后者会被链自动展平，后续回调等待它完成。程序先取」
- `curriculum/chapters/async_patterns.dart:384:203` · semicolon · hard · 真实问题 · 命中「；」 · 散文「除了 async/await，Future.then 也能表达数据依赖。回调可以直接返回普通值，也可以返回另一个 Future，后者会被链自动展平，后续回调等待它完成。程序先取」
- `curriculum/chapters/async_patterns.dart:426:110` · passive-voice · advisory · 多为真实，需人工确认 · 命中「被打印」 · 散文「降级逻辑应该针对明确的失败类型，而不是把所有异常都掩盖成成功。程序的本地数据提供器在 await 之后抛出自定义 DataUnavailable，包装函数只捕获这个领域异常并返」
- `curriculum/chapters/async_patterns.dart:426:148` · passive-voice · advisory · 多为真实，需人工确认 · 命中「被误当成普通不」 · 散文「降级逻辑应该针对明确的失败类型，而不是把所有异常都掩盖成成功。程序的本地数据提供器在 await 之后抛出自定义 DataUnavailable，包装函数只捕获这个领域异常并返」
- `curriculum/chapters/async_patterns.dart:426:179` · long-sentence · hard · 真实问题 · 命中「51 字」 · 散文「降级逻辑应该针对明确的失败类型，而不是把所有异常都掩盖成成功。程序的本地数据提供器在 await 之后抛出自定义 DataUnavailable，包装函数只捕获这个领域异常并返」
- `curriculum/chapters/async_patterns.dart:426:207` · semicolon · hard · 真实问题 · 命中「；」 · 散文「降级逻辑应该针对明确的失败类型，而不是把所有异常都掩盖成成功。程序的本地数据提供器在 await 之后抛出自定义 DataUnavailable，包装函数只捕获这个领域异常并返」
- `curriculum/chapters/async_patterns.dart:475:33` · long-sentence · hard · 真实问题 · 命中「41 字」 · 散文「并发任务共用一个可变的当前编号容易让日志串线。程序把 trace id 作为参数传入每个任务，任务内部建立独立日志列表，分别记录开始和完成，再随 Future 返回。main 」
- `curriculum/chapters/async_patterns.dart:475:151` · long-sentence · hard · 真实问题 · 命中「45 字」 · 散文「并发任务共用一个可变的当前编号容易让日志串线。程序把 trace id 作为参数传入每个任务，任务内部建立独立日志列表，分别记录开始和完成，再随 Future 返回。main 」
- `curriculum/chapters/async_patterns.dart:478:58` · synonym-rotation · hard · 待人工确认 · 命中「显示」 · 散文「全局 currentId 在并发任务间会相互覆盖。 汇总后的显示顺序不能当作真实完成时间线。」
- `curriculum/chapters/async_patterns.dart:522:176` · long-sentence · hard · 真实问题 · 命中「59 字」 · 散文「普通 Future 没有通用的强制取消方法，可以由任务主动在安全边界检查取消令牌。程序用 Completer 通知调用者任务已进入等待阶段，调用者收到通知后设置令牌，再等待任务」
- `curriculum/chapters/async_patterns.dart:522:208` · semicolon · hard · 真实问题 · 命中「；」 · 散文「普通 Future 没有通用的强制取消方法，可以由任务主动在安全边界检查取消令牌。程序用 Completer 通知调用者任务已进入等待阶段，调用者收到通知后设置令牌，再等待任务」
- `curriculum/chapters/apis_contracts.dart:9:17` · synonym-rotation · hard · 待人工确认 · 命中「校验」 · 散文「可组合的校验规则链」
- `curriculum/chapters/apis_contracts.dart:10:18` · synonym-rotation · hard · 待人工确认 · 命中「保存」 · 散文「把规则保存为函数列表，按顺序执行并在首次失败时停止。」
- `curriculum/chapters/apis_contracts.dart:10:29` · synonym-rotation · hard · 待人工确认 · 命中「执行」 · 散文「把规则保存为函数列表，按顺序执行并在首次失败时停止。」
- `curriculum/chapters/apis_contracts.dart:13:179` · long-sentence · hard · 真实问题 · 命中「52 字」 · 散文「校验逻辑常常由多个独立条件组成，写成一大段条件表达式会让错误原因难以定位。程序把每条规则定义为接收字符串、返回可空错误消息的函数，null 表示通过。校验器按列表顺序调用，遇到」
- `curriculum/chapters/apis_contracts.dart:13:196` · semicolon · hard · 真实问题 · 命中「；」 · 散文「校验逻辑常常由多个独立条件组成，写成一大段条件表达式会让错误原因难以定位。程序把每条规则定义为接收字符串、返回可空错误消息的函数，null 表示通过。校验器按列表顺序调用，遇到」
- `curriculum/chapters/apis_contracts.dart:13:205` · synonym-rotation · hard · 待人工确认 · 命中「显示」 · 散文「校验逻辑常常由多个独立条件组成，写成一大段条件表达式会让错误原因难以定位。程序把每条规则定义为接收字符串、返回可空错误消息的函数，null 表示通过。校验器按列表顺序调用，遇到」
- `curriculum/chapters/apis_contracts.dart:60:37` · long-sentence · hard · 真实问题 · 命中「41 字」 · 散文「资料表单里的必填、文本长度和数值范围是不同种类的约束。程序分别读取姓名和年龄文本，姓名先 trim 再检查长度，年龄先尝试解析，解析成功后才判断合法范围。这样“不是数字”和“数」
- `curriculum/chapters/apis_contracts.dart:60:104` · passive-voice · advisory · 多为真实，需人工确认 · 命中「被混成同一个问」 · 散文「资料表单里的必填、文本长度和数值范围是不同种类的约束。程序分别读取姓名和年龄文本，姓名先 trim 再检查长度，年龄先尝试解析，解析成功后才判断合法范围。这样“不是数字”和“数」
- `curriculum/chapters/apis_contracts.dart:60:171` · long-sentence · hard · 真实问题 · 命中「48 字」 · 散文「资料表单里的必填、文本长度和数值范围是不同种类的约束。程序分别读取姓名和年龄文本，姓名先 trim 再检查长度，年龄先尝试解析，解析成功后才判断合法范围。这样“不是数字”和“数」
- `curriculum/chapters/apis_contracts.dart:60:192` · semicolon · hard · 真实问题 · 命中「；」 · 散文「资料表单里的必填、文本长度和数值范围是不同种类的约束。程序分别读取姓名和年龄文本，姓名先 trim 再检查长度，年龄先尝试解析，解析成功后才判断合法范围。这样“不是数字”和“数」
- `curriculum/chapters/apis_contracts.dart:111:117` · passive-voice · advisory · 多为真实，需人工确认 · 命中「被发现」 · 散文「批量导入时逐条修完一个错误再重新运行会很低效，聚合校验可以一次收集全部问题。程序对每条商品记录分别检查编号和数量，把行号、字段名、原因组成明确消息后加入列表。它不会因为第一条记」
- `curriculum/chapters/apis_contracts.dart:111:153` · long-sentence · hard · 真实问题 · 命中「66 字」 · 散文「批量导入时逐条修完一个错误再重新运行会很低效，聚合校验可以一次收集全部问题。程序对每条商品记录分别检查编号和数量，把行号、字段名、原因组成明确消息后加入列表。它不会因为第一条记」
- `curriculum/chapters/apis_contracts.dart:111:175` · semicolon · hard · 真实问题 · 命中「；」 · 散文「批量导入时逐条修完一个错误再重新运行会很低效，聚合校验可以一次收集全部问题。程序对每条商品记录分别检查编号和数量，把行号、字段名、原因组成明确消息后加入列表。它不会因为第一条记」
- `curriculum/chapters/apis_contracts.dart:114:36` · synonym-rotation · hard · 待人工确认 · 命中「创建」 · 散文「错误集合要在整批开始时创建，不能每行重新覆盖。 聚合错误不等于自动跳过坏记录并继续写入。」
- `curriculum/chapters/apis_contracts.dart:160:32` · long-sentence · hard · 真实问题 · 命中「50 字」 · 散文「版本号不是普通小数，也不能按整段字符串排序。程序只接受主版本、次版本、修订号三段非负整数，先用完整正则验证格式，再把每一段解析成整数，按从左到右的顺序比较。找到第一处不同时即可」
- `curriculum/chapters/apis_contracts.dart:160:139` · long-sentence · hard · 真实问题 · 命中「69 字」 · 散文「版本号不是普通小数，也不能按整段字符串排序。程序只接受主版本、次版本、修订号三段非负整数，先用完整正则验证格式，再把每一段解析成整数，按从左到右的顺序比较。找到第一处不同时即可」
- `curriculum/chapters/apis_contracts.dart:160:174` · semicolon · hard · 真实问题 · 命中「；」 · 散文「版本号不是普通小数，也不能按整段字符串排序。程序只接受主版本、次版本、修订号三段非负整数，先用完整正则验证格式，再把每一段解析成整数，按从左到右的顺序比较。找到第一处不同时即可」
- `curriculum/chapters/apis_contracts.dart:214:36` · long-sentence · hard · 真实问题 · 命中「62 字」 · 散文「依赖范围可以理解为包含最低版本、排除某个上界的区间。程序限定输入为完整三段数字，caret 在主版本非零时允许到下一个主版本之前，主版本为零时把边界收紧到首个非零段；tilde」
- `curriculum/chapters/apis_contracts.dart:214:92` · semicolon · hard · 真实问题 · 命中「；」 · 散文「依赖范围可以理解为包含最低版本、排除某个上界的区间。程序限定输入为完整三段数字，caret 在主版本非零时允许到下一个主版本之前，主版本为零时把边界收紧到首个非零段；tilde」
- `curriculum/chapters/apis_contracts.dart:214:133` · passive-voice · advisory · 多为真实，需人工确认 · 命中「被排除」 · 散文「依赖范围可以理解为包含最低版本、排除某个上界的区间。程序限定输入为完整三段数字，caret 在主版本非零时允许到下一个主版本之前，主版本为零时把边界收紧到首个非零段；tilde」
- `curriculum/chapters/apis_contracts.dart:266:35` · synonym-rotation · hard · 待人工确认 · 命中「报错」 · 散文「复制默认值后应用合法覆盖项，对未知键立即报错。」
- `curriculum/chapters/apis_contracts.dart:269:38` · synonym-rotation · hard · 待人工确认 · 命中「更改」 · 散文「配置覆盖不仅是把两张 Map 展开，还要决定哪些字段允许更改。程序先复制默认配置，然后逐项检查覆盖键是否存在于默认表，未知键直接抛出格式错误，以便尽早发现拼写失误。合法字段才会」
- `curriculum/chapters/apis_contracts.dart:269:41` · long-sentence · hard · 真实问题 · 命中「47 字」 · 散文「配置覆盖不仅是把两张 Map 展开，还要决定哪些字段允许更改。程序先复制默认配置，然后逐项检查覆盖键是否存在于默认表，未知键直接抛出格式错误，以便尽早发现拼写失误。合法字段才会」
- `curriculum/chapters/apis_contracts.dart:269:142` · long-sentence · hard · 真实问题 · 命中「42 字」 · 散文「配置覆盖不仅是把两张 Map 展开，还要决定哪些字段允许更改。程序先复制默认配置，然后逐项检查覆盖键是否存在于默认表，未知键直接抛出格式错误，以便尽早发现拼写失误。合法字段才会」
- `curriculum/chapters/apis_contracts.dart:269:159` · semicolon · hard · 真实问题 · 命中「；」 · 散文「配置覆盖不仅是把两张 Map 展开，还要决定哪些字段允许更改。程序先复制默认配置，然后逐项检查覆盖键是否存在于默认表，未知键直接抛出格式错误，以便尽早发现拼写失误。合法字段才会」
- `curriculum/chapters/apis_contracts.dart:317:43` · long-sentence · hard · 真实问题 · 命中「41 字」 · 散文「限流逻辑不必依赖真实等待才能测试，可以把当前时间作为显式参数传入。程序用毫秒时间戳整除窗口长度得到窗口编号，每个窗口最多允许两次请求，只在允许时增加计数。示例输入跨越两个窗口，」
- `curriculum/chapters/apis_contracts.dart:317:110` · passive-voice · advisory · 多为真实，需人工确认 · 命中「被拒绝」 · 散文「限流逻辑不必依赖真实等待才能测试，可以把当前时间作为显式参数传入。程序用毫秒时间戳整除窗口长度得到窗口编号，每个窗口最多允许两次请求，只在允许时增加计数。示例输入跨越两个窗口，」
- `curriculum/chapters/apis_contracts.dart:317:152` · long-sentence · hard · 真实问题 · 命中「68 字」 · 散文「限流逻辑不必依赖真实等待才能测试，可以把当前时间作为显式参数传入。程序用毫秒时间戳整除窗口长度得到窗口编号，每个窗口最多允许两次请求，只在允许时增加计数。示例输入跨越两个窗口，」
- `curriculum/chapters/apis_contracts.dart:317:181` · semicolon · hard · 真实问题 · 命中「；」 · 散文「限流逻辑不必依赖真实等待才能测试，可以把当前时间作为显式参数传入。程序用毫秒时间戳整除窗口长度得到窗口编号，每个窗口最多允许两次请求，只在允许时增加计数。示例输入跨越两个窗口，」
- `curriculum/chapters/apis_contracts.dart:320:28` · passive-voice · advisory · 多为真实，需人工确认 · 命中「被拒绝请求也算」 · 散文「不要把被拒绝请求也算成成功消费额度，除非契约如此规定。 窗口编号是时间除以窗口长度，不是请求序号。」
- `curriculum/chapters/apis_contracts.dart:372:37` · long-sentence · hard · 真实问题 · 命中「67 字」 · 散文「令牌桶允许在积累额度后短时突发，又按固定速率补充额度。程序从满桶开始，根据当前时间与上次补充时间的差求出完整周期，只补充完整周期对应的令牌，并把记录时间推进这些周期，因此不足一」
- `curriculum/chapters/apis_contracts.dart:372:198` · semicolon · hard · 真实问题 · 命中「；」 · 散文「令牌桶允许在积累额度后短时突发，又按固定速率补充额度。程序从满桶开始，根据当前时间与上次补充时间的差求出完整周期，只补充完整周期对应的令牌，并把记录时间推进这些周期，因此不足一」
- `curriculum/chapters/apis_contracts.dart:404:10` · long-sentence · hard · 真实问题 · 命中「41 字」 · 散文「0:true 剩余1\n0:true 剩余0\n50:false 剩余0\n100:true 剩余0\n100:false 剩余0\n350:true 剩余1\n350:tru」
- `curriculum/chapters/apis_contracts.dart:436:68` · long-sentence · hard · 真实问题 · 命中「44 字」 · 散文「接口一致不仅指方法名字相同，还要求可观察行为遵守同一契约。程序定义简单整数存储接口，分别用 Map 和平行列表实现。统一检查函数验证缺失键返回 null、写入后可读、同名键覆盖」
- `curriculum/chapters/apis_contracts.dart:436:190` · long-sentence · hard · 真实问题 · 命中「44 字」 · 散文「接口一致不仅指方法名字相同，还要求可观察行为遵守同一契约。程序定义简单整数存储接口，分别用 Map 和平行列表实现。统一检查函数验证缺失键返回 null、写入后可读、同名键覆盖」
- `curriculum/chapters/apis_contracts.dart:441:17` · passive-voice · advisory · 多为真实，需人工确认 · 命中「被关闭」 · 散文「assert 可能被关闭，关键契约检查不能仅依赖它。」
- `curriculum/chapters/apis_contracts.dart:494:102` · passive-voice · advisory · 多为真实，需人工确认 · 命中「被偷偷修成零岁」 · 散文「数据迁移应先验证旧记录，再生成新结构，不能仅改字段名就假定数据可用。程序读取旧的姓名和年龄文本，清理姓名并解析年龄，通过后创建带 schemaVersion 的新 Map。无效」
- `curriculum/chapters/apis_contracts.dart:494:143` · synonym-rotation · hard · 待人工确认 · 命中「核对」 · 散文「数据迁移应先验证旧记录，再生成新结构，不能仅改字段名就假定数据可用。程序读取旧的姓名和年龄文本，清理姓名并解析年龄，通过后创建带 schemaVersion 的新 Map。无效」
- `curriculum/chapters/apis_contracts.dart:494:158` · passive-voice · advisory · 多为真实，需人工确认 · 命中「被修改」 · 散文「数据迁移应先验证旧记录，再生成新结构，不能仅改字段名就假定数据可用。程序读取旧的姓名和年龄文本，清理姓名并解析年龄，通过后创建带 schemaVersion 的新 Map。无效」
- `curriculum/chapters/apis_contracts.dart:494:177` · long-sentence · hard · 真实问题 · 命中「51 字」 · 散文「数据迁移应先验证旧记录，再生成新结构，不能仅改字段名就假定数据可用。程序读取旧的姓名和年龄文本，清理姓名并解析年龄，通过后创建带 schemaVersion 的新 Map。无效」
- `curriculum/chapters/apis_contracts.dart:494:194` · semicolon · hard · 真实问题 · 命中「；」 · 散文「数据迁移应先验证旧记录，再生成新结构，不能仅改字段名就假定数据可用。程序读取旧的姓名和年龄文本，清理姓名并解析年龄，通过后创建带 schemaVersion 的新 Map。无效」
- `curriculum/chapters/apis_contracts.dart:519:32` · passive-voice · advisory · 多为真实，需人工确认 · 命中「被拒绝记录的原」 · 散文「增加年龄上限一百三十，并报告被拒绝记录的原始行号。」
- `curriculum/chapters/apis_contracts.dart:543:48` · long-sentence · hard · 真实问题 · 命中「55 字」 · 散文「接口升级期间可能同时遇到旧字段 name 和新字段 displayName。程序接受任意一种形式，先验证存在字段的类型，再处理两者同时出现的情况：若清理后值不同就抛出冲突错误，」
- `curriculum/chapters/apis_contracts.dart:543:179` · semicolon · hard · 真实问题 · 命中「；」 · 散文「接口升级期间可能同时遇到旧字段 name 和新字段 displayName。程序接受任意一种形式，先验证存在字段的类型，再处理两者同时出现的情况：若清理后值不同就抛出冲突错误，」
- `curriculum/chapters/mini_apps.dart:10:35` · synonym-rotation · hard · 待人工确认 · 命中「核对」 · 散文「录入整数分流水，计算分类净额和总余额，并核对流水守恒。」
- `curriculum/chapters/mini_apps.dart:13:157` · long-sentence · hard · 真实问题 · 命中「62 字」 · 散文「综合记账程序需要同时维护输入规则、分类统计和余额关系。示例把每条流水表示为分类与分单位变动，收入为正、支出为负，不经过浮点金额。处理时逐条输出余额，同时为每个分类累计净额，最后」
- `curriculum/chapters/mini_apps.dart:13:180` · semicolon · hard · 真实问题 · 命中「；」 · 散文「综合记账程序需要同时维护输入规则、分类统计和余额关系。示例把每条流水表示为分类与分单位变动，收入为正、支出为负，不经过浮点金额。处理时逐条输出余额，同时为每个分类累计净额，最后」
- `curriculum/chapters/mini_apps.dart:13:206` · synonym-rotation · hard · 待人工确认 · 命中「存储」 · 散文「综合记账程序需要同时维护输入规则、分类统计和余额关系。示例把每条流水表示为分类与分单位变动，收入为正、支出为负，不经过浮点金额。处理时逐条输出余额，同时为每个分类累计净额，最后」
- `curriculum/chapters/mini_apps.dart:14:29` · synonym-rotation · hard · 待人工确认 · 命中「校验」 · 散文「能将流水、分类汇总和余额校验组合成完整的小型账本。」
- `curriculum/chapters/mini_apps.dart:44:10` · long-sentence · hard · 真实问题 · 命中「45 字」 · 散文「流水1 余额5000.00\n流水2 余额4975.00\n流水3 余额4969.00\n流水4 余额4951.00\nsalary:5000.00\nfood:-43.00\」
- `curriculum/chapters/mini_apps.dart:70:105` · synonym-rotation · hard · 待人工确认 · 命中「执行」 · 散文「库存程序不能只把入库和出库分别打印出来，还必须保护不能出现负库存的不变量。示例把变更集中在 Inventory.change 中，先计算候选库存，验证通过后才写回，拒绝时保持原」
- `curriculum/chapters/mini_apps.dart:70:176` · semicolon · hard · 真实问题 · 命中「；」 · 散文「库存程序不能只把入库和出库分别打印出来，还必须保护不能出现负库存的不变量。示例把变更集中在 Inventory.change 中，先计算候选库存，验证通过后才写回，拒绝时保持原」
- `curriculum/chapters/mini_apps.dart:127:127` · synonym-rotation · hard · 待人工确认 · 命中「显示」 · 散文「成绩单把多条规则组合在一起：分数降序、同分按姓名排序、同分共享名次，并统计等级分布。程序先排序条目，再根据前一人的分数决定是否更新名次，形成一、二、二、四这种竞赛排名。等级函数」
- `curriculum/chapters/mini_apps.dart:127:160` · long-sentence · hard · 真实问题 · 命中「47 字」 · 散文「成绩单把多条规则组合在一起：分数降序、同分按姓名排序、同分共享名次，并统计等级分布。程序先排序条目，再根据前一人的分数决定是否更新名次，形成一、二、二、四这种竞赛排名。等级函数」
- `curriculum/chapters/mini_apps.dart:127:186` · semicolon · hard · 真实问题 · 命中「；」 · 散文「成绩单把多条规则组合在一起：分数降序、同分按姓名排序、同分共享名次，并统计等级分布。程序先排序条目，再根据前一人的分数决定是否更新名次，形成一、二、二、四这种竞赛排名。等级函数」
- `curriculum/chapters/mini_apps.dart:184:42` · long-sentence · hard · 真实问题 · 命中「41 字」 · 散文「词频报告不仅是把单词计数，还应说明清洗规则与报告覆盖了多少原文。程序先转小写，再用只识别英文字母的正则提取词，累计频次后按次数降序、同次数按字母顺序排序。输出前三项，并把这几项」
- `curriculum/chapters/mini_apps.dart:184:146` · long-sentence · hard · 真实问题 · 命中「46 字」 · 散文「词频报告不仅是把单词计数，还应说明清洗规则与报告覆盖了多少原文。程序先转小写，再用只识别英文字母的正则提取词，累计频次后按次数降序、同次数按字母顺序排序。输出前三项，并把这几项」
- `curriculum/chapters/mini_apps.dart:184:176` · passive-voice · advisory · 多为真实，需人工确认 · 命中「被拆分」 · 散文「词频报告不仅是把单词计数，还应说明清洗规则与报告覆盖了多少原文。程序先转小写，再用只识别英文字母的正则提取词，累计频次后按次数降序、同次数按字母顺序排序。输出前三项，并把这几项」
- `curriculum/chapters/mini_apps.dart:236:142` · semicolon · hard · 真实问题 · 命中「；」 · 散文「迷宫寻路把二维格子看成图：可通行相邻格子之间有一条等长边。程序用队列进行广度优先搜索，第一次发现某格子时记录它的前驱，防止重复入队。到达终点后沿前驱反向走回起点，再把结果反转成」
- `curriculum/chapters/mini_apps.dart:307:49` · long-sentence · hard · 真实问题 · 命中「49 字」 · 散文「表达式求值需要先区分数字、运算符和括号，再按优先级执行，不能简单从左到右相加。程序先提取词元并核对是否覆盖全部非空白输入，拒绝未知字符；随后用数值栈保存操作数，用符号栈保存待计」
- `curriculum/chapters/mini_apps.dart:307:77` · semicolon · hard · 真实问题 · 命中「；」 · 散文「表达式求值需要先区分数字、运算符和括号，再按优先级执行，不能简单从左到右相加。程序先提取词元并核对是否覆盖全部非空白输入，拒绝未知字符；随后用数值栈保存操作数，用符号栈保存待计」
- `curriculum/chapters/mini_apps.dart:371:50` · passive-voice · advisory · 多为真实，需人工确认 · 命中「被拒绝」 · 散文「单独实现词法覆盖检查，验证 2+3 合法而 2/3 和 a+1 被拒绝。」

## 附录 B：复现

机械首查（会大量误报，仅作首查）：

```powershell
python scripts/ste-lint-zh.py --json `
  curriculum/chapters/numbers_strings.dart curriculum/chapters/text_processing.dart `
  curriculum/chapters/algorithms_basic.dart curriculum/chapters/algorithms_advanced.dart `
  curriculum/chapters/data_structures.dart curriculum/chapters/math_stats.dart `
  curriculum/chapters/oop_modeling.dart curriculum/chapters/enum_states.dart `
  curriculum/chapters/errors_resilience.dart curriculum/chapters/json_modeling.dart `
  curriculum/chapters/dates_money.dart curriculum/chapters/collection_reporting.dart `
  curriculum/chapters/formatting_output.dart curriculum/chapters/async_patterns.dart `
  curriculum/chapters/apis_contracts.dart curriculum/chapters/mini_apps.dart
```

散文范围（导入同一 linter，屏蔽 code/answer/output，保留行号）：

```python
import importlib.util, re, sys
spec = importlib.util.spec_from_file_location("ste", "scripts/ste-lint-zh.py")
ste = importlib.util.module_from_spec(spec); sys.modules["ste"] = ste
spec.loader.exec_module(ste)
PROSE = ("title","summary","concepts","explain","objective","prerequisites",
         "pitfalls","exampleTitle","exampleSummary","prompt","hint")

def reconstruct(path):
    lines = open(path, encoding="utf-8").read().split("\n")
    out = []; in_raw = False
    for line in lines:
        if in_raw:
            out.append(" " * len(line))
            if "'''" in line: in_raw = False
            continue
        if re.match(r"^\s*(code|answer)\s*:", line) and "'''" in line:
            in_raw = True; out.append(" " * len(line)); continue
        if re.match(r"^\s*output\s*:", line):
            out.append(" " * len(line)); continue
        n = len(line); res = [" "] * n; i = 0
        while i < n:
            ch = line[i]
            if ch in "\"'":
                q = ch; j = i + 1
                while j < n and line[j] != q:
                    if line[j] == "\\": j += 2; continue
                    j += 1
                for k in range(i + 1, min(j, n)): res[k] = line[k]
                i = j + 1
            else: i += 1
        out.append("".join(res))
    return "\n".join(out)

for p in [ ...16 files... ]:
    for f in ste.analyze(reconstruct(p), p, ste.Options()):
        print(f"{p}:{f.line}:{f.col} {f.rule} {f.match}")
```
