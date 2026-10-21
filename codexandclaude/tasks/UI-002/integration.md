# UI-002 集成记录

日期：2026-10-21（America/Los_Angeles）｜集成及补充审查：Codex。

## 授权与固定合入

- 用户原话：“测试完成了，没问题”；“同意合入 UI-002”。本轮明确要求合入固定 `7202580eace21c1fd541e8e9c8e6fb579141aef8`。
- 合并前master：`9fa942db75158dfb9f65d9822871b0d7743f3be5`；执行 `git merge --no-ff -m "Merge UI-002 accepted HUD 7202580" 7202580eace21c1fd541e8e9c8e6fb579141aef8`，无冲突。
- 合并SHA：**`853d9bd0b38f26e1f1bdb89e448fafad5292178e`**。没有合并可移动分支名；SYS-006尚未合入本次被测内容，后续单独合入并单独验证。
- 主目录有用户未提交的game/project.godot修改，与本次目标无文件重叠。未暂存、提交、还原或覆盖它；合并前后原始字节相同：11110字节，SHA256 `8246aab2ebfa4f7445c53e79d918f81943137fca37d75c36bed57e5855f77aa5`。证据在主目录runs/ui002-integration-preservation.json。

## 追加验收适配的补充审查

既有HUD/会话代码与已通过的7889615相同（含第3轮审查3009c4b）；新增仅ENV-006合并、验收适配ui002_hud.gd、新登记套件test_hud_acceptance.gd及说明/记录。

已审适配的真实快照、临时目录隔离、场景重载、只读面板位置与长短预算路径：使用ENV-006基类，在ready前重定向存档、通过真实FinalBattleSession/Room进入战斗；不手动推进计时；适配自测临时设置day_remaining仅为准备警示状态，没有调用时钟tick。游戏中面板缩为右侧单行，避开底部HUD；不改正式HUD。

- 首次专项启动前漏做编辑器导入，发生本地全局类缓存找不到FormalHud的准备错误，未作为有效测试结果。停止该自测进程并完成标准editor import后，原样内部 **19/19**、外层 **3/3**，无ERROR/WARNING；未改实现代码。
- 独立变异：仅把LONG_BUDGET从1500改为552，内部19项失败 **1** 项，外层3项失败 **2** 项，退出1；按原始字节恢复后再次通过。证明适配会识别长预算错误，不是只测能启动。
- 日志在检查工作区runs/ui002-g4-review-{import,adapter-after-import,long-budget-mutant,adapter-restored}.txt；首次准备错误原日志ui002-g4-review-adapter.txt保留。补审结论通过。

## 用户G4结果

交付记录末节记载用户在e240c6c上验收槽1～3，并正常新游戏玩到第2日，结论通过。边缘脉动保持现强度，灰盒说明右侧位置可接受。透支下限拒绝也闪红由SYS-006单独处理，不冒充已在本次UI验收中验证。

## master合并后独立检查

为保护主目录的用户配置，**在Codex工作区干净检出master上述固定合并SHA**执行 `python codexandclaude/tools/run_checks.py full --jobs 4`，不是在Claude分支或用户未提交配置上检查。G2 **81/81**、G3 **102/102 + 67/67**，退出0、起止干净、**content_stable=True**。摘要 `D:/31days/codexandclaude/worktrees/codex/codexandclaude/runs/20261021T085255.871290Z/summary.json`；完整自动证据见下。

随后仅更新本记录和任务卡首部。在同一master固定提交的干净代码检出中复制这两份待提交记录运行G3，主目录用户配置始终未参与或被覆盖；G3 **102/102 + 67/67通过，退出0**，摘要为检查工作区runs/20261021T090723.536978Z/summary.json（仅两份记录未提交，非干净运行不作复用来源）。填写结果后提交前再次G3通过。BOARD/BACKLOG由规划维护者串行刷新，本轮不改。

## full 自动证据

<!-- run_checks evidence v1 -->
总结果：**通过**；模式：`full`。
被测SHA：`853d9bd0b38f26e1f1bdb89e448fafad5292178e`；工作区：`D:\31days\codexandclaude\worktrees\codex`。
工作区状态：**干净**。
开始：2026-10-21T08:52:55.871290+00:00；结束：2026-10-21T09:06:00.193506+00:00。

入口命令（JSON参数数组）：`["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\codex\\codexandclaude\\tools\\run_checks.py", "full", "--jobs", "4"]`。
检查（缺项均不通过；env只代表环境探测，不代表G2/G3）：
- G2：实际81 / 预期81；完整=True；通过=True。
- G3:tests：实际102 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。
- G3:codexandclaude/tests：实际67 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。

