# UI-006 第1轮审查

日期：2026-10-21（America/Los_Angeles）｜审查者：Codex｜结论：**需修改**，两项P2。

## 固定对象与范围

- 基线：`053013e0b37f9ce450b921744d9918bdb5aa2ce0`（UI-004第1轮审查修正交付）。
- 实现：`e1c417f289852d90000d9a1eeb490d410014f44c`。
- 被审交付：`14eb59c914e58e5814e009d7fdc106eb6edd551a`，在Codex独立工作区用 git switch --detach 固定；没有使用作废的94efc6c。
- 实现到交付只有 delivery.md 与任务卡首部变化；相对UI-004基线的游戏变化限于正式设置页、入口、相关测试与实施说明。SettingsService、文件格式、输入映射、存档均未修改。两项任务仍须按UI-004 → UI-006的顺序集成。
- 本审查只新增review.md，不修改Claude分支、实现或master。UI-006用户G4仍待进行。

## R1（P2）：恢复默认确认框没有封住方向键焦点

位置：`game/ui/menus/settings_page.gd` ask_restore()，约181～210行，尤其201～202行。

确认框只禁用了SettingsPage自己的focusables，并只连了确认/返回的横向邻居；背景PauseMenu的选项仍可聚焦。真实暂停会话中，打开恢复默认确认框，焦点在“返回”，按上键跳到背景“存档槽”，按下键跳到背景“保存并退出”。继续Enter即可触发背景操作，违反确认纸页作为当前交互上下文的预期。

独立探针继承 `res://tests/test_settings_page.gd`，在原restore_cases后重新打开确认框；每次将焦点放在纸页返回按钮，仅发一次KEY_UP或KEY_DOWN，断言焦点仍是confirm后代。实际 **SETTINGS_PAGE_TESTS checks=54 failures=2，退出1**；日志明确输出上述两个背景按钮名称。

探针命令：`Godot --headless --path game --fixed-fps 60 --script ../codexandclaude/runs/ui006_modal_focus_probe.gd`。脚本位于本审查工作区的codexandclaude/runs，输出保留在其上级 `worktrees/codex/codexandclaude/runs/ui006-modal-focus-probe.txt`。

建议：在确认框内完整限制方向键、Tab/Shift-Tab焦点，或禁用并在关闭时恢复所有背景可聚焦控件，包括暂停选项与主界面按钮；补暂停和主界面两种入口的真实键盘/手柄回归。关闭后仍回到“恢复默认”，恢复/取消语义不变。

## R2（P2）：按键文字和设置值的记录仍脱离真实绘制

位置：`game/ui/menus/settings_page.gd` KeyList._draw() 84～87行；`game/ui/menus/setting_row.gd` _draw() 111～133行；test_settings_page.gd 的文字断言。

KeyList先draw_string，再从原bindings字典复制name/keyboard/controller作为记录；SettingRow在各分支画出shown后，独立把shown存进drawn。实际文字被删或被替换时，测试仍在验证原始数据，并非实际画出的文字。

独立变异（均固定本交付、临时改动后按原字节恢复）：

1. 仅删除KeyList中手柄键位的draw_string，保留shown.append。所有手柄文字消失，仍 **52/0，退出0**。
2. 仅把SettingRow音量与开关分支的实际draw_string参数shown改为字符串“0”，保留drawn记录shown。实际数值/开关文字错误，仍 **52/0，退出0**。

违反完成标准1“断言读实际绘制记录”。建议沿用UI-004本轮修订的同次绘制辅助调用模式：用实际传入的文字/颜色生成记录，再由断言读取；同时在滚动时逐页核对名称、键盘、手柄全文，覆盖当前可见列表之外的早期条目。补以上两种只改实际显示的变异，确认会失败；对设置页说明和恢复确认文字的记录也作同样核对。

## 旧断言、接口、布局与范围记录

