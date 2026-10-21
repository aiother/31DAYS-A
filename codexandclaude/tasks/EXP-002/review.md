# EXP-002 审查记录

日期：2026-10-20｜审查：Codex｜实现：Claude｜结论：**需修改**

- 固定交付SHA：`42ec8526365616d8eedfcb9530f70b35272eac57`，在Codex工作区用`git switch --detach`检出后审查。
- 实现SHA：`bb5be39730faab84e6e61218f5cbbad475bf62f9`；审查分支：codex/EXP-002-review，从交付SHA新建。
- master已快进到规划SHA `43e7dc2a5c8f9376b9b28db9053ebfddd6ed9c46`，它已是本交付的祖先。任务记录中“合入后再合并master”的描述可在下一次交付更新，无须制造空合并。

## 范围与批准依据

1. 实现到交付只新增delivery.md、修改task.md首部状态。排除EXP-002原型目录、协作测试及本任务目录后的基线到实现差异为空；EXP-001、正式游戏、project.godot、输入映射、存档及验证器均没有改动。
2. 以本轮用户消息提供的原话为批准依据：用户喜欢甲、丙并提出甲为基底加丙的质感与设计，同意“黄昏随末日临近渐入”，并允许“后面一起吧”。任务卡只调整样张方向、完成标准1和3，改为两种混合比例和逐日变化；仍保持既定布局与交互、仍在原型范围内。调整与批准一致，没有扩大为正式美术、正式界面或玩法规则。
3. style.gd固定生命/可能性/成长/透支/警示等语义色，逐日变化作用于氛围、光晕与底色。代码核对及14张已提交截图支持目前实现符合这项设计；但现有冒烟没有关键色不变的断言（见R2）。纸墨/黄昏两种比例及与T7的新增表现、字体尚待选择，README均有说明。
4. 已查看两个样张全部14张截图：徽记、地平线、透支与最后1点生命、暂停时钟、设置盖住时钟、对话框均可辨认。是否选某种比例、黄昏幅度或引入字体由用户G4决定。

## 阻断项

### R1（P2）：缺少“开战余时不足15分钟”的可操作入口

位置：game/prototypes/EXP-002/preview.gd的jump/press（尤其第88～95、109～135行）；任务卡“每个样张必须覆盖的画面”第2项。

`KEY_8 -> jump(4)`始终调用`state.start_final(25.0 * 60.0)`，完全覆盖用户此前调出的第3日余时。按键表没有另一条短余时入口，EXP-001原有P入口也未保留。HUD虽有`final_from <= FINAL_SECONDS`时显示“余时不足”的分支，但正常预览无法进入，因此不能在两个样张下挑选A-016短预算的警示表现。

独立探针向真实Viewport注入按键事件：按8得到final_from=1500、budget=900，按P仍为1500/900。用绘制文本探针核对：该状态只显示普通“最终战倒计时/15:00”；仅直接调用状态的`start_final(552.0)`才得到“最终战倒计时 · 余时不足/09:12”及朱红色。说明绘制分支存在，缺的是用户可达入口。

请在原型中提供明确的长/短预算切换入口并补说明；两个样张都应能通过入口直接显示真实短预算且没有长余时加速演出。回归测试应通过同一个输入入口验证这两种状态及实际显示文字/警示色，不能只在测试里直接改状态而绕开入口。

证据：忽略目录runs/exp002-review-probe.gd、exp002-review-probe.txt。探针继承HUD、记录其ink_text实际调用，未改被审实现。

### R2（P2）：冒烟没有遍历两个样张的全部画面，也没有拦住关键表现缺失

位置：game/prototypes/EXP-002/tests/smoke_test.gd第32～37行及hud_states/pause_menu/dialog_sample。