工具版本：
- godot：`4.7.2.stable.official.ed1daf0bf`；`D:\DMyself\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`。
- python：`3.12.14 / openpyxl=3.1.5`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe`。
- git：`git version 2.56.0.windows.2`；`C:\Program Files\Git\cmd\git.exe`。
- node：`v24.19.0`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe`。

提交树：`25384d5cd1f19eb99ee3576396ae72df7b294873`；指纹范围：`['exclude codexandclaude/runs/**', 'exclude codexandclaude/tasks/<ID>/{delivery,review,integration,acceptance}.md']`。
已提交范围指纹：`2b7a1578316a50badd7e22d3b97193d4aedb185f32c1b4958b3f987abee8d517`；工作区范围指纹（原始字节）：`d06a46225e29c88cd275a421cc4fc0a1d7789b66517cf3b3da81ff7b6435acc4`。
全工作区指纹：`2f3c83dc162c8869ee2107c6fa3fa41d6c95786d75f38460f7aa8f76f0e1c047`；运行前后内容稳定：`True`。
内容身份说明：起止快照不一致时，检查结果照实保留，但该运行不可作为复用来源；不是对运行期间每次瞬时写入的监控。
已跟踪总diff SHA256：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；未暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。

实际命令与日志（参数为JSON数组）：
- `["C:\\Program Files\\Git\\cmd\\git.exe", "rev-parse", "HEAD"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261021T085255.871290Z\001.txt`；SHA256=`079425d131c51f66a983e034c34f63ee64c071c076d91c00dc41ba2ef72e6f19`。
- `["C:\\Program Files\\Git\\cmd\\git.exe", "status", "--porcelain", "--untracked-files=all"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261021T085255.871290Z\002.txt`；SHA256=`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。
- `["D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--version"]`；退出=0；耗时=0.032秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261021T085255.871290Z\003.txt`；SHA256=`bf8803022b574250bb04dea65053a46b7c58570725316c1f7fe2aa6735706498`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-c", "import sys,openpyxl; print(sys.version.split()[0]); print(\"openpyxl=\"+openpyxl.__version__)"]`；退出=0；耗时=0.313秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261021T085255.871290Z\004.txt`；SHA256=`6d8032bb36596789957df461b308076a9002b5585e5b4d43f8a62b51f0ac622b`。
- `["C:\\Program Files\\Git\\cmd\\git.exe", "--version"]`；退出=0；耗时=0.015秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261021T085255.871290Z\005.txt`；SHA256=`dc0a995f896e73e8fc394cc5dc4d8cabfea65b5eb2db4a40d134dc21c4feb3c0`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\node\\bin\\node.exe", "--version"]`；退出=0；耗时=0.016秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261021T085255.871290Z\006.txt`；SHA256=`bc697de995dc791df53d688ef69c08994cdffc8ce30c906b1ffc65b131ccd0eb`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\codex\\scripts\\verify_game.py", "--godot", "D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--project", "D:\\31days\\codexandclaude\\worktrees\\codex\\game", "--report", "D:\\31days\\codexandclaude\\worktrees\\codex\\codexandclaude\\runs\\20261021T085255.871290Z\\engine.txt", "--jobs", "4"]`；退出=0；耗时=768.0秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261021T085255.871290Z\007.txt`；SHA256=`66d2637e43669a30f9b3fe8c3a587c4f9d0c47cecb1b3b6a351eac9d800844d6`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "tests", "-v"]`；退出=0；耗时=3.344秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261021T085255.871290Z\008.txt`；SHA256=`545bf81f737659deeb77a754567af5bc43459ab51d8906e584c48af5f77a1807`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "codexandclaude/tests", "-v"]`；退出=0；耗时=11.375秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261021T085255.871290Z\009.txt`；SHA256=`c463fd6717eaf5ee6b698b5f98247a092011dbfde50cd27cff76a61a7d427b8f`。
- 报告 `D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261021T085255.871290Z\engine.txt` SHA256=`0ba1cf377e2efb0fa11eeddc0efed8e9449a4a455346bb7c912bae17312b9fd8`。

失败清单：无。
失败归因：未提供基线失败证据，不自动区分旧失败与新失败。
复用限制：只比较内容不替代审查/授权；须成功完整且干净、运行前后稳定、范围相同的来源；只改记录时G2可复用，G3必须重跑；另核对工具、命令和外部依赖。
