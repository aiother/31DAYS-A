# ENV-006 交付记录

日期：2026-10-20（America/Los_Angeles；UTC为2026-10-21）｜实现：Codex｜审查：Claude

## 基线与范围

- 用户批准第三批任务卡，并要求SYS-005合入后开工、随后继续ENV-006。初始基线 `01188d7f3bc1b21a8b8eefbd1f53b26a874b8dfe`；UI-001集成后，用固定master `c11d88045b0833d01a80c2d67df0ab5ae476f636` 更新分支（合并提交1633695）。当前基线与UI-002开工基线一致。
- 分支 `codex/ENV-006`；实现SHA `d7a450bdf7e06e4f51fc8e9cfbb711cd5ff80a1d`。包含79b0e64的行尾规则/回归、固定master更新和共用启动器实现。本交付提交仅新增本记录、更新任务卡首部状态。
- 新增game/tests/acceptance/acceptance_harness.gd、completed_slots.gd、run_acceptance.gd及各.uid；新增game/tests/test_acceptance_launcher.gd及.uid，首行按ENV-004登记；修改test_completed_slots.gd的验收分派；新增codexandclaude/tests/test_import_line_endings.py；修改.gitattributes、env.md、任务卡首部。
- 未改游戏规则、计时、输入映射、存档格式、正式UI、SYS-002入口或验证器。UI-002适配由UI-002自己编写。未改run_checks.py或摘要字段，稳定性按原有原始字节判定，不修改或忽略摘要结果。

## 共用入口与适配

```powershell
Godot --path game --script res://tests/acceptance/run_acceptance.gd
Godot --headless --path game --script res://tests/acceptance/run_acceptance.gd -- --self-test
Godot --path game --script res://tests/acceptance/run_acceptance.gd -- --self-test --capture
# 旧入口仍兼容
Godot --headless --path game --script res://tests/test_completed_slots.gd -- --acceptance-smoke
```

默认SYS-004已通关槽适配；其他任务继承acceptance_harness.gd，通过`--adapter=res://...`选择，提供configuration里的会话场景、真实槽快照与检查点、是否直接进入、说明文字，按需覆盖status_fields及self_test。基类提供目录、参数、面板、实际鼠标点击、截图、退出清理。完整字段与参数说明见env.md通用G4小节。

- 每进程在OS缓存新建唯一31days_acceptance目录；scene.ready前设置save_directory，核对store.directory后才写槽。恢复场景时沿用原有checkpoint_reload里的目录，不读写玩家正式槽。
- SYS-004夹具先保存余额2的备份，再保存余额3的主档；两者均有END，继续后逐字节不变，并可确认新游戏正常开始。
- 面板只读当前日、余额、生命，可用--no-panel关闭。真实SceneTree输入、物理帧、现有时钟不变，没有手动推进生成器或玩法时钟。
- 截图是有渲染的真实Viewport图像，默认忽略目录runs/SYS-004-g4/的slots/blocked/new-game.png；headless请求截图会明确失败，不伪造图像。
- 正常关闭窗口走统一finish；退出树有清理兜底。清理只针对本进程生成的缓存平面槽目录，截图保留在输出目录。

## 完成标准与专项

| 标准 | 自测证据 |
| --- | --- |
| 目录、参数、重定向、可选面板、截图 | 新登记套件ACCEPTANCE_LAUNCHER_TESTS 11/11；内部SYS-004适配16/16、自动进入另一槽/检查点适配11/11；参数含非法槽/未知参数检查；有渲染截图22/22 |
| SYS-004迁移行为 | 普通套件仍73/73；最终旧无头验收命令16/16（原9项的等价检查加目录、主档/备份等额外断言）；截图22/22（原12项的等价检查加通用检查）。已查看blocked与new-game图，实际菜单提示及新游戏均正常 |
| 原测试逻辑不变 | 对c11d880逐函数比较，只有run分派变动，移出acceptance/capture两个验收函数；其他普通测试函数文本不变。runs/env006-migration-proof.json |
| 清理真实退出路径 | 非自测模式发出真实close_requested，临时目录由存在变为不存在，finished=[0]。runs/env006-close-probe.txt |
| 全量 | 固定实现SHA、起止干净：G2 79/79，G3 102/102 + 67/67，content_stable=True，见自动证据 |

变异均临时修改后按原始字节恢复，并在最终全量再次验证正例：

| 变异 | 结果 |
| --- | --- |
| cleanup直接返回 | 新11项中4项失败，两个适配各1项清理失败，退出1；测试有独立清理兜底，不留残存夹具 |
| 不设置save_directory | 新11项中2项失败，两个适配各1项失败，退出1；在场景ready及写夹具之前即被拦截，不碰正式存档 |

## BL-113：原始字节与Claude工作区

`.gitattributes`固定`*.import text eol=lf`，覆盖SVG及字体导入描述。新Python回归在真实临时Git仓库强制core.autocrlf=true，检出三个.import，核对与Godot的LF原始字节一致；旧规则先失败4处，新规则通过。Codex真实导入字节对比及最终full均稳定。

