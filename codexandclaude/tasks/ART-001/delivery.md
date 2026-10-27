# ART-001 交付记录：风格说明与素材规格

状态：第1轮审查 R1 已修复（`aba620b`），待复审｜实现：Claude｜日期：2026-10-27

## 固定对象

- 基线：master `9bed956bd6ebbe3ba35692fcb6810a6666e28439`（PLN-003 合入后）。
- 实现提交：`eed3d2f263603b6fdabfb063c2f204bbd657216a`（分支 `claude/ART-001`）。本记录与任务卡首部状态另行提交，不改实现文件。
- 过程：`985f6da` 定 `CREDITS.md` 格式（已发 Codex 对齐 ENV-008）→ `7f52736`、`21ec754` 草稿 → 用户在单独会话中逐项讨论，`21ec754..bc9022e` 共 35 个提交，`bc9022e` 用户定稿 → `eed3d2f` 补入设定文件。每个提交前都跑过 G3。

## 用户定稿

`game/docs/art_style.md` 首部：“已定稿（2026-10-27，用户确认）”，用户原话“风格定稿。”。讨论中每一轮的修改与用户原话都记在 `art_style.md`（32 行）与 `asset_spec.md`（15 行）的变更记录里，这里不重复。与起草时相比的主要变化：

| 方面 | 起草时 | 定稿 |
| --- | --- | --- |
| 敌人方向 | 墨块、单色强调、天人金饰的简单区分 | 推翻草稿与“后室”方向，按用户的世界观设定 `Words/怪物设定.md` 重建框架（第 6.1 节）：同化 = 压缩、逐级去人化；颜色即身份（《雨世界》）；生前物件说明身份（《丝之歌》）；无色、单色各留一处人的遗存；实体共用一套视觉语言，脸一律是纸色面甲 |
| 阶层 | — | 依据 `Words/阶层设定.md`（第 6.0 节）：天人 > 匠首 > 齿仆 > 工畜；面甲是实体的标志 |
| 比例与气质 | 写实比例 | 所有人形 2.5 头身、可爱；敌人造型按《丝之歌》（硬壳、面甲、细尖腿、角、披布） |
| 玩家 | 纸色衣物 + 红围巾 + 短刀 | **匠首**：深银连帽长斗篷、深蓝工装、黑纱覆面透两点萤石光、玫瑰金扣镶紫水晶；去掉红围巾，生命红不再用于角色；识别锚点为**萤环**（十三枚碎片绕腕）与初始武器**晶弦**（散合：前摇聚合、后摇散回，只改外观不改玩法） |
| 天人战士 | 墨色加金饰 | 高冠、立领、及地黑袍、直角金纹、黑曜石甲片；金色微笑面具 + 额心红宝石（重击前摇亮朱红）；黑袍下摆化墨，低血量面具崩角 |
| Boss | 悬空巨眼；口与触须 | 渴望俯视 = 住在皮鞋里的飞虫、随高低变脸；寄生同伴者 = 人与虫两个前半身拼接 |
| 场景 | 三区主色 | 三区主色调整（田野暖灰天空 + 夕阳金线，逆时战场只在天顶留暗红褐），每区一处“暗室的痕迹”（荒地天顶渗墨、田野纸剪夕阳、逆时战场时间倒流），背景按日褪色（第 1 日原色 → 第 3 日接近单色，只作用于背景层） |
| 光 | 左侧暖色边光 | 保留；边光随意识递减：人与天人完整、单色减半、无色没有 |

## 改动

