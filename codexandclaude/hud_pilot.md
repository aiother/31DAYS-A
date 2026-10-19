# HUD-001：灰盒 HUD 与错误提示防重叠

用户已确认本试点。先阅读 Agents.md、codexandclaude/collaboration.md 和 codexandclaude/hud_baseline.md。保持 Manual 手动审批，不启动其他 Agent 或 CLI 自动协作。

## 工作区和基线

只在 D:\31days\codexandclaude\worktrees\claude-hud 工作，分支必须是 claude/hud-layout-pilot。先运行只读命令确认根目录、分支、HEAD、git status；必须干净。游戏代码基线 36d05826ba24eea9423204eaca6de956b48a33af，工作区 HEAD 另包含协调者的任务准备提交。出现未知变更或位置不符就停止报告。

不得在 D:\31days 的 master 工作目录写代码。原目录的 T6/T7 和 project.godot 有用户未提交修改，不复制、不提交、不覆盖；T7 已填写规格见基线摘要，但本次只修现有灰盒布局，不实现正式图标与特效。T0–T8 保持冻结。

## 已授权的文件清单

只允许修改以下文件；相对路径均以自己的工作区根目录为准：

- game/ui/menus/life_ui.gd
- game/tests/test_hud_layout.gd（新增）
- game/tests/test_hud_layout.gd.uid（Godot 自动生成时一并提交）
- scripts/verify_game.py（仅登记 HUD 套件，不改既有校验语义）
- tests/test_verification_runner.py（仅同步两处套件数量并保留实际文件检查）
- codexandclaude/hud_pilot_delivery.md（新增交付记录，含复现证据、验证、未验证项；不要写自身提交哈希造成循环，哈希在会话回复）

不要改其他文件。自动导入产生的未跟踪资源标识若不在清单中，报告给协调者处理，不擅自提交或清理。Godot 缓存和被忽略的测试日志不是源码变更。

## 先复现，后修复

1. 在真实 UI 的真实更新流程中准备含恢复/滑步、珍珠、药包的五行 HUD，调用既有 save_failed(message) 展示错误；测试需确认五行状态和提示确实出现。
2. 等待布局完成后测量 HUD 与错误 Label 的实际可见文字区域或正确变换后的控件矩形。基线应因重叠而失败；记录命令、断言和测量结果，不只写估计行高。若未复现，不做无证据的重构，先报告实际状态。
3. 优先用左上角容器管理 HUD 和提示的纵向布局。保持原有显示语义、字体大小、左上起点和颜色，长错误文本也应可读，不引入新的交互或鼠标拦截。不改 public 方法/信号、调用方、状态计算或存档错误处理。
4. 针对相同用例验证修复后无重叠；覆盖四行/五行动态切换、错误清空/重现、较长中文提示，以及 1280×720 和 1920×1080 视口对应的坐标变换。测量要与实际布局一致，不能手动设置 Label 矩形假装修复。
5. 结局/对话层级、正式 HUD 重设计、全局菜单布局、手柄焦点重做均不在本次范围。

测试使用已有项目节点/场景，写测试存档时使用独立标识和临时路径，不访问玩家正式存档。不把真实恢复与真实磁盘失败强行同步作为必要人工操作，可在测试中调用既有 save_failed() 注入提示而不破坏磁盘权限。

## 验证与交付

引擎：D:\DMyself\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe。

Python：C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe（已有表格依赖；无需安装）。

在自己的工作区依次验证，并保留真实输出：

```powershell
& 'D:\DMyself\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe' --headless --editor --path game --import --quit
& 'D:\DMyself\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe' --headless --path game --script res://tests/test_hud_layout.gd
& 'C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' -X utf8 -m unittest discover -s tests -v
& 'C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' -X utf8 -m unittest discover -s codexandclaude/tests -v
& 'C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' -X utf8 scripts/verify_game.py --godot 'D:\DMyself\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe' --jobs 4 --report codexandclaude/runs/hud_engine_validation.txt
```

新增套件必须有真实检查计数和 failures=0 摘要，登记时匹配该摘要。不能只依据进程退出码或最后一句话判断通过；错误、解析异常、泄漏或超时均报告失败。不要削弱既有测试或绕过权限错误；遇到权限限制，报告需要用户授权的具体动作。

人工视觉验收另列：恢复中五行 HUD 与提示同时可读，1280×720、1920×1080 和全屏可读、暂停/设置交互无回归。没有实际截图、手柄或人工检查就标“未验证”，不能以无界面测试代替。无需为此修改正式存档或制造真实写盘失败。人工验收未完成时不能声称可最终合并。

每次改动更新相关测试；相关自动测试和验证全部通过后，检查差异只含授权文件，使用显式文件列表创建本地提交。先前临时失败的复现测试在修复提交时必须通过；不提交失败版本，不提交测试生成物或个人设置，不使用整仓批量暂存。

在会话中回复：基线 HEAD、复现前后证据、修改文件、测试命令与结果、未验证项、最终提交哈希及 git status。不要自行合并 master、推送、删除工作区、安装依赖或扩展任务。交付后停止，等用户转交 Codex 做独立审查。