- 六项设置都通过GameSettings接口读写。新专项真实输入覆盖键盘、手柄、鼠标，核对即时服务值、实际总线/帧率与隔离设置文件；原子系统格式和冻结InputMap未改。
- test_pause_menu / test_settings 的旧三种控件换成SettingRow.commit，接口值、持久化、窗口与暂停断言保留；新专项补上真实输入。test_title_slots改为居中的正式设置覆盖主界面，去掉的是已经隐藏的旧暂停“继续游戏”入口，保留Esc回主界面并检查返回“设置”焦点。未发现这些适配削弱原有系统保证。
- **范围记录待补**：test_settings.gd、test_title_slots.gd不在任务卡明确列出的旧测试允许清单中。具体适配有必要且交付已披露；修订时请将这两份必要适配补入范围说明并补记用户批准依据，本审查不代替范围授权。
- 暂停/主界面共用SettingsPage组件，各自返回原入口，层级恢复、时钟覆盖与双分辨率纸面内控件分离等现有检查通过。恢复默认的取消/确认正常路径通过，但其方向键焦点有R1。
- 验收适配保存目录与设置文件隔离；独立 `--self-test` **UI006_ACCEPTANCE_TESTS checks=20 failures=0**。G4需在修复后由用户进行。

## 非阻断建议

N1：交付记录写“拖动最多约20次写入”，与_slider_at的实际roundi百分比不符：键盘步长是5，但鼠标按1%取整，单向从0拖到100可有约100个不同值并触发保存。请纠正记录；是否采用释放时保存或节流仍可另行讨论，不要求本任务改SYS-007。

## 独立检查与变异

固定交付、起点dirty=false执行 `python codexandclaude/tools/run_checks.py full --jobs 4`：**退出0，G2 87/87，G3 102/102 + 67/67**。

原始摘要：`worktrees/codex/codexandclaude/runs/ui006-review-worktree/codexandclaude/runs/20261022T000059.747541Z/summary.json`；原始完整输出：`worktrees/codex/codexandclaude/runs/ui006-review-full.txt`。

专项与变异命令：`Godot --headless --path game --fixed-fps 60 --script res://tests/test_settings_page.gd`。每次变异后恢复原字节；在完整检查前恢复至固定交付且清理本次导入生成的两个未跟踪UID。源码未带变异进入full。

| 检查 | 实际结果 |
| --- | --- |
| 界面绕过接口直接改Master总线 | 52项、9失败、退出1 |
| 恢复默认不确认直接执行 | 52项、11失败、退出1 |
| 按键列表漏最后一项 | 52项、2失败、退出1 |
| 删除真实手柄文字绘制 | 52/0，漏检（R2） |
| 实际音量/开关文字统一画0 | 52/0，漏检（R2） |
| 原字节恢复后专项 | 52/0、退出0 |
| 恢复默认确认框方向焦点探针 | 54项、2失败、退出1（R1） |
| UI-006验收自测 | 20/0、退出0 |

日志位于 `worktrees/codex/codexandclaude/runs/ui006-mutant-*.txt`、ui006-restored.txt、ui006-modal-focus-probe.txt、ui006-acceptance-review.txt。原有full通过与新增探针失败/变异漏检分开列出。

full结束content_stable=False：仅生成EXP-003两个未跟踪capture.gd.uid、smoke_test.gd.uid，全部已跟踪diff为空。原始摘要保持不变，不作为后续复用来源；结束后只删除这两个本轮生成文件。审查记录追加后另跑G3，通过再仅提交本文件。

## full 自动证据

<!-- run_checks evidence v1 -->
总结果：**通过**；模式：`full`。
被测SHA：`14eb59c914e58e5814e009d7fdc106eb6edd551a`；工作区：`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\ui006-review-worktree`。
工作区状态：**干净**。
开始：2026-10-22T00:00:59.747541+00:00；结束：2026-10-22T00:14:29.764193+00:00。

入口命令（JSON参数数组）：`["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\codex\\codexandclaude\\runs\\ui006-review-worktree\\codexandclaude\\tools\\run_checks.py", "full", "--jobs", "4"]`。
检查（缺项均不通过；env只代表环境探测，不代表G2/G3）：
- G2：实际87 / 预期87；完整=True；通过=True。
- G3:tests：实际102 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。
- G3:codexandclaude/tests：实际67 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。

工具版本：
- godot：`4.7.2.stable.official.ed1daf0bf`；`D:\DMyself\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`。
- python：`3.12.14 / openpyxl=3.1.5`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe`。
- git：`git version 2.56.0.windows.2`；`C:\Program Files\Git\cmd\git.exe`。
- node：`v24.19.0`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe`。

