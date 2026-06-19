# Image Generator Settings

## Platform
AISure.uk — FLUX-based image generation

## Recommended Settings

| Setting        | Value    | Notes                                          |
|----------------|----------|------------------------------------------------|
| Quality        | Pro      | Use Ultra only for final production refinement |
| Style Preset   | Fantasy  | Not Photorealistic — MMO UI art style          |
| Aspect Ratio   | 1:1      | Always — crop/resize with ImageMagick after    |
| Image Count    | 4        | Always generate 4, pick the best               |

## Negative Prompt (use for every generation)

blurry, deformed, text, watermark, signature, letters, numbers,
interface screenshot, window frame, gradient background,
3D render, photographic, realistic photograph, modern UI,
flat design, simple, cartoon, low detail, pixelated,
artifacts, noise, oversaturated colors, neon, sci-fi

## Reference Image Strategy

| Asset Type      | Use as Reference                                      |
|-----------------|-------------------------------------------------------|
| Frame corners   | TopLeft.tga → all 4 corners                          |
| Top/Bottom edge | Top.tga → Bottom.tga                                 |
| Side edges      | Vertical_Left.tga → Vertical_Right.tga               |
| Gems            | HeaderGem.tga → FooterGem.tga                        |
| Icons           | Generate Icon_General first → use for all icons      |
| Nav buttons     | Button_Normal → Hover, Selected                      |
| Action buttons  | ActionButton_Normal → Hover, Pressed                 |
| Close buttons   | CloseButton_Normal → Hover, Pressed                  |

---

# OUS2 Asset Prompts Reference — v2

## Purpose

Enhanced prompts for regenerating the OUS2 Midnight Arcane artwork pack using AISure.uk or any FLUX-based generator.

## Theme Identity

* Dark metallic charcoal with oxidized steel texture
* Night Elf inspired arcane filigree and ornamental engravings
* Lavender crystal glow — soft purple energy highlights
* Midnight aesthetic — deep shadows, magical ambiance
* Fantasy MMO UI style — World of Warcraft Midnight expansion

## Background Convention

* **White background `#FFFFFF`** — default for all assets (easier removal, consistent)
* **Green background `#00FF00`** — only when artwork contains bright white highlights or glowing white elements
* Never use transparency in generation — always solid background, remove in post with ImageMagick

## ImageMagick Removal Commands

```powershell
# White background removal — 128x128 icons
magick "input.png" -fuzz 5% -fill none -draw "color 0,0 floodfill" -trim -resize "128x128>" -background none -gravity center -extent 128x128 -alpha on -define tga:bits-per-pixel=32 -type TrueColorAlpha "output.tga"

# Green background removal — 128x128 icons
magick "input.png" -fuzz 20% -fill none -draw "color 0,0 floodfill" -trim -resize "128x128>" -background none -gravity center -extent 128x128 -alpha on -define tga:bits-per-pixel=32 -type TrueColorAlpha "output.tga"

# White background removal — 256x64 buttons
magick "input.png" -fuzz 5% -fill none -draw "color 0,0 floodfill" -trim -resize "256x64>" -background none -gravity center -extent 256x64 -alpha on -define tga:bits-per-pixel=32 -type TrueColorAlpha "output.tga"

# Batch icons — white background
Get-ChildItem -Path "Icons_PNG" -Filter "*.png" | ForEach-Object {
    $outName = [System.IO.Path]::GetFileNameWithoutExtension($_.Name) + ".tga"
    magick $_.FullName -fuzz 5% -fill none -draw "color 0,0 floodfill" -trim -resize "128x128>" -background none -gravity center -extent 128x128 -alpha on -define tga:bits-per-pixel=32 -type TrueColorAlpha $outName
    Write-Host "Converted: $($_.Name) -> $outName"
}
```

## Derived Assets — ImageMagick

```powershell
# Generate TopLeft perfectly first, then:
magick TopLeft.tga -flop TopRight.tga
magick TopLeft.tga -flip BottomLeft.tga
magick TopLeft.tga -flip -flop BottomRight.tga
```

