# 素材来源登记

`game/assets/` 下每个素材文件都在下表登记一行（`Words/T6_素材来源与规格决定.md` 第 2.1 节）。接入素材的人在同一提交里登记；ENV-008 的检查在 G3 中逐项核对。

## 登记范围

- 需要登记：`game/assets/` 下的素材文件，包括 `png`、`jpg`、`jpeg`、`webp`、`svg`、`ttf`、`otf`、`wav`、`ogg`、`mp3`；未知格式也须登记，不因扩展名而漏检。
- 不登记：Godot 生成的 `.import`、`.uid`；`.gitkeep`；本文件；说明与授权文本（`README.md`、`OFL.txt`、`LICENSE*`）；项目自建的 Godot 资源（`.tres`、`.tscn`、`.gd`，如动画资源与骨骼场景，它们引用的图片照常登记）。
- 素材收件箱 `assets_src/`（仓库根目录）不入库，不在本表登记；素材处理后放进 `game/assets/` 时再登记。

## 列与填写规则

| 列 | 填写 |
| --- | --- |
| 文件 | 相对 `game/assets/` 的路径，用反引号，例如 `` `characters/player/parts/player_part_head.png` `` |
| 来源 | 网址，或工具 / 做法：`GPT Image 2`、`Claude 代码绘制`、`自制` 等 |
| 授权 | 只能是下列之一：`CC0`、`CC-BY-4.0`（或其他 `CC-BY-x.x`）、`OFL-1.1`、`免版税可商用`、`AI 生成`、`自制`。**禁止**任何 NC（禁止商用）或 ND（禁止改编）类授权 |
| 作者 / 署名 | 授权为 `CC-BY-*` 时必填署名原文；其余可填 `—` |
| 日期 | 取得或生成日期，`YYYY-MM-DD` |
| 改动 | `否`，或 `是：` 加简述（裁切、去背、缩放、拆层、调色、剪辑等） |
| 备注 | 授权为 `AI 生成` 时必填 `工具：…；日期：YYYY-MM-DD；套餐：…；提示词：<提示词文件路径>`；日期与日期列一致，其余可填 `—` |

## 登记表

| 文件 | 来源 | 授权 | 作者 / 署名 | 日期 | 改动 | 备注 |
| --- | --- | --- | --- | --- | --- | --- |
| `characters/player_placeholder.svg` | 自制（项目代码绘制，灰盒基线 `142a032`） | 自制 | 项目自制 | 2026-10-14 | 否 | 灰盒占位角色 |
| `environments/gray_tile.svg` | 自制（项目代码绘制，灰盒基线 `142a032`） | 自制 | 项目自制 | 2026-10-14 | 否 | 灰盒瓦片 |
| `fonts/LXGWWenKai-Regular.ttf` | https://github.com/lxgw/LxgwWenKai/releases/download/v1.530/LXGWWenKai-Regular.ttf | OFL-1.1 | LXGW；The Klee Project Authors（完整版权见 OFL.txt） | 2026-10-20 | 否 | v1.530；未裁剪；随包附 fonts/OFL.txt，下载依据见 fonts/README.md |

## 自动检查（ENV-008）

`python codexandclaude/tools/check_assets.py`；G3 的 `tests/test_asset_registry.py` 同样执行实际仓库检查。只核对登记与配置，不替代公开发布前的授权复核。

Godot 4 的线性过滤来自项目默认 `rendering/textures/canvas_textures/default_texture_filter=1`（未设置时引擎默认同为 1），不是图片的 `.import` 选项；若项目默认改成最近邻，检查失败。characters/environments 下每张 PNG 必须有已导入的 `.import`，其中 `mipmaps/generate=false` 且 `source_file` 与图片一致。场景或脚本主动覆盖 CanvasItem 过滤的情况由接入任务复核。本次未修改导入或项目设置。
