# Arcade Juice Polish — Death, Collect, Level-Up Fanfare

**Date:** 2026-05-08  
**Status:** Design Spec (Ready for Implementation)

---

## Overview

Three complementary arcade polish improvements to amplify emotional impact at key player moments: death (every session end), power-up collection (rare rewards), and level transitions (progression milestones).

**Scope:** Particle effects, screen effects, SFX, text feedback — all visual/audio juice, no core gameplay changes.

---

## Feature 1: Death Sequence Drama

### Problem
Currently, dying is silent and instant — character vanishes, state cuts to "Game Over" with no feedback. Arcade games make death **theatrical** with visual/audio punch.

### Solution
When `change_state("gameover")` is triggered:
1. **Screen Shake:** 2-frame rapid horizontal jitter (±2px offset)
2. **Flash:** White/red flash overlay (2 frames, 100% opacity)
3. **SFX:** Crunchy death hit (descending tone or sharp beep)
4. **Pause:** 0.3 second hold before "Game Over" fade begins

**Timing:** Total 0.3-0.5s from death to "Game Over" state change.

### Implementation Details

**Variables to add (globals):**
- `death_timer = 0` — countdown for death sequence animation
- `death_active = false` — true during death sequence

**When death occurs:**
- In `update_player()` collision with obstacle: instead of immediate `change_state("gameover")`, set `death_active = true` and `death_timer = 30` (0.5s at 60 FPS)
- Game continues rendering normally during shake/flash

**Shake effect:**
- Frame 1: offset x by -2
- Frame 2: offset x by +2
- Applies to all game rendering

**Flash effect:**
- Overlay full screen with white (color 7) or red (color 8)
- 100% opacity for frames 1-2, then fade out

**SFX:**
- Use existing SFX slot (e.g., sfx ID 5 or 6) for death sound
- Single descending note or "bzzzzt" hit sound

**State transition:**
- After `death_timer` expires, call `change_state("gameover")` normally
- Fade state machine handles the rest

### Success Criteria
- Screen visibly shakes on death
- Brief flash of white/red
- Audible death hit SFX
- "Game Over" fade begins 0.3-0.5s later
- Feels punchy, not sluggish

---

## Feature 2: Power-Up Collect Juice

### Problem
Collecting power-ups is silent and invisible — the score increases, but there's no feedback that something special happened.

### Solution
When power-up is collected (collision detected):
1. **Screen Flash:** Brief white flash (1 frame, lighter than death)
2. **Text Feedback:** "+100" text appears at collection point, floats upward, fades out
3. **SFX:** Uplifting "ding" sound (higher pitch than death)

**Timing:** 0.5s animation (text float + fade).

### Implementation Details

**Floating text animation:**
- Create a temporary text object: `{x, y, value, timer, life}`
- Spawn at power-up collection point (power-up.x, power-up.y)
- Each frame: `y -= 0.5` (float upward), `alpha` decreases from 1 to 0
- Draw with reduced opacity as it fades
- Remove when `life <= 0`

**Screen flash:**
- 1-frame full-screen white overlay (color 7, 50% opacity via fillp)
- Lighter than death flash (less jarring during gameplay)

**SFX:**
- Single rising note or "ding" (SFX slot 7 or 8)
- Higher pitch than death sound for psychological "positive" association

**Variables to add:**
- `collect_floats = {}` — table of floating "+100" texts
- `collect_flash_timer = 0` — countdown for screen flash

**When power-up collected:**
- Add to `collect_floats`: `{x, y, value, timer, life = 30}`
- Set `collect_flash_timer = 1`
- Play SFX

**In `_update()`:**
- For each float: decrement timer, update position, remove if dead
- Decrement `collect_flash_timer`

**In `_draw()`:**
- Draw each float at calculated position with fading opacity
- Draw collect flash overlay if `collect_flash_timer > 0`

### Success Criteria
- Power-up collection produces white flash
- "+100" text rises upward and fades
- "ding" SFX plays on collection
- Animation is smooth, not jarring
- Multiple collects in sequence (if possible) don't break

---

## Feature 3: Level-Up Fanfare

### Problem
Level transitions are silent — just a brief text announcement. Arcade games celebrate progression with palette shifts, musical stings, and visual fanfare.

