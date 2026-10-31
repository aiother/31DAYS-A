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

## 第 2 轮交付（2026-10-31）

本节为现行交接，以上保留第 1 轮历史。分支先从 313b6dd 快进至 Claude 审查提交 `8602fafe507b09091f2681e3acef0fe2aa27f130`，保留 review.md。**第 2 轮实现 SHA：`14510f2`**；交付提交只追加本节，不再修改任务卡或代码。

### 审查项与修复

- R1：接受规则改为对完整授权字段做 NFKC + casefold（首尾空白去除），整体匹配固定白名单或带版本的 CC-BY 格式：主版本为一位数字，可附点号与一位次版本；cc、by 与版本之间各允许一个空格、下划线或连字符。不再通过删除非 ASCII 字符构造可接受标签，因此中文和英文后缀一律不能被吞掉。中文说明没有额外限制的情况也须放备注，不另开例外。
- NC/ND 匹配仅改善拒绝理由，连写许可使用限定的 CC-BY-NC/ND 前缀模式，单词按边界识别，避免把 Candy/Fonds 内部的 nd 当作限制。未知附加说明返回“未知或不允许”，不会由它们取得授权。
- N1：错误提示注明白名单格式、CC-BY 须写版本号及 CC-BY-4.0 示例；支持建议正则中的整数版本（如 CC BY 3）。
- N2：CREDITS.md 已说明白名单之外的授权须先经用户批准再扩充。本次没有加入 CC-BY-SA、MIT 或 Apache-2.0。
- 同步 AI 元数据校验也使用归一化标签，确保新允许的大小写/全角 AI 标签仍强制核对工具、生成日期、套餐、提示词。

实际修改四个文件：check_assets.py、test_asset_registry.py、CREDITS.md、ENV-008/task.md 首部。未改导入设置、项目默认、游戏代码、登记范围或收件箱检查。

### 回归与变异

- 新增 4 项测试。修复前运行这四项产生 24 个子断言失败，包含审查给出的五种中文后缀、Candy 误判以及新的归一化格式要求。
- 修复后 `python codexandclaude/tools/run_checks.py focused --python-all`：**203 + 83 = 286** 项全部通过，`content_stable=true`。被测 8602faf 加本轮四个未提交文件，内容与 14510f2 一致；摘要 `codexandclaude/runs/20261031T083250.128291Z/summary.json`。
- 工具：Python 3.12.14 / openpyxl 3.1.5、Node v24.22.1、Git 2.56.0.windows.2。
- 三项独立变异：恢复丢弃非 ASCII 后缀的 CC-BY 接受规则；恢复将 compact 内部 nd 判为限制；恢复只对原始大写 AI 标签检查元数据。各自对应测试均断言失败，finally 按原始字节还原。日志：`codexandclaude/runs/env008-r2-{suffix,candy,ai}.txt`。
- 本交付记录追加后再跑完整 G3，要求仍为 203 + 83 全通过，交付前核对通过才提交。本任务未改变导入或引擎行为，按任务卡未跑 G2。
- 交付记录首次检查被现有 Markdown 链接测试将内联正则误读为链接，已将本节正则改为文字说明，再完整重跑 G3；没有改动链接检查工具。

Claude 请固定第 2 轮交付提交，确认与 14510f2 仅 delivery.md 有差异后复审。重点复测完整标签白名单、五个中文后缀拒绝、Candy 的正确错误类型及归一化 AI 的元数据约束。未合并、未推送；SYS-013 的通过版本未修改，继续等待用户 G4；ART-003 未生成动作帧。
