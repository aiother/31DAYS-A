# SYS-007 续作交付记录

实现者：Codex｜审查者：Claude｜分支：`codex/SYS-007-r2`。
基线：`f6844a38e6f89ec8144296de068fd4889d1c0e4c`（已含UI-003与最新第五批规划的master）。
实现 SHA：`430333b08d1884105ce6286e85567eaabc6e0b6d`。
状态：编译问题修复，实现与G1/G2/G3完成，待Claude审查；不合并实现。

## 原失败与本轮授权

原分支codex/SYS-007保留在失败记录`b592666903ab318d1f8dc47c196413538fcb3e4d`，不重写旧历史。原G1的JSON嵌套数值类型比较与无头窗口模式问题已在9d24d3b修正，但随后full在验收预加载路径报`Identifier not found: GameSettings`，因此按停止条件暂停。

用户本轮要求继续处理编译错误，并明确UI-003已合入、设置调用位于PauseMenu.show_settings。由此在新master基线上续作：重新应用已写的设置后端，改PauseMenu中的三个接口调用，不恢复过时的LifeUI设置实现；LifeUI文件本轮不改。此接入点以本轮用户会话为准，原卡文件清单中的旧LifeUI设置位置不再适用。

修复用 `get_node("/root/GameSettings")` 在运行时取得Node并调用设置API，不依赖自动加载名在自定义SceneTree预加载时可见。测试常量直接预加载真实最终战会话与灰盒场景，覆盖原编译顺序缺口；原先失败的test_acceptance_launcher独立及full均通过11/0。

## 改动与完成标准

| 文件 | 内容 |
| --- | --- |
| game/project.godot | 仅新增GameSettings自动加载与音频布局登记，保留既有物理帧率与输入配置 |
| game/default_bus_layout.tres | Master下新增效果音、背景音；默认100，输出Master |
| game/systems/game_settings.gd | 六项设置的读取、即时应用保存、恢复默认、changed信号、冻结按键只读查询及隔离文件策略 |
| 三个敌人visual及player/placeholder_visual.gd | 每个只为原有音效播放器增加效果音bus指定 |
| game/ui/menus/pause_menu.gd | 只把现有音量、尺寸、全屏控件的取值和回调接到运行时设置接口；布局不改 |
| game/tests/test_settings.gd | 新登记套件，静态预加载、隔离文件、新进程读回、实际总线与播放器路由、按键表、当前PauseMenu设置、原生窗口与F11检查 |
| game/docs/settings_implementation.md | API、值域、JSON文件格式、隔离与预加载说明 |
| 任务卡首部与脚本UID | 状态与Godot标识 |

- 三条总线默认100；四个实际占位音效播放器走效果音；背景音只预留。
- 总音量/效果音/背景音0～100默认100；窗口1280×720或1920×1080默认1280×720；全屏默认false；渲染上限30/60/120/0（不限制）默认60，物理始终60。
- 修改每个设置立即应用并保存到独立settings.cfg；新进程首帧前读回，文件缺失、损坏、不支持版本、越界或字段类型错误安全回退默认。文件为version=1的UTF-8 JSON，窗口尺寸用两元素数组序列化；不改玩家槽格式或内容。
- InputMap只读返回T1冻结表十五项，名称、顺序、键盘/鼠标与手柄文字逐项核对；不改映射。
- 保留已有F11处理；设置服务在其后读取DisplayServer实际模式并保存，不重复切换。测试采用真实原生事件验证。

## G1、渲染与变异

环境：Godot4.7.2.stable.official.ed1daf0bf，Python3.12.14。

- 无头设置：`SETTINGS_TESTS checks=112 failures=0`；原生OpenGL兼容渲染：`115/0`（实际窗口尺寸/模式、F11单次切换及保存），均退出0。
- 相关登记套件：验收启动器11/0、输入89/0、玩家29/0、生命33/0、无色31/0、单色45/0、天43/0、手柄菜单33/0、暂停菜单53/0，均通过。
- 四项变异重新复现：音效仍走Master失败1项、不保存21项、损坏文件报错1项、帧率改变物理帧率6项；每项退出1，源文件逐字节恢复，恢复后112/0。
- 无头显示不实现原生全屏，因此无头子进程验证读入设置、实际总线、窗口尺寸与帧率，原生模式由渲染运行验证。JSON两侧先做相同往返以消除嵌套数值类型差异，不删除存储值检查。

