# ENV-008 交付

实现：Codex｜审查：Claude｜基线：`cc42d356d54b19c3ed7ef7d0b9bf2a0919f486d7`｜分支：`codex/ENV-008`｜工作区：`codexandclaude/worktrees/codex`

**实现 SHA：`f2ed760`**。该提交含检查工具、测试、现有素材登记与任务卡进行中状态；后续只追加本记录并把任务卡改为待审查。未经交叉审查和用户授权，不合并 master，不推送任务分支。

## 改动与复现

- 新增 `codexandclaude/tools/check_assets.py`：可独立执行，也由 G3 的 `tests/test_asset_registry.py` 实际检查仓库。只读，不下载、不生成素材、不修改索引或导入。
- 沿用 ART-001 的七列表格，补齐字体与两张灰盒 SVG 共三行。取得日期来自字体 README/提交记录及灰盒基线；保留 OFL 版权与授权文件。
- 检查全部素材（未知扩展名也登记），精确排除说明、授权文本、Godot 自建资源和生成记录；重复、缺失、越界/非规范路径、无来源、日期或改动说明有误均给出文件及原因。
- 授权识别先做 Unicode/大小写归一，拒绝 NC、ND、拼接/下划线/全角、NonCommercial/NoDerivatives/NoDerivs 及中文常见形式，再使用 ART-001 的允许授权集合；CC-BY 须署名。AI 备注核对工具、日期、套餐、提示词字段，日期与日期列一致。
- `.gitignore` 已有 `/assets_src/`，保持原样；实际执行 `git ls-files` 拒绝已跟踪收件箱文件，并用 `git check-ignore --no-index` 验证忽略规则，防止只检查文件当前是否忽略而漏掉强制入库。
- PNG 检查要求 characters/environments 下每张图有 `.import`、source_file 匹配且 mipmaps/generate=false；同时核对 2D 项目默认线性过滤。Godot 4 的过滤不在图片 `.import` 中，依据 ProjectSettings 官方文档：`https://docs.godotengine.org/en/4.6/classes/class_projectsettings.html`。当前项目未显式设置该项，引擎默认值 1 即 Linear，本次不改 project.godot 或导入文件。

改前只有空登记表、没有自动检查；改后真实仓库三行均通过。新增 11 项测试覆盖任务卡所有失败场景，以及未知素材类型、路径、无效日期、伪装为 README 的图片、错误来源导入与坏表格。纯夹具 PNG 用于检查元数据，不是生产素材或动作帧。

## 检查证据

- `python codexandclaude/tools/run_checks.py focused --python-module tests.test_asset_registry`：**11** 项通过。
- `python codexandclaude/tools/run_checks.py focused --python-all`：**199 + 83 = 282** 项全部通过，内容稳定。被测为 cc42d35 加本实现的四个文件；提交 f2ed760 与被测文件一致。摘要：`codexandclaude/runs/20261031T044823.397081Z/summary.json`。
- 工具：Python 3.12.14 / openpyxl 3.1.5、Node v24.22.1、Git 2.56.0.windows.2。
- 三项变异分别临时将 NC/ND 拒绝改为通过、删除未登记报错、删除已跟踪收件箱报错，分别运行对应 unittest 方法，三项均出现断言失败，随后按原始字节还原。日志：`codexandclaude/runs/env008-mutation-{nc,unregistered,inbox}.txt`。首次未登记变异命令误写测试名，未形成有效证据，随后修正并重跑三项。
- `git diff --cached --check` 通过。当前没有角色/环境 PNG，导入失败场景由临时夹具实际覆盖；未修改任何导入设置，按本任务卡只需 G3，未跑 G2。

## 限制与复核

自动检查验证登记信息与项目默认/PNG 导入设置，不能证明外部供应者授权描述属实。场景或脚本覆写 CanvasItem.texture_filter 的情况由具体素材接入任务复核；本任务未扫描任意运行时脚本推断过滤。AI 工具/套餐/提示词只核对已填写，不验证账号权益；公开发布前仍须按 T6 复核。

Claude 请固定本交付提交，先确认与 f2ed760 的差异只有记录及任务卡状态，再复跑 G3、重点核对授权识别和排除范围。无 G4 需求。回滚：对实现和交付记录使用 git revert。
