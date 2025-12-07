# Arc_Swift - AI Coding Agent Instructions

## Project Overview
Arc_Swift is a **cross-platform rhythm game** built with **Godot Engine 4.4.1**, targeting both PC and mobile platforms. The game features a 7-lane note highway system with tap, long, and swipe note mechanics. The project prioritizes performance optimization, precise input handling, and dynamic content loading.

## Architecture & Core Systems

### Autoload Singletons (`globals/`)
The game uses 5 autoloaded global scripts that manage state across scenes:

1. **`ProfileData.gd`**: Player records (high scores, play counts, recent plays). Updates via `update_play_record()` and persists to `user://profile.json`
2. **`UserSettings.gd`**: User preferences (color modes, audio volumes, low-spec mode, **gameplay options**). Provides `linear_to_db_custom()` for volume conversion
   - **Gameplay Options**: Scroll speed (1.0-10.0), Effect (NONE/MIRROR/FADE_IN/FADE_OUT), Judgement display mode, Audio offset, Sudden death settings, Center display type, Note FX brightness
   - **Scroll Speed Formula**: `visible_time_range_ms = 3000.0 / scroll_speed` (Time = Constant / Speed)
     - Examples: 1.0x = 3000ms (3s), 5.0x = 600ms (0.6s), 10.0x = 300ms (0.3s)
   - **Mirror Effect**: Swaps lane indices (SIDE_L↔SIDE_R, MID_1↔MID_5, MID_2↔MID_4, MID_3 unchanged)
3. **`GameplayData.gd`**: Scene-to-scene data transfer (selected song/difficulty). Set by `select_song.gd`, read by `ingame.gd`
4. **`TextureLoader.gd`**: Asynchronous texture loading with priority queue system. Emits `texture_loaded` signal when complete
5. **`GlobalEnums.gd`**: Shared enumerations (`NoteType`, `Lane` 0-6)

### Scene Flow
```
boot.gd → splash_screen.tscn → main_menu.tscn → select_song.tscn → ingame.tscn → result.tscn
```

- **Boot**: Applies settings from `user://settings.cfg`, sets input mode (`Input.set_use_accumulated_input(false)`), auto-detects locale
- **Select Song**: Dynamically scans `res://song/` folders for `_category_*.json`, loads album covers via `TextureLoader` with priority system
- **Ingame**: 8-rail system (`Rail.gd`) with `NoteManager.gd` parsing Beatrice JSON format, spawning `NoteObject.tscn` instances

### Input System (CRITICAL)
**Godot 4.4.1 input handling with input buffer system:**

- **Use `_unhandled_input(event)` for gameplay input** to avoid conflicts with UI
- **Input Buffer System**: 50ms buffer (`INPUT_BUFFER_TIME_MS`) stores all inputs and processes them in `_process()`
- Call `event.is_action_pressed("action_name", true)` - the second `true` parameter ensures "just pressed" behavior
- Use **`if` statements** (not `elif`) for multi-lane simultaneous input detection
- Set `Input.set_use_accumulated_input(false)` in `boot.gd` for high polling rate devices
- **ESC Key**: Pauses game (shows `pause_popup`), Resume blocks input for 50ms after unpause
- Example pattern from `ingame.gd`:
  ```gdscript
  func _unhandled_input(event):
      if event.is_action_pressed("ui_cancel", true):  # ESC key
          _pause_game()
      if event.is_action_pressed("lane_1", true):
          input_buffer.append({"lane": GlobalEnums.Lane.SIDE_L, "time_ms": current_song_time_ms})
      # ... continue for all 7 lanes
  ```