| 文件 | 内容 |
| --- | --- |
| `game/docs/art_style.md`（新增） | 风格说明：线条、上色、光、色板（与 `DuskStyle` 一致，另加角色专用色）、阶层与比例、敌人设计框架、各角色、萤环与晶弦、场景与暗室的痕迹、日褪色、音频风格、不做什么、变更记录 |
| `game/docs/asset_spec.md`（新增） | 尺寸（2 倍交付、0.5 显示；玩家受击胶囊 96 px 与物理胶囊 88 px 分列，PLN-003 审查建议）、目录与命名、骨骼与部件、场景、音频格式与响度、生成与一致性、收件箱、导入设置 |
| `game/assets/CREDITS.md`（新增） | 登记范围、七列与填写规则、空表（现有素材行由 ENV-008 补） |
| `game/tools/art_style_sheet.gd`（新增，非运行路径） | 绘制三张样张：`style_sheet.png`（总览）、`style_sheet_bosses.png`（两场 Boss）、`style_sheet_close_up.png`（特写） |
| `codexandclaude/tasks/ART-001/prompts/` | 模板与 01～08（含 06b 探索稿）：玩家、荒地背景、无色实体、两场 Boss、晶弦概念、金缮散合探索、晶弦切割原图、天人战士；每条附验收要点 |
| `Words/怪物设定.md`、`Words/阶层设定.md`（新增） | 用户写的世界观设定，`art_style.md` 第 6.0、6.1 节以它们为依据；原样从主工作区复制入库（逐字节相同） |
| `Words/T6_素材来源与规格决定.md` | 只追加变更记录行（规格起点定为正式数值的去向） |
| `.gitignore` | 加 `/assets_src/`（收件箱不入库，用户同意；任务卡把它列给 ENV-008，提前加入，ENV-008 只需核对） |
| `tests/test_art_spec.py`（新增） | 16 项，见“测试” |

## 逐条对照任务卡

1. **风格说明**：第 2～9 节齐全；三张代码样张已交用户对照。
2. **素材规格**：素材决定记录第 3、4 节与音频规格的每一项都有数值或做法；调整处回写了决定记录的变更记录。
3. **收件箱与登记**：`assets_src/inbox/<art|audio>/<对象或区域>/`，整体不入库；`CREDITS.md` 格式已发 Codex（ENV-008 开工前对齐）。
4. **提示词**：模板与玩家第一批（及素材决定记录第 7 节要求的荒地背景、无色实体），另有 Boss、武器、天人。已认可的试做图在 `assets_src/inbox/art/`（不入库）：WSST_04/05、BOSS_01/01_1/01_2、BOSS_02_2、player_01_3、weapon_player_03/04/06、blade_whole_02、tian_02、tian_02_broken。
5. **用户定稿**：见上。

## 超出任务卡“允许修改的文件”的部分（请审查确认）

- `.gitignore`、`Words/怪物设定.md`、`Words/阶层设定.md`：理由见改动表。主工作区（master 检出）仍有这两份设定文件的未跟踪副本，本分支合入后应删除副本（内容相同），否则检出可能报“未跟踪文件会被覆盖”。
- 样张从一张增为三张，提示词从三组增为九组：随讨论扩展，均在任务目录内。

## 留给后续任务（不在本卡）

- ART-002：晶弦切割工具（`blade_whole_02` → 13 片）；玩家待机与跑动。
- 特效任务：萤环 / 晶弦光缝闪亮、天人红宝石发光、暗室痕迹的动态部分、日褪色着色器。
- 接入任务：天人面具切换（低血量崩角）、渴望俯视变脸、寄生同伴者朝向；FX-002 渴望俯视出招“眼”的位置随新造型调整。
- 尚无 AI 试做图：单色实体、田野 / 逆时战场的无色变体、田野与逆时战场背景。

## 测试

`tests/test_art_spec.py` 16/0：定稿状态；色板与 `DuskStyle` 一致；比例按 T6-E 与 2 倍交付；胶囊名称与高度与 `player.tscn` 一致；收件箱被忽略、`CREDITS.md` 列与 NC/ND 禁令；每条提示词带风格块与验收要点；敌人形象要点；敌人框架；2.5 头身；Boss 提示词；玩家为匠首；金缮探索稿；晶弦切割原图；天人战士；区域暗室痕迹与褪色；无色实体提示词。

变异（各改一处，在项目副本中跑本套件，结果 `codexandclaude/runs/art001-mutations.json`，不入库）：

| 变异 | 结果 |
| --- | --- |
| 色板墨色与 `DuskStyle` 不一致 | 失败 |
| 去掉定稿状态 | 失败 |
| Boss 显示高度偏离 T6-E | 失败 |
| 受击胶囊写成 88 px | 失败 |
| 收件箱不再被忽略 | 失败 |
| `CREDITS.md` 去掉 NC/ND 禁令 | 失败 |
| 玩家提示词丢失风格块 | 失败 |
| 玩家提示词加回红围巾 | 失败 |

