# Arcade Polish: Core Loop Juice & Hall of Fame Persistence

## Overview

Two polish features to bring Oracle Odyssey closer to retro arcade quality:

1. **Core loop juice** — sound effects for jump and power-up collect, palette flash on collect, dust particles on landing
2. **Hall of fame persistence** — save and load the top-5 leaderboard across sessions using PICO-8 cartdata

## Feature 1: Core Loop Juice

### Jump SFX

- Play existing SFX 1 on channel 3 when the player jumps
- Triggered in `update_player()` alongside the existing `btnp(4)` jump logic
- Fires for both single and double jumps

### Power-Up Collect SFX + Flash

- Play existing SFX 2 on channel 3 when `collect_power_up()` fires
- Set a global `flash_timer = 3` on collect
- In `_draw()`, before drawing the current state:
  - If `flash_timer == 3`: swap all palette colors to white (7) via `pal()`
  - If `flash_timer == 2`: swap to bright yellow (10)
  - If `flash_timer == 1`: restore palette with `pal()`
  - Decrement `flash_timer` each frame (clamped to 0)

### Landing Dust Particles

- Global `particles = {}` table
- When player transitions from airborne to grounded (detected in `update_player()` when `player.y` clamps to 88 and `player.state` was `"jumping"`), call `spawn_dust(player.x, 88)`
- `spawn_dust(x, y)`: add 3–5 particles with:
  - `dx`: `rnd(1) - 0.5` (random spread)
  - `dy`: `-0.1 - rnd(0.2)` (slight upward drift)
  - `life`: `8 + flr(rnd(5))` (8–12 frames)
  - `color`: 6 (light gray)
- `update_particles()`: called from `update_game()`, for each particle:
  - `p.x += p.dx`, `p.y += p.dy`
  - `p.life -= 1`
  - If `p.life < 4`: change `p.color` to 5 (dark gray)
  - If `p.life <= 0`: remove from table
- `draw_particles()`: called from `draw_game()`, draw each particle as `pset(p.x, p.y, p.color)`

### Integration Points

- `update_player()`: add `sfx(1, 3)` at jump, add landing detection for dust spawn
- `collect_power_up()`: add `sfx(2, 3)` and `flash_timer = 3`
- `_draw()`: add flash palette logic before state drawing
- `update_game()`: add `update_particles()` call
- `draw_game()`: add `draw_particles()` call

## Feature 2: Hall of Fame Persistence

### Cartdata Slot Layout

| Slot | Purpose |
|------|---------|
| 0 | High score (existing, unchanged) |
| 1–5 | Hall of fame scores (entries 1–5) |
| 6–10 | Hall of fame names (encoded as numbers) |

### Name Encoding

Each 3-letter name is encoded as a single number:

```
encode: c1 * 676 + c2 * 26 + c3
```

Where a=0, b=1, ..., z=25. Decode reverses via integer division and modulo.

Two new functions: `encode_name(name)` and `decode_name(n)`.

### Load (in `_init()`)

After `cartdata("oracle_odyssey")` and loading high score:

```
for i = 1, 5 do
  local score = dget(i)
  local name_code = dget(i + 5)
  if score > 0 then
    hall_of_fame[i] = {name = decode_name(name_code), score = score}
  end
end
```

### Save (in `add_to_hof()`)

After inserting the new entry and shifting others down, save all 5 entries:

```
for i = 1, 5 do
  dset(i, hall_of_fame[i].score)
  dset(i + 5, encode_name(hall_of_fame[i].name))
end
```

### Reset (in `reset_all_scores()`)

Add clearing of slots 1–10:

```
for i = 1, 10 do
  dset(i, 0)
end
```

## Files Modified

- `oracle-odyssey.p8` — all changes are in this single file's `__lua__` section

## Token Budget Estimate

Approximately 60 new tokens. The game's current code is well within PICO-8's 8192-token limit.
