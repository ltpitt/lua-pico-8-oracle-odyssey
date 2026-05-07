# Arcade Polish Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add core loop juice (jump SFX, collect SFX + flash, landing dust particles) and persistent hall of fame to Oracle Odyssey.

**Architecture:** All changes live in the `__lua__` section of `oracle-odyssey.p8`. New globals (`particles`, `flash_timer`) and functions are added near existing game logic. Hall of fame persistence uses PICO-8 `cartdata` slots 1–10 alongside the existing high-score slot 0. No new files are created.

**Tech Stack:** PICO-8 / Lua. No test framework available — verification is manual (load cart in PICO-8, test behavior).

---

## File Structure

**Modified:** `oracle-odyssey.p8` (single PICO-8 cartridge)

| Area | Lines (approx.) | Changes |
|------|-----------------|---------|
| Globals | 89–92 | Add `particles = {}`, `flash_timer = 0` |
| `_init()` | 94–101 | Add hall of fame load loop |
| `_draw()` | 134–151 | Add palette flash logic |
| `update_game()` | 220–248 | Add `update_particles()` call |
| `update_player()` | 268–294 | Add jump SFX, landing dust detection |
| `draw_game()` | 351–359 | Add `draw_particles()` call |
| `collect_power_up()` | 711–715 | Add collect SFX + flash_timer |
| `add_to_hof()` | 744–756 | Add cartdata save loop |
| `reset_all_scores()` | 758–767 | Add cartdata clear for slots 1–10 |
| New functions (after line 800) | — | `spawn_dust`, `update_particles`, `draw_particles`, `encode_name`, `decode_name` |

---

### Task 1: Add particle system infrastructure

**Files:**
- Modify: `oracle-odyssey.p8:89-92` (add globals)
- Modify: `oracle-odyssey.p8` (add new functions before `__gfx__` section)

- [ ] **Step 1: Add global variables**

After line 92 (`ground_offset = 0`), add:

```lua
particles = {}
flash_timer = 0
```

- [ ] **Step 2: Add particle functions**

Before the `__gfx__` line (line 804), after the `write_c` function, add:

```lua
function spawn_dust(x, y)
    for i = 1, 3 + flr(rnd(3)) do
        add(particles, {
            x = x,
            y = y,
            dx = rnd(1) - 0.5,
            dy = -0.1 - rnd(0.2),
            life = 8 + flr(rnd(5)),
            color = 6
        })
    end
end

function update_particles()
    for p in all(particles) do
        p.x = p.x + p.dx
        p.y = p.y + p.dy
        p.life = p.life - 1
        if p.life < 4 then
            p.color = 5
        end
        if p.life <= 0 then
            del(particles, p)
        end
    end
end

function draw_particles()
    for p in all(particles) do
        pset(p.x, p.y, p.color)
    end
end
```

- [ ] **Step 3: Reset globals on game restart**

In `_init_game()`, add particle and flash cleanup. Find:

```lua
    game.level_quote = ""
end
```

Replace with:

```lua
    game.level_quote = ""
    particles = {}
    flash_timer = 0
end
```

- [ ] **Step 4: Wire particles into the game loop**

In `update_game()`, add `update_particles()` after `update_power_ups()`. Find:

```lua
    update_power_ups()
    check_collisions()
```

Replace with:

```lua
    update_power_ups()
    update_particles()
    check_collisions()
```

In `draw_game()`, add `draw_particles()` after `draw_power_ups()`. Find:

```lua
    draw_power_ups()
    draw_score()
```

Replace with:

```lua
    draw_power_ups()
    draw_particles()
    draw_score()
```

- [ ] **Step 5: Commit**

