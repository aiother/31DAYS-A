# UI-004 第1轮审查

日期：2026-10-21（UTC）｜审查者：Codex｜结论：**需修改**。

## 固定对象与范围

- 基线：`07fa7e924d9db048edb079043bbf3cf9646e5948`。
- 实现：`8d2d4c96d993801e3f2c6ea6eda8879eaf5d7135`。
- 交付：`5136b691a69eb0d05608e68c92fa6cef0914c3d7`。
- 在 Codex 工作区执行 `git switch --detach 5136b691a69eb0d05608e68c92fa6cef0914c3d7` 后审查；实现到交付只有 delivery.md 新增与任务卡首部变化。
- 源码范围符合任务卡：四个菜单脚本、LifeUI、相关新旧测试和验收适配、实施说明。没有修改存档格式、输入映射、SYS-008 数据接口、共享样式模块。
- 本审查只新增 review.md；临时探针和原始日志放 runs，不修改 Claude 分支，不合并 master。G4 待用户另行验收。

## R1（P2）：新游戏保存失败后丢失键盘/手柄焦点

位置：`game/ui/menus/menu_screen.gd` 114～116 行、123～137 行；`game/tests/test_title_slots.gd` 291～303 行。

确认按钮先 `close_dialog(false)` 再调用开始游戏。写盘失败时仍停留在书签页，确认按钮随纸页被释放，但没有把焦点归还给书签。真实会话中 `gui_get_focus_owner()` 返回 null；按右键后仍为 null，Enter 也没有可确认的书签。用户必须借助鼠标或先退出该页，不能直接用原来的键盘/手柄操作重试。

复现直接沿用现有 layout_cases 的隔离真实存档失败夹具：把 store.directory 临时设为已存在的 slot_1.json 文件路径，确认新游戏；错误提示“无法写入存档，请检查磁盘空间和权限”正确显示，但确认纸页关闭后的焦点为空。现有测试随后手动 `cards[focus].grab_focus()`，掩盖了问题。

独立探针继承 `res://tests/test_title_slots.gd`，覆盖 click()，在确认回调返回且无会话、书签仍可见时，先断言 `root.gui_get_focus_owner() != null`，再发送 KEY_RIGHT 并断言 `slots().focused() >= 0`；得到 **TITLE_SLOTS_TESTS checks=79 failures=2，退出1**。原套件仍77/0。探针与输出为 `worktrees/codex/codexandclaude/runs/ui004_failed_save_regression.gd`、同名 .txt；只读焦点输出另见 ui004_failed_save_probe.txt。

建议：开始失败且仍留在选槽页时，把焦点归还到发起操作的书签；补真实失败后的键盘/手柄选择、重新确认与返回回归，不在断言前手动补焦点。成功开始仍正常关闭选槽。

## R2（P2）：关键色与已通关提示的绘制记录可脱离真实绘制，规定变异漏检

位置：`game/ui/menus/slot_select.gd` 186～200 行；`game/ui/menus/menu_screen.gd` 76～84 行；`game/tests/test_title_slots.gd` 的 colour_cases / continue_cases。

日期、生命、可能性等 keys 记录是另外赋常量，而非实际绘制调用的颜色。提示文字同样在 draw_string 后直接复制 prompt。真实画面改变、记录不变时，断言仍通过。已独立复现：

1. 只将日期 `_text(..., UiTheme.SIZE_BODY, DuskStyle.LIFE)` 的实际颜色改为 `DuskStyle.LIFE.lerp(paper, 0.5)`，保留 `keys["date"] = DuskStyle.LIFE`。不同日期的真实颜色漂移，但 **77/0、退出0**。
2. 在 draw_prompt() 仅对 `prompt == "游戏已通关"` 跳过 draw_string，保留记录赋值及其他提示绘制。已通关反馈文字实际消失，但 **77/0、退出0**。

这分别违反完成标准1“断言读实际绘制记录”和完成标准4“去掉已通关提示绘制、关键色随日期漂移，相应测试失败”。交付的“去掉已通关印”检查验证了印章，不等于去掉选槽后的“游戏已通关”提示文字。

建议：把实际绘制和记录收敛到同一绘制辅助调用，用真实传入的颜色、文字生成记录；关键色检查覆盖实际生命碎片、可能性、日期等绘制参数，不能另赋期望常量。补以上两种只改真实绘制的变异并确认失败。

