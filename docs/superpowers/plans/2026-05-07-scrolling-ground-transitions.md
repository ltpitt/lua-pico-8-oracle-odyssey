# Scrolling Ground + State Transitions Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Activate progression-based ground scroll and add smooth fade transitions between game states for cohesive arcade polish.

**Architecture:** Modify `update_ground()` to use `get_obstacle_speed() * 0.5` instead of fixed scroll. Add fade state variables (`fade_timer`, `fading`) and fade logic to `_update()` and `_draw()`. Integrate fades into `change_state()` call sites via state machine sequencing.

**Tech Stack:** PICO-8 Lua, palette manipulation (existing flash logic model)

---

## File Structure

**Modify:**
- `oracle-odyssey.p8` — Update `update_ground()`, add fade globals, integrate fade logic into `_update()`, `_draw()`, and `change_state()`

---

## Task 1: Fix Ground Scroll to Use Progression Speed

**Files:**
- Modify: `oracle-odyssey.p8:374-376` (update_ground function)

**Context:**
Current `update_ground()` scrolls at fixed 2 pixels/frame. Needs to scale with `get_obstacle_speed()` for escalating arcade tension.

- [ ] **Step 1: View current update_ground function**

```bash
sed -n '374,376p' oracle-odyssey.p8
```

Expected: See fixed -2 scroll value

- [ ] **Step 2: Replace with progression-based scroll**

Replace lines 374-376:

```lua
function update_ground()
    local spd = get_obstacle_speed() * 0.5
    ground_offset = (ground_offset - spd) % screen_size
end
```

- [ ] **Step 3: Verify the change**

```bash
sed -n '374,377p' oracle-odyssey.p8
```

Expected: See `get_obstacle_speed() * 0.5` calculation

- [ ] **Step 4: Test in PICO-8**

1. Load cartridge
2. Start game and observe ground scrolling
3. Play for increasing score (ground should accelerate smoothly)
4. Verify: no stuttering, motion feels natural

- [ ] **Step 5: Commit**

```bash
git add oracle-odyssey.p8
git commit -m "feat: tie ground scroll speed to game progression

Ground now scrolls at speed = obstacle_speed * 0.5, scaling from
1 px/frame (level 1) to 2.25 px/frame (level 6). Creates escalating
arcade tension as score increases.

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

## Task 2: Add Fade State Variables and Initialization

**Files:**
- Modify: `oracle-odyssey.p8` globals section (around line 93-100)

**Context:**
Add global fade state variables at initialization time alongside existing globals like `ground_offset`, `particles`, `flash_timer`.

- [ ] **Step 1: View current globals section**

```bash
sed -n '85,105p' oracle-odyssey.p8
```

Expected: See `particles = {}`, `flash_timer = 0`, `ground_offset = 0`

- [ ] **Step 2: Add fade globals after ground_offset**

Find the line `ground_offset = 0` and add these globals after it:

```lua
fade_timer = 0
fading = false  -- true during transition, false when idle
fade_duration = 4  -- frames for complete fade in/out
```

- [ ] **Step 3: Verify globals are added**

```bash
grep -n "fade_timer\|fading\|fade_duration" oracle-odyssey.p8
```

Expected: Three lines showing the new globals defined

- [ ] **Step 4: Commit**

```bash
git add oracle-odyssey.p8
git commit -m "feat: add fade state variables for transitions

Added fade_timer, fading, and fade_duration globals to track
state transition fades. No behavior change yet.

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

## Task 3: Implement Fade Draw Logic

**Files:**
- Modify: `oracle-odyssey.p8:_draw()` function (add fade palette logic)

**Context:**
Similar to existing `flash_timer` logic, we need to gradually fade palette toward black and back. Add fade palette logic at end of `_draw()` before return.

- [ ] **Step 1: View current _draw() end**

```bash
tail -50 oracle-odyssey.p8 | grep -B 30 "^end$" | head -40
```

Expected: See end of _draw() function, current flash logic

- [ ] **Step 2: Add fade logic to _draw()**

Find the end of `_draw()` function (before final `end`). Add this fade palette logic after existing flash logic:

```lua
-- fade transition palette
if fading then
    fade_timer = fade_timer + 1
    if fade_timer <= fade_duration then
        -- fade toward black (0)
        local fade_progress = fade_timer / fade_duration
        -- palette fade: set all colors to progressively darken
        for i = 0, 15 do
            palt(i, false)  -- all colors opaque
        end
        -- simple approach: use pal to darken, then restore after transition
        if fade_progress < 0.5 then
            -- fade out (to black)
            pal(7, 0)  -- white to black
            pal(6, 0)  -- grey to black
        else
            -- fade in (restore)
            pal()  -- restore default palette
        end
    else
        -- fade complete
        fading = false
        fade_timer = 0
        pal()  -- restore palette
    end
end
```

- [ ] **Step 3: Verify fade logic inserted**

```bash
grep -n "fade_progress\|fade out\|fade in" oracle-odyssey.p8
```