```bash
git add oracle-odyssey.p8
git commit -m "feat: add particle system infrastructure

Add particles table, flash_timer global, spawn_dust(),
update_particles(), and draw_particles() functions.
Wire into game loop. Reset on game restart.

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

### Task 2: Add jump SFX and landing dust

**Files:**
- Modify: `oracle-odyssey.p8:268-294` (`update_player()`)

- [ ] **Step 1: Add jump SFX**

In `update_player()`, add `sfx(1, 3)` inside the jump condition. Find:

```lua
    if btnp(4) and player.jump_count < player.max_jumps then
        player.dy = player.jump_strength
        player.jump_count = player.jump_count + 1
        player.state = "jumping"
        player.anim_timer = 0
    end
```

Replace with:

```lua
    if btnp(4) and player.jump_count < player.max_jumps then
        player.dy = player.jump_strength
        player.jump_count = player.jump_count + 1
        player.state = "jumping"
        player.anim_timer = 0
        sfx(1, 3)
    end
```

- [ ] **Step 2: Add landing dust detection**

In `update_player()`, add landing detection before the ground clamp. Find:

```lua
    if player.y > 88 then
        player.y = 88
        player.dy = 0
        player.jump_count = 0
        player.state = "walking"
        -- do not reset anim_timer here
        player.sprite = player.walk_sprite -- set sprite for walking
    end
```

Replace with:

```lua
    if player.y > 88 then
        if player.state == "jumping" then
            spawn_dust(player.x, 88)
        end
        player.y = 88
        player.dy = 0
        player.jump_count = 0
        player.state = "walking"
        player.sprite = player.walk_sprite
    end
```

- [ ] **Step 3: Verify manually**

Load `oracle-odyssey.p8` in PICO-8 and start a game:
- Press Z to jump → should hear SFX 1
- Land on ground → should see 3–5 small gray pixels scatter from feet
- Double jump (with power-up) → should hear SFX on both jumps, dust on final landing

- [ ] **Step 4: Commit**

```bash
git add oracle-odyssey.p8
git commit -m "feat: add jump SFX and landing dust particles

Play SFX 1 on channel 3 when jumping. Spawn dust particles
at player's feet on landing transition.

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

### Task 3: Add collect SFX and screen flash

**Files:**
- Modify: `oracle-odyssey.p8:711-715` (`collect_power_up()`)
- Modify: `oracle-odyssey.p8:134-151` (`_draw()`)

- [ ] **Step 1: Add SFX and flash trigger to collect_power_up()**

Find:

```lua
function collect_power_up()
    player.double_jump_enabled = true
    player.double_jump_timer = player.double_jump_duration
    player.max_jumps = 2
end
```

Replace with:

```lua
function collect_power_up()
    player.double_jump_enabled = true
    player.double_jump_timer = player.double_jump_duration
    player.max_jumps = 2
    sfx(2, 3)
    flash_timer = 3
end
```

- [ ] **Step 2: Add palette flash logic to _draw()**

Find:

```lua
function _draw()
    cls()
    if game.debug then
```

Replace with:

```lua
function _draw()
    cls()
    if flash_timer == 3 then
        for i = 0, 15 do pal(i, 7) end
    elseif flash_timer == 2 then
        for i = 0, 15 do pal(i, 10) end
    end
    if game.debug then
```

Then find the closing of `_draw()`. Find:

```lua
    elseif game.state == game.states.hall_of_fame then
        draw_hall_of_fame()
    end
end
```

Replace with:

```lua
    elseif game.state == game.states.hall_of_fame then
        draw_hall_of_fame()
    end
    pal()
    if flash_timer > 0 then
        flash_timer = flash_timer - 1
    end
end
```

- [ ] **Step 3: Verify manually**

Load in PICO-8, start a game, and collect a power-up:
- Should hear SFX 2 on collection
- Screen should flash white for 1 frame, then yellow for 1 frame, then restore on the 3rd frame
- Game should continue normally after flash

- [ ] **Step 4: Commit**

