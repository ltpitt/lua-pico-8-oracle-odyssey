# Arcade Juice Polish Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task.

**Goal:** Implement death drama, power-up collect feedback, and level-up fanfare with screen effects, SFX, and text animations.

**Architecture:** 
- Death sequence: Collision detection → state machine (shake/flash 2-3 frames) → gameover transition
- Collect juice: Collision → float animation system with random humor text + flash + SFX
- Level fanfare: Obstacle count milestone detection → palette shift + SFX + enhanced level announcement

**Tech Stack:** PICO-8 Lua, particle/animation tables, palette manipulation, SFX system

---

## File Structure

**Single file modified:** `oracle-odyssey.p8`

**Key sections:**
- Globals (~85-100): Add death/collect/fanfare state variables
- Humor text list: New function with table of phrases
- Death sequence: New `handle_death_sequence()` function
- Collect floats: New `draw_floats()` function and float animation update
- Level fanfare: New `handle_level_fanfare()` function
- Collision handlers: Modify `check_collisions()` and `collect_power_up()` to trigger effects
- Main draw loop: Add shake offset, flash/collect overlays, float rendering, palette shifts

---

## Tasks

### Task 1: Add Death and Fanfare Globals

**Files:**
- Modify: `oracle-odyssey.p8` (globals section, ~85-100)

- [ ] **Step 1: View current globals section**

Around line 85-100, locate where `fade_timer`, `fading`, `particles` are declared.

- [ ] **Step 2: Add death sequence globals**

After `fade_duration = 4`, add:
```lua
death_timer = 0
death_active = false
```

- [ ] **Step 3: Add collect floats globals**

After death globals, add:
```lua
collect_floats = {}
collect_flash_timer = 0
```

- [ ] **Step 4: Add level fanfare globals**

After collect globals, add:
```lua
level_fanfare_timer = 0
level_fanfare_active = false
prev_level = 0
```

- [ ] **Step 5: Commit**

```bash
cd "/Users/xt41vb/Library/Application Support/pico-8/carts/lua-pico-8-oracle-odyssey"
git add oracle-odyssey.p8
git commit -m "feat: add death, collect, fanfare globals"
```

---

### Task 2: Create Humor Text List Function

**Files:**
- Modify: `oracle-odyssey.p8` (add new function before `add_obstacle()`, ~200)

- [ ] **Step 1: View the area around line 200**

Find `function add_obstacle()` at line 203. We'll add the humor function just before it.

- [ ] **Step 2: Add humor text function**

Insert before `function add_obstacle()`:
```lua
function get_random_humor()
    local phrases = {
        "YEET!",
        "BUSSIN'",
        "SHIP IT",
        "PERFECT",
        "NO BUGS",
        "PROD READY",
        "UNDEFEATED",
        "BIG BRAIN",
        "HUGE W",
        "UNSTOPPABLE"
    }
    return phrases[flr(rnd(#phrases)) + 1]
end
```

- [ ] **Step 3: Commit**

```bash
git add oracle-odyssey.p8
git commit -m "feat: add get_random_humor function"
```

---

### Task 3: Implement Death Sequence Trigger

**Files:**
- Modify: `oracle-odyssey.p8` (function `check_collisions()`, ~764-785)

- [ ] **Step 1: View check_collisions function**

Around line 764-785. This is where `change_state(game.states.gameover)` is called.

- [ ] **Step 2: Replace state change with death sequence trigger**

Find these lines (around 780):
```lua
change_state(game.states.gameover)
```

Replace with:
```lua
death_active = true
death_timer = 30
```

Keep the `game.game_over = true` line after it.

- [ ] **Step 3: Verify structure**

The collision handler should now trigger death sequence instead of immediate state change. The actual state change will happen after death_timer expires.

- [ ] **Step 4: Commit**

```bash
git add oracle-odyssey.p8
git commit -m "feat: trigger death sequence on collision"
```

---

### Task 4: Implement Death Sequence Handler in Update Loop

**Files:**
- Modify: `oracle-odyssey.p8` (function `_update60()`, ~137+)

- [ ] **Step 1: View _update60 function**

Locate where `update_particles()` and `update_ground()` are called (around line ~200).

- [ ] **Step 2: Add death sequence update logic**

After `update_ground()`, add:
```lua
-- Handle death sequence animation
if death_active then
    death_timer = death_timer - 1
    if death_timer <= 0 then
        death_active = false
        change_state(game.states.gameover)
    end
end
```

- [ ] **Step 3: Commit**

```bash
git add oracle-odyssey.p8
git commit -m "feat: implement death sequence countdown"
```

---

### Task 5: Implement Death Sequence Draw Logic (Shake + Flash)

**Files:**
- Modify: `oracle-odyssey.p8` (function `_draw()`, ~171+)

- [ ] **Step 1: View _draw function structure**

The _draw function starts at line 171. Locate where the main game rendering happens (before UI).

- [ ] **Step 2: Add death shake offset variable at draw start**

