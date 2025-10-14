-- Test script to verify grid calculation fix
-- Run with: lua test_grid_calc.lua

-- Set up constants (same as game)
gridSize = 64
girdXOffset = (1000 - gridSize*10) / 2  -- windowWidth=1000, gridWidth=10
girdYOffset = (800 - gridSize*9) / 4     -- windowHeight=800, gridHeight=9

print("Grid constants:")
print("  gridSize:", gridSize)
print("  girdXOffset:", girdXOffset)
print("  girdYOffset:", girdYOffset)
print()

-- Test spawn position for spawner at (3,7) spawning RIGHT
-- This is the case that was failing
checkX = 4  -- One cell to right of spawner at (3,7)
checkY = 7
locs_x = 1  -- Spawning RIGHT
locs_y = 0

-- Calculate spawn position (from spawner.lua line 142-143)
orbX = (checkX - 1) * gridSize + girdXOffset + gridSize/2 + locs_x*gridSize*0.4
orbY = (checkY - 1) * gridSize + girdYOffset + gridSize/2 + locs_y*gridSize*0.4

print("Test case: Green spawner at (3,7) spawning RIGHT")
print("  checkX, checkY:", checkX, checkY)
print("  Spawn position:")
print("    orbX =", orbX)
print("    orbY =", orbY)
print()

-- Calculate grid position using OLD method (BROKEN)
gridX_old = math.floor((orbX - girdXOffset + gridSize/2) / gridSize) + 1
gridY_old = math.floor((orbY - girdYOffset + gridSize/2) / gridSize) + 1

print("  OLD grid calculation (WITH extra gridSize/2):")
print("    gridX =", gridX_old, (gridX_old == checkX) and "✅ CORRECT" or "❌ WRONG!")
print("    gridY =", gridY_old, (gridY_old == checkY) and "✅ CORRECT" or "❌ WRONG!")
print()

-- Calculate grid position using NEW method (FIXED)
gridX_new = math.floor((orbX - girdXOffset) / gridSize) + 1
gridY_new = math.floor((orbY - girdYOffset) / gridSize) + 1

print("  NEW grid calculation (WITHOUT extra gridSize/2):")
print("    gridX =", gridX_new, (gridX_new == checkX) and "✅ CORRECT" or "❌ WRONG!")
print("    gridY =", gridY_new, (gridY_new == checkY) and "✅ CORRECT" or "❌ WRONG!")
print()

-- Test a few more cases to be thorough
print("Additional test cases:")
print()

local test_cases = {
    {spawner_x=3, spawner_y=3, dir="RIGHT", locs_x=1, locs_y=0},
    {spawner_x=3, spawner_y=3, dir="DOWN", locs_x=0, locs_y=1},
    {spawner_x=7, spawner_y=3, dir="LEFT", locs_x=-1, locs_y=0},
    {spawner_x=7, spawner_y=3, dir="UP", locs_x=0, locs_y=-1},
}

for i, test in ipairs(test_cases) do
    local sx, sy = test.spawner_x, test.spawner_y
    local cx = sx + test.locs_x
    local cy = sy + test.locs_y

    local ox = (cx - 1) * gridSize + girdXOffset + gridSize/2 + test.locs_x*gridSize*0.4
    local oy = (cy - 1) * gridSize + girdYOffset + gridSize/2 + test.locs_y*gridSize*0.4

    local gx = math.floor((ox - girdXOffset) / gridSize) + 1
    local gy = math.floor((oy - girdYOffset) / gridSize) + 1

    local correct = (gx == cx and gy == cy)
    print(string.format("  Case %d: Spawner (%d,%d) spawning %s -> Grid (%d,%d) %s",
        i, sx, sy, test.dir, gx, gy, correct and "✅" or "❌"))
end
