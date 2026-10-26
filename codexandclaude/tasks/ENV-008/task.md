# ENV-008：素材登记与导入检查

状态：待批准（2026-10-25 起草）｜级别：M｜实现：Codex｜审查：Claude
工作区：worktrees/codex｜基线：本任务卡合入后的 master 最新提交（实现者在交付记录中写明完整 SHA）｜依赖：PLN-003（素材决定文件入库）；与 ART-001 并行，`CREDITS.md` 列格式两卡交付前对齐

## 目标

M3 开始后会有大量外来与 AI 生成素材进入仓库。用自动检查保证每个素材都有来源登记、授权可用，原始大图不进 Git，导入设置统一，避免以后公开前逐个补查。

## 依据

- `Words/T6_素材来源与规格决定.md` 第 2.1 节（授权与来源登记：优先 CC0 / 免版税可商用；不用 NC、ND；CC-BY 须登记署名；AI 素材登记工具、套餐、日期、提示词）、第 2.2 节（收件箱在 `game/` 之外，原图建议不入库）、第 4.1 节（PNG RGBA、线性过滤、2 倍交付 0.5 显示）。
- 现有素材：`game/assets/` 下的字体（LXGW WenKai，OFL）、两张灰盒 SVG。
- 现有检查工具：`codexandclaude/tools/run_checks.py`、G3 测试目录。

## 要求

1. **登记表格式**：`game/assets/CREDITS.md` 为 Markdown 表，列至少包括：文件路径、来源（网址或工具名）、授权、作者 / 署名、日期、是否改动、备注（AI 套餐等）。与 ART-001 对齐列名后固定。
2. **登记检查**（G3）：
   - `game/assets/` 下每个素材文件（排除 `.import`、`.gitkeep`、`CREDITS.md` 与说明文件）都在登记表有且只有一行；登记表中的路径都存在；
   - 授权一栏不得为 NC、ND 类（大小写与“-NC”“NonCommercial”等写法都要识别）；为 CC-BY 类时署名不能为空；为 AI 生成时备注须有工具与日期；
   - 失败信息写明文件与原因。
3. **收件箱不入库**：收件箱目录（按 ART-001 定的位置，默认 `assets_src/`）写入 `.gitignore`；检查拒绝已跟踪的收件箱文件。
4. **导入默认**：`game/assets/characters/`、`environments/` 下 PNG 的导入设置统一为线性过滤、无 mipmap（或按 ART-001 规格）；检查导入文件与规格一致，或提供一次性设置脚本并在检查中验证。
5. **现有素材补登记**：字体（OFL）、两张灰盒 SVG（自制）补入登记表，使检查在当前 master 通过。

## 允许修改的文件

- `game/assets/CREDITS.md`（与 ART-001 对齐格式；本任务只补现有素材行）。
- `.gitignore`；`codexandclaude/tools/` 下新增或扩展检查；`tests/` 或 `codexandclaude/tests/` 新增测试。
- 导入设置（`.import` 或项目导入默认值）只限 `game/assets/` 范围。
- `codexandclaude/tasks/ENV-008/task.md`（只更新首部状态）、`delivery.md`（新增）。

## 完成标准

1. 检查在当前 master 通过；测试覆盖：未登记文件、登记了不存在的文件、重复登记、NC / ND 授权、CC-BY 缺署名、AI 缺工具或日期、已跟踪的收件箱文件、导入设置不符，各自失败且信息清楚。
2. 变异检查至少包括：放过 NC、放过未登记文件、放过收件箱文件，相应测试失败。
3. G3 通过；若改了导入设置，G2 通过。

## 检查

- G3：`python codexandclaude/tools/run_checks.py focused --python-all`；改导入设置时跑 full。
- 审查重点：授权识别是否有漏网写法；检查范围是否误伤代码生成的资源或字体说明文件。

## 回滚方案

`git revert` 本任务提交即可。

## 不在范围内

- 风格说明与规格正文（ART-001）；实际素材的生成与接入。
