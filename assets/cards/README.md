# 卡图放这里

## 命名约定

**一张卡的图 = `assets/cards/<卡牌 id>.png`**

例如：

```
assets/cards/footman.png     ← 卡 id 是 "footman"
assets/cards/tank.png        ← 卡 id 是 "tank"
assets/cards/fire_bolt.png   ← 卡 id 是 "fire_bolt"
```

卡 id 就是 `data/tables/cards.json` 里那个 `"id"` 字段。
`src/ui/card_view.gd` 的 `art_path_of()` 负责拼这个路径。

## 想用别的文件名？

在 `cards.json` 那张卡里加一个 `"image"` 字段，写路径就行：

```json
{ "id": "tank", "name": "坦克", ..., "image": "res://assets/cards/my_tank_art.png" }
```

（相对路径也认，会自动补 `res://`。）

## 没放图会怎样

不会报错、不会崩。卡面会显示一个占位框，框里写**期望的文件名**（如 `tank.png`），
完整路径放在鼠标悬停提示里 —— 作者一眼就知道该往哪放文件，又不会被长路径挤成三行。

## 尺寸建议

- 卡图区大致比例 **4:3 ~ 3:4** 之间都能看，`CardView` 用的是
  `STRETCH_KEEP_ASPECT_COVERED`（等比铺满、超出部分裁掉，不变形）。
- 建议 **≥ 512px 宽**，否则放大后会糊。
- PNG 带透明通道没问题。

## ⚠️ 新放进来的图片需要引擎导入

Godot 的 `res://` 资源要先被导入（生成 `.godot/imported/` 里的缓存），
`ResourceLoader.exists()` 才会返回 `true`。两种办法：

```bat
:: 1) 命令行导入（不改工程，最省事）
"%GODOT%" --headless --path . --import

:: 2) 或者用编辑器打开项目一次
"%GODOT%" --path .
```

没导入时卡面仍显示占位框 —— 不是 bug，是图片还没进缓存。

## 版权提醒

**不要直接把商业游戏的卡图（KARDS 等）抠下来放进项目。**
那是受版权保护的素材，尤其这个仓库如果以后公开发布/发版，
会留下法律风险。自己画、用买过授权的素材、或用 CC0 图库都可以。

卡面的**版式**（费用徽标位置、卡图区、攻防数字布局）借鉴 KARDS 的结构是没问题的
—— 版式属于设计思路，不属于可版权化的表达。**素材文件不能照搬。**