老工作区采用新规则后，需要按新属性一次性重新检出既有导入物；只改工作树属性而保留CRLF时，初次探针仍会漂移。必须先确认没有实质编辑，仅行尾差异，再对明确文件重新检出；必要时刷新索引，且暂存内容差异必须为空。不要手改summary.json。

供审查者在现有Claude工作区采用已提交新规则后使用（新工作区通常不需要）：

```powershell
git checkout-index --force -- game/assets/characters/player_placeholder.svg.import game/assets/environments/gray_tile.svg.import game/assets/fonts/LXGWWenKai-Regular.ttf.import game/prototypes/EXP-002/fonts/LXGWWenKai-Regular.ttf.import
git add --renormalize -- game/assets/characters/player_placeholder.svg.import game/assets/environments/gray_tile.svg.import game/assets/fonts/LXGWWenKai-Regular.ttf.import game/prototypes/EXP-002/fonts/LXGWWenKai-Regular.ttf.import
git diff --cached --stat
```

Claude工作区短暂对比：事先确认claude/UI-001@89687e8且干净；原检出运行editor import，原始字节不稳定；临时候选属性并按新检出应有的Git LF原文字节准备四份.import后，再运行同一导入，字节稳定。最后finally恢复原属性与所有原文件字节，验证分支、HEAD及Git状态与开始一致；未切换分支、未暂存改动，未占用其工作区跑full。记录runs/env006-claude-import-comparison.json与两份导入日志。

**待独立复现项**：上述Claude对比只是实际编辑器导入，不是Claude full。按任务卡完成标准3，请Claude审查时在自己的工作区固定交付，采用新规则后跑full，确认起止干净且content_stable=True；本记录没有把Codex full冒充Claude full。已保留Claude先前UI-001的原始不稳定full作为前测参考：

- 原始文件：D:/31days/codexandclaude/worktrees/claude/codexandclaude/runs/20261021T032000.123378Z/summary.json；SHA256 `ca5789d5a5d6cc091eccdfc91b7387d7ecb94e524f87085e6c0f054067eb8169`；被测SHA `ed02593025142a12adb8445d2fa95e39c19cbc47`；content_stable `False`。

## 最终full自动证据

<!-- run_checks evidence v1 -->
总结果：**通过**；模式：`full`。
被测SHA：`d7a450bdf7e06e4f51fc8e9cfbb711cd5ff80a1d`；工作区：`D:\31days\codexandclaude\worktrees\codex`。
工作区状态：**干净**。
开始：2026-10-21T04:21:21.575883+00:00；结束：2026-10-21T04:34:02.831147+00:00。

入口命令（JSON参数数组）：`["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\codex\\codexandclaude\\tools\\run_checks.py", "full", "--jobs", "4"]`。
检查（缺项均不通过；env只代表环境探测，不代表G2/G3）：
- G2：实际79 / 预期79；完整=True；通过=True。
- G3:tests：实际102 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。
- G3:codexandclaude/tests：实际67 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。

工具版本：
- godot：`4.7.2.stable.official.ed1daf0bf`；`D:\DMyself\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`。
- python：`3.12.14 / openpyxl=3.1.5`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe`。
- git：`git version 2.56.0.windows.2`；`C:\Program Files\Git\cmd\git.exe`。
- node：`v24.19.0`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe`。

提交树：`0c048fc41e2f40cbde2ae1772849dd7044ae36de`；指纹范围：`['exclude codexandclaude/runs/**', 'exclude codexandclaude/tasks/<ID>/{delivery,review,integration,acceptance}.md']`。
已提交范围指纹：`94f550ce9027a9c0a54be8a69ef9a248db7d9fb9a9de549a78cf9d98db03a0b0`；工作区范围指纹（原始字节）：`dfe9032837a31448cd66d8367b720359fc28ed9b332b771265510de98d1ca030`。
全工作区指纹：`a3233ba5e78d0231cefb9f795082013264b0283b007f81427531758b37be9bd9`；运行前后内容稳定：`True`。
内容身份说明：起止快照不一致时，检查结果照实保留，但该运行不可作为复用来源；不是对运行期间每次瞬时写入的监控。
已跟踪总diff SHA256：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；未暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。

