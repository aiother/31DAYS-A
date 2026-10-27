# ART-001 集成记录

日期：2026-10-27（America/Los_Angeles）｜集成：Codex｜状态：已完成。

## 授权与合入

用户明确授权将复审通过的固定审查提交 `f8e1c55` 合入 master，并要求先删除主工作区 Words 下两份相同的未跟踪副本。

- 合入前 master：`9bed956bd6ebbe3ba35692fcb6810a6666e28439`。
- 固定审查与合并后被测 SHA：`f8e1c55f40907b0b2446ee5229871729c2a9ce33`。
- 修复实现：`aba620b76b4af77c7ba2d2461f2207cece1454da`；交付：`7f52ba76d2e6fc863c0a02604219c52155f75c86`。
- 在主目录执行 `git merge --ff-only f8e1c55f40907b0b2446ee5229871729c2a9ce33`，成功快进。没有改动已审实现或测试。

## 主目录保护

确认两份文件未被 master 跟踪，并与固定审查提交所在工作区的干净检出文件逐字节相同，再仅删除这两个指定副本：

| 文件 | 检出字节 SHA256 |
| --- | --- |
| `Words/怪物设定.md` | `20badfec7004fd551cd0ddb0c5abf98e0adaf6437c1d36c838ae6ed2bc6bc797` |
| `Words/阶层设定.md` | `0ae95f0636cbdd6e106d415a95ba9182c5cab9ef3d3d1dde72bbcecfe58da9cc` |

Git blob 与 Windows 检出字节的换行不同，最初的严格 blob 比较未通过，保护性停止，未删除；随后按干净审查工作区的实际检出字节核验通过后才删除。首次合并因副本仍在而安全中止；未发生覆盖。合并后两份文件均已成为受跟踪文件。

现有 `.claude/` 与 `assets_src/` 内容全部保留；合入的 `/assets_src/` 忽略规则生效。未提交用户其他文件，未清理目录。合并后普通 Git 状态仍显示既有未跟踪 `.claude/`；检查工具的内容快照排除此类本地配置，报告 dirty=False，不将其表述为整个主目录没有本地文件。

## 检查

合并后 master 运行 `python codexandclaude/tools/run_checks.py focused --python-all`：退出 0，G3 `tests` **129/129**、协作测试 **67/67**，完整且无跳过，`content_stable=True`。被测 SHA 为上述固定审查 SHA；完整命令、版本、指纹与日志哈希附后。原始证据位于 `codexandclaude/runs/20261027T084453.168390Z/`，不入库。

本任务为风格、规格与提示词交付，样张工具在非游戏运行路径；按任务卡与纯文档检查矩阵运行 G3，本次不重跑 G2，也不把实现者既有 G2 当作本次运行。用户 2026-10-27 已定稿风格，本轮明确授权合并。

前一次因合并中止而运行在旧 master `9bed956` 的检查不作为本次合并后证据。

收尾只更新本任务首部状态并新增此记录，提交前再跑完整 G3 验证。BOARD/BACKLOG 由 Claude 按协作规范后续刷新；登记规则与七列不变，ENV-008 可继续按此接口实施。

## 合并后自动证据

<!-- run_checks evidence v1 -->
总结果：**通过**；模式：`focused`。
被测SHA：`f8e1c55f40907b0b2446ee5229871729c2a9ce33`；工作区：`D:\31days`。
工作区状态：**干净**。
开始：2026-10-27T08:44:53.168390+00:00；结束：2026-10-27T08:45:09.790674+00:00。

入口命令（JSON参数数组）：`["C:\\Users\\Administrator\\AppData\\Local\\Programs\\Python\\Python310\\python.exe", "D:\\31days\\codexandclaude\\tools\\run_checks.py", "focused", "--python-all"]`。
检查（缺项均不通过；env只代表环境探测，不代表G2/G3）：
- G3:tests：实际129 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。
- G3:codexandclaude/tests：实际67 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。

工具版本：
- python：`3.12.14 / openpyxl=3.1.5`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe`。
- git：`git version 2.56.0.windows.2`；`C:\Program Files\Git\cmd\git.exe`。
- node：`v24.22.1`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe`。

提交树：`ea44fa773013ad485784adcd0babcc33b50c0ce7`；指纹范围：`['exclude codexandclaude/runs/**', 'exclude codexandclaude/tasks/<ID>/{delivery,review,integration,acceptance}.md']`。
已提交范围指纹：`036b028474d1c849bae46c662ed35252cadaf467a84cb3671cf4faa60d4f6b18`；工作区范围指纹（原始字节）：`225bc4522e8e9179cf89e7b464e9a9e559b8303ac5046ec3fb9ccc49672b0439`。
全工作区指纹：`87d5e6dc4382ae5c4dceac89648e60ffde7d7b2ea498369a9aa199bd33652c56`；运行前后内容稳定：`True`。
内容身份说明：起止快照不一致时，检查结果照实保留，但该运行不可作为复用来源；不是对运行期间每次瞬时写入的监控。
已跟踪总diff SHA256：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；未暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。

实际命令与日志（参数为JSON数组）：
- `["C:\\Program Files\\Git\\cmd\\git.exe", "rev-parse", "HEAD"]`；退出=0；耗时=0.015秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261027T084453.168390Z\001.txt`；SHA256=`be771c5130c6e61fc1997af127cc067afbd27e21a7482e413d705b79061aaa57`。
- `["C:\\Program Files\\Git\\cmd\\git.exe", "status", "--porcelain", "--untracked-files=all"]`；退出=0；耗时=0.25秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261027T084453.168390Z\002.txt`；SHA256=`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-c", "import sys,openpyxl; print(sys.version.split()[0]); print(\"openpyxl=\"+openpyxl.__version__)"]`；退出=0；耗时=0.312秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261027T084453.168390Z\003.txt`；SHA256=`6d8032bb36596789957df461b308076a9002b5585e5b4d43f8a62b51f0ac622b`。
- `["C:\\Program Files\\Git\\cmd\\git.exe", "--version"]`；退出=0；耗时=0.015秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261027T084453.168390Z\004.txt`；SHA256=`dc0a995f896e73e8fc394cc5dc4d8cabfea65b5eb2db4a40d134dc21c4feb3c0`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\node\\bin\\node.exe", "--version"]`；退出=0；耗时=0.016秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261027T084453.168390Z\005.txt`；SHA256=`b8a527ca60b496131eccd1fcbeccf289ebc0a7e63be57e4b4c6f8f67648bcc07`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "tests", "-v"]`；退出=0；耗时=3.265秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261027T084453.168390Z\006.txt`；SHA256=`a7a91ef5bdfad01200da50a7c41fcd9aee08d05e3cd6bb44e000dde283f73a7d`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "codexandclaude/tests", "-v"]`；退出=0；耗时=11.344秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261027T084453.168390Z\007.txt`；SHA256=`097e8b94ad2be9e0f0b0c8a41742b09126a9c26cdc06834edfd07d90e311ae59`。

失败清单：无。
失败归因：未提供基线失败证据，不自动区分旧失败与新失败。
复用限制：只比较内容不替代审查/授权；须成功完整且干净、运行前后稳定、范围相同的来源；只改记录时G2可复用，G3必须重跑；另核对工具、命令和外部依赖。

