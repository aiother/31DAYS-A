# EXP-004 第1轮审查

日期：2026-10-21（America/Los_Angeles；交付中的用户选择日期为2026-10-22）｜审查者：Codex｜结论：**需修改，R1、R2两项P2阻断**。未合入master。

## 固定对象与范围

- 使用 `git switch --detach 26cc9ce8ad7d178b6b35dbd1717ba3e1f5960edb` 固定新交付，旧9bf0f87不再作为最终审查对象。
- 基线：`5c73dfcef60efe0a14e6e126ab2af940cf6968ad`。相对该规划提交，只有game/prototypes/EXP-004新增内容及本任务task.md首部、delivery.md变化；没有修改正式场景、共享脚本、project.godot、InputMap或存档。原型无存档调用。
- 原实现b5f4a6a到原交付9bf0f87只有delivery.md和任务卡首部；新增D的ddb7757只改原型目录并更新交付记录；ddb7757到新交付26cc9ce只有交付记录与任务卡状态，无代码变化。
- 新交付包含用户原话“对话框就用D，EXP-004定稿：对话D、G-08短提示、介绍卡2”；D确为B的黄昏纸笺与墨色正文、C的上下纸边与墨色名签，未扩到正式界面。允许用户继续组合方案，符合协作规范§3.3。README与交付标明D不是T7-C黑色半透明，正式实现时同步修订，处理方式合适；本轮没有改Words/。
- 已检查交付截图dialogue_d_leave.png及绘制代码；原型脚本/截图均在独立目录，截图有.gdignore，测试脚本UID已登记。D、两种G-08和两种介绍卡均有对应示例；三张对比表与推荐分开。
- 当前master为ac23a8a1525f9f62bebb47de19f1daac18b72b24，含稍晚合入的UI-005；本分支基于更早2183e77，不把跨基线双点diff中的UI-005差异误判成原型修改。

## R1（P2）：救助确认两按钮重叠，现有防重叠检查漏了问句

位置：game/prototypes/EXP-004/dialogue_view.gd第98～99行；tests/smoke_test.gd的layout_cases。

四个方案共用的两枚Button宽均为300，实际全局矩形分别为(700,292,300,56)和(920,292,300,56)，横向重叠80；两个分辨率均如此（canvas_items下逻辑尺寸保持1920×1080）。重叠区域会同时落入“留下”和“确认离开并放弃救助”的点击范围，后添加按钮覆盖前一个按钮的一部分，不满足任务卡完成标准2的元素互不重叠。截图中文字没压在一起并不能证明点击区域没有重叠。

独立探针打开真实离开确认并读取实际Button.get_global_rect，A/B/C/D × 1920×1080、1280×720共8例全部失败。原冒烟80/0仍通过：layout_cases只按T打开普通对话，比较整个对话框、卡、提示、横幅和模拟HUD，未打开L问句，也未测内部按钮矩形。

建议：把两个完整点击区域分开并留出间距，保留默认“留下”；登记冒烟加入四方案、两分辨率的救助问句布局与实际控件点击检查。修复范围可完全留在原型目录。

## R2（P2）：暂停时仍能点击离开确认，改变对话与救助状态

位置：game/prototypes/EXP-004/preview.gd第52行、98～102行；dialogue_view.gd第100～105行。

重现：8选D → L → E两次显示确认 → Esc暂停 → 鼠标点击“确认离开并放弃救助”。实际paused=true时，last_choice变为leave，active变false，对话关闭。A/B/C/D与两种分辨率共8例均复现。

原因：toggle_pause只设置对话/卡的paused标记；_process与press会看该标记，但Button.pressed回调不看。暂停覆盖层mouse_filter=IGNORE，GUI输入在_unhandled_input的paused早退之前已到达底下的Button，因此底层状态继续被改变。违反要求5、完成标准1与T7-F“暂停返回后对话状态保持”。

建议：暂停时隔离底层GUI鼠标与焦点输入，并在恢复时还原选项与焦点；或对选择动作增加可靠的暂停约束。回归必须在问句打开时用真实鼠标/键盘/手柄尝试选择，确认暂停中不触发departure_chosen、不关闭对话，恢复后才可以正常选择。当前已验证的是实际鼠标路径；键盘/手柄须由新增回归覆盖，不声称已实测。

## N1（非阻断）：长按加速断言只证明文字变多

tests/smoke_test.gd第87行以held > normal作为加速证据，普通逐字随更多帧流逝也会满足。临时把HOLD_MULTIPLIER由4改成1（完全移除加速）后，原冒烟仍80/0、退出0。当前代码有4倍分支，未认定实际功能缺失；建议使用同样帧数、足够长且未补全的一句，比较普通与持续按住的实际绘制进度，或明确覆盖从完整句按住进入下一句后的加速，不让“单击补全”冒充长按加速。

## 独立检查、探针与变异

固定26cc9ce，源码起点干净：

