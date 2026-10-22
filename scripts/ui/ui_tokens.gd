class_name UiTokens
extends RefCounted
## Design tokens: the spacing scale, radii, type sizes and motion timings.
## Sizes are in base-resolution pixels (1080 x 1920 portrait).

# Spacing scale.
const S1 := 4
const S2 := 8
const S3 := 16
const S4 := 24
const S5 := 32

# Corner radii.
const RADIUS_SM := 12
const RADIUS_MD := 24
const RADIUS_LG := 32
const RADIUS_XL := 40
const RADIUS_PILL := 999

# Type scale (one family, Manrope).
const FONT_DISPLAY := 128
const FONT_SCORE := 80
const FONT_TITLE := 64
const FONT_VALUE := 48
const FONT_HEADING := 44
const FONT_BUTTON := 38
const FONT_BODY := 34
const FONT_SMALL := 30
const FONT_CAPTION := 24

const ICON := 56
const TOUCH_TARGET := 112

# Motion.
const SCREEN_IN := 0.2
const SCREEN_OUT := 0.15
const THEME_FADE := 0.35
const SLIDE := 24.0
