# Scrolling Ground + State Transitions Design

**Date:** 2026-05-07  
**Feature:** Activate progression-based ground scroll and add smooth state transition fades

## Goal

Polish the arcade experience by creating a sense of continuous forward momentum and cohesive state transitions. Retro arcade mechanical feel meets modern polish.

## Design

### Ground Scroll

**Current State:**
- `update_ground()` exists but scrolls at fixed 2 pixels/frame
- `get_obstacle_speed()` provides 6 speed levels based on score
- Ground offset is calculated but not currently used in draw

**Improvement:**
Ground scroll speed should scale with game progression (obstacle speed).

**Implementation:**
```lua
function update_ground()
    local spd = get_obstacle_speed() * 0.5  -- scale to ~half obstacle speed
    ground_offset = (ground_offset - spd) % screen_size
end
```

**Behavior:**
- At level 1 (obstacle speed 2): ground scrolls 1 pixel/frame
- At level 6 (obstacle speed 4.5): ground scrolls 2.25 pixels/frame
- Smooth acceleration as score increases
- Creates escalating tension and "world speeding up" effect

**Call Site:**
`_update()` already calls `update_ground()`, so no wiring needed

### State Transitions (Fades)

**Goal:**
Smooth cross-fade when changing states (splash ↔ game ↔ gameover) to create visual cohesion.

**Mechanism:**
- Add fade state tracking: `fade_timer` (0 = opaque, max = fully faded)
- Add fade direction: `fade_in` (true = fading in, false = fading out)
- When `change_state()` is called, trigger a fade-out, change state, fade-in sequence

**Fade Behavior:**
- Duration: ~4-6 frames (4 frames = ~0.067 seconds at 60fps, modern polish)
- Palette fade: gradually shift all colors toward black (fade out), then restore (fade in)
- Ground continues scrolling during fade (never stops)

**Call Sites:**
- Splash screen entry (fade in from black)
- Player input to start game (fade out → fade in on game state)
- Death transition to gameover (fade out → fade in on gameover state)
- Gameover restart (fade out → fade in on splash state)

**Implementation Details:**
- `fade_timer` increments each frame during transition
- Use palette manipulation similar to existing screen flash logic (see collect SFX implementation)
- Fade is opaque at start/end of transition, fully transparent in middle

### Drawing Order

Ground draws in `draw_background()` (before sprites). Fade happens in `_draw()` after all game content. Ground continues scrolling and is visible through fade.

### Behavior Specifics

**Game progression speed table (existing):**
```lua
local speeds = {2, 2.5, 3, 3.5, 4, 4.5}
```

**Ground scroll formula:**
- Level 1: 2 * 0.5 = 1 px/frame
- Level 2: 2.5 * 0.5 = 1.25 px/frame
- Level 3: 3 * 0.5 = 1.5 px/frame
- Level 4: 3.5 * 0.5 = 1.75 px/frame
- Level 5: 4 * 0.5 = 2 px/frame
- Level 6: 4.5 * 0.5 = 2.25 px/frame

**Fade timing:**
- Fade duration: 4 frames (current frame 0-3 = fade in progress, frame 4+ = complete)
- No fade on initial splash screen load (or fade in from black)

## Success Criteria

✓ Ground scroll activates and runs every frame  
✓ Ground speed increases smoothly as score increases  
✓ No visual stuttering or jarring motion  
✓ Smooth fades between all state transitions  
✓ Ground continues scrolling during fades  
✓ Fades feel intentional and polished (not jarring)  
✓ Game feels like a continuous arcade machine, not discrete scenes  
✓ Retro arcade feel + modern polish balance maintained