变异工作区固定同一交付 SHA，位于 `worktrees/codex/codexandclaude/runs/ui004-mutation-worktree`；与 full 被测目录分离。每次变异后立即按原字节恢复，最后 git diff 为空、原专项重新77/0。日志在其上级 runs。

## 其余核对与非阻断建议

- 五处旧断言的界面替换有必要：title_flow 从占位 slots 改为正式 title；checkpoints 检查空书签；completed_slots 与旧验收适配改为两种模式和确认纸页；pause_menu 检查正式书签被设置页替换。A-013 的拒绝进入、会话/重载状态不变、主存档/备份/临时文件字节不变、新游戏覆盖等断言都保留。没有删减这些系统保证。提示可见性的测试仍有 R2 的记录缺口。
- 无会话 resume_game 返回主界面；从主界面进入设置后返回或 Esc 回主界面，已有真实输入用例通过。另继承原套件，在 enter_cases 后对真实活动会话调用 LifeUI.show_title()，等待8帧，确认场景ID变化、无会话、正式主界面可见且暂停，**78/0**，输出 ui004_title_route_probe.txt。
- 防重叠用例在1280×720、1920×1080及三个选中位置下检查书签、标题/操作提示、底部错误提示、返回按钮两两分离且在窗口内，现有6项通过。G4 仍需用户确认视觉与交互。
- 验收适配隔离真实存档，F2/F3只操作临时目录；独立 `--self-test` **UI004_ACCEPTANCE_TESTS checks=22 failures=0**，无ERROR/WARNING。
- N1（非阻断）：最后检查点文字断言目前仅验证非空；可直接与夹具对应的明确显示名比较，避免以后错误显示另一检查点名称也通过。

## 独立检查与变异汇总

Godot 命令前缀：`Godot --headless --path game --fixed-fps 60 --script res://tests/test_title_slots.gd`；Godot绝对路径、版本见下方自动证据。探针命令将 --script 换成 `../codexandclaude/runs/<上述探针名>.gd`。

| 检查 | 结果 |
| --- | --- |
| 完整 full --jobs 4（固定交付、开始dirty=false） | G2 86/86；G3 102/102 + 67/67；退出0 |
| 删除已通关印调用 | 77项、1失败、退出1 |
| 无存档仍显示继续游戏 | 77项、1失败、退出1 |
| 确认纸页默认焦点改为确认 | 71项、17失败、退出1 |
| 日期实际颜色与记录一起随纸色漂移 | 77项、1失败、退出1 |
| 只改日期实际绘制颜色（R2） | 77/0，漏检 |
| 只跳过已通关反馈文字实际绘制（R2） | 77/0，漏检 |
| 失败后焦点回归探针（R1） | 79项、2失败、退出1 |
| 活动会话显示主界面探针 | 78/0、退出0 |
| UI-004验收自测 | 22/0、退出0 |
| 所有变异恢复后原专项 | 77/0、退出0 |

原始 full 摘要：`worktrees/codex/codexandclaude/runs/20261021T155734.717287Z/summary.json`。content_stable=False，仅编辑器生成EXP-003的capture.gd.uid、smoke_test.gd.uid两个未跟踪文件；已跟踪diff为空，原始摘要未改写，结束后仅删除这两个生成文件，不将此轮作为后续复用来源。

审查记录写入后再跑G3，通过后仅提交本记录。现有检查通过与R1新增失败、R2漏检分别记录，不把新增探针的预期失败算成原 full 的失败。

## full 自动证据

<!-- run_checks evidence v1 -->
总结果：**通过**；模式：`full`。
被测SHA：`5136b691a69eb0d05608e68c92fa6cef0914c3d7`；工作区：`D:\31days\codexandclaude\worktrees\codex`。
工作区状态：**干净**。
开始：2026-10-21T15:57:34.717287+00:00；结束：2026-10-21T16:10:58.961013+00:00。

入口命令（JSON参数数组）：`["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\codex\\codexandclaude\\tools\\run_checks.py", "full", "--jobs", "4"]`。
检查（缺项均不通过；env只代表环境探测，不代表G2/G3）：
- G2：实际86 / 预期86；完整=True；通过=True。
- G3:tests：实际102 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。
- G3:codexandclaude/tests：实际67 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。

