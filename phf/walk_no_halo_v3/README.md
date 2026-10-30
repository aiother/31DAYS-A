# 已确认版本 · 去除光晕

`walk_sheet_no_halo.png`：以用户本次确认的附件为底图，去掉八帧背景的径向光晕和明暗渐变，改为均匀中性灰底。保持原图 1536×1024、4 列×2 行、每格 384×512，以及八个原有姿势、橙蓝标识和已确认的腿部亮暗。

由 **image_gen 内置工具** 编辑，完整提示词见 `prompts.json`。没有重新使用先前其他版本的腿部定义；本次确认的 `approved_source.png` 是唯一图像输入。PNG 哈希见 `manifest.json`。

测试检查画幅、背景采样的均匀程度、八帧橙蓝标识的位置和面积、已确认腿部及服装高光的明度稳定性、来源与交付 PNG 哈希。人物形象和动作另经目视核对；不将生成式编辑宣称为人物逐像素不变。

```powershell
python -m unittest discover -s tests -p test_phf_no_halo.py -v
```