两个样张循环只执行dusk_rules和hud_states，暂停与对话框在循环结束后执行一次，此时固定为样张二。关键色不随天数变化没有断言；按钮测试覆盖normal/focus/pressed/disabled，未验证hover。最终战只断言状态为final_active且加速计时存在，没有检查画面输出或短预算分支。这不足以满足完成标准4“全部基调、全部画面与状态”，也与本轮交接所述“关键色不变、按钮各状态”的覆盖不符。

临时变异实测（逐项恢复原始字节）：

| 变异 | 原38项冒烟结果 | 判断 |
| --- | --- | --- |
| `_draw_final()`在final_active时直接return，移除全部最终倒计时绘制 | 38/38，退出0，无错误/警告 | 漏检 |
| 暂停视图`_draw()`在sample==0时直接return，移除样张一暂停画面 | 38/38，退出0，无错误/警告 | 漏检 |
| 可能性实际填充色随style.dusk(state)混向生命红色 | 38/38，退出0，无错误/警告 | 漏检关键色变化 |
| 将三个DAY_RANGE都改为0.5～0.5 | 38项中2项失败，退出1，两个逐日递增断言失败 | 正确拦截 |

请将暂停、二级页、对话框和按钮各状态放到每个样张内验证；补足语义色跨日期不变、长短最终预算实际呈现的断言。可用实际绘制消费的表现数据或绘制调用探针，不要求像素截图测试。至少应拦住上表三个漏检变异，并保持逐日变化的现有正向覆盖。不要以只读模拟状态的断言代替新视图是否输出内容的检查。

证据：runs/exp002-review-mutations.json及exp002-mutation-*.txt。变异只临时修改本审查工作区，全部按原字节还原；还原后冒烟与G3均再次通过。

## 非阻断建议

N1：tests/capture.gd以200个process_frame等待最终战演出结束，帧数不等于2.5秒真实时间。现有两张final_countdown截图均停在“时间加速……/22:0x”，未展示演出后的稳定倒计时。建议有上限地等待accelerate_left实际归零，再截图稳定状态；补R1时可另留短预算截图。这能让用户明确区分演出与真实剩余预算。

## 独立检查证据

被测交付SHA为上述42ec852；原型探索按任务卡运行冒烟、G3及引擎前两步，没有运行正式全量76套件。

| 检查 | 命令（在工作区根目录） | 结果 |
| --- | --- | --- |
| 编辑器导入 | Godot --headless --path game --editor --import --quit | 退出0，无ERROR/WARNING |
| 主场景180帧 | Godot --headless --path game --quit-after 180 | 退出0，无ERROR/WARNING |
| EXP-002冒烟及变异还原后复跑 | Godot --headless --path game --script res://prototypes/EXP-002/tests/smoke_test.gd | checks=38 failures=0 |
| EXP-001原有冒烟 | Godot --headless --path game --script res://prototypes/EXP-001/tests/smoke_test.gd | checks=105 failures=0 |
| G3及还原后复跑 | python codexandclaude/tools/run_checks.py focused --python-all | 102/102 + 47/47，complete=true、passed=true |

工具：Godot4.7.2.stable.official.ed1daf0bf；Python3.12.14/openpyxl3.1.5；Git2.56.0.windows.2；Nodev24.19.0。实际Godot为D:/DMyself下控制台版；Python为Codex bundled runtime。

首次G3的dirty=true仅含已知两份SVG.import生成物；确认差异仅换行后恢复，最终复跑20261020T144622.898100Z的SHA仍为交付SHA、dirty=false，两个目录计数完整。原始证据均在忽略的codexandclaude/runs：exp002-review-import.txt、exp002-review-main180.txt、exp002-review-smoke.txt、exp002-review-restored-smoke.txt、exp002-review-exp001-smoke.txt、20261020T144622.898100Z/summary.json及逐命令日志。没有新增正式源码或测试修改；本审查提交只新增review.md。

G4待用户挑选。请Claude先快进到本审查提交，再修订R1、R2，提交新的实现SHA和交付SHA后复审；非阻断N1可一并处理。master仍为规划SHA，未合并本原型。

