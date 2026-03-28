# Gold Star Echo Chamber -- Complete GUI Control Catalog

**Source image:** `resources/gui/mockv30.jpeg` (1376 x 768 px, RGB)
**Coordinate system:** All positions are in image-space pixels, origin at top-left.
**Cross-reference:** `src/standalone/standalone_ui.mm` uses `imageRectToView()` which converts these coords (top-left origin) to NSView coords (bottom-left origin).

---

## GLOBAL LAYOUT

The GUI is a photorealistic rendering of a vintage hardware rack unit with:
- **Wood frame border** surrounding the entire unit (darker walnut/mahogany trim)
- **Brass/bronze faceplate** as the main panel surface
- **Title "GOLD STAR ECHO CHAMBER"** engraved across the top in dark serif text, approximately y=68, centered horizontally

### Color Palette
| Element | Hex | RGB | Description |
|---------|-----|-----|-------------|
| Brass faceplate (mid) | #8a5f35 | (138,95,53) | Warm brushed brass, slight gradient darker at edges |
| Brass faceplate (top) | #a17342 | (161,115,66) | Lighter brass near VU meters |
| Wood frame (top) | #92643d | (146,100,61) | Lighter walnut grain |
| Wood frame (bottom) | #623c1e | (98,60,30) | Darker walnut, more shadow |
| Knob body (dark) | #331e0d | (51,30,13) | Very dark brown/black Bakelite |
| Fader track (dark) | #160402 | (22,4,2) | Near-black recessed slot |
| IR button body | #c79560 | (199,149,96) | Light tan/beige keycap |

---

## 1. INPUT CONTROL SECTION (Left Panel)

### Section Label
- **Text:** "INPUT CONTROL"
- **Position:** Approximately x=270, y=268 (centered over the 3 knobs)
- **Style:** Dark brown engraved uppercase serif text on brass

---

### 1.1 LOW PASS Knob
- **Type:** Small rotary knob
- **Center:** (170, 357)
- **Overlay size:** 80 x 80 px (code: `smallKnob = 80.0`)
- **Knob body diameter:** ~60 px
- **Parameter:** LOW_PASS, range 200-20000 Hz, default 20000
- **Label:** "LOW PASS" printed below knob in dark brown uppercase
- **Number ring:** Printed directly on the brass faceplate around the knob. Numbers visible: 0, 3, 5, 7, 9, 10 arranged clockwise from ~7 o'clock to ~5 o'clock. Dark brown text, approximately 8-9pt equivalent.
- **Visual description:**
  - Knob cap is a dark Bakelite-style material, nearly black with a very subtle warm brown sheen
  - Slightly domed/convex top surface
  - Subtle concentric machining lines visible on cap surface
  - Metallic brass pointer line (thin radial indicator from center toward edge)
  - Sits in a shallow recess in the brass faceplate
  - Top highlight suggests overhead lighting from slightly above-center
- **Crop file:** `controls/knob_low_pass.png`

### 1.2 HIGH PASS Knob
- **Type:** Small rotary knob
- **Center:** (279, 357)
- **Overlay size:** 80 x 80 px
- **Knob body diameter:** ~60 px
- **Parameter:** HIGH_PASS, range 20-8000 Hz, default 20
- **Label:** "HIGH PASS" printed below knob in dark brown uppercase
- **Number ring:** Same style as LOW PASS -- numbers 0-10 in an arc, dark brown on brass
- **Visual description:** Identical to LOW PASS knob in construction and material
- **Crop file:** `controls/knob_high_pass.png`

### 1.3 GAIN Knob
- **Type:** Small rotary knob (slightly larger)
- **Center:** (388, 353)
- **Overlay size:** 90 x 90 px (code: `smallKnob + 10`)
- **Knob body diameter:** ~68 px
- **Parameter:** INPUT_GAIN, range -80 to +12 dB, default 0
- **Label:** "GAIN" printed below knob in dark brown uppercase
- **Number ring:** Numbers 0-10 in arc, same style
- **Visual description:** Same dark Bakelite style as other small knobs, slightly larger diameter
- **Crop file:** `controls/knob_gain.png`