Expected: See the new fade logic lines

- [ ] **Step 4: Test in PICO-8**

1. Load cartridge
2. Manually set `fading = true` at console to trigger fade
3. Observe: screen should gradually fade to black and back
4. Verify: smooth transition, ground continues scrolling

- [ ] **Step 5: Commit**

```bash
git add oracle-odyssey.p8
git commit -m "feat: add fade palette transition logic

Added fade drawing logic to _draw(). When fading=true, palette
gradually transitions to black over fade_duration frames, then
restores. Ground continues scrolling during fade.

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

## Task 4: Integrate Fade into change_state()

**Files:**
- Modify: `oracle-odyssey.p8:change_state()` function

**Context:**
When `change_state()` is called, we want to:
1. Set `fading = true` to trigger fade out
2. Wait for fade complete
3. Change actual state
4. Fade back in

This requires a state machine: track that we're "in transition" and defer the actual state change until fade completes.

- [ ] **Step 1: View current change_state() function**

```bash
grep -n "function change_state" oracle-odyssey.p8
```

Expected: Find the function line number

- [ ] **Step 2: Add transition state tracking**

Add global variable (with other state vars):

```lua
next_state = nil  -- tracks pending state change during fade
```

- [ ] **Step 3: Modify change_state() to defer state change**

Find `function change_state(new_state)` and replace logic:

```lua
function change_state(new_state)
    if game.state == new_state then
        return  -- already in target state, skip
    end
    next_state = new_state
    fading = true
    fade_timer = 0
end
```

- [ ] **Step 4: Add fade completion logic to _update()**

In `_update()`, after fade logic completes, perform the deferred state change. Find end of `_update()` and add:

```lua
-- handle deferred state change after fade completes
if fading == false and next_state ~= nil then
    game.state = next_state
    next_state = nil
    fading = true  -- fade in on new state
    fade_timer = 0
end
```

- [ ] **Step 5: Verify state change integration**

```bash
grep -n "next_state\|fading = true" oracle-odyssey.p8
```

Expected: See new fade trigger and state change deferral logic

- [ ] **Step 6: Test in PICO-8**

1. Load cartridge
2. From splash screen, press button to start game → observe fade transition
3. Die in game → observe fade to gameover → observe fade back to splash
4. Restart → verify smooth fades between all states

- [ ] **Step 7: Commit**

```bash
git add oracle-odyssey.p8
git commit -m "feat: integrate fade transitions into state changes

Modified change_state() to defer state change until fade completes.
State transitions now sequence: fade out → change state → fade in.
All state changes (splash→game, game→gameover, etc) now have smooth fades.

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

## Task 5: Refinement and Polish

**Files:**
- Modify: `oracle-odyssey.p8` palette fade logic (Task 3), optional tweaks

**Context:**
Initial fade logic is functional but may need tuning:
- Fade duration (currently 4 frames) might be too slow/fast
- Palette fade (currently just darken white/grey) might be too subtle
- May need to fine-tune fade curves

- [ ] **Step 1: Playtest fade feel**

1. Play game normally, test all state transitions
2. Assess: Do fades feel smooth and modern? Or jarring?
3. Check: Is 4-frame duration right, or should it be 3/5/6?

- [ ] **Step 2: Adjust fade duration if needed**

If fades feel too slow, reduce `fade_duration` to 3. If too fast, increase to 5.

Edit the fade globals:

```lua
fade_duration = 4  -- adjust to 3 or 5 based on feel
```

- [ ] **Step 3: Test ground scroll acceleration**

Play game and verify:
- Ground starts slow and steadily accelerates
- Acceleration is smooth, not jarring
- At high levels, ground feels appropriately "fast"

If scroll feels wrong, adjust multiplier in `update_ground()` from `* 0.5` to `* 0.6` or `* 0.4`.

- [ ] **Step 4: Verify no regressions**

1. Play through complete game session
2. Verify: all previous features still work (jump dust, collect flash, HoF)
3. Verify: no crashes or visual glitches
4. Verify: arcade feel maintained (cohesive, not jarring)

- [ ] **Step 5: Commit (if changes made)**

```bash
git add oracle-odyssey.p8
git commit -m "polish: tune fade duration and ground scroll feel

Final tuning pass: fade duration adjusted to X frames for optimal feel,
ground scroll multiplier verified for smooth acceleration. Game transitions
and progression feel arcade-smooth and modern-polished.

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

(Or, if no changes needed: `git commit --allow-empty -m "chore: task 5 verification complete, no tuning needed"`)

---

## Success Criteria

✓ Ground scroll active and scales with progression (levels 1-6)  
✓ Fade transitions smooth and ~4 frames duration  
✓ All state transitions (splash↔game↔gameover) fade smoothly  
✓ Ground continues scrolling during fades  
✓ No visual stuttering, crashes, or regressions  
✓ Arcade mechanical feel + modern polish balance achieved  
✓ Game feels like a continuous arcade machine
