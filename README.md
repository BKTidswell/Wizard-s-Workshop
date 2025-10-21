# Wizard's Workshop

**A chaos management game about burnout disguised as magical automation.**

Route colored orbs from spawners to a cauldron to fulfill increasingly demanding orders under time pressure. Your routing system must constantly adapt as spawners change colors and multiple orders pile up.

**Status:** Critical Design Pivot (October 20, 2025)
**Build:** Playable, Major Design Issues Being Addressed

---

## Quick Start

```bash
# Install LÖVE2D
# macOS: brew install love
# Linux: sudo apt-get install love
# Windows: Download from love2d.org

# Run the game
love .

# Toggle debug mode (in-game)
Press 'D'
```

**Controls:**
- Left-click + drag: Draw routing lines
- Right-click: Delete lines ($5 per segment)
- R: Rotate held object
- X: Cancel held object
- D: Toggle debug mode
- SPACE: Restart after game over

---

## For New Developers/Agents

**Start here:** [GAME_DEV_DIARY.md](/Users/skybad/Documents/GitHub/Wizard-s-Workshop/GAME_DEV_DIARY.md)

This comprehensive dev diary contains:
- Complete game vision and design philosophy
- Full development history (10 phases)
- Current game state and known issues
- Technical architecture and file structure
- What worked, what didn't, and why
- Open questions and active experiments
- Performance notes and optimization guide
- How to extend the game without breaking it

**For quick reference:**
- Core files: `main.lua`, `line.lua`, `order.lua`, `spawner.lua`
- Key mechanic: Spawner color switching (forces active routing)
- Critical insight: This is Papers Please, not Factorio
- Main problem: Passive gameplay (being fixed with color switching)

---

## The Critical Design Pivot

**What we accidentally built:** A passive factory puzzle (Factorio-style)
- Draw lines once → watch machine work → boring

**What we meant to build:** An active chaos management game (Papers Please-style)
- Constant re-routing → pressure → decisions → chaos

**Solution being tested:** Spawner color switching every 10 seconds
- Forces ongoing routing adjustments
- Makes line drawing an ACTIVE skill, not a one-time setup

**Status:** Implemented October 20, 2025. Needs extensive playtesting and balancing.

---

## Documentation Map

```
GAME_DEV_DIARY.md          ← Start here (comprehensive history)
├── DESIGN_PLAN.md          ← Original vision and phases
├── ADAPTIVE_FEEDBACK_SYSTEM.md  ← Throughput-based feedback
├── ROUTING_FIX_SUMMARY.md  ← Corner routing logic
├── LINE_CROSSING_IMPLEMENTATION.md  ← Slowdown mechanic
├── JUICE_IMPLEMENTATION_COMPLETE.md  ← Visual polish
├── DEBUG_MODE_GUIDE.md     ← Debug overlay features
├── QUICK_START.md          ← How to play
└── [16 other .md files]    ← Specific implementations
```

**All documentation has been synthesized into GAME_DEV_DIARY.md for easier navigation.**

---

## Game Vision

**Core feeling:** Papers Please meets Overcooked meets burnout metaphor

**Core loop:**
1. Draw routing lines (tactile, immediate)
2. Spawners change colors (forces adaptation)
3. Multiple orders overlap (pressure builds)
4. Make imperfect decisions (good enough vs optimal)
5. Experience satisfying chaos when it breaks

**Unique angle:** Most factory games are about perfection. Ours is about **knowing when to stop.**

---

## Current State (October 20, 2025)

**Working:**
- ✅ Routing system (straight lines, corners, all directions)
- ✅ Adaptive feedback (prevents nausea at high throughput)
- ✅ Line crossing slowdown (architectural debt mechanic)
- ✅ Multiple overlapping orders (pressure!)
- ✅ Spawner color switching (active gameplay solution)
- ✅ Debug mode (accelerates development)
- ✅ Visual polish (particles, shake, floating text)

**Being Tested:**
- 🔄 Spawner switching intervals (10s? 15s? 20s?)
- 🔄 Order spawn timing (15s → 12s → 10s escalation)
- 🔄 Balance of chaos vs control

