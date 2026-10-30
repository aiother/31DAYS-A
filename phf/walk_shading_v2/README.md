# 用户附件 · 第 1、7、8 帧腿部亮暗修正

最终图：`walk_sheet_corrected.png`。画幅保留原图 1536×1024，4 列×2 行，单帧 384×512。

本次以用户附件为唯一底图，按用户明确的定义执行：**橙色圆点＝右腿＝亮色外侧；蓝色双线＝左腿＝暗色内侧。** 只修正第 1、7、8 帧两条腿从可见大腿、小腿至靴子的亮暗。第 7 帧蓝色弯腿的膝部与横向小腿也改为暗色，橙色支撑腿保持亮色。

使用 **image_gen 内置工具** 进行明暗编辑，完整提示词、输入顺序和采用区域见 `prompts.json`。第 1、8 帧采用整图编辑结果的腿部片段；第 7 帧采用单独编辑的结果。`scripts/package_phf_shading.cjs` 仅选择并合成生成片段，不自行绘制腿部或计算新的明暗颜色。

保留原图全部透明度像素、原有深色线条和全部橙/蓝标识。修正区域之外的像素直接沿用原图，包含第 2、3、4、5、6 帧，以及第 1、7、8 帧的头发、脸、衣领、披风等上半身。原图和生成来源在 `source/`，合成区域在 `edit_mask.png`、`edit_regions.json`，PNG 文件哈希在 `manifest.json`。

验证直接比较原图与交付图：画幅和透明轮廓逐像素一致、未修改的五帧逐像素一致、上半身及标识一致、全部改动位于指定腿部区域、三帧的右亮左暗关系及明暗修正方向，以及来源和交付文件哈希。

```powershell
node scripts/package_phf_shading.cjs
python -m unittest discover -s tests -p test_phf_shading.py -v
```

依赖 Node.js、`@napi-rs/canvas`、`sharp`，以及 Python/Pillow。Node 包目录可通过 `CODEX_NODE_MODULES` 指定，默认使用当前 Codex 捆绑运行时。