```powershell
magick TopLeft.png -flop TopRight.png
magick TopLeft.png -flip BottomLeft.png
magick TopLeft.png -flip -flop BottomRight.png
magick Top.png -flip Bottom.png
magick Vertical_Left.png -flop Vertical_Right.png
magick HeaderGem.png -flip FooterGem.png
```

---

# OUS Logo prompt

```
Professional Game Logo for "Odysseus Utility Suite". Main text "Odysseus" in large,
ornate, dark metallic charcoal serif font. Make the "O" in Odysseus word look like
a Flight Master's Compass. Subtitle "Utility Suite" in smaller elegant lettering below.
Iconographic elements integrated into the filigree: A stylized silver gryphon wing (Flight),
a glowing arcane fishing hook, and a shimmering loot-chest glint. The text is encrusted
with lavender crystal veins and Night Elf arcane engravings. Between the text lines is
a decorative divider featuring a progress-bar motif with glowing XP runes. Soft purple
void energy and magical embers float around the letters. High-fantasy UI asset style,
World of Warcraft Midnight aesthetic. High contrast against a solid flat white background (#FFFFFF).
Extremely detailed, sharp edges, metallic textures, 8k resolution, centered composition. No borders.
```

# Frame Assets

## TopLeft Corner — 128x128

```
Fantasy MMO UI frame corner asset, top-left piece for a NineSlice configuration panel.
Dark metallic charcoal base with oxidized steel texture and subtle surface weathering.
Outer frame has Night Elf inspired arcane filigree with interlocking vine and crystal motifs.
Inner corner edge features a thin lavender crystal glow line following the right angle.
Small arcane rune engraving near the inner corner point.
Decorative raised metal ridge along both inner edges.
Soft purple energy emanates from the filigree details.
Perfectly squared 90-degree inner corner — no curves.
The corner ornament tapers naturally toward the inner point.
Solid flat white background #FFFFFF. No transparency. No gradients on background.
Game UI texture asset. 128x128 pixels.
Corner piece only. No full frame. No other edges visible.
```

**Note:** Use as style reference for all other corner pieces to ensure consistency.

---

## TopRight Corner — 128x128

```
Fantasy MMO UI frame corner asset, top-right piece for a NineSlice configuration panel.
Mirror of the top-left corner — horizontally flipped.
Dark metallic charcoal base with oxidized steel texture and subtle surface weathering.
Outer frame has Night Elf inspired arcane filigree with interlocking vine and crystal motifs.
Inner corner edge features a thin lavender crystal glow line following the right angle.
Small arcane rune engraving near the inner corner point.
Decorative raised metal ridge along both inner edges.
Soft purple energy emanates from the filigree details.
Perfectly squared 90-degree inner corner — no curves.
Solid flat white background #FFFFFF. No transparency.
Game UI texture asset. 128x128 pixels.
Corner piece only. No full frame. No other edges visible.
```

---

## BottomLeft Corner — 128x128

```
Fantasy MMO UI frame corner asset, bottom-left piece for a NineSlice configuration panel.
Mirror of the top-left corner — vertically flipped.
Dark metallic charcoal base with oxidized steel texture.
Night Elf inspired arcane filigree, interlocking vine and crystal motifs.
Inner corner edge thin lavender crystal glow line.
Perfectly squared 90-degree inner corner.
Solid flat white background #FFFFFF. No transparency.
Game UI texture asset. 128x128 pixels.
Corner piece only. No full frame. No other edges visible.
```

---

## BottomRight Corner — 128x128

```
Fantasy MMO UI frame corner asset, bottom-right piece for a NineSlice configuration panel.
Mirror of the top-left corner — both horizontally and vertically flipped.
Dark metallic charcoal base with oxidized steel texture.
Night Elf inspired arcane filigree, interlocking vine and crystal motifs.
Inner corner edge thin lavender crystal glow line.
Perfectly squared 90-degree inner corner.
Solid flat white background #FFFFFF. No transparency.
Game UI texture asset. 128x128 pixels.
Corner piece only. No full frame. No other edges visible.
```

---

## Top Border — 512x68

