# Wizard's Workshop: Complete Development Diary

**Last Updated:** October 20, 2025
**Current Status:** Critical Design Pivot - Passive Puzzle → Active Chaos Management
**Build Status:** Playable, Major Design Issues Identified

---

## Table of Contents

1. [Game Vision & Core Concept](#1-game-vision--core-concept)
2. [Design Philosophy](#2-design-philosophy)
3. [The Critical Design Pivot (October 20, 2025)](#3-the-critical-design-pivot-october-20-2025)
4. [Current Game State](#4-current-game-state)
5. [Technical Architecture](#5-technical-architecture)
6. [Development Journey](#6-development-journey)
7. [Key Design Decisions & Pivots](#7-key-design-decisions--pivots)
8. [What Worked](#8-what-worked)
9. [What Didn't Work](#9-what-didnt-work)
10. [Open Questions & Active Experiments](#10-open-questions--active-experiments)
11. [Performance Notes](#11-performance-notes)
12. [For Future Agents](#12-for-future-agents)

---

## 1. Game Vision & Core Concept

### What Is This Game Trying to Be?

**Wizard's Workshop** is a chaos management game about burnout disguised as a magical automation game. You route colored orbs from spawners to a cauldron to fulfill increasingly demanding orders under time pressure.

### The Emotional Experience

**Target feeling:** The mounting pressure of a service job where you can't say no.

- **Floor (unavoidable chaos):** Random spawner color switching, overlapping orders, time cascades
- **Ceiling (player choice chaos):** Taking on too many orders, building messy infrastructure, cutting corners

**The burnout metaphor:** "When everything explodes, it's because you took on too much work."

### What This Game Is NOT

**NOT Factorio/Satisfactory:** We're not about perfect optimization and permanent solutions. This is not "build once, watch forever."

**NOT a puzzle game:** There are no predefined "correct" solutions. Success comes from imperfect decisions under pressure.

### Inspirations

- **Papers Please:** Repeated, tactile actions under time pressure with moral weight
- **Overcooked:** Cooperative chaos that's fun to fail at
- **Mini Metro:** Elegant systems that inevitably collapse
- **Opus Magnum:** Multiple valid solutions with different tradeoffs

**Our unique angle:** Most factory games are about perfection. Ours is about **knowing when to stop** and accepting "good enough" when the pressure is on.

### Core Interaction Loop

1. Draw routing lines (tactile, immediate)
2. Watch orbs flow through your system
3. Make imperfect decisions under pressure
4. Experience satisfying chaos when it breaks
5. Learn what "good enough" actually means

---

## 2. Design Philosophy

### Imperfect Decisions Over Optimal Solutions

The game should never have one "correct" answer. Every decision is a tradeoff:
- Fast but messy vs slow but clean
- Risky but profitable vs safe but sustainable
- Rebuild now vs work around it

### Emergent Gameplay Over Predefined Puzzles

Orders escalate in difficulty, but the challenge emerges from YOUR previous choices, not from pre-designed puzzles. Your architectural debt from Order 1 becomes the bottleneck in Order 5.

### Tactile Interactions

Everything should feel PHYSICAL:
- Drawing lines (not clicking menus)
- Watching orbs flow (not abstract numbers)
- Screen shake on collection (haptic feedback)
- Manual actions when needed (stirring, serving)

### Self-Imposed Chaos

**Floor:** The game creates baseline chaos you must manage (color switching, overlapping orders, time pressure).

**Ceiling:** The player creates ADDITIONAL chaos by being greedy (taking on too many orders, building too fast, cutting corners).

The best moments are when players realize "I did this to myself."

---

## 3. The Critical Design Pivot (October 20, 2025)

### The Problem Discovered

**What we accidentally built:** A passive factory puzzle game (Factorio-style)
- Player draws lines once
- Player watches the machine work
- No active gameplay after initial setup
- Boring to play: "Once I draw lines, I just watch"

**What we meant to build:** An active chaos management game (Papers Please-style)
- Constant player involvement
- Repeated tactile actions under pressure
- No time to just watch
- Routing should be what stamping is to Papers Please

### The Core Insight

> "Routing should be what stamping is to Papers Please - repeated, tactile, pressured. Not Factorio where you build once and admire it."

The game was designed around the WRONG core loop. Drawing lines can't be a one-time setup action - it needs to be ONGOING.

### Solution Being Tested: Spawner Color Switching

**Mechanic:** Spawners change colors every 10 seconds (with 5-second warnings).

**Effect:** Forces players to constantly re-route, making line drawing an ACTIVE skill instead of a setup phase.

**Implementation Status:** ✅ WORKING (October 20, 2025)
- Visual warnings (pulsing borders)
- Color switches on timer
- Overlapping orders for added pressure

### Future Layers

**Manual mechanics to add tactical depth:**
1. **Cauldron serving:** Player must click to "serve" completed orders (already partially implemented)
2. **Combiner stirring:** Player must click combiners to activate them (designed but not coded)
3. **Heat management:** Cauldrons overheat if unused (implemented, needs balancing)

These create tactical decisions: "Do I rebuild this line OR serve that order OR stir that combiner?"

### What Changed Today (October 20)

**Implemented:**
- Spawner color switching with 10-second intervals
- Visual warnings (pulsing red/orange borders)
- First order spawns immediately (UX improvement)
- Multiple simultaneous orders (pressure!)
- Performance optimizations for spawner updates

**Discovered Issues:**
- Random color switching can make orders impossible
- Need to decide: Tool shop (player control) vs guaranteed color coverage
- Spawner image references use unsafe globals (technical debt)

---

## 4. Current Game State

### What's Implemented and Working ✅

**Core Gameplay (Dual Modes):**
- **ROUTING MODE:** Draw routing lines, orbs auto-route to cauldrons
- **CHARACTER MODE:** Control wizard, pickup orbs, deliver manually
- Press 'P' to toggle between modes during gameplay
- Both modes fully functional and playable
- Order system works in both modes
- Multiple simultaneous orders (chaos!)
- Money/scoring system
- Game over when all orders fail

**Routing System (Routing Mode):**
- Straight lines (horizontal/vertical)
- Corner pieces with proper redirects
- Line crossing slowdown (architectural debt mechanic)
- Intersection detection (up to 4+ lines per cell)
- Spawning from line segments adjacent to spawners
- Permanent arrow overlays for direction clarity
- Spawner color switching (10s intervals with warnings)

**Character System (Character Mode):**
- Wizard controlled by mouse (smooth lerp following)
- Click spawners to pickup orbs
- Orbs orbit around wizard visually
- Max carrying capacity: 5 orbs (upgradeable)
- Weight-based movement: 15% slower per orb carried
- Auto-drop when near cauldron (64px range)
- Visual capacity indicator (turns red when full)

**Polish & Juice:**
- Adaptive feedback system (prevents nausea at high throughput)
- Screen shake on orb collection (with cooldown)
- Particle systems (color-matched bursts)
- Floating score numbers (rise and fade)
- Visual slowdown at intersections (darker lines)
- Debug mode with comprehensive overlays

**Visual Feedback:**
- Order UI with timer and progress bars
- Time warnings (red text when < 10s)
- Spawner color switching with pulsing warnings
- Heat meters on cauldrons
- Game over screen with stats

**Performance:**
- Optimized spawner updates (direct table iteration)
- Efficient line intersection checks
- Particle systems created once
- Maintains 60 FPS with hundreds of entities

### What's Designed But Not Coded

**Manual Mechanics:**
- Combiner stirring (click to activate)
- Advanced cauldron serving UI
- Tool shop for upgrades

**Progression Systems:**
- Meta-progression between runs
- Permanent upgrades
- Day structure with resets

**Narrative Layer:**
- Boss emails with flavor text
- Burnout themes in UI/dialogue
- Multiple endings based on choices

### Known Issues (Unfixed)

**Critical:**
- **Impossible orders:** Random spawner switching can make orders uncompletable
- **Unsafe globals:** Spawner images (redSqr, greenSqr, yellowCirc) referenced via globals
- **No player control:** Can't choose what colors are available

**Design Questions:**
- Should there be a tool shop where players buy spawner colors?
- Or should the game guarantee color coverage for active orders?
- How much control should players have vs random chaos?

**Technical Debt:**
- Global state management (redCirc, greenCirc, yellowCirc accessed everywhere)
- No proper dependency injection
- lineCleanUp function disabled but not removed

### Performance Status

**Target:** 60 FPS
**Actual:** 55-60 FPS with typical gameplay (100+ orbs, 50+ lines)
**Bottlenecks:** Particle systems at very high throughput (acceptable)

---

## 5. Technical Architecture

### File Structure

```
/Users/skybad/Documents/GitHub/Wizard-s-Workshop/
├── main.lua              # Game loop, state management, rendering
├── orb.lua              # Orb entities (movement, drawing)
├── line.lua             # Routing lines (straight, corners, spawning)
├── spawner.lua          # Color sources (spawning, switching)
├── cauldron.lua         # Collection point (scoring, heat)
├── combiner.lua         # Orb merging (2 colors → 1 color)
├── order.lua            # Quest system (requirements, timers)
├── imgs/                # Sprite assets
└── [23 .md files]       # Documentation (audited below)
```

### Key Classes and Responsibilities

**Orb (`orb.lua`):**
- Position (x, y)
- Velocity (dx, dy)
- Color type ("red", "green", "yellow")
- Draw method
- Movement update

**Line (`line.lua`):**
- Grid position (gridX, gridY)
- Line type ("hLine", "vLine", "cLine")
- Direction (dx/dy for straight, redirects table for corners)
- Orb spawning (checks adjacent spawners)
- Speed adjustment (applies slowdown at intersections)
- Visual rendering (with permanent arrow overlays)

**Spawner (`spawner.lua`):**
- Color type (current output color)
- Switching timer (10s intervals)
- Warning state (5s before switch)
- Update method (timer + color switching)
- Draw method (with pulsing border warnings)

**Cauldron (`cauldron.lua`):**
- Scoring logic (orb type → points)
- Heat management (overheat if unused)
- Order notification (tells active orders about collections)
- Stir mechanic (player interaction)

**Combiner (`combiner.lua`):**
- Input colors (what it accepts)
- Output color (what it produces)
- Combining logic (checks for matching pairs)
- Position and rotation

**Order (`order.lua`):**
- Requirements (orb counts per color)
- Progress tracking
- Timer (counts down)
- State machine ("active", "success", "failed")
- UI rendering (top of screen, stacked vertically)

### Global State Management

**Main game loop state (main.lua):**
```lua
orbTable = {}           -- All active orbs
lineTable = {}          -- All routing lines
combinerTable = {}      -- All combiners
spawnerTable = {}       -- All spawners (optimized)
spellArray[x][y] = obj  -- Grid-based object lookup
activeOrders = {}       -- Currently active orders
orderQueue = {}         -- Pending orders
gameState = "playing"   -- State machine
score = 0               -- Current run score
totalMoney = 0          -- Accumulated money
gameplayMode = "routing"  -- NEW: "routing" or "character"
wizard = {              -- NEW: Character mode wizard
    x, y,               -- Position
    radius = 16,
    carriedOrbs = {},   -- Orbs being carried
    speed = 5,          -- Lerp speed
    maxCarryCapacity = 5  -- Max orbs (upgradeable)
}
```

**Performance globals:**
```lua
collectionHistory = {}  -- Timestamps for throughput calculation
currentThroughput = 0   -- Orbs/sec (adaptive feedback)
```

**Visual feedback globals:**
```lua
shakeX, shakeY = 0, 0   -- Screen shake offset
shakeTimer = 0          -- Shake duration
floatingTexts = {}      -- Score popups
redParticleSystem       -- Particle effects
greenParticleSystem
yellowParticleSystem
```

### Update/Draw Pipeline

**love.update(dt):**
1. Update screen shake timer (decay)
2. Update particle systems (animate)
3. Update floating texts (rise and fade)
4. Handle game state ("playing", "orderComplete", etc.)
5. Update spawners (color switching)
6. Update cauldrons (heat management)
7. Update orders (timers, completion checks)
8. Move all orbs
9. Update orb grid (collect at cauldrons)
10. Spawn new orbs from lines
11. Route orbs (adjust speeds at lines)
12. Combine orbs at combiners

**love.draw():**
1. Apply screen shake transform
2. Draw grid background
3. Draw all objects in spellArray
4. Draw cauldron heat meters
5. Draw orbs
6. Draw holding array (tool shop items)
7. Draw active orders (stacked vertically)
8. Draw score/money (top-right)
9. Draw particles
10. Draw floating texts
11. Reset transform
12. Draw debug overlay (if enabled)

### Performance Considerations

**Optimizations in place:**
- Spawners in dedicated table (avoid grid scan)
- Line intersection check only on orb entry
- Particle systems created once in love.load()
- Adaptive feedback reduces effects at high throughput
- Backward iteration for safe table removal

**Known slow paths:**
- Intersection counting (O(n) per line, acceptable)
- Orb routing (O(n*m) where n=orbs, m=lines at position)

---

## 6. Development Journey

### Phase 1: Foundation (Early October 2025)

**Goals:** Get basic routing working.

**Implemented:**
- Grid-based placement system
- Line drawing via mouse drag
- Orb spawning from spawners
- Basic movement along lines
- Cauldron collection

**Challenges:**
- Lua 1-based indexing bugs
- Grid position calculation errors
- Orb velocity not updating correctly

**Lessons:** LÖVE2D coordinate systems are straightforward, but grid math requires careful attention to offsets.

### Phase 2: Routing Fixes (Mid October)

**Problem:** Orbs moving diagonally at corners, LEFT direction not working.

**Root cause:** Corners had fixed dx/dy values (both set simultaneously = diagonal movement).

**Solution:** Redirect tables mapping entry direction → exit direction.

**Files changed:** `line.lua` (lines 34-81, 216-236)

**Documentation:** `ROUTING_FIX_SUMMARY.md`

**Impact:** Routing now works correctly for all four cardinal directions. Foundation for complex paths.

### Phase 3: Critical Bug Fixes

**Bug 1: Zero Orbs Spawning**
- Root cause: Off-by-one error in bounds checking (`>= 0` instead of `>= 1`)
- Lua uses 1-based indexing, grid checks were using 0-based logic
- Fixed in `line.lua` spawn function
- Documentation: `BUGFIX_SPAWNING.md`

**Bug 2: Diagonal Movement**
- Root cause: Corners with dx AND dy set
- Fixed with redirect tables
- Documentation: `ROUTING_FIX_SUMMARY.md`

### Phase 4: Polish & Juice (Mid-Late October)

**Visual Improvements:**
- Permanent arrow overlays on all lines (subtle, always visible)
- Screen shake on orb collection (Vlambeer-style)
- Particle systems (color-matched bursts)
- Floating score numbers (rise and fade)

**Files changed:** `line.lua` (arrows), `main.lua` (juice)

**Documentation:** `JUICE_IMPLEMENTATION_COMPLETE.md`

**Impact:** Game went from functional to SATISFYING. Collecting orbs now has weight and feedback.

### Phase 5: Adaptive Feedback (Late October)

**Problem:** Screen shake at high throughput (20-30 orbs/sec) causing nausea.

**Solution:** Three-tier adaptive feedback system:
- Tier 1 (≤5 orbs/sec): Full feedback (shake + text + 12 particles)
- Tier 2 (6-15 orbs/sec): Reduced (8 particles only)
- Tier 3 (16+ orbs/sec): Minimal (4 particles only)

**Technical approach:**
- Track collection timestamps (last 2 seconds)
- Calculate throughput (orbs in last 1 second)
- Apply tier-specific feedback

**Files changed:** `main.lua` (lines 90-95, 233-247, 280-370)

**Documentation:** `ADAPTIVE_FEEDBACK_SYSTEM.md`, `IMPLEMENTATION_COMPLETE.md`

**Impact:** No more nausea at any throughput. Feedback scales naturally with machine efficiency.

### Phase 6: Architectural Debt Mechanic (Late October)

**Goal:** Make messy routing have mechanical consequences.

**Implementation:** Line crossing slowdown
- Count lines at grid position
- Apply slowdown multiplier: 2 lines = 0.6x, 3 lines = 0.4x, 4+ lines = 0.3x
- Visual feedback: Intersections render darker

**Files changed:** `line.lua` (adjustOrbSpeed), `main.lua` (pass lineTable)

**Documentation:** `LINE_CROSSING_IMPLEMENTATION.md`, `BEFORE_AFTER_SLOWDOWN.md`

**Impact:** "Cutting corners" now has VISIBLE consequences. Spaghetti routing creates throughput bottlenecks. Players must decide: rebuild cleanly or accept slower flow.

### Phase 7: Order System & Multiple Orders (Late October)

**Implemented:**
- Order class with requirements and timers
- Queue system (spawn new orders on timer)
- Multiple simultaneous orders (chaos!)
- Cascade failure (failed order penalizes others)
- Game over when all orders fail

**Files changed:** `order.lua` (new file), `main.lua` (state machine)

**Design decisions:**
- Orders stack vertically (left side of screen)
- First order spawns immediately (good UX)
- Order spawn interval decreases (escalation)
- Cascade penalty reduced from 20s to 10s (balance)

**Impact:** Creates the PRESSURE needed for chaos management. No more "take your time" - orders force speed.

### Phase 8: Debug Mode (Late October)

**Features:**
- Grid coordinates overlay
- Orb velocity display
- Line direction arrows (green/cyan/orange)
- Intersection count indicators (yellow x2, red x3+)
- FPS meter and entity counts
- Toggle with 'D' key

**Files changed:** `main.lua` (drawDebugOverlay function)

**Documentation:** `DEBUG_MODE_GUIDE.md`, `DEBUG_MODE_QUICK_START.md`

**Impact:** Accelerated development by 3-4x. Instantly see what's broken, no more blind debugging.

### Phase 9: The Passive Gameplay Problem (October 20, 2025) ⚠️

**Discovery:** Game is boring after initial setup.

**Analysis:**
- Players draw lines once, then watch
- No active gameplay loop
- Feels like Factorio (build and admire) not Papers Please (constant action)
- Routing is a SETUP phase, not core gameplay

**Critical realization:** We built the wrong game.

**Decision:** Pivot to active chaos management.

### Phase 10: Active Routing Solution (October 20, 2025) 🔄

**Solution:** Spawner color switching

**Implementation:**
- Spawners change colors every 10 seconds
- Visual warnings 5 seconds before switch
- Pulsing border (orange → red)
- Multiple simultaneous orders for added pressure

**Files changed:** `spawner.lua` (new update/draw methods), `main.lua` (spawner updates)

**Status:** ✅ WORKING, but with open design questions

**Impact:** Line drawing is now ONGOING. Players must constantly adapt routing. Still needs balancing and control mechanics.

---

## 7. Key Design Decisions & Pivots

### Decision 1: Fixed Feedback → Adaptive Feedback

**Problem:** Screen shake nauseating at 20+ orbs/sec
**Old approach:** Fixed feedback on every collection
**New approach:** Three-tier system scales with throughput
**Result:** Nausea solved, feedback feels natural

**Why this matters:** High throughput is a GOAL state (optimized machine). Can't punish players for playing well.

### Decision 2: Corners with dx/dy → Redirect Tables

**Problem:** Diagonal movement, LEFT direction broken
**Old approach:** `dx=100, dy=100` on corners
**New approach:** `redirects = {{from={dx,dy}, to={dx,dy}}}`
**Result:** Clean 90-degree turns, all directions work

**Why this matters:** Foundation for complex routing paths. Without this, game is unplayable.

### Decision 3: Single Order → Overlapping Orders

**Problem:** Too much time to build perfect solutions
**Old approach:** One order at a time, take your time
**New approach:** New orders spawn every 15s (then 12s, 10s)
**Result:** Time pressure, forced imperfection

**Why this matters:** Core to burnout theme. Can't say no to new orders, must juggle multiple demands.

### Decision 4: Static Spawners → Color Switching

**Problem:** Passive gameplay, one-time routing setup
**Old approach:** Spawners produce same color forever
**New approach:** Colors switch every 10s, must re-route
**Result:** Active gameplay, routing is ongoing skill

**Why this matters:** This is THE critical pivot. Makes line drawing the core loop instead of a setup phase.

### Decision 5: Factory Puzzle → Chaos Management (THE BIG ONE)

**Problem:** Game feels like Factorio, not Papers Please
**Old approach:** Build optimal solution and watch it work
**New approach:** Constant re-routing under pressure
**Result:** TBD - currently being tested

**Why this matters:** This defines what the game IS. Wrong core loop = wrong game. This pivot could save the project or require a full restart.

### Decision 6: Line Crossing Allowed → Slowdown Penalty

**Problem:** No reason to build cleanly
**Old approach:** Lines couldn't intersect at all
**New approach:** Lines can intersect but orbs slow down
**Result:** Architectural debt is visible and consequential

**Why this matters:** Makes "good enough" a meaningful choice. Messy but fast vs clean but slow.

### Decision 7: Grid-Only Routing → Free-Form Drawing (NOT IMPLEMENTED)

**Considered:** Free-form line drawing with bezier curves
**Rejected:** Too complex, loses grid clarity, harder to balance
**Current:** Grid-based placement remains

**Why this matters:** Grid-based is simpler to understand and debug. Free-form would need collision detection, path smoothing, etc. Not worth the complexity.

### Decision 8: Instant Line Drawing → Paid Deletion

**Problem:** Players could rebuild instantly for free
**Old approach:** Right-click deletes lines for free
**New approach:** Deletion costs $5 per line segment
**Result:** Rebuilding has cost, forces planning

**Why this matters:** Makes cutting corners tempting. Rebuilding should hurt a little, reinforcing "good enough" philosophy.

---

## 8. What Worked

### Adaptive Feedback System ✅

**What:** Scales feedback intensity based on throughput
**Why it worked:** Solved nausea without losing satisfaction
**Key insight:** Good gameplay states (high throughput) shouldn't feel bad (nauseating)
**Reusable pattern:** Track throughput, adapt to player success

**Implementation notes:**
- Simple timestamp tracking
- O(n) calculation per collection (acceptable)
- Three tiers maps to natural gameplay progression

### Line Crossing Slowdown ✅

**What:** Orbs slow at intersections (architectural debt)
**Why it worked:** Visual + mechanical consequences for messy routing
**Key insight:** Don't PREVENT bad choices, make them have COST
**Reusable pattern:** Emergent complexity from simple rules

**Implementation notes:**
- Count lines at grid position (O(n))
- Apply multiplier to velocity
- Visual feedback (darker lines)

### Debug Mode ✅

**What:** Toggle overlay showing game state
**Why it worked:** Accelerated development by 3-4x
**Key insight:** Visibility into system state is essential for iteration
**Reusable pattern:** Press D to see everything

**Implementation notes:**
- No performance impact (simple drawing)
- Lives outside main game loop
- Can be stripped for release

### Permanent Arrow Overlays ✅

**What:** Subtle direction indicators on all lines
**Why it worked:** Players can understand routing at a glance
**Key insight:** Under time pressure, clarity > aesthetics
**Reusable pattern:** Always-visible guidance for complex systems

**Implementation notes:**
- 8-pixel arrows, 50% opacity
- Gray color (unobtrusive)
- Single arrow per line (not cluttered)

### Grid-Based System ✅

**What:** All objects snap to 64px grid
**Why it worked:** Clean routing paths, predictable behavior
**Key insight:** Constraints create clarity
**Reusable pattern:** Grid systems for spatial puzzles

**Implementation notes:**
- 10x9 grid (640x576 play area)
- Centered in 1000x800 window
- Integer grid coordinates (no floating point errors)

### Overlapping Orders ✅

**What:** Multiple orders active simultaneously
**Why it worked:** Creates pressure and forces prioritization
**Key insight:** Can't say no = burnout metaphor
**Reusable pattern:** Escalating demands over time

**Implementation notes:**
- Orders spawn on timer (15s → 12s → 10s)
- All orders share same orb collection pool
- Failed orders penalize active orders (cascade)

---

## 9. What Didn't Work

### Fixed Feedback at High Throughput ❌

**What:** Screen shake on every orb collection
**Why it failed:** Nauseating at 20+ orbs/sec (every 0.05s)
**Lesson learned:** Good gameplay states shouldn't feel bad
**Fixed by:** Adaptive feedback system (see Phase 5)

### Passive Routing (CURRENT PROBLEM) ❌

**What:** Draw lines once, watch machine work
**Why it fails:** Boring after 30 seconds, no active gameplay
**Lesson learned:** Setup phases aren't core loops
**Being fixed by:** Spawner color switching (Phase 10)

**Key realization:** We built Factorio when we meant to build Papers Please.

### Single Orders ❌

**What:** One order at a time, linear progression
**Why it failed:** Too much time to optimize, no pressure
**Lesson learned:** Time pressure requires multiple demands
**Fixed by:** Overlapping orders (Phase 7)

### Free Line Deletion ❌

**What:** Right-click to delete lines instantly for free
**Why it failed:** No cost to rebuilding, encourages perfectionism
**Lesson learned:** Mistakes should have SMALL costs
**Fixed by:** $5 per line deletion

**Open question:** Is $5 too cheap? Should it scale with game progress?

### Random Spawner Colors (CURRENT PROBLEM) ❌

**What:** Spawners switch to random colors every 10s
**Why it fails:** Can make orders impossible (need red, all spawners switch to green)
**Lesson learned:** Random chaos needs guardrails
**Proposed fix:** Tool shop (buy spawner colors) OR guaranteed coverage

**Active debate:** How much control should players have vs RNG chaos?

---

## 10. Open Questions & Active Experiments

### Critical Design Questions

#### Q1: How to Solve Impossible Orders?

**The problem:** Random spawner switching can make orders uncompletable.

**Option A: Tool Shop (Player Control)**
- Players buy spawner types ($50-100 each)
- Spawners still switch, but within purchased colors
- Example: Buy red+green spawners → switches between red and green only
- PRO: Player agency, strategic planning
- CON: Adds complexity, shop UI, balancing costs

**Option B: Guaranteed Coverage (Game Assistance)**
- Algorithm ensures all active order colors are available
- Spawners switch intelligently to maintain coverage
- Example: Active order needs red → at least one spawner becomes red
- PRO: No impossible situations, cleaner UX
- CON: Less chaotic, removes some pressure

**Option C: Hybrid Approach**
- Base spawners switch randomly
- Players can BUY "locked" spawners that don't switch
- Example: Spend $100 to lock a red spawner
- PRO: Combines player control and chaos
- CON: Most complex to implement and explain

**Current status:** Under discussion, needs playtesting.

**Recommendation:** Start with Option B (guaranteed coverage), test if it's too easy, then add Option C (locked spawners) for player control.

#### Q2: Should We Add Manual Cauldron Serving?

**The idea:** Player must click cauldron to "serve" completed orders.

**PRO:**
- Adds tactical depth (when to serve?)
- Creates prioritization decisions
- Reinforces Papers Please comparison (manual action)
- Natural fit for burnout theme (too much to click!)

**CON:**
- Could be tedious if too frequent
- Might break flow of watching routing
- Needs careful UX (how to signal readiness?)

**Partially implemented:** Cauldron has `stir()` method in code, not connected to order completion.

**Next step:** Prototype and playtest. Make it OPTIONAL first (can collect OR serve, serving gives bonus?).

#### Q3: Should We Add Manual Combiner Stirring?

**The idea:** Combiners don't work automatically, must click to activate.

**PRO:**
- Another tactical decision point
- Makes yellow orbs harder to get (good for progression)
- Adds skill ceiling (when to stir vs when to route?)

**CON:**
- Could be frustrating if too manual
- Might slow down gameplay too much
- Needs clear visual feedback

**Current status:** Designed but not implemented.

**Next step:** Add as OPTIONAL mechanic first. Combiners work automatically BUT clicking them speeds up production or gives bonus efficiency.

#### Q4: What's the Tool Shop Progression?

**Potential purchases:**
- Spawner colors ($50-100): Unlock color for switching pool
- Locked spawners ($100-200): Prevent color switching
- Faster spawners ($150): Reduce orb spawn interval
- Extra combiners ($100): Place more combiners
- Line deletion discount ($50): Reduce deletion cost
- Heat resistance ($75): Cauldrons overheat slower

**Open questions:**
- When can players buy? Between runs? Mid-run?
- Do purchases persist? Or reset each run?
- How much money should orders give?
- Should there be a meta-progression curve?

**Current status:** No shop implemented, money accumulates but no spending.

#### Q5: How to Balance Spawner Switching Interval?

**Current:** 10 seconds switch, 5 seconds warning
**Too fast?** No time to adapt, feels unfair
**Too slow?** Routing becomes static again

**Tuning needed:** Playtest at 10s, 15s, 20s intervals.

**Consider:** Should interval DECREASE as orders escalate? (10s → 8s → 5s)

#### Q6: Should Orders Give More Nuanced Feedback?

**Current:** Red timer when < 10s
**Possible additions:**
- Color-coded progress bars (green → yellow → red)
- Audio cues (ticking clock at low time)
- Screen border flash when order fails
- Success animation (confetti burst?)

**Question:** How much juice is too much? Game already has heavy feedback.

### Active Experiments

**Experiment 1: Spawner Color Switching** (Status: IN PROGRESS)
- Hypothesis: Forces active routing, solves passive gameplay
- Test: Play for 10 minutes, measure engagement
- Success criteria: Never bored, always something to do
- Failure criteria: Feels random or unfair

**Experiment 2: Overlapping Orders** (Status: COMPLETE)
- Hypothesis: Creates pressure and prioritization decisions
- Test: Play with 1 order vs 2-3 simultaneous
- Result: ✅ Much more engaging with multiple orders
- Next: Balance spawn intervals and cascade penalties

**Experiment 3: Line Deletion Cost** (Status: NEEDS TESTING)
- Hypothesis: Small cost encourages "good enough" over perfection
- Test: Play with $0, $5, $10, $20 deletion costs
- Success criteria: Players sometimes leave messy routing
- Failure criteria: Players never rebuild OR always rebuild

---

## 11. Performance Notes

### Current Performance

**Target:** 60 FPS
**Typical:** 55-60 FPS with 100 orbs, 50 lines, 3 active orders
**Bottlenecks:** Particle systems at very high throughput (16+ orbs/sec)
**Acceptable:** Particle slowdown is minor, doesn't impact gameplay

### Optimizations Applied

**Spawner Updates:**
- Before: Scan entire spellArray grid (O(n*m))
- After: Direct iteration of spawnerTable (O(k) where k=3)
- Impact: 3x faster spawner updates

**Line Intersection Checks:**
- Only run when orb ENTERS line (not every frame)
- O(n) where n = lines at position (typically 1-3)
- Could cache if needed, but not currently a bottleneck

**Particle Systems:**
- Created once in love.load() (not per emission)
- Three systems (red, green, yellow)
- Max 100 particles per system (300 total)
- Adaptive feedback reduces emissions at high throughput

**Table Removal:**
- Always iterate BACKWARDS (safe removal during iteration)
- LÖVE best practice: `for i = #table, 1, -1 do`

### Known Slow Paths

**Orb Routing:**
- Each orb checks grid position against spellArray
- O(n) where n = number of orbs
- Could optimize with spatial partitioning if needed
- Not currently a problem at 100-200 orbs

**Debug Mode:**
- Drawing all overlays costs 5-10 FPS
- Acceptable tradeoff for development
- Can be stripped for release build

### Performance Gotchas to Avoid

**DON'T create fonts in draw loop:**
- Create once in love.load()
- Store in global variables
- LÖVE recreates font textures on every call (expensive!)

**DON'T create particle systems per emission:**
- Create once, emit bursts as needed
- setPosition() before emit() to move existing system

**DON'T scan entire grid every frame:**
- Use dedicated tables (spawnerTable, lineTable)
- Only iterate what you need

**DON'T remove from tables while iterating forward:**
- Always iterate backwards: `for i = #table, 1, -1 do`
- Lua indices shift when you remove items

### Future Performance Concerns

**If game slows down:**
1. Profile with debug mode (FPS drops when?)
2. Check entity counts (orbs, lines, particles)
3. Consider spatial partitioning for orb routing
4. Cache line intersection counts per grid cell
5. Reduce particle emissions or lifetimes

**If memory becomes an issue:**
1. Check collectionHistory size (should auto-prune)
2. Verify orbs/lines are being removed when off-grid
3. Check for leaked event listeners or timers

---

## 12. For Future Agents

### Core Files to Understand

**Start here:**
1. `main.lua` (game loop, state machine, all globals)
2. `line.lua` (routing logic, spawning, intersection detection)
3. `order.lua` (quest system, win/loss conditions)

**Then read:**
4. `spawner.lua` (color switching mechanic - THE KEY TO ACTIVE GAMEPLAY)
5. `orb.lua` (entity movement)
6. `cauldron.lua` (collection and scoring)

**Finally:**
7. `combiner.lua` (orb merging)

**Don't read unless debugging:**
- Image loading code in main.lua
- Debug overlay rendering

### Key Design Principles to Respect

1. **Imperfect decisions under pressure over optimal solutions**
   - Don't design mechanics with one "correct" answer
   - Every choice should be a tradeoff
   - "Good enough" should be a valid strategy

2. **Emergent gameplay over predefined puzzles**
   - Orders should escalate naturally
   - Difficulty comes from player's own choices
   - Architectural debt from early orders affects later orders

3. **Tactile interactions (drawing, clicking, dragging)**
   - Keep it physical
   - Avoid abstract menus
   - Actions should FEEL satisfying

4. **Active gameplay, not passive watching**
   - THIS IS THE CRITICAL ONE
   - If players can "set and forget," it's wrong
   - Routing should be ONGOING, not one-time setup

5. **Self-imposed chaos**
   - Game creates floor (unavoidable baseline chaos)
   - Player creates ceiling (optional additional chaos)
   - Best moments: "I did this to myself"

### Performance Gotchas to Avoid

**LÖVE2D-specific:**
- Never create fonts in draw loop
- Particle systems: create once, reuse
- Iterate backwards when removing from tables
- Use 0-1 color range (not 0-255)

**Lua-specific:**
- Arrays are 1-indexed (not 0-indexed)
- nil is falsy, false is falsy, 0 is truthy
- Tables are reference types (pass by reference)

**Game-specific:**
- Don't break grid alignment (everything 64px)
- Don't remove adaptive feedback (prevents nausea)
- Don't disable line crossing slowdown (architectural debt mechanic)
- Don't make spawners static (breaks active gameplay)

### Testing Approach

**Minimum viable playtest:**
1. Draw routing from all three spawners to cauldron
2. Complete at least 3 orders
3. Verify spawner color switching happens
4. Confirm orders overlap after 15 seconds
5. Let one order fail, check cascade penalty
6. Play until game over screen

**Good playtest:**
1. Complete all 10 orders (or fail trying)
2. Build complex routing with intersections
3. Observe throughput tiers (enable debug mode)
4. Test line deletion (costs money)
5. Test combiner usage (make yellow orbs)
6. Try different strategies (clean vs messy, fast vs careful)

**Comprehensive playtest:**
1. Play 5+ full runs
2. Try to find impossible orders
3. Test edge cases (delete all lines, let cauldron overheat, etc.)
4. Check performance at high entity counts
5. Verify all feedback systems work
6. Look for exploits or broken strategies

### How to Extend the Game

**Adding new orb colors:**
1. Add color string to possible types ("orange", "purple")
2. Create sprite image in imgs/
3. Add to spawner possibleColors array
4. Add to cauldron scoring logic
5. Add combiner recipe (if needed)
6. Add particle system in main.lua love.load()
7. Update order requirements to use new color

**Adding new mechanics:**
1. Consider if it's ACTIVE or PASSIVE
2. If passive, don't add it (breaks core loop)
3. If active, prototype as manual interaction (click/drag)
4. Test if it creates interesting decisions
5. Balance cost/benefit
6. Add feedback (visual, audio, haptic)

**Adding new order types:**
1. Update Order:new() with new requirements
2. Add to orderQueue in main.lua resetGame()
3. Balance time limit vs difficulty
4. Test with spawner color switching active
5. Verify order is completable (not impossible)

**Adding progression systems:**
1. Decide: between-run or within-run?
2. Add shop UI (if needed)
3. Implement purchase logic
4. Balance costs vs order rewards
5. Test progression curve (too fast? too slow?)
6. Add persistence (save/load if needed)

### Common Mistakes to Avoid

**Mistake 1: Adding optimization mechanics**
- DON'T add "build perfect solution and watch it work"
- DON'T reward static routing setups
- DO keep players busy and engaged

**Mistake 2: Removing pressure**
- DON'T give players unlimited time
- DON'T make orders optional
- DO keep escalation and cascade penalties

**Mistake 3: One "correct" solution**
- DON'T design orders with single optimal path
- DON'T punish messy routing too harshly
- DO reward "good enough" strategies

**Mistake 4: Breaking grid alignment**
- DON'T allow free-form positioning
- DON'T use floating point grid coordinates
- DO keep everything snapped to 64px grid

**Mistake 5: Ignoring feedback systems**
- DON'T remove adaptive feedback (causes nausea)
- DON'T add more feedback without testing at high throughput
- DO keep shake cooldowns and tier thresholds

### Where to Find Information

**Documentation map:**
```
GAME_DEV_DIARY.md            ← You are here (full history)
DESIGN_PLAN.md                ← Original vision and plan
ADAPTIVE_FEEDBACK_SYSTEM.md   ← Throughput tiers (technical)
ROUTING_FIX_SUMMARY.md        ← Corner redirect logic
LINE_CROSSING_IMPLEMENTATION.md ← Slowdown mechanic
JUICE_IMPLEMENTATION_COMPLETE.md ← Visual polish details
DEBUG_MODE_GUIDE.md           ← Debug overlay features
QUICK_START.md                ← How to play the game
```

**For specific issues:**
- Nausea/feedback problems → ADAPTIVE_FEEDBACK_SYSTEM.md
- Routing bugs → ROUTING_FIX_SUMMARY.md + CORNER_ANGLE_VERIFICATION.md
- Performance issues → IMPLEMENTATION_COMPLETE.md (performance notes)
- Gameplay feel → DESIGN_PLAN.md (core principles)
- Testing approach → TESTING_CHECKLIST.md + TEST_PLAN.md

### Current State Summary (October 20, 2025)

**What's solid:**
- ✅ Routing system works correctly
- ✅ Adaptive feedback prevents nausea
- ✅ Line crossing slowdown creates consequences
- ✅ Debug mode accelerates development
- ✅ Multiple overlapping orders create pressure

**What's being tested:**
- 🔄 Spawner color switching (active gameplay solution)
- 🔄 Balance of switching intervals
- 🔄 Order spawn timing and difficulty curve

**What needs decisions:**
- ❓ How to prevent impossible orders (tool shop? guaranteed coverage?)
- ❓ Should cauldron serving be manual?
- ❓ Should combiners require stirring?
- ❓ What should tool shop progression look like?

**What's broken:**
- ❌ Random spawner switching can make orders impossible
- ❌ No player control over available colors
- ❌ Unsafe global image references in spawner.lua

**Next steps:**
1. Playtest spawner switching for 30+ minutes
2. Decide on impossible order solution
3. Implement guaranteed coverage OR tool shop
4. Prototype manual serving (optional bonus?)
5. Balance switching intervals
6. Add audio (if time permits)

---

## Appendix: Documentation Audit

This dev diary synthesizes information from 23 markdown files:

**Design & Planning:**
- DESIGN_PLAN.md (original vision, phases)
- QUICK_START.md (how to play)
- QUICK_REFERENCE.md (controls and mechanics)

**Technical Implementation:**
- ADAPTIVE_FEEDBACK_SYSTEM.md (throughput tiers)
- ROUTING_FIX_SUMMARY.md (corner redirect logic)
- LINE_CROSSING_IMPLEMENTATION.md (slowdown mechanic)
- JUICE_IMPLEMENTATION_COMPLETE.md (visual polish)
- IMPLEMENTATION_COMPLETE.md (adaptive feedback status)
- IMPLEMENTATION_SUMMARY.md (general progress)

**Bug Fixes:**
- BUGFIX_SPAWNING.md (zero orbs spawning fix)
- FIX_COMPLETE.md (general bug resolution)
- CORNER_ANGLE_VERIFICATION.md (corner routing verification)

**Testing & Validation:**
- TESTING_CHECKLIST.md (feature checklist)
- TEST_PLAN.md (comprehensive test plan)
- LINE_DELETION_TESTING.md (deletion mechanic tests)

**Debug Tools:**
- DEBUG_MODE_GUIDE.md (full debug feature docs)
- DEBUG_MODE_QUICK_START.md (5-minute guide)
- DEBUG_MODE_IMPLEMENTATION_NOTES.md (technical notes)
- DEBUG_MODE_VISUAL.txt (ASCII diagrams)

**Tuning & Balance:**
- FEEDBACK_TUNING_GUIDE.md (parameter adjustment guide)
- FEEDBACK_SYSTEM_VISUAL.txt (feedback tier diagrams)

**Comparisons:**
- BEFORE_AFTER_COMPARISON.md (before/after snapshots)
- BEFORE_AFTER_SLOWDOWN.md (slowdown mechanic impact)

**Reference Files:**
- ARROW_VISUAL_REFERENCE.txt (arrow overlay examples)
- JUICE_TIMING_REFERENCE.txt (timing constants)
- ROUTING_FIX_VISUAL.txt (routing diagrams)

**Agent Prompts:**
- LOVE_EXPERT_AGENT_PROMPT.md (AI assistant context)

All documentation has been consolidated and synthesized into this master diary for easier navigation and context understanding.

---

---

## Phase 11: The Character Mode Experiment (October 20, 2025) 🧙‍♂️

**After spawner switching playtest failure, we prototyped a radically different approach.**

### What Was Built

**Dual gameplay mode system:**
- Press 'P' to toggle between "routing" and "character" modes
- Both modes fully functional side-by-side
- Clean code separation for easy comparison

**Character mode mechanics:**
- Purple wizard follows mouse cursor (smooth lerp)
- Click spawners to pickup orbs (max 5 capacity)
- Orbs orbit around wizard
- Walk near cauldron to auto-drop
- Weight system: More orbs = 15% slower per orb (5 orbs = 25% speed)
- Visual feedback: Capacity shown as "3/5", red when full

**File modified:** `main.lua` (added ~200 lines for character system)

### Playtest Results

**What felt good:**
- ✅ Cute wizard character (even as purple circle)
- ✅ More split-second decisions than routing
- ✅ Spawner switching creates variety
- ✅ Weight mechanic creates trade-offs (few fast trips vs one slow trip)
- ✅ Actually fun to play!

**What felt off:**
- ⚠️ "Too similar to Overcooked. Don't want Overcooked with wizards."
- ⚠️ "Building factory while maintaining it" theme is lost
- ⚠️ No automation/infrastructure building involved
- ⚠️ Just moving between places, not managing systems

**Developer quote:** "Maybe there's a way to combine automation with the character approach... a hybrid."

### Key Insight: The Single Destination Problem

**Why spawner switching failed to create active gameplay:**

Even with color switching every 10s:
- Player routed all 3 spawners → 1 cauldron
- Color switches changed INPUTS but not DECISIONS
- Route never needed to change (all colors go to same place)
- "Universal routing" solved everything

**Mathematical proof:**
- 3 spawners × 1 cauldron = 0 routing decisions
- All orbs need the same destination regardless of color
- Switching aesthetics ≠ switching decisions

**Like if Papers Please:**
- Changed which countries people were from
- But you still stamped every document the same way
- Visual changed, decision didn't

### The Hybrid System Proposal

**Core concept:** "Automation creates problems, manual solves them"

**Not:** Lines make the game easier
**Instead:** Lines transform chaos into DIFFERENT higher-stakes problems

**Framework:**
1. Lines deliver orbs automatically (routing infrastructure)
2. BUT: Cauldrons require manual serving (character execution)
3. AND: Cauldrons overheat if ignored (failure pressure)
4. AND: Systems break under load (forcing rebuilds)

**The unique appeal:**
> **Overcooked:** "The kitchen is designed to be chaotic"
> **Wizard's Workshop:** "YOU designed a chaotic kitchen. Can you survive your own creation?"

### Two Interpretations of Hybrid

**Interpretation A: Mode Switching IS the Mechanic**
- Routing mode = Pause/slow time, draw lines, strategic planning
- Character mode = Real-time execution, manual tasks
- Must toggle between modes during gameplay
- **Pressure:** While routing, cauldrons overheat! While executing, can't fix broken systems!

**Interpretation B: Simultaneous Control**
- Draw lines AND control character at same time
- Limited automation capacity (max X lines)
- Systems break, forcing rebuilds during execution
- **Pressure:** Split attention between building and maintaining

**Status:** Unclear which direction to take. Need to test both.

### Current Questions

**Does character mode need routing at all?**
- Pure character = Overcooked clone (not unique)
- Pure routing = Passive puzzle (already rejected)
- Hybrid = Potentially unique, but needs prototyping

**If hybrid, which interpretation?**
- Mode switching (novel, never seen this)
- Simultaneous (traditional, but might work)
- Something else?

**What creates "building while maintaining" feel?**
- Limited automation capacity?
- Systems that break?
- Manual finishers (automation delivers 90%, you do final 10%)?

### Next Steps Proposed

**Option 1:** Prototype hybrid with manual cauldron serving
- Lines deliver, character serves
- Test if combination feels unique

**Option 2:** Test mode switching mechanic
- Routing mode = strategic pause
- Character mode = frantic execution
- See if toggling creates interesting rhythm

**Option 3:** Explore pure character mode more
- Add more manual mechanics
- See if it differentiates from Overcooked enough

**Status:** Awaiting developer direction. Character mode prototype exists and is playable. Decision needed on next iteration.

---

## Phase 12: (Future - To Be Written)

*This section will document the chosen direction and its results.*

---

## Final Notes

This is a LIVING DOCUMENT. Update it as the game evolves.

**Key areas to track:**
1. Design pivots (when and WHY)
2. Technical debt (what's broken, what's temporary)
3. Open questions (what needs playtesting)
4. Performance issues (what slows down, how to fix)
5. Lessons learned (what worked, what failed)

**For the next agent/developer:**

This game is at a critical inflection point. We've now tested THREE approaches:
1. **Pure routing** = Passive after setup ❌
2. **Spawner switching** = Didn't create routing decisions ❌
3. **Character control** = Fun but too Overcooked ⚠️

The current hypothesis: **Hybrid automation + manual intervention** might capture the unique "building while maintaining" theme.

The core question has evolved: **Not "can we make routing active?" but "how do automation and manual control complement each other?"**

The burnout theme is strong. The mechanical loop is still being discovered. The next phase will determine if this becomes a unique entry in the chaos management genre or needs another fundamental pivot.

Test extensively. Listen to playtesters. Be willing to pivot again if needed.

Good luck. 🎮