所有自定义SceneTree测试及验收进程自动选择各自缓存目录；G2无头主场景冒烟也隔离。读回子进程显式使用父测试目录，结束清理；模拟slot_1.json字节前后相同。未读写玩家正式settings.cfg。

## 全量检查与稳定性

在实现SHA、开始dirty=false运行 `python codexandclaude/tools/run_checks.py full --jobs 4`：**通过**，退出0，G2预期84、实际84/84，G3 102/102 + 67/67完整通过。摘要 runs/20261021T141817.360392Z/summary.json。

工作区位于Codex自己的 `worktrees/codex/codexandclaude/runs/sys007-r2-worktree`。本轮content_stable=False，仅因导入生成EXP-003/tests/capture.gd.uid、smoke_test.gd.uid两个未跟踪文件；结束时全部已跟踪diff为空。原始摘要保留，**不可作为证据复用来源**；只移除这两个本次生成文件，不纳入任务。专项、原生窗口、变异与full原日志均在该工作区runs，不入库。

## 审查交接与未验证项

- Claude固定新交付SHA审查整个SYS-007实现，重点复现预加载路径、原失败启动器、隔离文件、新进程读回与四类变异。旧失败分支用于追溯，本轮应使用codex/SYS-007-r2。
- 设置调用已适配UI-003的PauseMenu，LifeUI不改；SYS-008在另一独立分支，不构成本任务依赖。两项以相同master基线开工，均未合并。
- G4按卡为可选，未声称用户手验通过；正式设置界面由UI-006接入后验收。可重跑 `Godot --path game --rendering-method gl_compatibility --script res://tests/test_settings.gd` 观察隔离的原生窗口自动检查，不接触正式存档与设置。
- 主目录用户game/project.godot修改保持原样。没有改BOARD/BACKLOG/ROADMAP、物理规则、输入映射或存档槽。

## full 自动摘要

<!-- run_checks evidence v1 -->
总结果：**通过**；模式：`full`。
被测SHA：`430333b08d1884105ce6286e85567eaabc6e0b6d`；工作区：`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\sys007-r2-worktree`。
工作区状态：**干净**。
开始：2026-10-21T14:18:17.360392+00:00；结束：2026-10-21T14:31:09.314177+00:00。

入口命令（JSON参数数组）：`["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\codex\\codexandclaude\\runs\\sys007-r2-worktree\\codexandclaude\\tools\\run_checks.py", "full", "--jobs", "4"]`。
检查（缺项均不通过；env只代表环境探测，不代表G2/G3）：
- G2：实际84 / 预期84；完整=True；通过=True。
- G3:tests：实际102 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。
- G3:codexandclaude/tests：实际67 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。

工具版本：
- godot：`4.7.2.stable.official.ed1daf0bf`；`D:\DMyself\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`。
- python：`3.12.14 / openpyxl=3.1.5`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe`。
- git：`git version 2.56.0.windows.2`；`C:\Program Files\Git\cmd\git.exe`。
- node：`v24.19.0`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe`。

提交树：`40f9bdd749e24b33702a34d982cbb464ef28c369`；指纹范围：`['exclude codexandclaude/runs/**', 'exclude codexandclaude/tasks/<ID>/{delivery,review,integration,acceptance}.md']`。
已提交范围指纹：`ed7b0a1d5008fb27f43f3fbf7cde6de65072d4793c19c3a004e48d35da04862d`；工作区范围指纹（原始字节）：`922ddb94f241097d3ff61237448a53b1942967cb856c5be1227e9303be763248`。
全工作区指纹：`20e0c5645737e435425a2479d6b4f9b50503a6636f009b412a6d9ba2ca1683b6`；运行前后内容稳定：`False`。
内容身份说明：起止快照不一致时，检查结果照实保留，但该运行不可作为复用来源；不是对运行期间每次瞬时写入的监控。
已跟踪总diff SHA256：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；未暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。