```
Fantasy MMO UI top border bar texture, horizontal edge piece for a configuration panel frame.
Dark metallic charcoal base with oxidized steel texture and subtle horizontal grain.
Thin lavender crystal inner glow line running along the bottom edge of the bar.
Subtle arcane rune engravings spaced evenly along the upper surface.
Night Elf inspired filigree ornamental details — vine and crystal motifs along the length.
Small decorative notches at regular intervals breaking the monotony of the bar.
The center features a raised arcane gem socket with a glowing lavender crystal jewel,
flanked by symmetrical ornamental wing motifs extending left and right from center.
Metallic sheen with soft purple energy highlights along the top ridge.
Clean sharp horizontal edges — seamless tiling from left to right excluding center gem.
Solid flat white background #FFFFFF. No transparency. 512x68 pixels.
```

---

## Bottom Border — 512x68

```
Fantasy MMO UI bottom border bar texture, horizontal edge piece for a configuration panel frame.
Vertically mirrored version of the top border.
Dark metallic charcoal base with oxidized steel texture.
Thin lavender crystal inner glow line running along the top edge of the bar.
Subtle arcane rune engravings along the lower surface.
Night Elf inspired filigree ornamental details along the length.
The center features a raised arcane gem socket with a glowing lavender crystal jewel,
flanked by symmetrical ornamental wing motifs.
Clean sharp horizontal edges.
Solid flat white background #FFFFFF. No transparency. 512x68 pixels.
```

---

## Vertical Left Border — 32x247

```
Fantasy MMO UI left side border texture, vertical edge piece for a configuration panel frame.
Dark metallic charcoal base with oxidized steel texture and subtle vertical grain.
Thin lavender crystal inner glow line running along the right edge of the bar.
Subtle arcane rune engravings spaced vertically along the surface.
Night Elf inspired filigree ornamental details — vine and crystal motifs along the length.
Seamless vertical tiling — top and bottom edges blend cleanly.
Metallic sheen with soft purple energy highlights along the left outer ridge.
Clean sharp vertical edges.
Solid flat white background #FFFFFF. No transparency. 32x247 pixels.
```

---

## Vertical Right Border — 32x247

```
Fantasy MMO UI right side border texture, vertical edge piece for a configuration panel frame.
Horizontally mirrored version of the left border.
Dark metallic charcoal base with oxidized steel texture.
Thin lavender crystal inner glow line running along the left edge of the bar.
Subtle arcane rune engravings along the surface.
Night Elf inspired filigree ornamental details along the length.
Seamless vertical tiling.
Solid flat white background #FFFFFF. No transparency. 32x247 pixels.
```

---

## Background — 512x512

```
Deep midnight blue fantasy UI background texture for a configuration panel interior.
Subtle arcane mist drifting across the surface — very low opacity, barely visible.
Faint star field pattern in the deep background — tiny points of soft lavender light.
Extremely low contrast — must not distract from UI content placed on top.
No symbols, no runes, no strong shapes — pure atmospheric texture only.
Seamless tileable texture — edges blend perfectly in all directions.
Overall tone: very dark navy blue to near-black with subtle purple undertones.
No border, no frame, no edge definition — interior fill only.
Solid flat white background #FFFFFF (will be removed — background itself is the content).
512x512 pixels.
```

**Note:** This asset IS the background — the white background removal is not needed here. Export with no white fill — the dark blue IS the final color.

---

## Header Gem — 128x20

```
Fantasy MMO UI decorative header ornament, slim horizontal gem bar.
Central arcane crystal jewel — glowing lavender purple, raised faceted surface.
Flanked on both sides by symmetrical dark metallic filigree wings tapering outward.
Night Elf inspired ornamental design — elegant, slim, decorative.
Metallic charcoal frame around the central gem.
Soft lavender glow emanating from the crystal center.
Very slim horizontal proportions — wide and thin.
Solid flat white background #FFFFFF. No transparency. 128x20 pixels.
```

---

## Footer Gem — 128x20

```
Vertically mirrored version of the Header Gem.
Same design flipped upside down to cap the bottom of the frame.
Central arcane crystal jewel glowing lavender purple.
Symmetrical dark metallic filigree wings.
Solid flat white background #FFFFFF. No transparency. 128x20 pixels.
```

---

# Navigation Buttons

## Button_Normal — 256x64

