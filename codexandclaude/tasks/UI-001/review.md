# UI-001 审查记录

审查者：Codex｜日期：2026-10-20（America/Los_Angeles；UTC为2026-10-21）｜结论：**通过，无阻断项**。

## 固定对象与范围

- 已执行 git switch --detach 固定交付 `89687e874f59df03f95f65ba81c278f02464c9c7`；实现 `ed02593025142a12adb8445d2fa95e39c19cbc47`，基线 `e3c6142233d59810f3ab2a04c40031dd6c47b162`。审查分支从交付建立，不混入SYS-005。
- 实现到交付只有delivery.md和任务卡首部状态。正式新增仅style模块、字体与授权、样式测试及一项协作检查，符合批准范围。
- 用户指定的零差异命令 `git diff --stat e3c6142 ed02593 -- game/ui/menus game/project.godot game/world game/player` 输出为空。原型目录未改；新主题没有注册为项目默认，既有界面未引用新模块；运行时构建的Theme本身是Godot资源，UiTheme.get_theme()可供正式界面显式套用。

## 重点核对

| 项目 | 结论 |
| --- | --- |
| 用户选定样张二 | 色板、PANEL_ALPHA=0.78、墨线1.7、抖动0.7、纸纤维8及玻璃/渐变/呼吸等公式与原型样张二一致；删除样张一切换而未改变选定方向 |
| 随日期变化 | DAY_RANGE沿用样张二，第1日起点0，日内夹到0～1，最终战dusk=1；关键色为常量，不随日期混色 |
| 最终战光晕70% | 同黄昏程度的glow_strength只乘0.7；未把缩减应用到纸色、玻璃或边缘晚霞 |
| SYS-005接口 | 三个输入键day:int、day_progress:float、final_active:bool与已合入master的ui_time_state一致；额外字段被忽略；未选槽day=0被夹到第1日清晨；不依赖会话类或另造时钟 |
| 字体 | 正式与原型TTF逐文件SHA256相同：`2D73EEA94AD808999D90C0000C239A84A33B09D4BC6AB6C5B8BBF1EDA8A7FC8B`；25,928,940字节，没有裁剪或安装依赖 |
| 授权 | 完整版权及OFL1.1在字体旁；Git原文5171字节、SHA256 `1A25E35DA1031C6C3436FDE545BB9CB5ACA954E9873AFE510C834B8B79BD21A0`，与README一致；CRLF检出为5265字节、原始SHA256 `CB973995026E28C931886A1D127397152187E03E53B2F71864E86CEE8C25E54A`，归一LF后与原文一致 |
| 共用绘制可执行 | 忽略目录的CanvasItem探针在实际_draw调用DuskStyle.panel与InkDraw的线、圆、纸盘、光晕、渐变，drawn=true，退出0，无ERROR/WARNING；不只是读取常量 |