实际命令与日志（参数为JSON数组）：
- `["C:\\Program Files\\Git\\cmd\\git.exe", "rev-parse", "HEAD"]`；退出=0；耗时=0.015秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\sys007-r2-worktree\codexandclaude\runs\20261021T141817.360392Z\001.txt`；SHA256=`b67e93ccc2f0188acfb7925677afa3d017f80470c81a0aba53c3c49bae2e853f`。
- `["C:\\Program Files\\Git\\cmd\\git.exe", "status", "--porcelain", "--untracked-files=all"]`；退出=0；耗时=0.032秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\sys007-r2-worktree\codexandclaude\runs\20261021T141817.360392Z\002.txt`；SHA256=`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。
- `["D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--version"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\sys007-r2-worktree\codexandclaude\runs\20261021T141817.360392Z\003.txt`；SHA256=`bf8803022b574250bb04dea65053a46b7c58570725316c1f7fe2aa6735706498`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-c", "import sys,openpyxl; print(sys.version.split()[0]); print(\"openpyxl=\"+openpyxl.__version__)"]`；退出=0；耗时=0.313秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\sys007-r2-worktree\codexandclaude\runs\20261021T141817.360392Z\004.txt`；SHA256=`6d8032bb36596789957df461b308076a9002b5585e5b4d43f8a62b51f0ac622b`。
- `["C:\\Program Files\\Git\\cmd\\git.exe", "--version"]`；退出=0；耗时=0.015秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\sys007-r2-worktree\codexandclaude\runs\20261021T141817.360392Z\005.txt`；SHA256=`dc0a995f896e73e8fc394cc5dc4d8cabfea65b5eb2db4a40d134dc21c4feb3c0`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\node\\bin\\node.exe", "--version"]`；退出=0；耗时=0.016秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\sys007-r2-worktree\codexandclaude\runs\20261021T141817.360392Z\006.txt`；SHA256=`bc697de995dc791df53d688ef69c08994cdffc8ce30c906b1ffc65b131ccd0eb`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\codex\\codexandclaude\\runs\\sys007-r2-worktree\\scripts\\verify_game.py", "--godot", "D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--project", "D:\\31days\\codexandclaude\\worktrees\\codex\\codexandclaude\\runs\\sys007-r2-worktree\\game", "--report", "D:\\31days\\codexandclaude\\worktrees\\codex\\codexandclaude\\runs\\sys007-r2-worktree\\codexandclaude\\runs\\20261021T141817.360392Z\\engine.txt", "--jobs", "4"]`；退出=0；耗时=755.594秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\sys007-r2-worktree\codexandclaude\runs\20261021T141817.360392Z\007.txt`；SHA256=`060b445856153c2ab082234ee88259e97078a0ce2fecb2eb4c7aaf66a4244d4d`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "tests", "-v"]`；退出=0；耗时=3.359秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\sys007-r2-worktree\codexandclaude\runs\20261021T141817.360392Z\008.txt`；SHA256=`d0b3b601d0cb56bb64eff43c76036f5b877ae9d4f453bd3f627dc87933e9d53d`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "codexandclaude/tests", "-v"]`；退出=0；耗时=11.407秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\sys007-r2-worktree\codexandclaude\runs\20261021T141817.360392Z\009.txt`；SHA256=`f1821a27aab666eb7a08a53b20f9ed0609a64f0e45b21b7196656960bde4e3fe`。
- 报告 `D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\sys007-r2-worktree\codexandclaude\runs\20261021T141817.360392Z\engine.txt` SHA256=`b16357ea2506f5e45ca76510b11a8d6a341e104fd04d69d8ecd37a55b5e516c7`。

失败清单：无。
失败归因：未提供基线失败证据，不自动区分旧失败与新失败。
复用限制：只比较内容不替代审查/授权；须成功完整且干净、运行前后稳定、范围相同的来源；只改记录时G2可复用，G3必须重跑；另核对工具、命令和外部依赖。