```
Fantasy MMO UI navigation button, normal resting state.
Horizontal rectangular button with ornate decorative border.
Dark metallic charcoal frame with oxidized steel texture.
Night Elf inspired arcane filigree along the top and bottom edges.
Subtle lavender accent lines tracing the inner border.
Very faint lavender glow — resting state, minimal energy.
Left side features a small decorative rune or gem inset.
Slightly raised metallic surface suggesting a pressable button.
No text. No icons. Border decoration only.
Clean sharp rectangular edges — no rounded corners, no tabs, no wings.
Solid flat white background #FFFFFF. No transparency. 256x64 pixels.
```

---

## Button_Hover — 256x64

```
Fantasy MMO UI navigation button, hover/highlighted state.
Same design as Button_Normal with enhanced magical energy.
Strong lavender crystal glow along the inner border.
Filigree details brightened with arcane energy.
Soft purple light emanating from the decorative elements.
Left side gem or rune glowing more intensely.
Visually brighter and more active than the normal state.
No text. No icons. Border decoration only.
Clean sharp rectangular edges.
Solid flat white background #FFFFFF. No transparency. 256x64 pixels.
```

---

## Button_Selected — 256x64

```
Fantasy MMO UI navigation button, selected/active state.
Same design as Button_Normal indicating currently selected page.
Bright lavender crystal glow — maximum energy, fully activated.
Inner surface slightly lighter suggesting illumination from within.
Filigree details fully lit with arcane magic.
Distinct visual difference from normal and hover states — clearly active.
No text. No icons. Border decoration only.
Clean sharp rectangular edges.
Solid flat white background #FFFFFF. No transparency. 256x64 pixels.
```

---

# Action Buttons

## ActionButton_Normal — 256x64

```
Fantasy MMO UI action button, normal resting state.
Horizontal rectangular button — box style with decorative border artwork.
Dark metallic charcoal frame with oxidized steel texture.
Night Elf inspired arcane filigree along all four edges.
Subtle lavender highlight lines on the inner border.
Slightly different design from navigation buttons — more solid, action-oriented feel.
No arrows. No wings. No pointed ends. No tab shape. Pure rectangular box.
No text. No icons.
Solid flat white background #FFFFFF. No transparency. 256x64 pixels.
```

---

## ActionButton_Hover — 256x64

```
Fantasy MMO UI action button, hover state.
Same as ActionButton_Normal with enhanced lavender glow.
Strong magical energy along all four border edges.
Filigree details brightened with arcane highlights.
No arrows. No wings. No pointed ends. Pure rectangular box.
No text. No icons.
Solid flat white background #FFFFFF. No transparency. 256x64 pixels.
```

---

## ActionButton_Pressed — 256x64

```
Fantasy MMO UI action button, pressed/clicked state.
Same as ActionButton_Normal with visual depression effect.
Slightly darker surface suggesting pushed inward.
Reduced glow — lavender energy partially suppressed.
Inner shadow effect along top and left edges.
No arrows. No wings. No pointed ends. Pure rectangular box.
No text. No icons.
Solid flat white background #FFFFFF. No transparency. 256x64 pixels.
```

---

# Close Button

## CloseButton_Normal — 128x128

```
Fantasy MMO UI close button, normal resting state.
Circular dark metallic medallion with ornate Night Elf arcane filigree frame.
Center features a bright arcane X symbol — clean, bold, magical energy lines.
Lavender crystal glow surrounding the X symbol.
Outer ring has decorative engraving with subtle rune details.
Circular shape only — no square frame, no background panel.
Soft purple ambient glow around the medallion edges.
Use green background #00FF00 — artwork contains bright white/lavender highlights.
No white background — glow elements would be lost.
128x128 pixels.
```

---

## CloseButton_Hover — 128x128

```
Fantasy MMO UI close button, hover state.
Same circular medallion as CloseButton_Normal.
Enhanced lavender glow — strong magical energy.
X symbol brighter and more intensely lit.
Outer ring filigree more prominently highlighted.
Use green background #00FF00.
128x128 pixels.
```

---

## CloseButton_Pressed — 128x128

```
Fantasy MMO UI close button, pressed state.
Same circular medallion as CloseButton_Normal.
Reduced glow — slightly dimmed energy.
Subtle inset/pressed visual effect on the medallion surface.
X symbol still visible but less intense.
Use green background #00FF00.
128x128 pixels.
```