---

## 2. FIVE-BAND INPUT EQ (Left Panel, Below Knobs)

### Section Label
- **Text:** "FIVE-BAND INPUT EQ"
- **Position:** Approximately x=278, y=452 (centered over fader group)
- **Style:** Dark brown engraved uppercase text on a darker brass strip/bar

### EQ Fader Sub-Labels (at top of each fader)
From left to right:
| Band | Label Line 1 | Label Line 2 | X Position |
|------|-------------|-------------|------------|
| 1 | LOW | (100 Hz) | 171 |
| 2 | L-MID | (250 Hz) | 224 |
| 3 | MID | (1 KHz) | 280 |
| 4 | M-HIGH | (4 KHz) | 334 |
| 5 | HIGH | (10 KHz) | 388 |

### 2.1-2.5 EQ Faders (5 identical faders)
- **Type:** Vertical linear fader / slider
- **Centers (x, y):** (171, 585), (224, 585), (280, 585), (334, 585), (388, 585)
- **Overlay size:** 30 x 300 px each (code: `eqFaderW=30, eqFaderH=300`)
- **Fader track visible area:** ~220 px tall
- **Parameter:** EQ_100, EQ_250, EQ_1K, EQ_4K, EQ_10K; range -12 to +12 dB, default 0
- **Red handle:** NO (brass/tan colored handles)
- **Visual description:**
  - **Track:** Narrow vertical slot (~4-5 px wide), very dark brown/black recessed groove cut into the brass faceplate
  - **Tick marks:** Horizontal hash marks on both sides of the track at regular dB intervals, dark brown, ~12 marks per side
  - **Handle/thumb:** Small rectangular brass-colored fader cap, approximately 20 x 8 px, with a horizontal groove/line across its center for grip
  - **Handle color:** Warm brass/tan metallic, slightly lighter than the faceplate (#c4a670 approximate)
  - **Cap at top of track:** Small brass dome/ball at the very top of the fader slot (decorative terminus)
- **Crop files:** `controls/fader_eq_100hz.png` through `controls/fader_eq_10khz.png`
- **Detail crop:** `controls/fader_eq_single.png`, `controls/fader_handle_closeup.png`

### Panel Screws (EQ Section)
- **Type:** Decorative Phillips-head screws at corners of the EQ sub-panel
- **Approximate positions:** (143, 455), (413, 455), (143, 710), (413, 710)
- **Diameter:** ~12-14 px
- **Visual description:** Small round brass-colored screw heads with a cross/Phillips slot, slightly raised, matching the faceplate color but with a subtle shadow ring around them
- **Crop file:** `controls/eq_panel_screw_tl.png`

---

## 3. IMPULSE RESPONSE (IR) MODULE BUTTONS (Center, Below VU Meters)

### Section Label
- **Text:** "IMPULSE RESPONSE (IR) MODULES"
- **Position:** Approximately x=680, y=264 (centered over button row)
- **Style:** Dark brown engraved uppercase serif text on brass

### 3.1-3.5 IR Select Buttons (A through E)
- **Type:** Momentary push buttons / selector buttons
- **Centers (x, y):** (508, 299), (592, 299), (680, 299), (765, 299), (851, 299)
- **Overlay size:** 60 x 60 px each (code: `irBtnSize = 60.0`)
- **Button face size:** ~52 x 52 px visible
- **Labels:** Single uppercase letters centered on each button: **A**, **B**, **C**, **D**, **E**
- **Visual description:**
  - Raised rectangular buttons with slightly rounded corners (~3-4 px radius)
  - Button face is a light tan/beige keycap color (#c79560), lighter than the brass faceplate
  - Subtle 3D beveled edge: lighter highlight on top/left edges, darker shadow on bottom/right edges (classic keycap lighting)
  - Letters are dark brown (#4a2a12 approximate), centered on button face, bold serif style
  - Each button sits within a thin dark recessed border/groove in the faceplate
  - When selected (code behavior): a golden highlight ring (0.914, 0.757, 0.463 alpha 0.5) appears around the button, 2.5px stroke
- **Crop files:** `controls/button_ir_a.png` through `controls/button_ir_e.png`
- **Section crop:** `controls/section_ir_modules.png`

---

## 4. REVERB CONTROL SECTION (Center)

### Section Label
- **Text:** "REVERB CONTROL"
- **Position:** Approximately x=688, y=358 (centered between IR buttons and the 4 knobs)
- **Style:** Dark brown engraved uppercase serif text on brass

### 4.1 PRE-DELAY Knob (Top-Left of quad)
- **Type:** Large rotary knob
- **Center:** (576, 490)
- **Overlay size:** 120 x 120 px (code: `bigKnob = 120.0`)
- **Knob body diameter:** ~90-95 px
- **Parameter:** PRE_DELAY, range 0-500 ms, default 0
- **Label:** "PRE DELAY" (two lines) printed below knob in dark brown uppercase
- **Number ring:** Numbers 0 through 10 arranged in arc around knob, dark brown on brass faceplate. Tick marks at each number.
- **Visual description:**
  - Significantly larger than input knobs
  - Same dark Bakelite-style cap material, very dark brown/black
  - Concentric machining rings visible on top surface
  - **Metallic center highlight:** A bright brass/gold specular highlight visible in the center of the cap, roughly circular, giving a polished dome appearance
  - Shallow bevel/chamfer at the outer edge of the knob cap
  - The knob sits in a visible circular recess/shadow on the brass plate
  - Pointer indicator: thin radial line from near-center to edge, matching the indicator overlay line color
- **Crop file:** `controls/knob_predelay.png`

### 4.2 TIME Knob (Top-Right of quad)
- **Type:** Large rotary knob
- **Center:** (789, 490)
- **Overlay size:** 120 x 120 px
- **Parameter:** REVERB_LENGTH, range 0.1-100%, default 100
- **Label:** "TIME" printed below knob
- **Visual description:** Identical construction to PRE-DELAY knob
- **Crop file:** `controls/knob_time.png`

### 4.3 SIZE Knob (Bottom-Left of quad)
- **Type:** Large rotary knob
- **Center:** (576, 655)
- **Overlay size:** 120 x 120 px
- **Parameter:** ROOM_SIZE, range 0-1, default 0.5
- **Label:** "SIZE" printed below knob
- **Visual description:** Identical construction to PRE-DELAY knob
- **Crop file:** `controls/knob_size.png`

### 4.4 DIFFUSION Knob (Bottom-Right of quad)
- **Type:** Large rotary knob
- **Center:** (788, 656)
- **Overlay size:** 120 x 120 px
- **Parameter:** DIFFUSION, range 0-1, default 0.5
- **Label:** "DIFFUSION" printed below knob
- **Visual description:** Identical construction to PRE-DELAY knob
- **Crop file:** `controls/knob_diffusion.png`

**Section crop:** `controls/section_reverb_control.png`

---

## 5. VU METERS (Top Center, 3 meters)

### 5.1 Input VU Meter (Left)
- **Type:** Analog VU meter panel
- **Center:** (480, 125)
- **Size:** 165 x 100 px (code: `vuW=165, vuH=100`)
- **Visual description:**
  - Recessed rectangular meter window with rounded corners (~4 px radius)
  - **Bezel:** Dark brass/bronze frame around the meter face, ~4-5 px thick, with a subtle inner bevel
  - **Face:** Warm cream/ivory background (#f5edd9 approximate), aged/yellowed vintage paper look
  - **Scale arc:** Curved arc from lower-left to lower-right, with tick marks at standard VU positions: -20, -10, -7, -5, -3, -2, -1, 0, +1, +2, +3
  - **Red zone:** Right portion of the arc (above 0 VU) has a red-tinted band
  - **Needle:** Thin black needle pivoting from bottom-center, with a slight shadow offset
  - **Pivot cap:** Small dark circular cap at the needle pivot point (bottom center of meter)
  - **"VU" label:** Centered text on the meter face, dark brown, bold
  - **Additional text:** Small text at bottom of face reads "TEMP VE - SE - OU TI" (partially legible vintage meter markings)
  - **Patina/aging effects:** Subtle brownish vignette at edges, faint stain spots, yellowed tint overlay (all rendered programmatically in code)
- **Note:** The VU meters are drawn entirely programmatically in `VUMeterOverlay` class -- not from the background image. The image shows placeholder meter rectangles.
- **Crop file:** `controls/vu_input.png`

### 5.2 Process VU Meter (Center)
- **Center:** (680, 125)
- **Size:** 165 x 100 px
- **Visual description:** Identical to Input VU meter
- **Crop file:** `controls/vu_process.png`

### 5.3 Output VU Meter (Right)
- **Center:** (880, 125)
- **Size:** 165 x 100 px
- **Visual description:** Identical to Input VU meter
- **Crop file:** `controls/vu_output.png`

**Section crop:** `controls/section_top_panel.png`

---

## 6. OUTPUT CONTROL SECTION (Right Panel)

### Section Label
- **Text:** "OUTPUT CONTROL"
- **Position:** Approximately x=1100, y=268 (centered over fader group)
- **Style:** Dark brown engraved uppercase serif text on brass

### Fader Bottom Labels
| Fader | Label | X Position |
|-------|-------|------------|
| Dry | "DRY SIGNAL" | 981 |
| Wet | "WET SIGNAL" | 1095 |
| Output | "OUTPUT" | 1205 |

### Scale Markings
- Horizontal tick marks on both sides of each fader track
- dB scale values printed: visible numbers include -140, -52, -40, and marks up to top

### 6.1 DRY SIGNAL Fader
- **Type:** Vertical linear fader
- **Center:** (981, 360)
- **Overlay size:** 36 x 320 px (code: `outFaderW=36, outFaderH=320`)
- **Parameter:** DRY_LEVEL, range -80 to 0 dB, default -6
- **Red handle:** NO
- **Visual description:**
  - **Track:** Narrow vertical dark slot, same as EQ faders but slightly wider (~5-6 px)
  - **Handle:** Brass/tan colored rectangular fader cap, ~24 x 10 px
  - Horizontal center groove on handle for grip
  - **Cap terminus:** Small brass dome at top of fader slot
  - **Tick marks:** Horizontal hash marks at dB intervals on both sides, more widely spaced than EQ faders
- **Crop file:** `controls/fader_dry.png`

### 6.2 WET SIGNAL Fader
- **Type:** Vertical linear fader
- **Center:** (1095, 360)
- **Overlay size:** 36 x 320 px
- **Parameter:** WET_LEVEL, range -80 to 0 dB, default -6
- **Red handle:** NO
- **Visual description:** Identical to DRY fader
- **Crop file:** `controls/fader_wet.png`

### 6.3 OUTPUT Fader
- **Type:** Vertical linear fader
- **Center:** (1205, 360)
- **Overlay size:** 36 x 320 px
- **Parameter:** OUTPUT_LEVEL, range -80 to +6 dB, default 0
- **Red handle:** YES
- **Visual description:**
  - Same track style as other output faders
  - **Handle is RED:** Distinct red/dark-red rectangular fader cap (#a01a1a approximate), clearly different from the brass handles on DRY/WET faders
  - Red handle has same grip groove
  - Red indicates master output / caution level
- **Crop file:** `controls/fader_output.png`, `controls/output_fader_handle_red.png`

**Section crop:** `controls/section_output_control.png`

---

## 7. TOGGLE SWITCHES (Right Panel, Below Faders)

### 7.1 REVERSE Toggle
- **Type:** Toggle switch (bat-handle style)
- **Center:** (971, 582)
- **Overlay size:** 50 x 40 px (code: `toggleW=50, toggleH=40`)
- **Label:** "REVERSE" printed below the switch in dark brown uppercase
- **Parameter:** REVERSE, on/off
- **Visual description:**
  - Classic vintage toggle/bat-handle switch
  - Chrome/silver metallic toggle lever protruding from a circular brass mounting plate (~20 px diameter base)
  - The lever/bat is a short metallic cylinder that tilts up or down
  - Base plate sits flush with the brass faceplate
  - Recessed dark square or circular border around the switch mounting
  - When ON (code behavior): Green glow overlay (0.2, 0.8, 0.3, alpha 0.3) with rounded rect
- **Crop file:** `controls/toggle_reverse.png`

### 7.2 MIC INPUT ON/OFF Toggle
- **Type:** Toggle switch (bat-handle style)
- **Center:** (1088, 582)
- **Overlay size:** 50 x 40 px
- **Label:** "MIC INPUT" (line 1) "ON/OFF" (line 2) printed below the switch
- **Parameter:** Triggers mic input device selection menu
- **Visual description:** Identical in construction to the REVERSE toggle
- **Crop file:** `controls/toggle_mic.png`

**Section crop:** `controls/output_on_off_switches.png`

---

## 8. AUDIO FILE TRANSPORT (Bottom-Right)

### Section Label
- **Text:** "AUDIO FILE TRANSPORT"
- **Position:** Approximately x=1040, y=642 (above the transport buttons)
- **Style:** Dark brown engraved uppercase text on brass, smaller than section headers

### File Status Display
- **Text area:** "LOAD AUDIO FILE" button/label on the left, "No file loaded" status text on the right
- **Position:** Approximately y=665, x range 945-1145
- **Style:** Text appears to be printed/engraved on the brass surface

### Signal Indicator
- **Type:** Small LED indicator
- **Text:** "Signal" with a small green LED square
- **Position:** Approximately (1165, 682)
- **LED size:** ~8 x 8 px
- **LED color:** Green (#4a8a2a approximate) when active

### 8.1 PLAY Button
- **Type:** Circular push button
- **Center:** (1010, 678)
- **Overlay size:** 44 x 44 px (code: `tBtnSize = 44.0`)
- **Button diameter:** ~40 px
- **Visual description:**
  - **Spherical/dome-shaped button** with a pronounced 3D convex surface
  - **Color: GREEN** -- rich saturated green (#2a8a2a approximate) with a bright specular highlight on the upper portion suggesting a glossy plastic or glass dome
  - Circular dark shadow/ring around the base where button meets the brass faceplate
  - "PLAY" text printed below the button on the faceplate
  - When pressed (code behavior): brief white flash overlay (alpha 0.15)
- **Crop file:** `controls/button_play.png`, `controls/button_play_wide.png`

### 8.2 STOP Button
- **Type:** Circular push button
- **Center:** (1070, 678)
- **Overlay size:** 44 x 44 px
- **Button diameter:** ~40 px
- **Visual description:**
  - Same dome/spherical shape as PLAY button
  - **Color: RED** -- rich saturated red (#c42020 approximate) with bright specular highlight
  - Same dark ring/shadow at base
  - "STOP" text printed below on faceplate
- **Crop file:** `controls/button_stop.png`, `controls/button_stop_wide.png`

### 8.3 BYPASS Overlay
- **Type:** Toggle button / clickable region
- **Center:** (1040, 730)
- **Overlay size:** 130 x 30 px
- **Visual description:**
  - Not a distinct visible button in the mockup -- the area sits on the brass-to-wood-trim boundary at the very bottom of the faceplate
  - When activated (code behavior): Red glow fill (0.7, 0.1, 0.1, alpha 0.5) with "BYPASSED" text overlay in red
- **Crop file:** `controls/button_bypass.png`, `controls/bypass_closeup.png`

**Section crop:** `controls/transport_full.png`, `controls/section_transport.png`

---

## 9. DECORATIVE / NON-INTERACTIVE ELEMENTS

### 9.1 Title Text
- **Text:** "GOLD STAR ECHO CHAMBER"
- **Position:** Centered horizontally (~x=688), y approximately 68
- **Style:** Large uppercase serif/display font, dark brown/black engraved into the brass panel. Appears to be embossed/stamped with slight shadow beneath letters.
- **Crop file:** `controls/title_bar.png`

### 9.2 Wood Frame Border
- **Description:** The entire GUI is framed by a walnut/mahogany wood grain border
- **Top border:** ~75 px tall, lighter wood (#92643d average)
- **Bottom border:** ~45 px tall, darker wood (#623c1e average)
- **Left border:** ~100 px wide
- **Right border:** ~76 px wide
- **Visual description:**
  - Realistic wood grain texture with horizontal grain direction
  - Warm medium-brown color with natural variation
  - Slightly darker at the bottom and edges (vignette/shadow)
  - The brass faceplate sits within this wood frame as if inset/mounted

### 9.3 Panel Screws
- **Type:** Decorative Phillips-head screws
- **Locations observed:** At corners of the EQ sub-panel inset area
  - (143, 455) -- top-left of EQ section
  - (413, 455) -- top-right of EQ section
  - (143, 710) -- bottom-left of EQ section
  - (413, 710) -- bottom-right of EQ section
- **Diameter:** ~12 px
- **Visual description:** Small round screw heads, brass/bronze colored matching the faceplate, with cross-slot (Phillips) indentation visible. Subtle ring shadow around each screw. Very small and decorative.

### 9.4 Engraved Section Dividers / Borders
- **Description:** Thin dark engraved lines visible as borders around the major sections (input control area, output control area, reverb control area). These appear as subtle recessed grooves in the brass surface forming rectangular borders around each control group.

### 9.5 Watermark Cover Patch
- **Position:** (1240, 745), size 100 x 80 px
- **Description:** Code-generated gradient patch that covers a watermark in the bottom-right corner. Gradient goes from brass faceplate color at top through a dark border line to wood trim color at bottom.
- **Not a real control** -- purely cosmetic code artifact

---

## 10. KNOB CONSTRUCTION REFERENCE (for programmatic recreation)

### Small Knobs (Input Section)
- **Body diameter:** ~60 px on a 1376-wide image
- **Material:** Dark Bakelite/phenolic resin appearance
- **Body color gradient:** Center #3d2510, edge #1a0e05 (very dark brown, nearly black)
- **Surface:** Subtle concentric machining rings/lines radiating from center
- **Top profile:** Slightly domed/convex
- **Edge chamfer:** Thin bevel at outer rim, ~2 px, slightly lighter catching light
- **Pointer:** Thin radial line, appears as a lighter groove or painted mark
- **Code indicator:** Line drawn from 15% to 92% of radius, color (0.914, 0.757, 0.463) = #e9c176, 2.5px wide
- **Rotation range:** 270 degrees, from -135 to +135 (7 o'clock to 5 o'clock)
- **Number ring:** External to knob body, printed on brass faceplate, numbers 0-10

### Large Knobs (Reverb Section)
- **Body diameter:** ~90-95 px
- **Same material and style** as small knobs but scaled up
- **Center highlight:** More prominent metallic/specular highlight visible in the center, suggesting a polished brass or chrome center cap area (~25 px diameter bright spot)
- **Shadow ring:** Slightly deeper shadow cast around base due to larger profile
- **Number ring:** Same external numbering system, 0-10 arc

### Common Knob Properties (Code Reference)
```
- Indicator line inner radius: 15% of overlay radius
- Indicator line outer radius: 92% of overlay radius
- Indicator color (normal): RGBA(0.914, 0.757, 0.463, 0.85) = warm gold
- Indicator color (dragging): RGBA(1.0, 0.9, 0.5, 0.95) = bright yellow-gold
- Line width: 2.5px normal, 3.0px dragging
- Glow ring when dragging: 2.0px stroke, RGBA(1.0, 0.9, 0.5, 0.15)
- Rotation: -135 deg (min) to +135 deg (max), 270 deg sweep
```

---

## 11. FADER CONSTRUCTION REFERENCE (for programmatic recreation)

### EQ Faders (Input Section)
- **Track width:** ~4-5 px dark slot
- **Track color:** Near-black #160402
- **Handle size:** ~20 x 8 px
- **Handle color:** Brass/tan metallic, warm gold
- **Tick marks:** Short horizontal lines, evenly spaced, dark brown on brass

### Output Faders (Output Section)
- **Track width:** ~5-6 px dark slot
- **Track color:** Near-black #080000
- **Handle size:** ~24 x 10 px
- **DRY/WET handle color:** Brass/tan metallic (same as EQ faders)
- **OUTPUT handle color:** RED #a01a1a (distinctive master output indicator)
- **Brass dome cap:** Small decorative sphere at top terminus of each track

### Common Fader Properties (Code Reference)
```
- Handle height: 12px (code)
- Handle horizontal margin: 2px each side
- Handle rounded rect radius: 2px
- Normal handle color (tan): RGBA(0.85, 0.80, 0.73, 0.6)
- Normal handle color (red): RGBA(0.8, 0.1, 0.1, 0.7)
- Dragging handle color (tan): RGBA(1.0, 0.95, 0.85, 0.8)
- Dragging handle color (red): RGBA(1.0, 0.2, 0.2, 0.9)
- Center line: 1px, white alpha 0.4
- Track margin: 8px top and bottom
- Drag sensitivity: range / 180px
```

---

## 12. COMPLETE POSITION TABLE (Quick Reference)

All coordinates are (center_x, center_y) in image space, top-left origin.

| # | Control | Type | Center X | Center Y | Width | Height | Parameter |
|---|---------|------|----------|----------|-------|--------|-----------|
| 1 | Low Pass | Small Knob | 170 | 357 | 80 | 80 | LOW_PASS |
| 2 | High Pass | Small Knob | 279 | 357 | 80 | 80 | HIGH_PASS |
| 3 | Gain | Small Knob | 388 | 353 | 90 | 90 | INPUT_GAIN |
| 4 | EQ 100Hz | Fader | 171 | 585 | 30 | 300 | EQ_100 |
| 5 | EQ 250Hz | Fader | 224 | 585 | 30 | 300 | EQ_250 |
| 6 | EQ 1kHz | Fader | 280 | 585 | 30 | 300 | EQ_1K |
| 7 | EQ 4kHz | Fader | 334 | 585 | 30 | 300 | EQ_4K |
| 8 | EQ 10kHz | Fader | 388 | 585 | 30 | 300 | EQ_10K |
| 9 | IR A | Button | 508 | 299 | 60 | 60 | selectIR(0) |
| 10 | IR B | Button | 592 | 299 | 60 | 60 | selectIR(1) |
| 11 | IR C | Button | 680 | 299 | 60 | 60 | selectIR(2) |
| 12 | IR D | Button | 765 | 299 | 60 | 60 | selectIR(3) |
| 13 | IR E | Button | 851 | 299 | 60 | 60 | selectIR(4) |
| 14 | Pre-Delay | Large Knob | 576 | 490 | 120 | 120 | PRE_DELAY |
| 15 | Time | Large Knob | 789 | 490 | 120 | 120 | REVERB_LENGTH |
| 16 | Size | Large Knob | 576 | 655 | 120 | 120 | ROOM_SIZE |
| 17 | Diffusion | Large Knob | 788 | 656 | 120 | 120 | DIFFUSION |
| 18 | Dry Signal | Fader | 981 | 360 | 36 | 320 | DRY_LEVEL |
| 19 | Wet Signal | Fader | 1095 | 360 | 36 | 320 | WET_LEVEL |
| 20 | Output | Fader (Red) | 1205 | 360 | 36 | 320 | OUTPUT_LEVEL |
| 21 | VU Input | VU Meter | 480 | 125 | 165 | 100 | (display) |
| 22 | VU Process | VU Meter | 680 | 125 | 165 | 100 | (display) |
| 23 | VU Output | VU Meter | 880 | 125 | 165 | 100 | (display) |
| 24 | Reverse | Toggle | 971 | 582 | 50 | 40 | REVERSE |
| 25 | Mic Input | Toggle | 1088 | 582 | 50 | 40 | (mic select) |
| 26 | Play | Button | 1010 | 678 | 44 | 44 | playFile() |
| 27 | Stop | Button | 1070 | 678 | 44 | 44 | stopFile() |
| 28 | Bypass | Button | 1040 | 730 | 130 | 30 | BYPASS |

### Decorative Elements
| Element | Center X | Center Y | Size | Notes |
|---------|----------|----------|------|-------|
| EQ Screw TL | 143 | 455 | ~12 dia | Phillips head |
| EQ Screw TR | 413 | 455 | ~12 dia | Phillips head |
| EQ Screw BL | 143 | 710 | ~12 dia | Phillips head |
| EQ Screw BR | 413 | 710 | ~12 dia | Phillips head |
| Cover Patch | 1240 | 745 | 100x80 | Gradient overlay |

---

## 13. CROP FILE INDEX

All crop files saved to `docs/controls/`:

### Individual Controls
- `knob_low_pass.png` -- Low Pass knob (100x100)
- `knob_high_pass.png` -- High Pass knob (100x100)
- `knob_gain.png` -- Gain knob (110x110)
- `knob_predelay.png` -- Pre-Delay knob (150x150)
- `knob_time.png` -- Time knob (150x150)
- `knob_size.png` -- Size knob (150x150)
- `knob_diffusion.png` -- Diffusion knob (150x150)
- `fader_eq_100hz.png` -- EQ 100Hz fader (60x320)
- `fader_eq_250hz.png` -- EQ 250Hz fader (60x320)
- `fader_eq_1khz.png` -- EQ 1kHz fader (60x320)
- `fader_eq_4khz.png` -- EQ 4kHz fader (60x320)
- `fader_eq_10khz.png` -- EQ 10kHz fader (60x320)
- `fader_dry.png` -- Dry Signal fader (70x340)
- `fader_wet.png` -- Wet Signal fader (70x340)
- `fader_output.png` -- Output fader with red handle (70x340)
- `button_ir_a.png` through `button_ir_e.png` -- IR selector buttons (90x90 each)
- `vu_input.png` -- Input VU meter (200x135)
- `vu_process.png` -- Process VU meter (200x135)
- `vu_output.png` -- Output VU meter (200x135)
- `toggle_reverse.png` -- Reverse toggle switch (80x70)
- `toggle_mic.png` -- Mic Input toggle switch (80x70)
- `button_play.png` / `button_play_wide.png` -- Play button
- `button_stop.png` / `button_stop_wide.png` -- Stop button
- `button_bypass.png` / `bypass_closeup.png` -- Bypass area

### Section Overview Crops
- `section_input_control.png` -- All 3 input knobs (340x130)
- `section_eq_faders.png` -- All 5 EQ faders with labels (310x320)
- `section_ir_modules.png` -- All 5 IR buttons (440x100)
- `section_reverb_control.png` -- All 4 reverb knobs (350x320)
- `section_output_control.png` -- All 3 output faders + toggles (350x390)
- `section_top_panel.png` -- VU meters and title (610x150)
- `section_transport.png` -- Transport buttons (190x100)
- `transport_full.png` -- Full transport area (280x130)

### Detail Crops
- `fader_handle_closeup.png` -- EQ fader handle detail
- `fader_eq_single.png` -- Single EQ fader full length
- `output_fader_handle_red.png` -- Red output fader handle detail
- `knob_number_ring_detail.png` -- Number ring around knob
- `output_on_off_switches.png` -- Both toggle switches
- `output_fader_labels.png` -- DRY SIGNAL / WET SIGNAL / OUTPUT labels
- `five_band_label.png` -- "FIVE-BAND INPUT EQ" label
- `title_bar.png` -- Title and VU meter area

### Full GUI
- `full_gui.png` -- Complete 1376x768 GUI image