## 全量检查（实现提交上）

<!-- run_checks evidence v1 -->
总结果：**通过**；模式：`full`。
被测SHA：`eed3d2f263603b6fdabfb063c2f204bbd657216a`；工作区：`D:\31days\codexandclaude\worktrees\claude`。
工作区状态：**干净**。
开始：2026-10-27T07:55:53.659338+00:00；结束：2026-10-27T08:07:39.129149+00:00。

入口命令（JSON参数数组）：`["C:\\Users\\Administrator\\AppData\\Local\\Programs\\Python\\Python310\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\claude\\codexandclaude\\tools\\run_checks.py", "full", "--jobs", "4"]`。
检查（缺项均不通过；env只代表环境探测，不代表G2/G3）：
- G2：实际99 / 预期99；完整=True；通过=True。
- G3:tests：实际128 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。
- G3:codexandclaude/tests：实际67 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。

工具版本：
- godot：`4.7.2.stable.official.ed1daf0bf`；`D:\DMyself\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`。
- python：`3.12.14 / openpyxl=3.1.5`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe`。
- git：`git version 2.56.0.windows.2`；`C:\Program Files\Git\ucrt64\bin\git.exe`。
- node：`v24.22.1`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe`。

提交树：`4f9097b528fa92455e1c57b61ee22138dc22f100`；指纹范围：`['exclude codexandclaude/runs/**', 'exclude codexandclaude/tasks/<ID>/{delivery,review,integration,acceptance}.md']`。
已提交范围指纹：`05d70d988245ab7a0a51f9aa4e135bad104e41aa76cd195f9411e0f882511a6e`；工作区范围指纹（原始字节）：`b2bad59af741981591cefbfee711f7d561d3e11ca99c30860ce10e3f01727c49`。
全工作区指纹：`3cb2b1ce701a44d149125161812a874948caa4a25d8377a296b6a23d2c84f01e`；运行前后内容稳定：`True`。
内容身份说明：起止快照不一致时，检查结果照实保留，但该运行不可作为复用来源；不是对运行期间每次瞬时写入的监控。
已跟踪总diff SHA256：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；未暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。

实际命令与日志（参数为JSON数组）：
- `["C:\\Program Files\\Git\\ucrt64\\bin\\git.exe", "rev-parse", "HEAD"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261027T075553.659338Z\001.txt`；SHA256=`eade5f8e77186e205f7c0bc0e33d7f69ab0da2ab5ab4adf661b048d7b1d06080`。
- `["C:\\Program Files\\Git\\ucrt64\\bin\\git.exe", "status", "--porcelain", "--untracked-files=all"]`；退出=0；耗时=0.047秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261027T075553.659338Z\002.txt`；SHA256=`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。
- `["D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--version"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261027T075553.659338Z\003.txt`；SHA256=`bf8803022b574250bb04dea65053a46b7c58570725316c1f7fe2aa6735706498`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-c", "import sys,openpyxl; print(sys.version.split()[0]); print(\"openpyxl=\"+openpyxl.__version__)"]`；退出=0；耗时=0.297秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261027T075553.659338Z\004.txt`；SHA256=`6d8032bb36596789957df461b308076a9002b5585e5b4d43f8a62b51f0ac622b`。
- `["C:\\Program Files\\Git\\ucrt64\\bin\\git.exe", "--version"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261027T075553.659338Z\005.txt`；SHA256=`dc0a995f896e73e8fc394cc5dc4d8cabfea65b5eb2db4a40d134dc21c4feb3c0`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\node\\bin\\node.exe", "--version"]`；退出=0；耗时=0.015秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261027T075553.659338Z\006.txt`；SHA256=`b8a527ca60b496131eccd1fcbeccf289ebc0a7e63be57e4b4c6f8f67648bcc07`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\claude\\scripts\\verify_game.py", "--godot", "D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--project", "D:\\31days\\codexandclaude\\worktrees\\claude\\game", "--report", "D:\\31days\\codexandclaude\\worktrees\\claude\\codexandclaude\\runs\\20261027T075553.659338Z\\engine.txt", "--jobs", "4"]`；退出=0；耗时=681.047秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261027T075553.659338Z\007.txt`；SHA256=`b35576a31e5be404729e2477de5d687ecb65c4742fbd5b25329f467b653f0716`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "tests", "-v"]`；退出=0；耗时=3.578秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261027T075553.659338Z\008.txt`；SHA256=`6cb00c35a02cfbe9eba85592cdd6611f435fe57acf3e238686d1046fe7e0362f`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "codexandclaude/tests", "-v"]`；退出=0；耗时=18.75秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261027T075553.659338Z\009.txt`；SHA256=`103cb5744f82bcc56a49361dbd136a82a40c10a384d91b1760c2578475be012f`。
- 报告 `D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261027T075553.659338Z\engine.txt` SHA256=`a4fab0372b2e80d594bafc92247c2f37edbfd4cd5dedcd2b92f79bbfd0fe6bb6`。

