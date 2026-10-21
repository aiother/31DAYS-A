# SYS-008 交付记录

实现者：Codex｜审查者：Claude｜分支：`codex/SYS-008`。
基线：`f6844a38e6f89ec8144296de068fd4889d1c0e4c`（第五批最新规划合入后的 master，已含 UI-003）。
实现 SHA：`857feb57f010dabf19bca77d4f45a9fdf4d9638b`。
状态：实现与检查完成，待 Claude 审查；不合并实现。

## 批准与规划合入

用户批准 SYS-008、UI-004、UI-005、UI-006 四张任务卡。最初授权的固定规划 c1bb492 已在中断前合入为32f6a6d并跑G3；收到替换目标后，保留历史，将固定747af1c86457f0150dfcd8c2f9aabf95fadb3c0e合入为上述基线。无冲突，余下差异只更新三份规划文档。新规划G3 102/102 + 67/67通过，摘要 runs/20261021T134856.454718Z/summary.json。

## 改动与完成标准

| 文件 | 内容 |
| --- | --- |
| game/debug/checkpoint_lab.gd | 无会话启动请求show_title；新增return_to_title、slot_summaries、has_any_save；保存成功后延迟重载、单次请求防重入及隔离目录传递 |
| game/ui/menus/life_ui.gd | 仅新增show_title占位，直接调用原show_slots；保留当前UI-003全部方法 |
| game/systems/save/slot_summaries.gd | 独立SlotStore只读查询，四种状态、备份标记、日期进度、时长、资源、珍珠与检查点资源显示名 |
| game/tests/test_title_flow.gd | 登记新套件，真实会话、真实隔离存档、五种返回路径及摘要只读检查 |
| game/docs/title_flow_implementation.md | 接口字段、状态、失败语义、UI-004/005接入说明 |
| 任务卡首部及脚本UID | 状态与Godot脚本标识；无存档格式修改 |

1. **启动与返回**：基线探针确认四个新接口均不存在。实现后，启动通过可观测UI子类验证show_title请求；返回前调用现有虚save_current，成功后释放旧场景/玩家/房间，以新实例进入slot=0、data为空的无会话状态。重新进入仍走未改动的start_slot及检查点恢复。返回值true表示请求已接受，实际重载在延迟调用中完成。
2. **失败与特殊状态**：正常、死亡、实际结局演出完成、最终战超时、第三日探索超时五条路径，均验证写盘失败保留原场景/面板并报告错误，成功后无旧玩家、房间、锁定、计时、剧情或重载元数据。死亡不重复结算；超时余时/预算不回补；结局END保留，继续仍按A-013拒绝而新游戏可用。保存目录通过一次性元数据传递，临时夹具重载后仍在原隔离目录，不读取正式存档。
3. **摘要**：进行中/已通关/空/无法读取四种状态、旧版本/损坏文件、有效备份、全部十个检查点名字；三槽主档/备份/临时文件全部字节前后相同。查询不改变活动store的last_error/used_backup，也不改活动data。has_any_save对损坏但存在的存档为true，对真正空槽为false，与原型“已有文件可展示”的流程一致；能否继续仍由start_slot校验。
4. **范围**：未改输入、UI布局、死亡/结束/超时规则或存档字段。FinalBattleSession继承接口即可，不需要额外修改该文件。无旧断言改动：UI-004之前show_title回退show_slots，所有既有套件继续通过。

## G1 与变异

Godot 4.7.2.stable.official.ed1daf0bf。新增套件使用OS缓存下带PID与时间的独立目录，不接触玩家正式槽。

- TITLE_FLOW_TESTS：106/0；CHECKPOINT_TESTS：39/0；COMPLETED_SLOTS_TESTS：73/0；SLOT_STORE_TESTS：30/0；PAUSE_MENU_TESTS：53/0。按各自登记参数执行，新增套件fixed_fps=60。
- 四项变异：不保存即返回18项失败（该错误流程完成102项检查）；保留旧场景32项；摘要调用save_slot写盘3项；损坏槽当空槽2项。均退出1，源文件按原字节恢复；恢复后106/0。
- 原始专项及变异日志：本工作区codexandclaude/runs/sys008-*.txt与sys008-mutations.json，不入库。

## 全量检查与证据限制

在实现SHA、开始dirty=false运行 `python codexandclaude/tools/run_checks.py full --jobs 4`：**通过**，退出0，G2预期84、实际84/84；G3 102/102 + 67/67完整通过。摘要 runs/20261021T140430.534192Z/summary.json。

本轮content_stable=False：导入生成两个原型测试的未跟踪UID（EXP-003/tests/capture.gd.uid、smoke_test.gd.uid）。结束时无已跟踪diff，原始摘要不改写，**本轮不作为复用来源**。结束后只移除这两个本轮生成文件，不把它们混入任务。最初导入准备也有“UID从缓存重建”的告警，正式套件无失败；不把普通缓存告警描述为源码修复。

## 交接与未验证项

- Claude按固定交付SHA审查，重点检查目录传递、五条返回路径、只读摘要及四类变异；G4按卡不需要，实际界面交给UI-004、UI-005。
- UI-004替换LifeUI.show_title占位；UI-005在现有菜单接return_to_title。接口返回字段和值域见实现说明。
- SYS-007在独立分支续作，两项都以同一个master基线开工；本提交不包含SYS-007，不把未审查的另一项实现作为依赖。
- 主目录用户game/project.godot修改未动；没有合并实现，没有改BOARD/BACKLOG/ROADMAP。