日志身份：

- exp002-review-import.txt SHA256：`c1f7fc0f916e3d0ee4626c390b506537040ef3b1348072ff7042a4e3ca1731ae`。
- exp002-review-main180.txt SHA256：`83cf0b082206af2aa236c83064fbcfa76be1e00a4aa3558574b2f65965d9481c`。
- exp002-review-smoke.txt SHA256：`eadd40d67dfd20001d97be74e8ed81d753eb81c840c4d314b00e5dc6c5186efb`。
- exp002-review-restored-smoke.txt SHA256：`eadd40d67dfd20001d97be74e8ed81d753eb81c840c4d314b00e5dc6c5186efb`。
- exp002-review-exp001-smoke.txt SHA256：`eb5ee4c71fde9eacf8af6a81913c564c208e61a7580a5b704d28fed38b4d8e68`。

## 第1轮修订复审（2026-10-20）

固定交付SHA：`10dd5ba89f7cae05ca1fffed959090e0b53e2ba9`；修订实现SHA：`35515ca686260706aac3b63ddd1560ef769508c6`。用git switch --detach固定后检查，再从该交付建立codex/EXP-002-review-r2。结论：**需修改，R1已解决，R2剩一项原有变异漏检**。

范围复核：修订实现到交付只改delivery.md和task.md状态；相对755c1b7的改动都在EXP-002原型目录，正式游戏及EXP-001差异为空。README与预览按键9说明同步；原型隔离测试未改。

### R1：已解决

按键9经真实Viewport输入探针得到final_from=552、final_remaining=552，实际ink_text调用为“最终战倒计时 · 余时不足”“09:12”，颜色b8382c；按键8仍为1500/900和加速演出。冒烟对两个样张分别覆盖长/短预算，去掉9入口导致4项失败。证据：runs/exp002-r2-probe.gd、exp002-r2-probe.txt。

### R2：大部分解决，仍需拦住上轮的逐日实际填充色变异（P2）

两个样张现在均运行HUD、暂停、设置、确认、时钟、对话框和按钮状态检查；最终倒计时等drawn记录在实际绘制路径产生。其余新增检查有效。独立变异结果与交付所列五项一致：去倒计时6项失败、去样张一暂停5项、改生命常量4项、去9入口4项、去时钟4项。

但上轮R2明确列出的第三种变异是“可能性实际填充色随style.dusk(state)向生命色混合”，并非仅更改一个基础色常量。修订后`drawn["palette"]`仍在最终颜色计算之前记录Style.POSSIBILITY；测试只核对这个基础字典。将实际填充表达式改成以下形式，字典未变、画面却随日期变红，69项仍全部通过（退出0，无ERROR/WARNING）：

```gdscript
# hud_view.gd中RING的实际填充色，唯一临时变异：
Color(palette["possibility"]).lerp(Style.LIFE, style.dusk(state)).lerp(Style.POSSIBILITY_GLOW, pulse * 0.6).lerp(palette["deny"], flash * 0.6)
```

请对实际传给_arc的语义填充色补一个独立回归：固定正常余额、gain_pulse=0、deny_left=0，比较第1日/第3日/最终战及两个样张，确保实际填充色保持README中的可能性颜色。可在_arc调用处记录最终颜色，或使用绘制调用探针；需要验证实际消耗的颜色，不能只在混色前保存调色板。该变异应失败，其余已有69项保持通过。此处没有发现未变异代码当前随日期变色；问题是上轮明确要求的同一回归仍漏检，不增加新的设计范围。

证据：runs/exp002-r2-mutations.json；exp002-r2-mutation-same_day_varying_fill_as_r1_review.txt为69/69。所有变异按原始字节还原。

### N1：已处理