### Timing & Synchronization
- **Use `_process(delta)` for gameplay updates**, NOT `_physics_process()`
- Song time tracked via `music_player.get_playback_position() * 1000.0` (milliseconds)
- **Pre-Start Timeline**: READY state starts at `-3000ms`, increments to `0ms` over 3 seconds, then music starts
- Note spawn timing calculated from `Rail` positions in global→local coordinate space
- **Judgement Rules (Current Implementation)**:
  - **TAP/LONG Notes**:
    - **Perfect**: ±30ms (100% score)
    - **Great**: ±60ms (75% score)
    - **Good**: ±100ms (50% score)
    - **Miss**: Beyond ±100ms (0% score)
  - **SWIPE Notes (First Note)**: Same as TAP (±30/60/100ms)
  - **SWIPE Notes (Follow-up Notes)**: More lenient timing
    - **Perfect**: ±75ms (100% score)
    - **Great**: ±100ms (75% score)
    - **Good**: ±125ms (50% score)
    - **Miss**: Beyond ±125ms (0% score)
  - Note: Always prioritize the highest judgement.

### Note Types & Processing

#### TAP Notes
- Standard single-hit notes
- Processed via `_process_tap_note()` in `ingame.gd`
- Input: Key press (`is_action_pressed` with just_pressed=true)

#### LONG Notes (Hold)
- Notes with duration, displayed as elongated bars (green color)
- `time_ms`: Start time (head reaches judge line)
- `duration_ms`: Length of hold
- Visual: Note bottom (head) at `time_ms`, top (tail) at `time_ms + duration_ms`
- **Processing**:
  - Start: Judged via `_process_long_note_start()` with TAP rules
  - Hold: Note moves to `holding_long_notes` dictionary, stays visible while key held
  - Release: Note removed when key released OR when tail passes judge line
  - `_process_holding_long_notes()` checks hold state every frame

#### SWIPE Notes
- Multi-lane sweeping notes with `is_swipe_head` flag
- **First note** (`is_swipe_head = true`): Standard TAP judgement
- **Follow-up notes** (`is_swipe_head = false`): Lenient judgement (±75/100/125ms)
- Each note is independently judged; mid-chain misses don't break subsequent notes
- **Input methods** (both work):
  - Hold key and slide to next lane (mobile swipe gesture equivalent)
  - Tap each key individually (PC keyboard friendly)
- Processed via `_process_swipe_note()` with `_process_held_keys_for_swipe()` for hold detection

### Scoring System
- **Combo System**: Increments on every non-Miss judgement, resets to 0 on Miss
- **Rate Percentage**: `(total_score_points / processed_notes_count) * 100`
  - Perfect = 1.0 point (100%), Great = 0.75 (75%), Good = 0.5 (50%), Miss = 0.0 (0%)
  - Displayed as "Rate: XX.XX%" with 2 decimal places
- **Center Display Modes**:
  - SCORE: Shows rate percentage
  - COMBO: Shows "N Combo" (empty if combo = 0)
  - SUDDEN_COUNT: Shows remaining lives (TODO)

### Pause System
- **ESC Key**: Toggle pause popup (Resume/Restart/Select Music buttons)
- **Resume**: Unpause with 50ms input block (`input_block_time_ms`)
- **Restart**: Calls `_restart_game()` (same as F5)
- **Select Music**: Returns to song selection without saving
- Pause popup uses CanvasLayer (layer=100) for z-index priority

## Chart System

### Chart System (Migration in Progress)

#### Target Custom JSON Format (Goal)
We are **migrating AWAY from Beatrice format**. The new `NoteManager.gd` must parse a custom JSON structure with the following specification:

**Format Structure:**
```json
{
  "metadata": {
    "title": "Song Title",
    "artist": "Artist Name",
    "bpm": 130.0,
    "audio_file": "path/to/song.mp3",
    "playlevel": 1,
    "charter": "User"
  },
  "timeline_events": [
    {
      "time": 30000,
      "type": "bpm_change",
      "value": 150.0
    }
  ],
  "notes": [
    {
      "line": 2,
      "time": 10500,
      "type": "tap",
      "duration": 0
    },
    {
      "line": 3,
      "time": 11200,
      "type": "hold",
      "duration": 750
    },
    {
      "line": 1,
      "time": 12000,
      "type": "swift",
      "duration": 0,
      "group_id": 1
    },
    {
      "line": 8,
      "time": 15000,
      "type": "change",
      "duration": 0,
      "active_lines": [0, 1, 2, 3]
    }
  ]
}
```