失败清单：无。
失败归因：未提供基线失败证据，不自动区分旧失败与新失败。
复用限制：只比较内容不替代审查/授权；须成功完整且干净、运行前后稳定、范围相同的来源；只改记录时G2可复用，G3必须重跑；另核对工具、命令和外部依赖。

## 第1轮审查修复（2026-10-27）

审查记录 [review.md](review.md)（Codex，`703a78b`，被审 `e2978c2`，已快进并入本分支）。R1 成立：任务卡要求的“部件拆分清单”没有交付。修复提交 `aba620b76b4af77c7ba2d2461f2207cece1454da`，只改提示词与测试，已定稿的风格与规格未动。

| 编号 | 问题 | 修复 | 回归 |
| --- | --- | --- | --- |
| R1 | 只有全身设定图提示词与通用骨骼树，没写清玩家的具体部件：斗篷与内衬怎样分图、面纱与头、兜帽与三段下摆对应哪些文件、哪些远侧肢体要补画 | 新增 `prompts/09_player_parts.md`，01 指向它：24 个部件逐行写**文件名、画面内容、挂接骨骼、层序、来源（从已认可设定图 `player_01_3` 切图 / 补画 / 两者）、遮挡与 15% 重叠**；斗篷分后片、内衬、前片与 `cloth_1…3` 下摆，兜帽分后半（挂 `hood`，在头后）与帽口（在面纱前），面纱单独成图挂 `head`（只画两点眼光，发光由特效做）；远侧六段肢体全部补画、同形压暗一档；不出图的骨骼（`root`、`spine`、`neck`、`weapon`、`ring`）写明原因；附补画用的部件提示词（含远侧说明句） | `test_player_parts_list_is_complete`：24 个文件名一个不多一个不少；每行骨骼正确且在 `asset_spec.md` 的骨骼树或附加骨骼内；层序连续，关键遮挡关系（远侧在身体后、兜帽在头后、头 < 面纱 < 帽口、后片 < 躯干 < 前片 < 近侧前臂）成立；来源只能是三种之一，被遮挡的部件必须补画；每行都有 15% 重叠说明；下摆骨骼链、远侧说明句、“萤环不画在手上”都在 |

编写测试时它先抓到清单本身的缺口：7 行写的是“同上”或没写重叠，已逐行写明。

变异（各改一处，在项目副本中跑本套件，结果 `codexandclaude/runs/art001-r1-mutations.json`，不入库）：

| 变异 | 结果 |
| --- | --- |
| 清单漏掉远侧手 | 失败 |
| 斗篷前片放到躯干后面 | 失败 |
| 面纱挂到 `hood` 骨骼 | 失败 |
| 远侧上臂标为切图 | 失败 |
| 近侧手去掉重叠说明 | 失败 |
| 01 不再指向清单 | 失败 |
| `hip` 改名为 `pelvis` | 失败 |

`tests/test_art_spec.py` 16 → **17/0**。修复只改 Markdown 与 Python 测试，按检查矩阵跑 G3（修复提交上）：

