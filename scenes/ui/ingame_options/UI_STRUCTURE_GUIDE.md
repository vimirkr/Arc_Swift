# Ingame Option Popup - UI Scene Structure Guide
# res://scenes/ui/ingame_options/ingame_option_popup.tscn

## Node Tree Structure:

```
IngameOptionPopup (Control)
├── ColorRect (Background overlay - semi-transparent black)
│   └── anchors_preset = 15 (full screen)
│   └── color = Color(0, 0, 0, 0.7)
│   └── mouse_filter = MOUSE_FILTER_STOP
└── MarginContainer
    └── anchors_preset = 8 (center)
    └── custom_minimum_size = Vector2(800, 600)
    └── offset_left = -400
    └── offset_top = -300
    └── offset_right = 400
    └── offset_bottom = 300
    └── Panel (Background panel)
    └── VBoxContainer
        └── add_theme_constant_override("separation", 15)
        ├── Label (Title: "INGAME OPTIONS")
        │   └── horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        │   └── add_theme_font_size_override("font_size", 32)
        │
        ├── HSeparator
        │
        ├── HBoxContainer (ScrollSpeedContainer)
        │   ├── Label ("Scroll Speed:")
        │   │   └── custom_minimum_size = Vector2(200, 0)
        │   ├── HSlider (ScrollSpeedSlider)
        │   │   └── size_flags_horizontal = SIZE_EXPAND_FILL
        │   └── SpinBox (ScrollSpeedSpinBox)
        │       └── custom_minimum_size = Vector2(100, 0)
        │
        ├── HBoxContainer (EffectContainer)
        │   ├── Label ("Effect:")
        │   │   └── custom_minimum_size = Vector2(200, 0)
        │   └── OptionButton (EffectButton)
        │       └── size_flags_horizontal = SIZE_EXPAND_FILL
        │
        ├── HBoxContainer (JudgementDisplayContainer)
        │   ├── Label ("Judgement Display:")
        │   │   └── custom_minimum_size = Vector2(200, 0)
        │   └── OptionButton (JudgementDisplayButton)
        │       └── size_flags_horizontal = SIZE_EXPAND_FILL
        │
        ├── HBoxContainer (AudioOffsetContainer)
        │   ├── Label ("Audio Offset:")
        │   │   └── custom_minimum_size = Vector2(200, 0)
        │   └── SpinBox (AudioOffsetSpinBox)
        │       └── size_flags_horizontal = SIZE_EXPAND_FILL
        │
        ├── HBoxContainer (SuddenDeathContainer)
        │   ├── Label ("Sudden Death:")
        │   │   └── custom_minimum_size = Vector2(200, 0)
        │   └── CheckBox (SuddenDeathCheck)
        │       └── text = ""
        │
        ├── HBoxContainer (SuddenDeathLimitContainer)
        │   ├── Label ("Sudden Death Limit:")
        │   │   └── custom_minimum_size = Vector2(200, 0)
        │   └── OptionButton (SuddenDeathLimitButton)
        │       └── size_flags_horizontal = SIZE_EXPAND_FILL
        │
        ├── HBoxContainer (CenterDisplayContainer)
        │   ├── Label ("Center Display Info:")
        │   │   └── custom_minimum_size = Vector2(200, 0)
        │   └── OptionButton (CenterDisplayButton)
        │       └── size_flags_horizontal = SIZE_EXPAND_FILL
        │
        ├── HBoxContainer (NoteFXContainer)
        │   ├── Label ("Note FX Brightness:")
        │   │   └── custom_minimum_size = Vector2(200, 0)
        │   └── HSlider (NoteFXSlider)
        │       └── size_flags_horizontal = SIZE_EXPAND_FILL
        │
        ├── HSeparator
        │
        └── Button (CloseButton)
            └── text = "Close"
            └── size_flags_horizontal = SIZE_SHRINK_CENTER
```

## Important Notes:

1. **Root Node (IngameOptionPopup)**:
   - Type: Control
   - Script: res://scenes/ui/ingame_options/ingame_option_popup.gd
   - anchors_preset = 15 (full screen)
   - Initially hidden (visible = false)

2. **ColorRect Background**:
   - Semi-transparent overlay to dim the game behind the popup
   - mouse_filter = MOUSE_FILTER_STOP to prevent clicks passing through

3. **Center Display Info Position**:
   - This label will appear in-game ABOVE the JudgementLabel
   - Position: Same horizontal center as JudgementLabel
   - Y offset: JudgementLabel.offset_top - 80 (약간 위)
   - Font size: 40pt
   - Horizontal/Vertical alignment: CENTER

4. **All Labels with tr() keys**:
   - Use tr("KEY") for all user-facing text
   - Translation keys defined in language/*.po files

## Translation Keys Required:

Add these to `language/*.po` files:

```
# Ingame Options
msgid "EFFECT_NONE"
msgstr "None"

msgid "EFFECT_MIRROR"
msgstr "Mirror"

msgid "EFFECT_FADE_IN"
msgstr "Fade In"

msgid "EFFECT_FADE_OUT"
msgstr "Fade Out"

msgid "JUDGEMENT_ALL_EXCEPT_ULTIMATE"
msgstr "All Except Ultimate"

msgid "JUDGEMENT_BELOW_PERFECT"
msgstr "Below Perfect Only"

msgid "JUDGEMENT_HIDE"
msgstr "Hide"

msgid "JUDGEMENT_OFF"
msgstr "Off"

msgid "CENTER_DISPLAY_SCORE"
msgstr "Score"

msgid "CENTER_DISPLAY_COMBO"
msgstr "Combo"

msgid "CENTER_DISPLAY_SUDDEN_COUNT"
msgstr "Sudden Count"

msgid "CENTER_DISPLAY_OFF"
msgstr "Off"

msgid "CENTER_DISPLAY_FIXED_SUDDEN"
msgstr "Fixed (Sudden Death)"
```

## Integration with Select Song Scene:

In `select_song.gd`, add:

```gdscript
@onready var ingame_options_popup = $IngameOptionsPopup

func _ready():
    # ... existing code ...
    ingame_options_button.pressed.connect(_on_ingame_options_pressed)

func _on_ingame_options_pressed():
    ingame_options_popup.show()
```

Add the popup as a child of the select_song scene root node.
