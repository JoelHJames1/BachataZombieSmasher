# Main Menu — known-good layout

Snapshot of the working menu values as of the user's "perfect" confirmation.
Restore from this file if the menu is ever broken again.

## File: `ZombieSmasher/Scenes/MainMenuScene.swift`

### Background
```swift
let bg = SKSpriteNode(imageNamed: AssetCatalog.menuBackground)
bg.zPosition = 0
let scale = max(size.width / bg.size.width, size.height / bg.size.height)
bg.setScale(scale)
bg.position = .zero
addChild(bg)

let dim = SKSpriteNode(color: .black.withAlphaComponent(0.15), size: size)
dim.zPosition = 1
addChild(dim)
```

### Logo (animated bachata sprite)

**Important:** scale by **height**, not width — keeps the size stable when the
asset pipeline changes the cell aspect ratio after a source-asset update.

```swift
let frames = AssetCatalog.menuLogoFrames()
let logo = SKSpriteNode(texture: frames.first)
let maxH = size.height * 0.32
logo.setScale(maxH / logo.size.height)
logo.position = CGPoint(x: 0, y: -size.height * 0.02)
logo.zPosition = 10
addChild(logo)

if !frames.isEmpty {
    logo.run(.repeatForever(.animate(with: frames, timePerFrame: 0.25)))
}
```

The y of `-size.height * 0.02` puts the character's feet near the painted
road surface, so he looks like he's dancing on the street.

### Start button (custom drawn, green with white)
```swift
let btnSize = CGSize(width: 160, height: 56)
let container = SKNode()
container.position = CGPoint(x: 0, y: -size.height * 0.20)
container.zPosition = 10
container.name = "start"
addChild(container)

// shadow
let shadow = SKShapeNode(rectOf: btnSize, cornerRadius: 18)
shadow.fillColor = .black.withAlphaComponent(0.45)
shadow.strokeColor = .clear
shadow.position = CGPoint(x: 0, y: -4)
shadow.zPosition = -1
shadow.name = "start"
container.addChild(shadow)

// body
let body = SKShapeNode(rectOf: btnSize, cornerRadius: 14)
body.fillColor = .systemGreen
body.strokeColor = .white
body.lineWidth = 2.5
body.name = "start"
container.addChild(body)

// highlight
let highlight = SKShapeNode(
    rectOf: CGSize(width: btnSize.width - 14, height: btnSize.height / 2 - 6),
    cornerRadius: 10
)
highlight.fillColor = .white.withAlphaComponent(0.20)
highlight.strokeColor = .clear
highlight.position = CGPoint(x: 0, y: btnSize.height / 4)
highlight.name = "start"
container.addChild(highlight)

// label
let label = SKLabelNode(fontNamed: "AvenirNext-Heavy")
label.text = "START"
label.fontSize = 22
label.fontColor = .white
label.verticalAlignmentMode = .center
label.horizontalAlignmentMode = .center
label.name = "start"
container.addChild(label)

let pulse = SKAction.sequence([
    .scale(to: 1.04, duration: 0.7),
    .scale(to: 1.0, duration: 0.7)
])
container.run(.repeatForever(pulse))
```

### Footer
```swift
let footer = SKLabelNode(fontNamed: "AvenirNext-Bold")
footer.text = "v1.0  ·  TAP START TO PLAY"
footer.fontSize = 14
footer.fontColor = .white.withAlphaComponent(0.7)
footer.position = CGPoint(x: 0, y: -size.height * 0.45)
footer.zPosition = 10
addChild(footer)
```

## Asset pipeline that the logo depends on

The bachata logo is `Resources/MainLogoBachataAnimatonSpriteSheet.png`,
sliced as **4×3 = 12 frames** in `AssetCatalog.menuLogoFrames()`.

Source asset lives at `~/Desktop/Assets/MainLogoBachataAnimatonSpriteSheet.png`.
To rebuild after replacing the source:

```bash
cp ~/Desktop/Assets/MainLogoBachataAnimatonSpriteSheet.png \
   ZombieSmasher/Resources/MainLogoBachataAnimatonSpriteSheet.png
cp ~/Desktop/Assets/MainLogoBachataAnimatonSpriteSheet.png \
   _resource_originals/MainLogoBachataAnimatonSpriteSheet.png
rm -f _resource_centered_originals/MainLogoBachataAnimatonSpriteSheet.png
python3 scripts/strip_white_bg.py    # only needed if source has white bg
python3 scripts/repack_logo_sheet.py  # detects gaps, repacks into uniform 4x3
python3 scripts/center_animation_frames.py  # average-centroid alignment
```

The repack adds **30px padding around each cell** to prevent feet from
clipping when frames are recentered. Compensate at render time with
`maxW = size.width * 0.85` (which is why 85% width looks correct here even
though 0.85 of the old static logo would have been smaller).

## Tuning dial cheatsheet

| Symptom | Adjust |
|---|---|
| Logo too big | lower `maxW` (e.g. `0.75`) |
| Logo too small | raise `maxW` (e.g. `0.95`) |
| Logo overlaps START | lower `logo.position.y` further (more negative) or move button down |
| Logo above the road | raise `logo.position.y` (less negative) |
| Background too dim | lower the `0.15` alpha on `dim` |
| Logo jitters left/right | re-run `center_animation_frames.py` |
| Feet clipped on dance | re-run `repack_logo_sheet.py` (recreates 30px cell padding) |