已核对[上游v1.530授权原文](https://raw.githubusercontent.com/lxgw/LxgwWenKai/v1.530/OFL.txt)与[OFL官方FAQ](https://openfontlicense.org/ofl-faq/)。保留字体名包括霞鹜、霞鶩、落霞孤鹜、落霞孤鶩、LXGW。游戏用字裁剪属于修改，不能默认套用“仅网页字体分发”的额外许可；因此未来裁剪须更改受保留名称限制的主字体名，当前完整未修改字体可保留原名。README有两处表述可更精确，见非阻断N1。

## 测试及独立变异

原样及变异恢复后的样式专项均19/19；四项临时变异逐一按原始字节恢复：

| 变异 | 19项中的失败数 |
| --- | --- |
| 可能性关键色改为红色 | 1 |
| 最终战光晕不乘0.7 | 1 |
| dusk整个函数恒为0 | 7 |
| 主题字体改为ThemeDB.fallback_font | 1 |

本次恒0变异具体替换整个dusk函数体，故失败数与交付记录所列6项不必相同；四类缺陷均被拦截，未放宽断言。结果在runs/ui001-review-mutations.json及ui001-mutation-*.txt；没有保留变异。

独立full在固定交付、干净工作区启动：G2 77/77，G3 102/102 + 66/66，完整、通过；包含编辑器导入和主场景180帧，无错误、泄漏或超时。该分支不含SYS-005新增套件，因此不是两任务合并后的计数。

导入导致.import纯行尾变化，逐文件ignore-space-at-eol检查后显式恢复；工具保留content_stable=False，不能作未来复用来源，没有引用Claude的摘要替代本轮独立full。完整自动证据如下。

<!-- run_checks evidence v1 -->
总结果：**通过**；模式：`full`。
被测SHA：`89687e874f59df03f95f65ba81c278f02464c9c7`；工作区：`D:\31days\codexandclaude\worktrees\codex`。
工作区状态：**干净**。
开始：2026-10-21T03:39:46.980639+00:00；结束：2026-10-21T03:53:31.938032+00:00。

入口命令（JSON参数数组）：`["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\codex\\codexandclaude\\tools\\run_checks.py", "full", "--jobs", "4"]`。
检查（缺项均不通过；env只代表环境探测，不代表G2/G3）：
- G2：实际77 / 预期77；完整=True；通过=True。
- G3:tests：实际102 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。
- G3:codexandclaude/tests：实际66 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。

工具版本：
- godot：`4.7.2.stable.official.ed1daf0bf`；`D:\DMyself\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`。
- python：`3.12.14 / openpyxl=3.1.5`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe`。
- git：`git version 2.56.0.windows.2`；`C:\Program Files\Git\cmd\git.exe`。
- node：`v24.19.0`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe`。

提交树：`76d2ec35bb49edd9bbb892cafc51a2eab783383f`；指纹范围：`['exclude codexandclaude/runs/**', 'exclude codexandclaude/tasks/<ID>/{delivery,review,integration,acceptance}.md']`。
已提交范围指纹：`39bd387a432278d29b74e07234f21a955fdfc300c9e698bb1f2b1fdd4844efbd`；工作区范围指纹（原始字节）：`7b74223ee7a9ad6edfbaa9a6cdee65437a708bd19fddd05268e6938d01a350ad`。
全工作区指纹：`7f4dce2d71cfbc344fc2379c3261dc8c903ab6dbe07bcad5e7c795eebc2423bd`；运行前后内容稳定：`False`。
内容身份说明：起止快照不一致时，检查结果照实保留，但该运行不可作为复用来源；不是对运行期间每次瞬时写入的监控。
已跟踪总diff SHA256：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；未暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。

实际命令与日志（参数为JSON数组）：
- `["C:\\Program Files\\Git\\cmd\\git.exe", "rev-parse", "HEAD"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261021T033946.979639Z\001.txt`；SHA256=`6f009f94bef31169e4902e5b2de46dfbcffac79d4045180d9d68472e68a48264`。
- `["C:\\Program Files\\Git\\cmd\\git.exe", "status", "--porcelain", "--untracked-files=all"]`；退出=0；耗时=0.032秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261021T033946.979639Z\002.txt`；SHA256=`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。
- `["D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--version"]`；退出=0；耗时=0.047秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261021T033946.979639Z\003.txt`；SHA256=`bf8803022b574250bb04dea65053a46b7c58570725316c1f7fe2aa6735706498`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-c", "import sys,openpyxl; print(sys.version.split()[0]); print(\"openpyxl=\"+openpyxl.__version__)"]`；退出=0；耗时=0.375秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261021T033946.979639Z\004.txt`；SHA256=`6d8032bb36596789957df461b308076a9002b5585e5b4d43f8a62b51f0ac622b`。
- `["C:\\Program Files\\Git\\cmd\\git.exe", "--version"]`；退出=0；耗时=0.015秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261021T033946.979639Z\005.txt`；SHA256=`dc0a995f896e73e8fc394cc5dc4d8cabfea65b5eb2db4a40d134dc21c4feb3c0`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\node\\bin\\node.exe", "--version"]`；退出=0；耗时=0.016秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261021T033946.979639Z\006.txt`；SHA256=`bc697de995dc791df53d688ef69c08994cdffc8ce30c906b1ffc65b131ccd0eb`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\codex\\scripts\\verify_game.py", "--godot", "D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--project", "D:\\31days\\codexandclaude\\worktrees\\codex\\game", "--report", "D:\\31days\\codexandclaude\\worktrees\\codex\\codexandclaude\\runs\\20261021T033946.979639Z\\engine.txt", "--jobs", "4"]`；退出=0；耗时=809.094秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261021T033946.979639Z\007.txt`；SHA256=`4e68e052f90e720f1bff8410502fcbac031fbb976c99e42f61a8005c0df44aad`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "tests", "-v"]`；退出=0；耗时=3.328秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261021T033946.979639Z\008.txt`；SHA256=`63118fa6c39db5dc0c42be1d10e3e329505521e27e8f7fbb1c0463db1f5b38f4`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "codexandclaude/tests", "-v"]`；退出=0；耗时=10.719秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261021T033946.979639Z\009.txt`；SHA256=`b304aadece99420d08390773c6b6b951fcb2cead2abdb2acdc552e107e43cb7b`。
- 报告 `D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261021T033946.979639Z\engine.txt` SHA256=`70455d666f96eeba08173aac8cdb93502b37cf053d92182618f77fae7c2109e6`。

失败清单：无。
失败归因：未提供基线失败证据，不自动区分旧失败与新失败。
复用限制：只比较内容不替代审查/授权；须成功完整且干净、运行前后稳定、范围相同的来源；只改记录时G2可复用，G3必须重跑；另核对工具、命令和外部依赖。


## 非阻断建议

N1：fonts/README.md的授权要点建议区分强制条款和项目习惯。OFL第3条限制的是向用户展示的主字体名；重命名字体文件是避免混淆的合理做法，但不是该条单独规定的必改对象。随包提供版权与授权有明确要求，在制作人员名单或关于页鸣谢则可作为项目建议，不宜表述为OFL额外强制要求。游戏字体裁剪须改受限主名的结论仍成立，本次未裁剪，不阻断当前交付。

N2：README中的OFL哈希建议注明是原下载/Git原文的LF字节；Windows CRLF检出后直接Get-FileHash得到另一个值。当前已用Git原文及归一LF双重核对，没有授权文件被替换或缺失。

## 日志身份与交接

- runs/ui001-review-import.txt SHA256：`296d60fccaa68301027baa6d3b2f926182ecb3e7b2693889571363e0c907cb2b`。
- runs/ui001-review-g1.txt SHA256：`874e9e0d65c820673a19dc2a0ef9cac890648d28f13031f8edfc060b9922b5de`。
- runs/ui001-review-restored-g1.txt SHA256：`874e9e0d65c820673a19dc2a0ef9cac890648d28f13031f8edfc060b9922b5de`。
- runs/ui001-review-mutations.json SHA256：`754a5fdcc7a20aad75fc447d5ff00beea4dc5537a179f9805af23a5facec5f15`。
- runs/ui001-draw-probe.txt SHA256：`ddcdaba202f730ccb023852ab117e911107820f7445d54302c48d20b6189f7fa`。

按任务卡不需要G4（没有现有界面可见变化），后续样式效果在UI-002验收。当前通过，无需修订后复审；上述建议可由规划方后续处理。本审查提交仅新增review.md。UI-001合并仍需用户授权，本轮没有合并UI-001。