已查看两个样张重拍的稳定长预算和新增短预算截图：分别为普通倒计时14:58和朱红“余时不足/09:12”。截图等待accelerate_left归零、有600帧保护上限，当前交付截图符合预期。

### 本轮独立证据

- Godot --headless --path game --editor --import --quit：退出0，无ERROR/WARNING。
- Godot --headless --path game --quit-after 180：退出0，无ERROR/WARNING。
- Godot --headless --path game --script res://prototypes/EXP-002/tests/smoke_test.gd：69/69；EXP-001同类命令仍105/105。
- python codexandclaude/tools/run_checks.py focused --python-all：102/102 + 47/47，complete=true、passed=true；原始汇总runs/20261020T150521.182728Z/summary.json，被测SHA为10dd5ba、dirty=false。工具版本与首轮相同（Godot4.7.2、Python3.12.14/openpyxl3.1.5、Git2.56.0、Nodev24.19.0）。
- 原始日志：runs/exp002-r2-import.txt、exp002-r2-main180.txt、exp002-r2-smoke.txt、exp002-r2-exp001-smoke.txt；变异结果另存上述JSON。已确认仅换行的SVG.import按env.md恢复，没有保留源码、测试或生成物改动。本复审提交只更新review.md。

请Claude快进至本复审提交后只补R2剩余颜色回归，再交新的实现与交付SHA复审。G4仍由用户挑选；未合并master。


## 第2轮修订复审（2026-10-20）

固定交付 SHA：`6e37f73580b5269f845ab355b97ffa3852910361`；修订实现 SHA：`f09cdb7e90643f513c262b923a13b7492290694e`。已用 git switch --detach 固定交付，再从该交付建立 codex/EXP-002-review-r3。结论：**通过，无阻断项，R2 剩余问题已解决**。此前 R1、N1 的通过结论保持有效。

### 范围与用户选定后的增量

- f09cdb7 到交付只改 delivery.md 与任务卡状态；合并复审记录的 ffc0822 到 f09cdb7 只改 hud_view.gd 和 smoke_test.gd。
- 从规划基线 43e7dc2 到修订实现，排除 EXP-002 原型目录、协作测试及本任务记录后差异为空；正式游戏与 EXP-001 没有改动。普通合并 ffc0822 保留了 3c2da53 的复审记录和此前用户选定后的光晕、字体提交，没有绕过复审。
- 交付记录保存用户原话“用样张2的样式，随天数变化和手写字体保留，最终战时的黄昏光晕可以适当的缩减30%左右的强度”，并记录用户随后批准下载指定字体。这些授权足以覆盖本轮原型内的选择与接入；原任务卡不下载外部字体的约束已有该明确授权补充。
- FINAL_GLOW_SCALE=0.7 仅在最终战降低光晕，未改变纸色、玻璃与边缘渐变；两个样张均有同黄昏程度下 70% 的断言。字体由 style.font() 提供，J 可切回内置字体；HUD、暂停、对话框、按钮、标题均使用该入口。原型字体文件 25,928,940 字节，SHA256 为 `2D73EEA94AD808999D90C0000C239A84A33B09D4BC6AB6C5B8BBF1EDA8A7FC8B`，与 fonts/README.md 记录一致。没有把字体接入正式游戏。
- 人工查看样张二第3日 HUD、暂停时钟、最终战稳定倒计时与余时不足截图，手写字体、较弱光晕及 14:58 / 朱红 09:12 的表现与记录相符。用户已选定样张二，最新颜色记录修订不改变画面。

### R2：已解决及独立变异

现在在实际 _arc / draw_colored_polygon 调用处记录最终消费的可能性环、透支、生命碎片颜色；测试在两个样张、第1日、第3日、最终战逐一检查。固定 gain_pulse=0、deny_left=0 和正常余额，另以负余额检查透支，避免混色前调色板的断言掩盖实际颜色漂移。89 项同时保留长短预算、暂停二级页遮钟、对话框、按钮和字体切换的覆盖。