---

# Scrollbar

## ScrollTrack — 32x256

```
Fantasy MMO UI scrollbar track, vertical.
Slim dark metallic channel — recessed groove appearance.
Dark charcoal with subtle oxidized steel inner surface.
Thin lavender crystal glow lines running along both inner edges of the channel.
Night Elf inspired small rune marks at top and bottom ends.
Seamless vertical tile — middle section repeats cleanly.
Track only — no thumb, no arrows, no buttons.
Solid flat white background #FFFFFF. No transparency. 32x256 pixels.
```

---

## ScrollThumb — 32x64

```
Fantasy MMO UI scrollbar thumb, draggable element.
Slim dark metallic pill-shaped handle.
Dark charcoal with raised center ridge.
Central lavender crystal gem or accent — glowing softly.
Night Elf inspired small filigree detail on the raised surface.
Thumb only — no track, no arrows.
Slightly wider than the track to suggest it sits on top.
Solid flat white background #FFFFFF. No transparency. 32x64 pixels.
```

---

# Module Icons

## Common Base — all icons 128x128

All icons share this base description — append the specific subject description below.

```
Fantasy MMO circular UI icon. World of Warcraft Midnight expansion aesthetic.
Dark metallic charcoal circular frame with ornate Night Elf arcane filigree border.
Inner circle contains the subject artwork on a deep midnight blue background.
Lavender crystal glow accents on the frame border.
Soft purple magical energy ambient lighting.
High detail. Clean edges. No text. Circular format.
Solid flat white background #FFFFFF. No transparency. 128x128 pixels.
```
Generate Icon_General first (no reference)
→ Use Icon_General as reference for ALL remaining icons
→ Only change the subject description in the prompt
→ Keep all other settings identical (Fantasy, Pro, same negative prompt)

---

## Icon_OUS — OUS Branding

Subject: `Central arcane crystal orb with orbiting magical runes. Lavender and purple energy. OUS branding icon.`

## Icon_General — General Settings

Subject: `Arcane crystal gear with magical engravings. Lavender glow. Settings and configuration symbol.`

## Icon_XPBar — Experience Bar

Subject: `Glowing arcane experience bar rising upward. Purple magical energy flowing through it. Level progression symbol.`

## Icon_Delves — Delves

Subject: `Glowing underground cave entrance with arcane lantern hanging inside. Purple crystal fragments on the cave walls.`

## Icon_FlightMaster — Flight Master

Subject: `Arcane gryphon silhouette with magical compass rose beneath it. Navigation and flight symbol.`

## Icon_FlightRouting — Flight Routing

Subject: `Arcane map with glowing magical path lines connecting points. Navigation route planning symbol.`

## Icon_Utilities — Utilities

Subject: `Arcane toolbox with magical tools visible — wrench, crystal, scroll. Utility and tools symbol.`

## Icon_Openables — Openables

Subject: `Glowing magical treasure chest slightly open with arcane light spilling out. Lavender crystal lock.`

## Icon_StatsBar — Stats Bar

Subject: `Arcane crystal chart with rising bars of magical energy. Performance statistics symbol.`

## Icon_AutoRemount — Auto Remount

Subject: `Arcane horse head silhouette with magical saddle and reins. Mount and remount symbol.`

## Icon_FasterLoot — Faster Loot

Subject: `Glowing treasure bag with magical motion streaks suggesting speed. Arcane sparkle effects.`

## Icon_FishingTracker — Fishing Tracker

Subject: `Arcane fishing hook with a glowing magical fish on the line. Midnight blue water ripple below.`

## Icon_Toolbox — Toolbox

Subject: `Arcane utility satchel bag with magical tools — wand, scroll, crystal — visible inside.`

## Icon_Help — Help

Subject: `Open arcane tome with a glowing magical question mark floating above the pages.`

## Icon_Changelog — Changelog

Subject: `Ancient arcane scroll unrolled with a glowing magical quill writing on it. Version history symbol.`

## Minimap_button — Minimap Button

Subject: `Arcane purple crystal orb set in a dark metallic circular frame. Minimap button icon.`

