# HUD 试点基线核对

2026-10-19，游戏代码基线：36d05826ba24eea9423204eaca6de956b48a33af。后续任务准备提交仅变更 codexandclaude/；创建工作区时使用该准备提交的完整 HEAD，双方从相同提交开始。不会把用户未提交文件自动带入新工作区。

## 用户未提交输入（只读核对，原件保留）

| 主工作区文件 | 核对时 SHA256 | 与已提交版本的关系 |
| --- | --- | --- |
| Words/T6_资源配置填写模板.xlsx | e369dff6c5ae147e22cf1ee33781df159a07d5191dbe9a267a943b4b0a8fa727 | 194 个单元格值或公式变化；数据验证规则序列亦不同 |
| Words/T7_UI_UX与存档规格填写模板.xlsx | fa46e8d4b48e69d46fe631c6e5223963d5222934edbe1867ee20864ec96be908 | 91 个单元格值或公式变化；数据验证规则序列一致 |
| game/project.godot | 68e52c624d7a967c902c7e27a5b6ecbb63b86d31d127a729af834085228d9f66 | 存在编辑器重新保存等差异；未为此声明运行行为完全等价 |

表格比较在内存读取 HEAD 与磁盘工作簿，不保存、不重新生成原文件。上述不是对样式、批注和所有 Excel 功能的完整等价审计。未提交输入尚未获得单独提交授权，此次不提交、不覆盖。

## 与本试点相关的 T7 内容

主工作区 T7 的 T7-B HUD信息 E6:E15 已填写生命图标、可能性容器、恢复特效、不提示连续闪避等正式呈现方向；E19 为任务目标显示。它们不等同于当前灰盒实现已经验收。

本次用户明确批准的是既有灰盒 HUD 与错误提示防重叠。暂时保留当前文字及状态语义，修复排版；不把当前文字显示冻结为最终视觉，也不顺带实现图标、容器、特效或任务系统。不改生命、可能性、恢复、药包、日期、存档、输入规则和公开 UI 方法。

此核对摘要使 Claude 知道新填写规格存在，不代表把未提交表格复制进分支。需要读取原表时只读主工作区绝对路径；发现新输入或任务冲突先报告。

## 只读审查的更正

- 实际当前分支为 master，没有已发现的 main 分支。
- game/ui/menus/ 含实际代码，不是空目录。
- HUD 和提示固定坐标、CanvasLayer 层级是代码事实；实际重叠和影响仍须运行复现。
- 登记新的 Godot 套件时，tests/test_verification_runner.py 中两处套件数量断言需同步更新，保持实际文件存在与数量校验，不能删除或放宽校验。

## 工作区与交付状态

Claude：D:\31days\codexandclaude\worktrees\claude-hud，分支 claude/hud-layout-pilot。

Codex：D:\31days\codexandclaude\worktrees\codex-review，分支 codex/hud-layout-review。

这些路径由协调者在准备提交之后创建；以 git worktree list、git status 和 git rev-parse HEAD 验证。工作区不复制未提交表格/配置。主工程仍在 D:\31days；独立工作区只是避免同时改同一份文件，不改变 Claude 对整个项目的职责。

当前尚无 HUD 修复提交、Godot 复现结果或人工视觉验收。不要把本文件的基线检查当成实现完成。

新工作区预检发现：tests/test_game_project.py 的资源存在检查也匹配了 test_air_pursuit.gd 内的输出路径 res://../outputs/pursuit_air.json；全新工作区没有该被忽略的生成文件，因此在未运行对应引擎测试前会出现一项失败。正确顺序为先运行 Godot 测试生成该工作区的真实报告，再运行 Python 检查。不要复制旧报告、创建占位文件或删除断言。协调者进行首次生成时未修改游戏源码。