```bash
git add oracle-odyssey.p8
git commit -m "feat: add collect SFX and screen flash

Play SFX 2 on channel 3 when collecting power-up. Flash screen
white then yellow for 2 frames using palette swap.

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

### Task 4: Add hall of fame persistence

**Files:**
- Modify: `oracle-odyssey.p8:94-101` (`_init()`)
- Modify: `oracle-odyssey.p8:744-756` (`add_to_hof()`)
- Modify: `oracle-odyssey.p8:758-767` (`reset_all_scores()`)
- Modify: `oracle-odyssey.p8` (add new functions before `__gfx__`)

- [ ] **Step 1: Add encode/decode functions**

Add these functions alongside the other new functions (after `draw_particles()`, before `__gfx__`):

```lua
function encode_name(name)
    local c1 = find_in_alphabet(sub(name, 1, 1)) - 1
    local c2 = find_in_alphabet(sub(name, 2, 2)) - 1
    local c3 = find_in_alphabet(sub(name, 3, 3)) - 1
    return c1 * 676 + c2 * 26 + c3
end

function decode_name(n)
    local c3 = n % 26
    n = flr(n / 26)
    local c2 = n % 26
    local c1 = flr(n / 26)
    return sub(alphabet, c1 + 1, c1 + 1) .. sub(alphabet, c2 + 1, c2 + 1) .. sub(alphabet, c3 + 1, c3 + 1)
end
```

- [ ] **Step 2: Add load logic to _init()**

Find:

```lua
function _init()
    cartdata("oracle_odyssey")
    game.high_score = dget(0)
    game.level_quote = ""
    game.player_initials = "aaa"
    game.initial_pos = 1
    game.state = game.states.splash
end
```

Replace with:

```lua
function _init()
    cartdata("oracle_odyssey")
    game.high_score = dget(0)
    for i = 1, 5 do
        local score = dget(i)
        if score > 0 then
            hall_of_fame[i] = {name = decode_name(dget(i + 5)), score = score}
        end
    end
    game.level_quote = ""
    game.player_initials = "aaa"
    game.initial_pos = 1
    game.state = game.states.splash
end
```

- [ ] **Step 3: Add save logic to add_to_hof()**

Find:

```lua
function add_to_hof(name, score)
    -- insert at correct position
    for i = 1, 5 do
        if score > hall_of_fame[i].score then
            -- shift entries down
            for j = 5, i + 1, -1 do
                hall_of_fame[j] = hall_of_fame[j - 1]
            end
            hall_of_fame[i] = {name = name, score = score}
            return
        end
    end
end
```

Replace with:

```lua
function add_to_hof(name, score)
    for i = 1, 5 do
        if score > hall_of_fame[i].score then
            for j = 5, i + 1, -1 do
                hall_of_fame[j] = hall_of_fame[j - 1]
            end
            hall_of_fame[i] = {name = name, score = score}
            for k = 1, 5 do
                dset(k, hall_of_fame[k].score)
                dset(k + 5, encode_name(hall_of_fame[k].name))
            end
            return
        end
    end
end
```

- [ ] **Step 4: Update reset_all_scores()**

Find:

```lua
function reset_all_scores()
    -- reset high score
    game.high_score = 0
    dset(0, 0)
    
    -- reset hall of fame
    for i = 1, 5 do
        hall_of_fame[i] = {name = "---", score = 0}
    end
end
```

Replace with:

```lua
function reset_all_scores()
    game.high_score = 0
    dset(0, 0)
    for i = 1, 5 do
        hall_of_fame[i] = {name = "---", score = 0}
    end
    for i = 1, 10 do
        dset(i, 0)
    end
end
```

- [ ] **Step 5: Verify manually**

Load in PICO-8:
1. Play a game, die with a top-5 score, enter initials "abc"
2. See the hall of fame screen showing your entry
3. Quit PICO-8 completely, relaunch, load the cart
4. Start a game and die → the hall of fame should still show "abc" with the previous score
5. On the splash screen, hold Up + Down + press Z → scores should reset
6. Relaunch → hall of fame should be empty (all "---" with 0 scores)

- [ ] **Step 6: Commit**

```bash
git add oracle-odyssey.p8
git commit -m "feat: persist hall of fame across sessions

Encode 3-letter names as numbers and store in cartdata slots 1-10.
Load on init, save on entry, clear on reset.

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```