实际命令与日志（参数为JSON数组）：
- `["C:\\Program Files\\Git\\cmd\\git.exe", "rev-parse", "HEAD"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261021T042121.575883Z\001.txt`；SHA256=`114f37eed96ffbedde79fba82a1da8fe3b8ecca1fea764eb671ff46b1bc5a6e2`。
- `["C:\\Program Files\\Git\\cmd\\git.exe", "status", "--porcelain", "--untracked-files=all"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261021T042121.575883Z\002.txt`；SHA256=`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。
- `["D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--version"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261021T042121.575883Z\003.txt`；SHA256=`bf8803022b574250bb04dea65053a46b7c58570725316c1f7fe2aa6735706498`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-c", "import sys,openpyxl; print(sys.version.split()[0]); print(\"openpyxl=\"+openpyxl.__version__)"]`；退出=0；耗时=0.344秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261021T042121.575883Z\004.txt`；SHA256=`6d8032bb36596789957df461b308076a9002b5585e5b4d43f8a62b51f0ac622b`。
- `["C:\\Program Files\\Git\\cmd\\git.exe", "--version"]`；退出=0；耗时=0.015秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261021T042121.575883Z\005.txt`；SHA256=`dc0a995f896e73e8fc394cc5dc4d8cabfea65b5eb2db4a40d134dc21c4feb3c0`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\node\\bin\\node.exe", "--version"]`；退出=0；耗时=0.016秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261021T042121.575883Z\006.txt`；SHA256=`bc697de995dc791df53d688ef69c08994cdffc8ce30c906b1ffc65b131ccd0eb`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\codex\\scripts\\verify_game.py", "--godot", "D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--project", "D:\\31days\\codexandclaude\\worktrees\\codex\\game", "--report", "D:\\31days\\codexandclaude\\worktrees\\codex\\codexandclaude\\runs\\20261021T042121.575883Z\\engine.txt", "--jobs", "4"]`；退出=0；耗时=745.563秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261021T042121.575883Z\007.txt`；SHA256=`4fd9363dcf113790c2550881693d757dca0ef651e0d0bf12a2636d3471cdf159`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "tests", "-v"]`；退出=0；耗时=3.328秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261021T042121.575883Z\008.txt`；SHA256=`4e4dc7bda532f7be951d2144b0a9ce84f823f4791bae56a06b46b117143b2aa3`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "codexandclaude/tests", "-v"]`；退出=0；耗时=10.797秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261021T042121.575883Z\009.txt`；SHA256=`7f9b9b917e3a9098cee240e8dd23f3b57043100fb2ead57b2ca8051dc2b40672`。
- 报告 `D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261021T042121.575883Z\engine.txt` SHA256=`1c8214348d9bce18896a029626b382cb44341007ee5de85e12d314a8931251dc`。

失败清单：无。
失败归因：未提供基线失败证据，不自动区分旧失败与新失败。
复用限制：只比较内容不替代审查/授权；须成功完整且干净、运行前后稳定、范围相同的来源；只改记录时G2可复用，G3必须重跑；另核对工具、命令和外部依赖。


## 原始日志身份

- runs/env006-final-g1.txt SHA256：`ca8bd50ca108ba3b00b6c09835249bc331cbccb524da1c5b1b6a3109683d1dd4`。
- runs/env006-final-legacy-smoke.txt SHA256：`e144a93cd63a493f136c8ec50b94076568171fab8138a70f859729a96336eb78`。
- runs/env006-completed-slots.txt SHA256：`cd3b068268715d856d8fac2b21be358cb8e3de6d40fc84432a51787fa9dc628d`。
- runs/env006-final-capture.txt SHA256：`64177d3adaf5c5ae93d5d43c9703cc3dbd4cd328f2c827581a40a3ecdabf4152`。
- runs/env006-mutations.json SHA256：`63a22ca2f4581e933d863dff557c9bfd1096f5b813a69d44897eb68c8a979630`。
- runs/env006-migration-proof.json SHA256：`e162cd40f7f906f3c7caf9e0c7d1a7c7f08ddb8eef5d1c0ba041a3b6ac5c86cc`。
- runs/env006-claude-import-comparison.json SHA256：`bdf075d42f757d77b0f9ba44f6ccbcbb380cca494d65d335120343a1cd175241`。
- runs/env006-close-probe.txt SHA256：`ad877b9ea7371fb5e7ea6d381f4969aedac5f87eba2ac0b0c7d550dab9e890f1`。
- runs/env006-import-red.txt SHA256：`3cb1125f5473af465d3920c7874d76359e24ad78f14fcfdfe5aae1e78469144a`。
- runs/env006-import-green.txt SHA256：`1ae707cc0f8a929fc493df8e9012665bac6068f145353a28b28e7ca1b7b581cc`。

## 审查与G4

请Claude固定交付，核对相对d7a450b只有本记录及任务卡状态，复现两项变异、核对普通测试未改并在Claude工作区独立跑完整G2+G3和稳定性。G4按卡可选：用户可用第一条命令再次点击已通关继续/新游戏，入口隔离临时存档。ENV-006尚未合入master；master仍为UI-001收尾c11d880。

## 交付记录G3

本记录和状态写入后重跑G3：102/102 + 67/67，完整且通过。被测HEAD仍为d7a450b，工作区未提交差异仅本记录与任务卡状态。摘要runs/20261021T043629.207859Z/summary.json，SHA256 `5777ead2dce122d8f0c98afc65c9f9939ace179da9b20d141514fe833c037453`。