### Solution
When level increases (at score thresholds):
1. **Palette Shift:** Whole screen colors brighten/shift toward warm tones (colors shift up by 1-2 in palette, creating a warmer/brighter feel)
2. **Musical Sting:** Rising beep-boop SFX sequence (3-4 quick ascending tones, ~0.3s total)
3. **Level Announcement:** Existing level text pulses with brighter color during announcement

**Timing:** Palette shift + SFX last 0.3-0.5s, then restore. Level announcement already shows for 1s.

### Implementation Details

**Variables to add (globals):**
- `level_fanfare_timer = 0` — countdown for fanfare sequence
- `level_fanfare_active = false` — true during fanfare

**When level increases:**
- In `get_current_level()` logic or after score check
- Set `level_fanfare_active = true`, `level_fanfare_timer = 30` (0.5s at 60 FPS)

**Palette shift:**
- Each frame during fanfare, modify palette mapping: `pal(old_color, new_color)` for key colors
  - Dark colors (0, 1) → slightly brighter/warmer
  - Mid colors (2, 3) → shifted up
  - Keep bright colors (14, 15) unchanged
- After fanfare ends: `pal()` restores default palette

**Musical sting:**
- 3-4 ascending tones, each ~100ms apart
- Each tone slightly higher pitch than the last
- Play via existing SFX system (SFX slot 9 or 10)

**Level announcement existing code:**
- Already shows level text and quote
- During fanfare, draw level text in brighter color (color 10 or 11 instead of 7)

**In `_update()`:**
- Decrement `level_fanfare_timer`
- When it reaches 0, set `level_fanfare_active = false` and restore palette

**In `_draw()`:**
- Check `level_fanfare_active` — if true, apply modified palette
- Draw level announcement as normal (color will be affected by palette)

### Success Criteria
- Whole screen colors noticeably shift when level increases
- Bright musical sting plays (3-4 ascending tones)
- Level announcement text is part of the visual moment
- Palette restores cleanly after fanfare ends
- No palette glitches or color corruption

---

## Technical Integration

### Call Points

1. **Death Sequence:** In `update_player()` or collision handler, detect obstacle collision:
   ```lua
   if collision then
       death_active = true
       death_timer = 30
   end
   ```
   Then in `_update()` countdown and transition to gameover state.

2. **Collect Juice:** In power-up collision handler:
   ```lua
   if player_collides_power_up then
       add(collect_floats, {x, y, value, timer = 30})
       collect_flash_timer = 1
       sfx(7)
   end
   ```

3. **Level-Up Fanfare:** In score update logic when level changes:
   ```lua
   if new_level > old_level then
       level_fanfare_active = true
       level_fanfare_timer = 30
       sfx(9)
   end
   ```

### SFX Assignments
- SFX 5: Death hit (crunchy descending tone)
- SFX 7: Collect ding (rising tone)
- SFX 9: Level-up sting (ascending beep-boop sequence)

(Adjust if these slots are already used.)

### Drawing Order
In `_draw()`:
1. Normal game rendering (ground, obstacles, player, etc.)
2. Fade overlay (existing)
3. Collect floats (new)
4. Collect flash (new, if active)
5. Death shake/flash (new, if active)
6. Level announcement + fanfare palette applied
7. UI/HUD

---

## Success Criteria (All Features)

- ✅ Death feels punchy with shake + flash + SFX
- ✅ Power-up collection is rewarding with floating text + ding
- ✅ Level transitions are celebrated with palette shift + sting
- ✅ No performance impact (all effects are lightweight)
- ✅ Effects don't interfere with core gameplay
- ✅ Visual/audio feedback is clear and readable
- ✅ Multiple simultaneous effects (e.g., collect during level-up) don't break

---

## Edge Cases & Notes

1. **Multiple collects before collection resolves:** Floats should accumulate independently (multiple "+100" on screen at once is fine, even cool).
2. **Death during power-up animation:** Death sequence takes priority; floats continue but game state changes.
3. **Level-up during death sequence:** Fanfare queues after death sequence completes (or suppress fanfare during death).
4. **SFX slot conflicts:** If any slots are already used, reassign to unused slots (check existing sfx() calls).
5. **Palette restoration:** Always restore default palette after fanfare ends to prevent visual corruption.

---

## Estimated Scope

**Complexity:** Medium (adds state machines, animations, SFX management)  
**Files affected:** `oracle-odyssey.p8` only  
**Lines of code:** ~150-200 (shake/flash, float animation, fanfare logic)  
**No external dependencies.**
