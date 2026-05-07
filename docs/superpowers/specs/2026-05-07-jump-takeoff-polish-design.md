# Jump Takeoff Polish Design

**Date:** 2026-05-07  
**Feature:** Inward-converging particles on jump takeoff for elegant dynamism

## Goal

Create a satisfying, elegant takeoff sensation that complements the powerful landing dust effect. The effect should hint at dynamism without mimicking the cathartic relief of landing.

## Design

### Overview

Extend the existing `spawn_dust()` function with an `inward` parameter to support two particle behaviors:
- **Landing particles** (outward): explosion of energy, powerful relief
- **Takeoff particles** (inward): quick convergence, elegant launch energy

### Particle System Extension

**Function Signature:**
```lua
function spawn_dust(x, y, inward)
```

**Parameters:**
- `x, y`: Spawn position
- `inward` (optional, default false): If true, particles converge inward; if false, spread outward

**Behavior by Mode:**

| Aspect | Landing (inward=false) | Takeoff (inward=true) |
|--------|------------------------|----------------------|
| Particle Count | 3-6 | 2-3 |
| dx Range | ±0.5 (outward spread) | -0.8 to -0.3 (leftward/inward) |
| dy Range | -0.1 to -0.3 | -0.2 to -0.4 (faster upward) |
| Life Span | 8-12 frames | 5-8 frames (shorter) |
| Color | 6 | 6 |
| Feel | Explosive, relieving | Quick, punchy, energetic |

### Call Sites

**Landing (unchanged):**
```lua
spawn_dust(player.x, 96)  -- default inward=false
spawn_dust(player.x + 8, 96)
```

**Takeoff (new):**
```lua
spawn_dust(player.x + 4, 96, true)  -- spawn from center, particles converge inward
```

Takeoff spawns from center (x + 4) since inward particles visually converge anyway; landing spawns from sides for symmetry.

### Implementation Details

- Modify `spawn_dust()` to check the `inward` parameter
- If inward, use tighter dx range (negative, faster) and faster dy
- Reuse particle update/draw logic; only spawn parameters differ
- No changes to `update_particles()` or `draw_particles()`

### Testing

- Jump and verify takeoff particles move inward and upward quickly
- Land and verify landing particles still spread outward as before
- Both effects should feel cohesive: landing is relief, takeoff is refined energy

## Success Criteria

✓ Takeoff effect is quick and punchy, not lingering  
✓ Particles converge inward, complementing outward landing spread  
✓ Overall feel is elegant and hinted, not overwhelming  
✓ Landing effect unchanged; both feel symmetrical