At the very beginning of `_draw()`, after any local declarations, add:
```lua
local shake_x = 0
if death_active then
    shake_x = (death_timer % 2 == 0) and -2 or 2
end
```

- [ ] **Step 3: Apply shake offset to all game rendering**

Find where obstacles are drawn (around line ~490+). Before each `rectfill()` or drawing command in the game scene, add `+ shake_x` to x coordinates.

For example, if you see:
```lua
rectfill(obstacle.x, obstacle.y, ...)
```

Change to:
```lua
rectfill(obstacle.x + shake_x, obstacle.y, ...)
```

Do this for: obstacles, player, ground pattern, power-ups. (Approximately 5-8 locations)

- [ ] **Step 4: Add death flash after game rendering**

After all game elements are drawn, before UI, add:
```lua
-- Death flash overlay
if death_active and death_timer < 5 then
    fillp(0.5)
    rectfill(0, 0, 127, 127, 7)  -- white flash
    fillp()
end
```

- [ ] **Step 5: Verify visually**

Code should not have syntax errors. Shake offset and flash are applied conditionally.

- [ ] **Step 6: Commit**

```bash
git add oracle-odyssey.p8
git commit -m "feat: add death sequence shake and flash effects"
```

---

### Task 6: Add Death SFX

**Files:**
- Modify: `oracle-odyssey.p8` (function `check_collisions()`, ~764-785)

- [ ] **Step 1: View check_collisions collision point**

Around line 769-780, where we trigger death.

- [ ] **Step 2: Add SFX call when death triggers**

Where we set `death_active = true`, add:
```lua
death_active = true
death_timer = 30
sfx(5)  -- death hit sound
```

- [ ] **Step 3: Note**

SFX ID 5 is assumed available. If it's already in use, change to 6, 7, or another free slot.

- [ ] **Step 4: Commit**

```bash
git add oracle-odyssey.p8
git commit -m "feat: add death SFX"
```

---

### Task 7: Implement Collect Float System

**Files:**
- Modify: `oracle-odyssey.p8` (add new function, ~400+)

- [ ] **Step 1: Add float update function**

After `collect_power_up()` function (around line ~413+), add:
```lua
function update_collect_floats()
    for float in all(collect_floats) do
        float.timer = float.timer - 1
        float.y = float.y - 0.5
        if float.timer <= 0 then
            del(collect_floats, float)
        end
    end
end
```

- [ ] **Step 2: Call update_collect_floats in _update60**

In `_update60()`, after other updates (around line ~290+), add:
```lua
update_collect_floats()
```

- [ ] **Step 3: Commit**

```bash
git add oracle-odyssey.p8
git commit -m "feat: add collect float update system"
```

---

### Task 8: Implement Collect Flash and Trigger

**Files:**
- Modify: `oracle-odyssey.p8` (function `collect_power_up()`, ~413+)

- [ ] **Step 1: View current collect_power_up function**

Locate around line 413. It likely sets `game.power_ups_collected` or similar.

- [ ] **Step 2: Add float spawn and effects**

At the start of `collect_power_up()`, add (before any existing logic):
```lua
-- Spawn floating humor text at player position
local float = {
    x = player.x + 4,
    y = player.y,
    text = get_random_humor(),
    timer = 30,
    opacity = 1
}
add(collect_floats, float)

-- Trigger flash
collect_flash_timer = 1

-- Play SFX
sfx(7)  -- collect ding
```

- [ ] **Step 3: Keep existing logic after**

The rest of `collect_power_up()` (score update, power-up effect, etc.) should remain unchanged.

- [ ] **Step 4: Commit**

```bash
git add oracle-odyssey.p8
git commit -m "feat: trigger collect float, flash, and SFX"
```

---

### Task 9: Add Collect Float Drawing

**Files:**
- Modify: `oracle-odyssey.p8` (function `_draw()`, add new render logic)

- [ ] **Step 1: View _draw function**

Locate the section after all game rendering but before UI (around line ~500+).

- [ ] **Step 2: Add collect float rendering**

After death flash but before UI, add:
```lua
-- Draw collect floats
for float in all(collect_floats) do
    local opacity = float.timer / 30
    local col = 7  -- white
    print(float.text, float.x, float.y, col)
end

-- Draw collect flash
if collect_flash_timer > 0 then
    fillp(0.5)
    rectfill(0, 0, 127, 127, 7)  -- white flash, semi-transparent
    fillp()
    collect_flash_timer = collect_flash_timer - 1
end
```

- [ ] **Step 3: Note on opacity**

PICO-8 doesn't have built-in opacity for text, so we fade the text by drawing it multiple times with decreasing "presence" or just let it naturally appear/disappear. The above is simplified for PICO-8 compatibility.

- [ ] **Step 4: Commit**

```bash
git add oracle-odyssey.p8
git commit -m "feat: add collect float and flash drawing"
```

---

### Task 10: Implement Level Fanfare Trigger

**Files:**
- Modify: `oracle-odyssey.p8` (function `_update60()`, ~137+)

- [ ] **Step 1: View _update60**

Locate around line 137.

- [ ] **Step 2: Add level detection logic**