以下变异由审查者独立执行，每次恢复原始字节后再进行下一项；均退出 1：

| 变异 | 89 项中的失败数 |
| --- | --- |
| 可能性实际填充色随黄昏向生命色混合（上轮明确的漏检） | 6 |
| 生命实际填充色随黄昏漂移 | 6 |
| 去掉最终战倒计时绘制 | 6 |
| 去掉样张一暂停绘制 | 6 |
| 改生命关键色常量 | 10 |
| 去掉按键 9 入口 | 4 |
| 去掉时钟绘制 | 4 |

原始结果：runs/exp002-r3-mutations.json、exp002-r3-mutation-*.txt。全部恢复后冒烟再次 89/89。没有保留实现或测试修改；本审查提交只追加 review.md。

### 独立检查与证据来源

被测内容为固定交付 6e37f735，Godot 4.7.2.stable.official.ed1daf0bf；Python 3.12.14/openpyxl 3.1.5、Git 2.56.0、Node v24.19.0。

| 检查 | 结果 |
| --- | --- |
| Godot --headless --path game --editor --import --quit | 退出 0，无 ERROR/WARNING |
| Godot --headless --path game --quit-after 180 | 退出 0，无 ERROR/WARNING |
| Godot --headless --path game --script res://prototypes/EXP-002/tests/smoke_test.gd | 89/89，变异还原后复跑同样通过，无 ERROR/WARNING |
| Godot --headless --path game --script res://prototypes/EXP-001/tests/smoke_test.gd | 105/105，无 ERROR/WARNING |
| G3 focused --python-all | 102/102 + 47/47，complete=true、passed=true |

导入产生两个 SVG.import 和原型字体 .ttf.import 的换行差异；逐文件确认 ignore-space-at-eol 差异为空后恢复。最终 G3 在干净交付上运行，运行前后内容稳定。探索任务未运行正式全量 76 套件，符合本任务矩阵。

按用户允许，G3 使用刚合入 ENV-005 的外部验证入口：`D:/31days/codexandclaude/tools/run_checks.py`，其来源 master 为 `c5c520a3256b7c23f6b05a58e67045ee64f29b1f`；通过 `--root D:/31days/codexandclaude/worktrees/codex` 验证固定 EXP-002 内容，未将 ENV-005 代码移入被审分支。因此被审目录协作测试仍为 47 项，而 master 为 64 项。未将 ENV-005 的全量摘要复用于这个不同内容的原型分支；本轮 G3 是独立重跑。

以下为新工具自动生成的干净 G3 evidence.md 原文（时间为 UTC，对应本地 2026-10-20）：

<!-- run_checks evidence v1 -->
总结果：**通过**；模式：`focused`。
被测SHA：`6e37f73580b5269f845ab355b97ffa3852910361`；工作区：`D:\31days\codexandclaude\worktrees\codex`。
工作区状态：**干净**。
开始：2026-10-21T01:10:00.074840+00:00；结束：2026-10-21T01:10:05.195065+00:00。

入口命令（JSON参数数组）：`["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\codexandclaude\\tools\\run_checks.py", "focused", "--python-all", "--root", "D:/31days/codexandclaude/worktrees/codex"]`。
检查（缺项均不通过；env只代表环境探测，不代表G2/G3）：
- G3:tests：实际102 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。
- G3:codexandclaude/tests：实际47 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。

工具版本：
- python：`3.12.14 / openpyxl=3.1.5`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe`。
- git：`git version 2.56.0.windows.2`；`C:\Program Files\Git\cmd\git.exe`。
- node：`v24.19.0`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe`。