**Key Specifications:**
- **Time Units**: All time values (`time`, `duration`) are in milliseconds (integer). Example: 1.5 seconds = 1500
- **Note Types**: 4 basic types via `type` field:
  - `"tap"`: Single tap note (duration = 0)
  - `"hold"`: Long note with duration in ms
  - `"swift"`: Swipe note (duration = 0, uses `group_id` for grouping)
  - `"change"`: Lane activation change (uses `active_lines` array)
  - Event lane notes can have additional types: `"stop"`, `"speed"`, `"bpm"`
- **Line Numbers**: `line` is zero-indexed integer:
  - `0 ~ N-1`: Active playable lanes (visible notes)
  - `N ~ N+4`: Temporary lanes (for chart efficiency, not displayed)
  - `N+5`: Event lane (scroll speed/BPM changes, affects gameplay but not displayed)
- **Lane Placement Rules**:
  - **Side Lanes**: Lowest number = Left side lane, Highest number = Right side lane
  - **Center Lanes**: Remaining notes (excluding side lanes) are grouped in pairs of 2, starting from lowest number
  - Each pair maps to one center lane, using the same input key
  - Pairs are assigned from left to right: first pair → MID_1, second pair → MID_2, etc.
  - Example with 12 active lanes (0-11):
    - Lane 0 → SIDE_L (left side)
    - Lanes 1,2 → MID_1 (same key)
    - Lanes 3,4 → MID_2 (same key)
    - Lanes 5,6 → MID_3 (same key)
    - Lanes 7,8 → MID_4 (same key)
    - Lanes 9,10 → MID_5 (same key)
    - Lane 11 → SIDE_R (right side)
- **Sorting Requirement**: `notes` array **MUST** be sorted by `time` in ascending order
- **Timeline Events**: Array for BPM changes, stops, scroll speed modifications (types: `"bpm_change"`, `"scroll_speed"`, `"stop"`)

**Task**: Implementing this parser is a **high priority**.

#### Legacy Beatrice Format (Deprecated)
Currently used but **slated for replacement**. Uses `notes[]` and `links[]` with Lane 2-12 mapping.

**Legacy Mapping**: `2→SIDE_L`, `4→MID_1`, `6→MID_2`, `8→MID_3`, `10→MID_4`, `12→MID_5`, `14→SIDE_R`
- See `NoteManager.gd::_map_beatrice_lane_to_7()` for current implementation

Legacy format example with new metadata fields:
```json
{
  "bpm": 100,
  "offset": 0,
  "charter": "Example Charter",
  "is_regular_difficulty": true,
  "charts": [{
    "notes": [{"songPos": 3000, "lane": 10, ...}],
    "links": [{
      "startNote": {"songPos": 5000, "lane": 8},
      "endNote": {"songPos": 6000, "lane": 6},
      "tick_count": 5
    }]
  }]
}
```

**Chart Metadata Fields**:
- `charter` (string): Chart designer name (displayed in album cover info, empty string if not specified)
- `is_regular_difficulty` (bool): Difficulty type flag
  - `true`: Regular difficulty (white border on album cover)
  - `false`: Extra difficulty like OD/IV/IN (black border on album cover)
  - Default: `true` if not specified

### Song Database Structure
- `song/_song_db.json`: Global song metadata (title, artist, BPM)
- `song/{Category}/_category_{name}.json`: Category manifest with song list
- `song/{Category}/Chart/{song}_Chart_{difficulty}.json`: Individual chart files (includes charter and is_regular_difficulty)

## UI & Rendering

### Dynamic Layout (Select Song)
`select_song.gd` calculates cover positions based on viewport size:
```gdscript
cover_size = Vector2(stage_height * 0.75, stage_height)
side_cover_gap = stage_height * 0.05
```
- Uses `set_deferred("size", ...")` to avoid layout conflicts with Godot's internal rendering cycle
- Marker system with 5 positions: center (0), side (±1), outer (±2)