After all other updates (around line ~220), add:
```lua
-- Detect level changes
local current_level = get_current_level()
if current_level > prev_level then
    level_fanfare_active = true
    level_fanfare_timer = 30
    sfx(9)  -- fanfare SFX
    prev_level = current_level
end
```

- [ ] **Step 3: Add fanfare countdown**

After the level detection, add:
```lua
-- Update fanfare timer
if level_fanfare_active then
    level_fanfare_timer = level_fanfare_timer - 1
    if level_fanfare_timer <= 0 then
        level_fanfare_active = false
        pal()  -- restore palette
    end
end
```

- [ ] **Step 4: Commit**

```bash
git add oracle-odyssey.p8
git commit -m "feat: implement level fanfare detection and countdown"
```

---

### Task 11: Implement Palette Shift in Draw Loop

**Files:**
- Modify: `oracle-odyssey.p8` (function `_draw()`, at start)

- [ ] **Step 1: View _draw function start**

Beginning of `_draw()`, around line 171.

- [ ] **Step 2: Add palette shift logic at draw start**

Right at the beginning of `_draw()`, after any initial rendering setup, add:
```lua
-- Apply fanfare palette shift
if level_fanfare_active then
    local progress = (30 - level_fanfare_timer) / 30
    if progress < 0.5 then
        -- Fade toward warm (brighten colors)
        pal(0, 1)   -- black -> dark blue
        pal(1, 2)   -- dark blue -> dark teal
        pal(2, 3)   -- etc...
        pal(3, 5)
        pal(5, 10)  -- shift mid tones upward
    else
        -- Fade back to normal
        pal()
    end
end
```

- [ ] **Step 3: Adjust palette mapping if needed**

The exact color transitions depend on your palette. Test and adjust `pal(old_color, new_color)` calls to achieve warm/bright shift.

- [ ] **Step 4: Commit**

```bash
git add oracle-odyssey.p8
git commit -m "feat: implement level fanfare palette shift"
```

---

### Task 12: Update Level Announcement Color During Fanfare

**Files:**
- Modify: `oracle-odyssey.p8` (function `draw_level_info()`, ~801+)

- [ ] **Step 1: View draw_level_info function**

Around line 801. It draws the level announcement text.

- [ ] **Step 2: Find the color selection logic**

It likely has a line like:
```lua
local col = flr(game.level_announcement / 8) % 2 == 0 and 7 or 10
```

- [ ] **Step 3: Brighten color during fanfare**

Modify to:
```lua
local col = flr(game.level_announcement / 8) % 2 == 0 and 7 or 10
if level_fanfare_active then
    col = 11  -- brighter color during fanfare
end
```

- [ ] **Step 4: Commit**

```bash
git add oracle-odyssey.p8
git commit -m "feat: brighten level announcement during fanfare"
```

---

### Task 13: Manual Testing and SFX Verification

**Files:**
- Test: Oracle Odyssey gameplay

- [ ] **Step 1: Launch PICO-8 and load cart**

```bash
cd "/Users/xt41vb/Library/Application Support/pico-8"
open . -a PICO-8.app
```

Load `oracle-odyssey.p8`.

- [ ] **Step 2: Test death sequence**

Play game, get hit. Observe:
- Screen shakes (±2px horizontal jitter)
- White flash appears briefly
- Death SFX (ID 5) plays
- "Game Over" fades in normally after 0.3-0.5s

- [ ] **Step 3: Test power-up collection**

Play game, collect power-up. Observe:
- Humor text floats upward and fades
- Brief white flash on screen
- "ding" SFX (ID 7) plays

- [ ] **Step 4: Test level-up fanfare**

Play until level 2+ (obstacle count > 5). Observe:
- Screen palette shifts toward warm/bright
- Rising SFX sting (ID 9) plays
- Level announcement text appears in brighter color
- Palette restores after ~0.5s

- [ ] **Step 5: Note any issues**

If SFX slots are wrong, edit tasks accordingly. If visual effects feel wrong, adjust timer durations or effect intensity.

- [ ] **Step 6: Final commit (if manual fixes needed)**

```bash
git add oracle-odyssey.p8
git commit -m "fix: adjust SFX slots and timing per manual testing"
```

---

## Summary of Changes

| Feature | Added | Modified |
|---------|-------|----------|
| Death Sequence | 30 LOC (shake, flash, handler) | `check_collisions()`, `_draw()` |
| Collect Juice | 50 LOC (floats, flash, humor) | `collect_power_up()`, `_draw()` |
| Level Fanfare | 30 LOC (palette shift, fanfare) | `_update60()`, `draw_level_info()` |
| **Total** | **~110 LOC** | **6 functions** |

All changes in single file: `oracle-odyssey.p8`

---

## Expected Outcome

✅ Death feels punchy with shake/flash/SFX  
✅ Power-ups are rewarding with humor text + ding feedback  
✅ Level transitions are celebrated with palette + sting  
✅ No performance impact (lightweight animations)  
✅ Arcade juice is palpable and satisfying