提交树：`8c006ded2f014277cda9b8af9f706c6f103795a4`；指纹范围：`['exclude codexandclaude/runs/**', 'exclude codexandclaude/tasks/<ID>/{delivery,review,integration,acceptance}.md']`。
已提交范围指纹：`c8230cfb84e2e474d9810bac01214669ed6658192a12a3733f9be63651ccf136`；工作区范围指纹（原始字节）：`1ca5d3dac7f2c0cb3c0bdf5a4c7f7a32f5a643fd723f92612c1132d85b3e7051`。
全工作区指纹：`2f40772ced659630db757ac3cc5b8dfb8fcd01eb9b37190d415dd3d71e79385e`；运行前后内容稳定：`False`。
内容身份说明：起止快照不一致时，检查结果照实保留，但该运行不可作为复用来源；不是对运行期间每次瞬时写入的监控。
已跟踪总diff SHA256：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；未暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。

实际命令与日志（参数为JSON数组）：
- `["C:\\Program Files\\Git\\cmd\\git.exe", "rev-parse", "HEAD"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\ui006-review-worktree\codexandclaude\runs\20261022T000059.747541Z\001.txt`；SHA256=`d9d99161b67fbdc24bca65e1d5d1a0bae77d3f3d2af4923098f4d7d21fa6e8ed`。
- `["C:\\Program Files\\Git\\cmd\\git.exe", "status", "--porcelain", "--untracked-files=all"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\ui006-review-worktree\codexandclaude\runs\20261022T000059.747541Z\002.txt`；SHA256=`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。
- `["D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--version"]`；退出=0；耗时=0.047秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\ui006-review-worktree\codexandclaude\runs\20261022T000059.747541Z\003.txt`；SHA256=`bf8803022b574250bb04dea65053a46b7c58570725316c1f7fe2aa6735706498`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-c", "import sys,openpyxl; print(sys.version.split()[0]); print(\"openpyxl=\"+openpyxl.__version__)"]`；退出=0；耗时=0.39秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\ui006-review-worktree\codexandclaude\runs\20261022T000059.747541Z\004.txt`；SHA256=`6d8032bb36596789957df461b308076a9002b5585e5b4d43f8a62b51f0ac622b`。
- `["C:\\Program Files\\Git\\cmd\\git.exe", "--version"]`；退出=0；耗时=0.032秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\ui006-review-worktree\codexandclaude\runs\20261022T000059.747541Z\005.txt`；SHA256=`dc0a995f896e73e8fc394cc5dc4d8cabfea65b5eb2db4a40d134dc21c4feb3c0`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\node\\bin\\node.exe", "--version"]`；退出=0；耗时=0.015秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\ui006-review-worktree\codexandclaude\runs\20261022T000059.747541Z\006.txt`；SHA256=`bc697de995dc791df53d688ef69c08994cdffc8ce30c906b1ffc65b131ccd0eb`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\codex\\codexandclaude\\runs\\ui006-review-worktree\\scripts\\verify_game.py", "--godot", "D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--project", "D:\\31days\\codexandclaude\\worktrees\\codex\\codexandclaude\\runs\\ui006-review-worktree\\game", "--report", "D:\\31days\\codexandclaude\\worktrees\\codex\\codexandclaude\\runs\\ui006-review-worktree\\codexandclaude\\runs\\20261022T000059.747541Z\\engine.txt", "--jobs", "4"]`；退出=0；耗时=793.968秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\ui006-review-worktree\codexandclaude\runs\20261022T000059.747541Z\007.txt`；SHA256=`8caa52b9c3c5543cad7952b721fc4fabb8d5d0e3b50351eda614ddb4de56bd17`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "tests", "-v"]`；退出=0；耗时=3.25秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\ui006-review-worktree\codexandclaude\runs\20261022T000059.747541Z\008.txt`；SHA256=`dd8eef9f9b562b8759c09228c3c35767427b1e87618b89a61a5c59d3383ba909`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "codexandclaude/tests", "-v"]`；退出=0；耗时=10.969秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\ui006-review-worktree\codexandclaude\runs\20261022T000059.747541Z\009.txt`；SHA256=`997fa2299f0ea819d41364228c56804907db291a9301f1a2fd9993d97491f977`。
- 报告 `D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\ui006-review-worktree\codexandclaude\runs\20261022T000059.747541Z\engine.txt` SHA256=`4eab0c2337584a438e587c9387964cc8285b03f4be098ea671479f6346a05461`。

失败清单：无。
失败归因：未提供基线失败证据，不自动区分旧失败与新失败。
复用限制：只比较内容不替代审查/授权；须成功完整且干净、运行前后稳定、范围相同的来源；只改记录时G2可复用，G3必须重跑；另核对工具、命令和外部依赖。
