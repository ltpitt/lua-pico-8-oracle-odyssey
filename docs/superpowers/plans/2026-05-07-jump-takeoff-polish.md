# Jump Takeoff Polish Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add elegant inward-converging particle effect on jump takeoff to complement the powerful landing dust effect.

**Architecture:** Extend `spawn_dust()` function with an optional `inward` parameter. When true, particles spawn with negative dx (moving leftward/inward) and faster upward movement for a "quick and punchy" takeoff feel. Landing particles remain unchanged (outward spread).

**Tech Stack:** PICO-8 Lua, particle system already implemented in oracle-odyssey.p8

---

## File Structure

**Modify:**
- `oracle-odyssey.p8` — Update `spawn_dust()` function signature and logic; add takeoff spawn call

---

## Task 1: Update spawn_dust Function to Support Inward Mode

**Files:**
- Modify: `oracle-odyssey.p8:833-844` (spawn_dust function)

**Context:**
Current `spawn_dust(x, y)` creates 3-6 particles with `dx = rnd(1) - 0.5` (range ±0.5, spreading outward) and `dy = -0.1 - rnd(0.2)` (upward).

For inward mode, we need:
- Fewer particles (2-3 instead of 3-6)
- Negative dx range (-0.8 to -0.3) for leftward/inward movement
- Faster upward dy (-0.2 to -0.4)
- Shorter lifespan (5-8 instead of 8-12)

- [ ] **Step 1: View current spawn_dust function**

```bash
grep -A 12 "function spawn_dust" oracle-odyssey.p8
```

Expected: See function starting at line 833 with 3-6 particles, dx/dy/life values

- [ ] **Step 2: Update spawn_dust signature and logic**

Replace the function at oracle-odyssey.p8:833-844 with:

```lua
function spawn_dust(x, y, inward)
    inward = inward or false
    local count = inward and (2 + flr(rnd(2))) or (3 + flr(rnd(3)))
    local life_min = inward and 5 or 8
    local life_max = inward and 8 or 12
    
    for i = 1, count do
        local dx
        if inward then
            dx = -0.8 + rnd(0.5)  -- range -0.8 to -0.3, leftward
        else
            dx = rnd(1) - 0.5     -- range ±0.5, outward spread
        end
        
        local dy = inward and (-0.2 - rnd(0.2)) or (-0.1 - rnd(0.2))
        
        add(particles, {
            x = x,
            y = y,
            dx = dx,
            dy = dy,
            life = life_min + flr(rnd(life_max - life_min + 1)),
            color = 6
        })
    end
end
```

- [ ] **Step 3: Verify spawn_dust is updated**

Run:
```bash
grep -A 25 "function spawn_dust" oracle-odyssey.p8 | head -30
```

Expected: New function with `inward` parameter, conditional logic for count/dx/dy/life

- [ ] **Step 4: Commit**

```bash
git add oracle-odyssey.p8
git commit -m "refactor: extend spawn_dust with inward parameter

Modified spawn_dust(x, y, inward) to support both outward (landing)
and inward (takeoff) particle behaviors:
- Inward: 2-3 particles, dx -0.8 to -0.3, faster dy, life 5-8 frames
- Outward: 3-6 particles, dx ±0.5, standard dy, life 8-12 frames (unchanged)

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

## Task 2: Add Takeoff Particle Spawn Call

**Files:**
- Modify: `oracle-odyssey.p8:289-295` (jump input handler in update_player)

**Context:**
Current jump handler at line 289-295 calls `spawn_dust(player.x, 96)` and `spawn_dust(player.x + 8, 96)` for landing particles (side dust). We need to add a call with `inward=true` from center (player.x + 4).

- [ ] **Step 1: View current jump handler**

```bash
sed -n '289,295p' oracle-odyssey.p8
```

Expected: See btnp(4) check, jump state setup, sfx call, and two spawn_dust calls

- [ ] **Step 2: Add inward takeoff spawn call**

Update lines 289-296 from:

```lua
    if btnp(4) and player.jump_count < player.max_jumps then
        player.dy = player.jump_strength
        player.jump_count = player.jump_count + 1
        player.state = "jumping"
        player.anim_timer = 0
        sfx(1, 3)
        spawn_dust(player.x, 96)
        spawn_dust(player.x + 8, 96)
    end
```

To:

```lua
    if btnp(4) and player.jump_count < player.max_jumps then
        player.dy = player.jump_strength
        player.jump_count = player.jump_count + 1
        player.state = "jumping"
        player.anim_timer = 0
        sfx(1, 3)
        spawn_dust(player.x + 4, 96, true)
    end
```

- [ ] **Step 3: Verify change**

```bash
sed -n '289,297p' oracle-odyssey.p8
```

Expected: Jump handler with single `spawn_dust(player.x + 4, 96, true)` call (inward particles from center)

- [ ] **Step 4: Commit**

```bash
git add oracle-odyssey.p8
git commit -m "feat: add inward particle effect on jump takeoff

Jump now spawns inward-converging particles from center (player.x + 4)
with inward=true flag, creating quick/punchy takeoff sensation that
complements the powerful landing dust effect.

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

## Task 3: Manual Testing

**Context:**
Test both landing and takeoff effects in PICO-8 to verify:
1. Takeoff particles spawn from center, move leftward (inward), move upward quickly, disappear fast
2. Landing particles still spawn from sides, spread outward, move upward, persist longer
3. Both effects feel cohesive and elegant

**Steps:**

- [ ] **Step 1: Load cartridge in PICO-8**

Open PICO-8 and load `oracle-odyssey.p8`

- [ ] **Step 2: Test takeoff effect**

1. Start game (press any button at title screen)
2. Jump by pressing Z/C
3. Observe: Particles should spawn from center, move inward (leftward), rise quickly, disappear within ~0.2 seconds
4. Verify: Effect is "quick and punchy," not lingering

- [ ] **Step 3: Test landing effect (verify unchanged)**

1. Land by letting character fall
2. Observe: Particles should spawn from both sides of character, spread outward, rise, persist longer than takeoff
3. Verify: Landing effect still feels powerful and relieving

- [ ] **Step 4: Test repeated jumps**

1. Jump multiple times in succession (double jump mechanics)
2. Observe: Each takeoff spawns fresh inward particles; landing particles appear on return
3. Verify: Effects chain smoothly without visual clipping or lag

- [ ] **Step 5: Verify no regressions**

1. Play through the game normally (dodging obstacles, collecting items)
2. Verify: Game is stable, no crashes or visual glitches
3. Verify: All other effects (landing, collect SFX/flash, HoF) still work

---

## Success Criteria

✓ Takeoff particles spawn from center and move inward (leftward)  
✓ Takeoff particles move upward quickly (faster than landing)  
✓ Takeoff particles have short lifespan (5-8 frames, vanish quickly)  
✓ Landing particles still spread outward and persist (8-12 frames)  
✓ Both effects feel cohesive and elegant  
✓ No visual glitches, crashes, or performance issues  
✓ Game remains fully playable