工具版本：
- godot：`4.7.2.stable.official.ed1daf0bf`；`D:\DMyself\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`。
- python：`3.12.14 / openpyxl=3.1.5`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe`。
- git：`git version 2.56.0.windows.2`；`C:\Program Files\Git\cmd\git.exe`。
- node：`v24.19.0`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe`。

提交树：`81cfd43d957a41c01b4c8a117726f27113615bd3`；指纹范围：`['exclude codexandclaude/runs/**', 'exclude codexandclaude/tasks/<ID>/{delivery,review,integration,acceptance}.md']`。
已提交范围指纹：`bfda90443cdab661cc566d93b82e782997f076bd2177cdd2ac69716c0e428bca`；工作区范围指纹（原始字节）：`775d749617191987fd873235df08222113993802226437d8a0f688e9ece70ea7`。
全工作区指纹：`217997620d81b346dc189e73c35d64d39f2cc0ec5ebf77677074952859e4ff37`；运行前后内容稳定：`False`。
内容身份说明：起止快照不一致时，检查结果照实保留，但该运行不可作为复用来源；不是对运行期间每次瞬时写入的监控。
已跟踪总diff SHA256：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；未暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。

实际命令与日志（参数为JSON数组）：
- `["C:\\Program Files\\Git\\cmd\\git.exe", "rev-parse", "HEAD"]`；退出=0；耗时=0.016秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261021T155734.717287Z\001.txt`；SHA256=`4c65909b4b870e9c174bd5d36b57b9d448130c144ec0f25e4f579dbedaf38976`。
- `["C:\\Program Files\\Git\\cmd\\git.exe", "status", "--porcelain", "--untracked-files=all"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261021T155734.717287Z\002.txt`；SHA256=`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。
- `["D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--version"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261021T155734.717287Z\003.txt`；SHA256=`bf8803022b574250bb04dea65053a46b7c58570725316c1f7fe2aa6735706498`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-c", "import sys,openpyxl; print(sys.version.split()[0]); print(\"openpyxl=\"+openpyxl.__version__)"]`；退出=0；耗时=0.312秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261021T155734.717287Z\004.txt`；SHA256=`6d8032bb36596789957df461b308076a9002b5585e5b4d43f8a62b51f0ac622b`。
- `["C:\\Program Files\\Git\\cmd\\git.exe", "--version"]`；退出=0；耗时=0.016秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261021T155734.717287Z\005.txt`；SHA256=`dc0a995f896e73e8fc394cc5dc4d8cabfea65b5eb2db4a40d134dc21c4feb3c0`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\node\\bin\\node.exe", "--version"]`；退出=0；耗时=0.015秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261021T155734.717287Z\006.txt`；SHA256=`bc697de995dc791df53d688ef69c08994cdffc8ce30c906b1ffc65b131ccd0eb`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\codex\\scripts\\verify_game.py", "--godot", "D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--project", "D:\\31days\\codexandclaude\\worktrees\\codex\\game", "--report", "D:\\31days\\codexandclaude\\worktrees\\codex\\codexandclaude\\runs\\20261021T155734.717287Z\\engine.txt", "--jobs", "4"]`；退出=0；耗时=786.594秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261021T155734.717287Z\007.txt`；SHA256=`d4181384432ee3b07654b7203b5a39b71608bcd6d952298da1b7ecd7676e9b71`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "tests", "-v"]`；退出=0；耗时=3.562秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261021T155734.717287Z\008.txt`；SHA256=`5ecb8b3d3a2bd302a415c8f853028e5c6f4429b3b867629fc982fd6ecd1cb808`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "codexandclaude/tests", "-v"]`；退出=0；耗时=12.547秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261021T155734.717287Z\009.txt`；SHA256=`ce6716cfef567e913ec7f4c949d9b815579d43cbebaf5e083ab4553e4ab13c51`。
- 报告 `D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261021T155734.717287Z\engine.txt` SHA256=`081f14ff99f1bc0de37355d9fe845045997e89f97b2083388796b1b4729c4dde`。

失败清单：无。
失败归因：未提供基线失败证据，不自动区分旧失败与新失败。
复用限制：只比较内容不替代审查/授权；须成功完整且干净、运行前后稳定、范围相同的来源；只改记录时G2可复用，G3必须重跑；另核对工具、命令和外部依赖。