提交树：`2429731ed6b82aacfa36014d89486d8d6ed9979a`；指纹范围：`['exclude codexandclaude/runs/**', 'exclude codexandclaude/tasks/<ID>/{delivery,review,integration,acceptance}.md']`。
已提交范围指纹：`7617cd02460cca48ea45ed3f0feb2a927d82753b95a71d9206e2bfdc443f9fc1`；工作区范围指纹（原始字节）：`7bf838df462dcbd14129510d6559ca16d4fa8142a7f058c59cdac792976908eb`。
全工作区指纹：`a17ad1b3032d753eb9afbbd914ab18e26f2b477383b73a14ecb7d80f46deca79`；运行前后内容稳定：`True`。
内容身份说明：起止快照不一致时，检查结果照实保留，但该运行不可作为复用来源；不是对运行期间每次瞬时写入的监控。
已跟踪总diff SHA256：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；未暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。

实际命令与日志（参数为JSON数组）：
- `["C:\\Program Files\\Git\\cmd\\git.exe", "rev-parse", "HEAD"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261021T011000.074840Z\001.txt`；SHA256=`8add5cb38ddd5791914ce0319f4c141b6a82b3bb09c9e104dae9d1a2f93d0c63`。
- `["C:\\Program Files\\Git\\cmd\\git.exe", "status", "--porcelain", "--untracked-files=all"]`；退出=0；耗时=0.016秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261021T011000.074840Z\002.txt`；SHA256=`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-c", "import sys,openpyxl; print(sys.version.split()[0]); print(\"openpyxl=\"+openpyxl.__version__)"]`；退出=0；耗时=0.297秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261021T011000.074840Z\003.txt`；SHA256=`6d8032bb36596789957df461b308076a9002b5585e5b4d43f8a62b51f0ac622b`。
- `["C:\\Program Files\\Git\\cmd\\git.exe", "--version"]`；退出=0；耗时=0.015秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261021T011000.074840Z\004.txt`；SHA256=`dc0a995f896e73e8fc394cc5dc4d8cabfea65b5eb2db4a40d134dc21c4feb3c0`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\node\\bin\\node.exe", "--version"]`；退出=0；耗时=0.016秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261021T011000.074840Z\005.txt`；SHA256=`bc697de995dc791df53d688ef69c08994cdffc8ce30c906b1ffc65b131ccd0eb`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "tests", "-v"]`；退出=0；耗时=3.453秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261021T011000.074840Z\006.txt`；SHA256=`b298add8051cbb3fa74d201687c814eaae7d5e28d078f2f68e2253a3b079967b`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "codexandclaude/tests", "-v"]`；退出=0；耗时=0.25秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261021T011000.074840Z\007.txt`；SHA256=`16faa02c17d56d743db610cdcd02f8d3b4e9604404abdd1fa006b102d39584a6`。

失败清单：无。
失败归因：未提供基线失败证据，不自动区分旧失败与新失败。
复用限制：只比较内容不替代审查/授权；须成功完整且干净、运行前后稳定、范围相同的来源；只改记录时G2可复用，G3必须重跑；另核对工具、命令和外部依赖。


引擎与变异日志身份（均在忽略的 codexandclaude/runs/）：

- exp002-r3-import.txt SHA256：`8a93a6a259bc1cfbb3b8336ed4a40049037bfd887be54da0fb36355f001dc27e`。
- exp002-r3-main180.txt SHA256：`83cf0b082206af2aa236c83064fbcfa76be1e00a4aa3558574b2f65965d9481c`。
- exp002-r3-exp001.txt SHA256：`eb5ee4c71fde9eacf8af6a81913c564c208e61a7580a5b704d28fed38b4d8e68`。
- exp002-r3-restored-smoke.txt SHA256：`986c29ee0b022a626e46cdc479f1d1c8a3270a337c0bbcb68f9a7f4d78380bf6`。
- exp002-r3-mutations.json SHA256：`da5a12b68c55ffb51158b172946549be27527edb71708f232e7c4ea4cd132004`。

本轮没有新增非阻断建议。EXP-002 尚未合并 master；请用户授权后按固定审查 SHA 集成。