---

# Utility Icons

## Icon_SectionStar — 64x64

```
Fantasy MMO UI section header marker icon.
Small decorative arcane star or diamond crystal shape.
Lavender crystal core with dark metallic frame.
Soft magical glow. Night Elf inspired design.
Used as bullet point for section headers in config panels.
Solid flat white background #FFFFFF. No transparency. 64x64 pixels.
```

## Checkbox_Checked — 64x64

```
Fantasy MMO UI enabled state checkbox icon.
Circular dark metallic frame with Night Elf filigree border.
Center contains a bright glowing arcane checkmark symbol.
Lavender crystal energy. Clearly enabled/active state.
Solid flat white background #FFFFFF. No transparency. 64x64 pixels.
```

## Checkbox_Unchecked — 64x64

```
Fantasy MMO UI disabled state checkbox icon.
Circular dark metallic frame with Night Elf filigree border.
Center is empty — dim metallic interior, no glow.
Very subtle lavender outline only. Clearly disabled/inactive state.
Solid flat white background #FFFFFF. No transparency. 64x64 pixels.
```

---

# Missing Assets — New for OUS2

## Divider_Horizontal — 512x8

```
Fantasy MMO UI horizontal divider line, minimalist style.
Extremely slim dark metallic bar — single thin line appearance.
Subtle lavender crystal glow along the center of the line.
Fades gracefully toward both left and right ends.
No ornaments. No center gem. No filigree. Clean and minimal.
Used to separate content sections inside configuration panels.
The line should feel etched or engraved into a surface.
Solid flat white background #FFFFFF. No transparency. 512x8 pixels.
```

## TabIndicator — 8x32

```
Fantasy MMO UI active tab indicator, vertical accent bar. Do not generate the bar. Only the tab indicator.
Slim bright lavender crystal bar with soft glow.
Indicates the currently selected navigation item.
Placed on the left edge of the active navigation button.
Solid flat white background #FFFFFF. No transparency. 8x32 pixels.
```

## Icon_XPBar — also needed as Icon_Delves variant

Delves1 was a variant — decide which to keep and delete the other.

---

# Asset Checklist

## Frame (all complete)
- [x] Background.tga
- [x] TopLeft.tga
- [x] TopRight.tga
- [x] BottomLeft.tga
- [x] BottomRight.tga
- [x] Top.tga
- [x] Bottom.tga
- [x] Vertical_Left.tga
- [x] Vertical_Right.tga
- [x] HeaderGem.tga
- [x] FooterGem.tga

## Buttons (all complete)
- [x] Button_Normal.tga
- [x] Button_Hover.tga
- [x] Button_Selected.tga
- [x] ActionButton_Normal.tga
- [x] ActionButton_Hover.tga
- [x] ActionButton_Pressed.tga
- [x] CloseButton_Normal.tga
- [x] CloseButton_Hover.tga
- [x] CloseButton_Pressed.tga

## Scrollbar (complete)
- [x] ScrollTrack.tga
- [x] ScrollThumb.tga

## Icons (complete)
- [x] Icon_OUS.tga
- [x] Minimap_button.tga
- [x] Icon_General.tga
- [x] Icon_XPBar.tga
- [x] Icon_Delves.tga
- [x] Icon_FlightMaster.tga
- [x] Icon_FlightRouting.tga
- [x] Icon_Utilities.tga
- [x] Icon_Openables.tga
- [x] Icon_StatsBar.tga
- [x] Icon_AutoRemount.tga
- [x] Icon_FasterLoot.tga
- [x] Icon_FishingTracker.tga
- [x] Icon_Toolbox.tga
- [x] Icon_Help.tga
- [x] Icon_Changelog.tga

## Utility Icons (complete)
- [x] Icon_SectionStar.tga
- [x] Checkbox_Checked.tga
- [x] Checkbox_Unchecked.tga

## New Assets Needed
- [x] Divider_Horizontal.tga — 512x8
- [x] TabIndicator.tga — 8x32

## Cleanup Needed
- [x] Delete Icon_General_test.tga
- [x] Delete Icon_Delves1.tga (duplicate)
- [x] Delete Checkbox_Unchecked1.tga (duplicate)