- 原冒烟：`Godot --headless --path game --fixed-fps 60 --script res://prototypes/EXP-004/tests/smoke_test.gd`，**EXP004_SMOKE checks=80 failures=0，退出0**，无ERROR/WARNING。日志runs/exp004-smoke.txt。
- 只读探针：`Godot --headless --path game --fixed-fps 60 --script ../codexandclaude/runs/exp004_review_probe.gd`，**24项，16失败，退出1**。8次确认已暂停均通过；8次按钮不相交与8次暂停后鼠标不可选均失败。未改原型源码，模拟数据不触碰存档。日志runs/exp004-review-probe.txt；脚本在同目录，不入库。
- 临时变异长按倍率4→1：**80/0，退出0，漏检（N1）**，日志runs/exp004-mutant-hold_speed.txt。
- 临时把实际对白绘制参数改为错误字符串：**80项8失败，退出1**，证明正文断言取自真实绘制返回；日志runs/exp004-mutant-drawn_dialogue.txt。
- 两次变异都在自己固定工作区执行，finally按原字节恢复；恢复后冒烟**80/0、退出0**，git diff --exit-code -- game/prototypes/EXP-004通过，日志runs/exp004-restored.txt。没有修改Claude分支。
- 独立G3：`python codexandclaude/tools/run_checks.py focused --python-all`，**102/102 + 67/67，退出0**；摘要runs/20261022T035138.410516Z/summary.json。
- **本轮未独立跑full/G2**：已发现上述阻断，停止通过/集成流程，不用原冒烟或旧full证明未覆盖的路径正确。任务卡要求的独立完整检查留待修订关闭阻断后完成。交付full的content_stable=False也不能作复用来源，不能据“正式代码无改动”直接宣称已复用G2。

## 后续

只新增本review.md，写入后另跑G3，通过后提交审查记录。修订先接入本固定审查SHA以保留历史，再在原型目录修复R1/R2并更新交付与检查证据；用户选定D、G-08短提示、介绍卡2不变。尚未合入master，也未改任何规划汇总状态。

## 独立G3自动证据

<!-- run_checks evidence v1 -->
总结果：**通过**；模式：`focused`。
被测SHA：`26cc9ce8ad7d178b6b35dbd1717ba3e1f5960edb`；工作区：`D:\31days\codexandclaude\worktrees\codex`。
工作区状态：**干净**。
开始：2026-10-22T03:51:38.410516+00:00；结束：2026-10-22T03:51:54.073544+00:00。

入口命令（JSON参数数组）：`["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\codex\\codexandclaude\\tools\\run_checks.py", "focused", "--python-all"]`。
检查（缺项均不通过；env只代表环境探测，不代表G2/G3）：
- G3:tests：实际102 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。
- G3:codexandclaude/tests：实际67 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。

工具版本：
- python：`3.12.14 / openpyxl=3.1.5`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe`。
- git：`git version 2.56.0.windows.2`；`C:\Program Files\Git\cmd\git.exe`。
- node：`v24.19.0`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe`。

提交树：`af58bc5f53a650ebca3853c3ce31cce16b2c9b4e`；指纹范围：`['exclude codexandclaude/runs/**', 'exclude codexandclaude/tasks/<ID>/{delivery,review,integration,acceptance}.md']`。
已提交范围指纹：`9e961e5bf72adacfff4c8514c4ecdb6550eb54df91d3103463e12dd6df67e393`；工作区范围指纹（原始字节）：`f2a31c561188c7d205c4b42aafec5e80d6c71823a96054e89a0f7a2ac25fed2d`。
全工作区指纹：`a6790a6a990c573e3cae57cb7056b87e2d015cc4d373b391103da6825f74d767`；运行前后内容稳定：`True`。
内容身份说明：起止快照不一致时，检查结果照实保留，但该运行不可作为复用来源；不是对运行期间每次瞬时写入的监控。
已跟踪总diff SHA256：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；未暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。

实际命令与日志（参数为JSON数组）：
- `["C:\\Program Files\\Git\\cmd\\git.exe", "rev-parse", "HEAD"]`；退出=0；耗时=0.015秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261022T035138.410516Z\001.txt`；SHA256=`555550367e6a9b2e2fae4155cee384ac571c1f597e600d7dea42ba8f5bb04bcf`。
- `["C:\\Program Files\\Git\\cmd\\git.exe", "status", "--porcelain", "--untracked-files=all"]`；退出=0；耗时=0.032秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261022T035138.410516Z\002.txt`；SHA256=`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-c", "import sys,openpyxl; print(sys.version.split()[0]); print(\"openpyxl=\"+openpyxl.__version__)"]`；退出=0；耗时=0.297秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261022T035138.410516Z\003.txt`；SHA256=`6d8032bb36596789957df461b308076a9002b5585e5b4d43f8a62b51f0ac622b`。
- `["C:\\Program Files\\Git\\cmd\\git.exe", "--version"]`；退出=0；耗时=0.016秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261022T035138.410516Z\004.txt`；SHA256=`dc0a995f896e73e8fc394cc5dc4d8cabfea65b5eb2db4a40d134dc21c4feb3c0`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\node\\bin\\node.exe", "--version"]`；退出=0；耗时=0.015秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261022T035138.410516Z\005.txt`；SHA256=`bc697de995dc791df53d688ef69c08994cdffc8ce30c906b1ffc65b131ccd0eb`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "tests", "-v"]`；退出=0；耗时=3.219秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261022T035138.410516Z\006.txt`；SHA256=`56123469c3b8b53e4d846e0606cc9589d8fb38273140c76b0e35f51e73d222ba`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "codexandclaude/tests", "-v"]`；退出=0；耗时=10.984秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261022T035138.410516Z\007.txt`；SHA256=`ea9abb2be0e4969d6a19219e5207ed00dad497289079d77d8ffb122187309c77`。

失败清单：无。
失败归因：未提供基线失败证据，不自动区分旧失败与新失败。
复用限制：只比较内容不替代审查/授权；须成功完整且干净、运行前后稳定、范围相同的来源；只改记录时G2可复用，G3必须重跑；另核对工具、命令和外部依赖。