### Album Cover Display
`album_cover.tscn` shows song information with dynamic metadata:

**Layout Structure**:
- BorderRect (ColorRect): Outer border, color changes based on difficulty type
  - White: Regular difficulty (EZ/NM/HD)
  - Black: Extra difficulty (OD/IV/IN)
- MarginContainer (3px margins): Creates border effect
  - Background (ColorRect): Dark background (0.1, 0.1, 0.1)
  - ContentBox (VBoxContainer): Album image + info labels
    - AlbumJacket (TextureRect): Album cover image (fallback to default image if missing)
    - InfoContainer (VBoxContainer): 3 labels with 2px separation
      - TitleLabel: Song title (centered, top)
      - ArtistLabel: Artist name (centered, middle, hidden if empty)
      - CharterLabel: "Charter: Name" (left-aligned, bottom, hidden if empty)

**Data Flow**:
1. `select_song.gd::_update_display()` calls `_load_chart_metadata(chart_path)` to load charter and is_regular_difficulty
2. Calls `album_cover.set_song_data(song_data, chart_data)` to display title/artist/charter
3. Calls `album_cover.set_border_color(is_regular)` to set border color
4. Calls `album_cover.set_texture(texture)` to load album jacket image

### Rail System (Ingame)
GameGear.tscn contains 8 `Rail` nodes with `@export` properties:
- `top_y`: Note spawn position (always 0, top of screen)
- `judge_y`: Judgement line position (dynamically set to viewport_height - 200)
- **Resolution Independence**: GameGear.gd sets rail positions and judge_y based on viewport size in `_ready()`
- Coordinate conversion: Global positions → GameGear local space via `get_global_transform_with_canvas().affine_inverse()`

### Note Rendering
`NoteObject.tscn` uses **Top-Left anchor**:
- Width: Distance between left/right rail minus `VISUAL_MARGIN`
- Position X: Left rail X + (VISUAL_MARGIN / 2)
- Long note height: `(duration_ms / 1000.0) * note_speed_pixels_per_sec`

### Ingame Options Popup
- `ingame_option_popup.tscn`: CanvasLayer (layer=100) UI popup for gameplay settings
- Accessible from select_song scene via OptionsButton
- Settings: Scroll speed (1.0-10.0), Effect, Judgement display, Audio offset, Sudden death, Center display, Note FX brightness
- Saves to `user://settings.cfg` [Gameplay] section
- Uses `RootControl` child node for proper UI hierarchy under CanvasLayer

## Settings & Platform Differences

### PC-Specific Features
- Screen mode: Fullscreen / Exclusive Fullscreen / Windowed
- Resolution: Native + predefined 16:9 resolutions (3840×2160 to 1280×720)
- Frame limit: 60/75/90/120/144/240/360/400 FPS or unlimited
- Audio device selection via `AudioServer.get_output_device_list()`
- Background audio toggle, compressor effect

### Mobile Optimizations
- Fixed resolution (no screen mode/resolution options)
- Limited frame rates (30/60 FPS)
- Simplified audio settings (no device selection/compressor)
- Low-spec mode flag in `UserSettings` (implementation pending)

### Audio System
- Buffer size controls latency: `(buffer_size / mix_rate) * 1000ms`
- Volume conversion: `linear_to_db(linear_val / 10.0)` where `linear_val` is 0-10
- Separate buses: Master, Music, SFX, UI
- Audio plays on Music bus with effect sends (see `default_bus_layout.tres`)

## Resolution Independence

**CRITICAL**: All UI and gameplay elements MUST be resolution-independent:

- **Use viewport size**: `get_viewport_rect().size` instead of hardcoded values
- **Use anchors**: Set anchors for UI elements (e.g., `anchor_top = 1.0` for bottom-aligned)
- **Use percentages**: Calculate positions/sizes as percentage of viewport (e.g., `viewport_size.x * 0.5`)
- **Dynamic initialization**: Set positions in `_ready()` based on actual viewport size
- **Examples**:
  - `GameGear.gd`: Sets rail `judge_y = viewport_size.y - 200` at runtime
  - `JudgementLine`: Uses `anchor_top = 1.0` with `offset_top = -200`
  - `JudgementLabel`: Size is `viewport_size.x * 0.3`, position is calculated from viewport center

**Why**: Game targets both PC (various resolutions) and mobile (different aspect ratios). Hardcoded pixel values will break layouts.

## Development Conventions

### GDScript Style
- Use `@onready` for node references
- Prefer `await` over `yield` (Godot 4 syntax)
- Use typed arrays: `Array[Dictionary]`, `Array[Rail]`
- Enums in GlobalEnums, not per-file
- Scene preloading: `preload("res://path/to/scene.tscn")`

### Resource Paths
- User data: `user://` (settings.cfg, profile.json)
- Game assets: `res://` (absolute paths from project root)
- Charts: `res://song/{Category}/Chart/{file}.json`
- Audio: `.ogg` files, loaded via `load(path)` to AudioStream

### Localization
- Supported locales: `en`, `ja`, `ko`
- `.po` files in `language/` folder
- Auto-detection in `boot.gd::_get_initial_locale()`
- Use `tr("KEY")` for translatable strings (implementation pending)

### Debugging
- F5 key: Restart ingame state (`_restart_game()` in `ingame.gd`)
- Debug data loader: Falls back to `example_no_commercial` song if GameplayData is empty
- `printerr()` for critical errors, `print()` for status messages

## Known Issues & TODOs

### High Priority
1. **New Chart Format Implementation**: `NoteManager.gd` requires a **complete rewrite** to support the new custom JSON format (`timeline_events`), replacing the current Beatrice parser.
2. **Note positioning**: Visual alignment issues if Rail `top_y`/`judge_y` values are incorrect

### Pending Features
- Hold note full duration scoring (currently only start timing is judged)
- Result screen implementation (stubbed)
- Colorblind mode application (palette defined, not applied to notes)
- Search tags in song database
- Ultimate judgement tier (±25ms, currently not implemented)

### Completed (Recent)
- ✅ Input buffer system (50ms buffer for precise timing)
- ✅ SWIPE note dual-input support (tap or hold+slide)
- ✅ SWIPE note lenient judgement for follow-up notes
- ✅ LONG note visual rendering (head at time_ms, tail at time_ms + duration_ms)
- ✅ Pause system with process_mode handling
- ✅ F5 restart functionality

## Testing & Running

### Project Settings
- Godot 4.4.1 (Mobile renderer)
- Display: 1920×1080, fullscreen by default
- Physics ticks: Default (60 tps, do NOT modify for input handling)

### Entry Point
Main scene: `boot.tscn` (set in `project.godot` as `run/main_scene`)

### Debug Commands
```gdscript
# In ingame.gd, add test functions:
func _test_spawn_note():
    var test_data = {"time_ms": current_song_time_ms + 2000, "lane": 3, "note_type": GlobalEnums.NoteType.TAP}
    _spawn_note(test_data)
```

### Common Errors
- **"Invalid time_to_judge_ms"**: Rail positions not initialized before note spawn
- **"GameGear not found"**: Check GameplayUI scene has GameGear.tscn instanced
- **Texture not loading**: Verify `TextureLoader.texture_loaded` signal connected in `_ready()`

## MCP Integration
Project uses Godot MCP plugin (`addons/gdai-mcp-plugin-godot/`) for AI-assisted development. MCP server configured in `.vscode/mcp.json`.

---

**When modifying this codebase:**
1. Always check Godot 4.4.1 API changes (use `linear_to_db` not `linear2db`, `FileAccess` not `File`)
2. Test input changes with both keyboard and touch devices
3. Verify coordinate space conversions when changing Rail/NoteObject logic
4. Update ProfileData after gameplay (result screen integration pending)
5. Preserve backwards compatibility with existing chart files