**Needs Decisions:**
- ❓ How to prevent impossible orders? (Tool shop? Guaranteed coverage?)
- ❓ Should cauldron serving be manual?
- ❓ Should combiners require stirring?

**Broken:**
- ❌ Random color switching can make orders impossible
- ❌ No player control over available colors
- ❌ Unsafe global image references

---

## Technical Stack

- **Engine:** LÖVE2D (Lua game framework)
- **Language:** Lua 5.1+
- **Resolution:** 1000x800
- **Grid:** 10x9 (64px cells)
- **Target FPS:** 60

**Core files:**
- `main.lua` - Game loop, state machine, rendering
- `line.lua` - Routing logic, spawning, intersection detection
- `order.lua` - Quest system, timers, win/loss
- `spawner.lua` - Color sources, switching mechanic
- `orb.lua` - Entity movement
- `cauldron.lua` - Collection and scoring
- `combiner.lua` - Orb merging (2 colors → 1)

---

## Key Mechanics

**Routing:**
- Draw lines with mouse (snap to grid)
- Orbs follow lines at 100px/s base speed
- Corners redirect flow (90-degree turns)
- Lines can cross (but orbs slow down)

**Architectural Debt:**
- Line crossings slow orbs (2x = 60% speed, 3x = 40%, 4x+ = 30%)
- Visual feedback (darker lines at intersections)
- Forces choice: clean but slow vs messy but fast

**Spawner Switching (NEW):**
- Spawners change colors every 10 seconds
- 5-second warning (pulsing red border)
- Forces constant re-routing (THIS IS THE KEY TO ACTIVE GAMEPLAY)

**Orders:**
- Multiple simultaneous orders (spawn every 15s → 12s → 10s)
- Time limits (30-80 seconds)
- Requirements (collect X red, Y green, Z yellow orbs)
- Cascade failure (failed order penalizes others)

**Money:**
- Earn from completing orders
- Spend to delete lines ($5 per segment)
- Future: Tool shop for upgrades

---

## Known Issues

**Critical:**
1. Random spawner switching can make orders impossible
2. Need to decide on control vs chaos balance
3. Unsafe globals for spawner images

**Technical Debt:**
- Global state management (refactor needed)
- lineCleanUp function disabled but not removed
- No proper dependency injection

**Balance:**
- Switching interval needs playtesting
- Order spawn timing may be too fast
- Cascade penalty may be too harsh

---

## Performance

**Current:** 55-60 FPS with 100 orbs, 50 lines, 3 orders

**Optimizations Applied:**
- Spawner table (avoid grid scan)
- Particle systems created once
- Adaptive feedback (reduces effects at high throughput)
- Backward iteration (safe table removal)

**Bottlenecks:** Particle systems at very high throughput (acceptable)

---

## For Contributors

**Before making changes:**
1. Read GAME_DEV_DIARY.md (understand design philosophy)
2. Test with debug mode enabled (press D)
3. Playtest for 10+ minutes before committing
4. Update GAME_DEV_DIARY.md with your changes

**Design principles:**
- Imperfect decisions under pressure (not optimal solutions)
- Emergent gameplay (not predefined puzzles)
- Tactile interactions (not abstract menus)
- Active gameplay (not passive watching)

**Don't break:**
- Adaptive feedback system (prevents nausea)
- Line crossing slowdown (architectural debt)
- Grid alignment (everything 64px)
- Spawner color switching (core to active gameplay)

---

## Next Steps

1. Playtest spawner switching extensively (30+ minutes)
2. Decide on impossible order solution (tool shop vs guaranteed coverage)
3. Balance switching intervals and order timing
4. Prototype manual serving (if needed)
5. Add audio (if time permits)

---

## Contact

**Project started:** October 10, 2025
**Critical pivot:** October 20, 2025
**Current focus:** Fixing passive gameplay problem

For full context on the design pivot and development history, see [GAME_DEV_DIARY.md](/Users/skybad/Documents/GitHub/Wizard-s-Workshop/GAME_DEV_DIARY.md).

---

## License

[Your license here]

---

**This is a living document. Update as the game evolves.**