## full 自动摘要

<!-- run_checks evidence v1 -->
总结果：**通过**；模式：`full`。
被测SHA：`857feb57f010dabf19bca77d4f45a9fdf4d9638b`；工作区：`D:\31days\codexandclaude\worktrees\codex`。
工作区状态：**干净**。
开始：2026-10-21T14:04:30.534746+00:00；结束：2026-10-21T14:17:25.000925+00:00。

入口命令（JSON参数数组）：`["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\codex\\codexandclaude\\tools\\run_checks.py", "full", "--jobs", "4"]`。
检查（缺项均不通过；env只代表环境探测，不代表G2/G3）：
- G2：实际84 / 预期84；完整=True；通过=True。
- G3:tests：实际102 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。
- G3:codexandclaude/tests：实际67 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。

工具版本：
- godot：`4.7.2.stable.official.ed1daf0bf`；`D:\DMyself\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`。
- python：`3.12.14 / openpyxl=3.1.5`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe`。
- git：`git version 2.56.0.windows.2`；`C:\Program Files\Git\cmd\git.exe`。
- node：`v24.19.0`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe`。

提交树：`5a322bf8ec084430161656e3feeab23f3147ad0f`；指纹范围：`['exclude codexandclaude/runs/**', 'exclude codexandclaude/tasks/<ID>/{delivery,review,integration,acceptance}.md']`。
已提交范围指纹：`bd636b51825e4c8b49e853d0c2d8092d20677a5af15c094f4e1581d01e587b3d`；工作区范围指纹（原始字节）：`8dac029b7bcf34af2bea718aaf47c9ff84948b3ce0a194a7aecbe68d1a1934bb`。
全工作区指纹：`25c0d57100fafdfc48356bb54100c39c55a33a9040f09a879558e6c1b857fe7b`；运行前后内容稳定：`False`。
内容身份说明：起止快照不一致时，检查结果照实保留，但该运行不可作为复用来源；不是对运行期间每次瞬时写入的监控。
已跟踪总diff SHA256：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；未暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。

实际命令与日志（参数为JSON数组）：
- `["C:\\Program Files\\Git\\cmd\\git.exe", "rev-parse", "HEAD"]`；退出=0；耗时=0.015秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261021T140430.534192Z\001.txt`；SHA256=`5b22bc2f840e73d88f76c717d465dc657e9109c52eb075a7005d024d9191b603`。
- `["C:\\Program Files\\Git\\cmd\\git.exe", "status", "--porcelain", "--untracked-files=all"]`；退出=0；耗时=0.032秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261021T140430.534192Z\002.txt`；SHA256=`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。
- `["D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--version"]`；退出=0；耗时=0.047秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261021T140430.534192Z\003.txt`；SHA256=`bf8803022b574250bb04dea65053a46b7c58570725316c1f7fe2aa6735706498`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-c", "import sys,openpyxl; print(sys.version.split()[0]); print(\"openpyxl=\"+openpyxl.__version__)"]`；退出=0；耗时=0.297秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261021T140430.534192Z\004.txt`；SHA256=`6d8032bb36596789957df461b308076a9002b5585e5b4d43f8a62b51f0ac622b`。
- `["C:\\Program Files\\Git\\cmd\\git.exe", "--version"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261021T140430.534192Z\005.txt`；SHA256=`dc0a995f896e73e8fc394cc5dc4d8cabfea65b5eb2db4a40d134dc21c4feb3c0`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\node\\bin\\node.exe", "--version"]`；退出=0；耗时=0.016秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261021T140430.534192Z\006.txt`；SHA256=`bc697de995dc791df53d688ef69c08994cdffc8ce30c906b1ffc65b131ccd0eb`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\codex\\scripts\\verify_game.py", "--godot", "D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--project", "D:\\31days\\codexandclaude\\worktrees\\codex\\game", "--report", "D:\\31days\\codexandclaude\\worktrees\\codex\\codexandclaude\\runs\\20261021T140430.534192Z\\engine.txt", "--jobs", "4"]`；退出=0；耗时=757.297秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261021T140430.534192Z\007.txt`；SHA256=`a871fbc9923c45c5ddf5054364c176edab7c22b277f3dccb517ca54a7dce39b0`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "tests", "-v"]`；退出=0；耗时=3.609秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261021T140430.534192Z\008.txt`；SHA256=`9042b885eb30cde99c4e193c6ae29e2365a170813045d8b60dda183beb65ce33`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "codexandclaude/tests", "-v"]`；退出=0；耗时=12.0秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261021T140430.534192Z\009.txt`；SHA256=`d43e1f162f060a6e92b148a27e9c4ad1b22872351b7dcf7efd480fda25d96772`。
- 报告 `D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261021T140430.534192Z\engine.txt` SHA256=`cdabecaad658b7444ce8dcb5f4883d7bcf521dfede2ee323c636977a96cfda9b`。

失败清单：无。
失败归因：未提供基线失败证据，不自动区分旧失败与新失败。
复用限制：只比较内容不替代审查/授权；须成功完整且干净、运行前后稳定、范围相同的来源；只改记录时G2可复用，G3必须重跑；另核对工具、命令和外部依赖。