<!-- run_checks evidence v1 -->
总结果：**通过**；模式：`focused`。
被测SHA：`aba620b76b4af77c7ba2d2461f2207cece1454da`；工作区：`D:\31days\codexandclaude\worktrees\claude`。
工作区状态：**干净**。
开始：2026-10-27T08:35:24.857973+00:00；结束：2026-10-27T08:35:49.468455+00:00。

入口命令（JSON参数数组）：`["C:\\Users\\Administrator\\AppData\\Local\\Programs\\Python\\Python310\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\claude\\codexandclaude\\tools\\run_checks.py", "focused", "--python-all"]`。
检查（缺项均不通过；env只代表环境探测，不代表G2/G3）：
- G3:tests：实际129 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。
- G3:codexandclaude/tests：实际67 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。

工具版本：
- python：`3.12.14 / openpyxl=3.1.5`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe`。
- git：`git version 2.56.0.windows.2`；`C:\Program Files\Git\ucrt64\bin\git.exe`。
- node：`v24.22.1`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe`。

提交树：`8c1b31a2f5a94c3cf2c2969a1ef50058d1e461a8`；指纹范围：`['exclude codexandclaude/runs/**', 'exclude codexandclaude/tasks/<ID>/{delivery,review,integration,acceptance}.md']`。
已提交范围指纹：`2210d83f5896c0a223dd87138770829ca659165bba470876830988e002bda5ac`；工作区范围指纹（原始字节）：`3971afef0b037ae4ee46f7889bf471b65fe3354d9696f3f7bcc9fba558443120`。
全工作区指纹：`4860a442fcff0c505a6dd5e5353c91ce1af7982e6c4217db32b5e77e2c6fb04f`；运行前后内容稳定：`True`。
内容身份说明：起止快照不一致时，检查结果照实保留，但该运行不可作为复用来源；不是对运行期间每次瞬时写入的监控。
已跟踪总diff SHA256：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；未暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。

实际命令与日志（参数为JSON数组）：
- `["C:\\Program Files\\Git\\ucrt64\\bin\\git.exe", "rev-parse", "HEAD"]`；退出=0；耗时=0.047秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261027T083524.856973Z\001.txt`；SHA256=`847d01735cf149784cc311ed5f35b85a5ee5427ef349103a4f944d2935b13396`。
- `["C:\\Program Files\\Git\\ucrt64\\bin\\git.exe", "status", "--porcelain", "--untracked-files=all"]`；退出=0；耗时=0.047秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261027T083524.856973Z\002.txt`；SHA256=`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-c", "import sys,openpyxl; print(sys.version.split()[0]); print(\"openpyxl=\"+openpyxl.__version__)"]`；退出=0；耗时=0.359秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261027T083524.856973Z\003.txt`；SHA256=`6d8032bb36596789957df461b308076a9002b5585e5b4d43f8a62b51f0ac622b`。
- `["C:\\Program Files\\Git\\ucrt64\\bin\\git.exe", "--version"]`；退出=0；耗时=0.047秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261027T083524.856973Z\004.txt`；SHA256=`dc0a995f896e73e8fc394cc5dc4d8cabfea65b5eb2db4a40d134dc21c4feb3c0`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\node\\bin\\node.exe", "--version"]`；退出=0；耗时=0.032秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261027T083524.856973Z\005.txt`；SHA256=`b8a527ca60b496131eccd1fcbeccf289ebc0a7e63be57e4b4c6f8f67648bcc07`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "tests", "-v"]`；退出=0；耗时=3.343秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261027T083524.856973Z\006.txt`；SHA256=`23f36350090003ba72875eae20a4fed586136abf4777442042ae574eadfe7a2a`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "codexandclaude/tests", "-v"]`；退出=0；耗时=19.078秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261027T083524.856973Z\007.txt`；SHA256=`597642d2d5aa3c3c76a54c5b3ed23a624d4889d422bd95d8cd2d5f9b0aee4739`。

失败清单：无。
失败归因：未提供基线失败证据，不自动区分旧失败与新失败。
复用限制：只比较内容不替代审查/授权；须成功完整且干净、运行前后稳定、范围相同的来源；只改记录时G2可复用，G3必须重跑；另核对工具、命令和外部依赖。
