-- orb.lua

Line = {}
Line.__index = Line

function Line:new(x, y, angle, kind, img, direction)
    local obj = setmetatable({}, self)
    obj.x = x
    obj.y = y
    obj.gridX = math.floor((x - girdXOffset) / gridSize) + 1
    obj.gridY = math.floor((y - girdYOffset) / gridSize) + 1
    obj.kind = kind
    obj.img = img
    obj.rads = angle / 180 * math.pi
    obj.sinceSpawn = 999

    -- Direction: +1 or -1 to indicate which way the line was drawn
    -- For hLine: +1 = right, -1 = left
    -- For vLine: +1 = down, -1 = up
    local dir = direction or 1

    if kind == "hLine" then
        obj.dx = baseSpeed * dir  -- Apply direction multiplier
        obj.dy = 0
        obj.toCheck = {{x=-1, y=0},{x=1, y=0}}
        obj.legalConnects = {{"hLine0", "cLine0","cLine90"},{"hLine0", "cLine180","cLine270"}}
        obj.fullKind = "hLine0"
    elseif kind == "vLine" then
        obj.dx = 0
        obj.dy = baseSpeed * dir  -- Apply direction multiplier
        obj.toCheck = {{x=0, y=-1},{x=0, y=1}}
        obj.legalConnects = {{"vLine0", "cLine90","cLine180"},{"vLine0", "cLine0","cLine270"}}
        obj.fullKind = "vLine0"
    elseif kind == "cLine" and angle == 0 then
        -- Corner angle 0: connects TOP and RIGHT (visual: ┐ shape)
        -- Redirects: DOWN→RIGHT or LEFT→UP
        obj.dx = nil  -- Corners don't have a fixed direction
        obj.dy = nil
        obj.redirects = {
            {from = {dx=0, dy=1}, to = {dx=1, dy=0}},   -- DOWN→RIGHT (from above)
            {from = {dx=-1, dy=0}, to = {dx=0, dy=-1}}  -- LEFT→UP (from left)
        }
        obj.toCheck = {{x=0, y=-1},{x=1, y=0}}
        obj.legalConnects = {{"vLine0", "cLine90","cLine180"},{"hLine0", "cLine180","cLine270"}}
        obj.fullKind = "cLine0"
    elseif kind == "cLine" and angle == 90 then
        -- Corner angle 90: connects BOTTOM and RIGHT (visual: ┘ shape)
        -- Redirects: UP→RIGHT or LEFT→DOWN
        obj.dx = nil
        obj.dy = nil
        obj.redirects = {
            {from = {dx=0, dy=-1}, to = {dx=1, dy=0}},  -- UP→RIGHT (from below)
            {from = {dx=-1, dy=0}, to = {dx=0, dy=1}}   -- LEFT→DOWN (from left)
        }
        obj.toCheck = {{x=0, y=1},{x=1, y=0}}
        obj.legalConnects = {{"vLine0", "cLine0","cLine270"},{"hLine0", "cLine180","cLine270"}}
        obj.fullKind = "cLine90"
    elseif kind == "cLine" and angle == 180 then
        -- Corner angle 180: connects LEFT and BOTTOM (visual: └ shape)
        -- Redirects: UP→LEFT or RIGHT→DOWN
        obj.dx = nil
        obj.dy = nil
        obj.redirects = {
            {from = {dx=0, dy=-1}, to = {dx=-1, dy=0}},  -- UP→LEFT (from below)
            {from = {dx=1, dy=0}, to = {dx=0, dy=1}}     -- RIGHT→DOWN (from right)
        }
        obj.toCheck = {{x=-1, y=0},{x=0, y=1}}
        obj.legalConnects = {{"hLine0", "cLine0","cLine90"},{"vLine0", "cLine0","cLine270"}}
        obj.fullKind = "cLine180"
    elseif kind == "cLine" and angle == 270 then
        -- Corner angle 270: connects LEFT and TOP (visual: ┌ shape)
        -- Redirects: DOWN→LEFT or RIGHT→UP
        obj.dx = nil
        obj.dy = nil
        obj.redirects = {
            {from = {dx=0, dy=1}, to = {dx=-1, dy=0}},  -- DOWN→LEFT (from above)
            {from = {dx=1, dy=0}, to = {dx=0, dy=-1}}   -- RIGHT→UP (from right)
        }
        obj.toCheck = {{x=-1, y=0},{x=0, y=-1}}
        obj.legalConnects = {{"hLine0", "cLine0","cLine90"},{"vLine0", "cLine90","cLine180"}}
        obj.fullKind = "cLine270"
    else
        print("Uh Oh")
    end

    return obj
end

-- Methods
function Line:move()
    self.x = self.x + self.dx * love.timer.getDelta()
    self.y = self.y + self.dy * love.timer.getDelta()
end

function Line:draw()
    -- Check if this is an intersection for visual feedback
    -- lineTable is global, so we can access it directly
    local linesAtPosition = 0
    if lineTable then
        for _, otherLine in ipairs(lineTable) do
            if otherLine.gridX == self.gridX and otherLine.gridY == self.gridY then
                linesAtPosition = linesAtPosition + 1
            end
        end
    end

    -- Draw darker if intersection (visual feedback for spaghetti)
    if linesAtPosition > 1 then
        love.graphics.setColor(0.7, 0.7, 0.7, 1)  -- Darker gray for crossings
    else
        love.graphics.setColor(1, 1, 1, 1)  -- Normal white
    end

    love.graphics.draw(self.img, self.x, self.y, self.rads, 1, 1, 32, 32)
    love.graphics.setColor(1, 1, 1, 1)  -- Always reset color

    -- PART 1: PERMANENT ARROW OVERLAYS (subtle direction indicators)
    -- Draw a small, semi-transparent arrow showing flow direction
    -- This helps players see routing at a glance without debug mode

    -- Calculate center of this grid cell for arrow placement
    local centerX = (self.gridX - 1) * gridSize + girdXOffset + gridSize / 2
    local centerY = (self.gridY - 1) * gridSize + girdYOffset + gridSize / 2

    -- Subtle gray color: visible but unobtrusive (50% opacity)
    local arrowColor = {0.4, 0.4, 0.4, 0.5}
    local arrowSize = 8  -- Small, unobtrusive size (8 pixels)

    if self.redirects then
        -- CORNER: Draw single arrow showing OUTPUT direction (Option A: simpler, less clutter)
        -- Use the first redirect's output direction (both outputs point same way for corners)
        local outputDir = self.redirects[1].to
        love.graphics.setColor(arrowColor)

        -- Draw arrow slightly offset toward output direction for clarity
        local offsetX = centerX + outputDir.dx * 5
        local offsetY = centerY + outputDir.dy * 5

        -- Calculate arrow angle from direction vector
        local angle = math.atan2(outputDir.dy, outputDir.dx)

        -- Draw small triangle pointing in output direction
        local tipX = offsetX + math.cos(angle) * arrowSize
        local tipY = offsetY + math.sin(angle) * arrowSize
        local base1X = offsetX + math.cos(angle + 2.5) * (arrowSize * 0.6)
        local base1Y = offsetY + math.sin(angle + 2.5) * (arrowSize * 0.6)
        local base2X = offsetX + math.cos(angle - 2.5) * (arrowSize * 0.6)
        local base2Y = offsetY + math.sin(angle - 2.5) * (arrowSize * 0.6)

        love.graphics.polygon("fill", tipX, tipY, base1X, base1Y, base2X, base2Y)

    else
        -- STRAIGHT LINE: Single arrow showing flow direction
        local dirX = 0
        local dirY = 0

        -- Normalize direction from line velocity
        if self.dx > 0 then dirX = 1
        elseif self.dx < 0 then dirX = -1 end
        if self.dy > 0 then dirY = 1
        elseif self.dy < 0 then dirY = -1 end

        love.graphics.setColor(arrowColor)

        -- Calculate arrow angle from direction vector
        local angle = math.atan2(dirY, dirX)

        -- Draw small triangle pointing in flow direction
        local tipX = centerX + math.cos(angle) * arrowSize
        local tipY = centerY + math.sin(angle) * arrowSize
        local base1X = centerX + math.cos(angle + 2.5) * (arrowSize * 0.6)
        local base1Y = centerY + math.sin(angle + 2.5) * (arrowSize * 0.6)
        local base2X = centerX + math.cos(angle - 2.5) * (arrowSize * 0.6)
        local base2Y = centerY + math.sin(angle - 2.5) * (arrowSize * 0.6)

        love.graphics.polygon("fill", tipX, tipY, base1X, base1Y, base2X, base2Y)
    end

    -- Always reset color after drawing arrows
    love.graphics.setColor(1, 1, 1, 1)
end

function Line:spawnOrbs(spellGrid, orbGrid, orbTable)
    -- Safety check: if toCheck is nil, this line wasn't initialized properly
    if not self.toCheck then
        print("WARNING: Line at (" .. self.gridX .. ", " .. self.gridY .. ") has nil toCheck - skipping spawn")
        return orbTable  -- CRITICAL: Must return orbTable to prevent breaking the chain!
    end

    for i, locs in ipairs(self.toCheck) do

        checkX = self.gridX + locs.x
        checkY = self.gridY + locs.y

        -- First deal with orbs and check that there is an orb there
        -- CRITICAL FIX: Use 1-based indices (Lua standard), not 0-based
        -- Old code used ">= 0" which prevented spawning from grid position 1
        if checkX >= 1 and checkX <= gridWidth and checkY >= 1 and checkY <= gridHeight and spellGrid[checkX] and spellGrid[checkX][checkY] then

            -- First see if we spawn an orb
            if spellGrid[checkX][checkY]:Iam() == "Spawner" and orbGrid[checkX][checkY][1] == nil then

                -- Make sure nothing has been spawned too soon
                if self.sinceSpawn >= minSpawnTime then
                    -- Spawn at exact CENTER of spawner cell
                    orbX = (checkX - 1) * gridSize + girdXOffset + gridSize/2
                    orbY = (checkY - 1) * gridSize + girdYOffset + gridSize/2

                    -- Determine spawn velocity based on which connection point we're checking
                    local xSpeed, ySpeed

                    if self.redirects then
                        -- Corner piece: spawn with velocity pointing INTO the corner
                        -- locs points FROM corner TO spawner, so we need -locs (same as straight lines)
                        xSpeed = -locs.x * baseSpeed
                        ySpeed = -locs.y * baseSpeed
                    else
                        -- Straight line: spawn orbs moving FROM spawner TO line
                        -- locs points FROM line TO spawner, so we need -locs
                        -- This ensures orbs always travel toward the line, not away
                        xSpeed = -locs.x * baseSpeed
                        ySpeed = -locs.y * baseSpeed
                    end

                    orbTable = spellGrid[checkX][checkY]:addOrb(orbX, orbY, xSpeed, ySpeed, orbTable)
                    self.sinceSpawn = 0

                -- Otherwise tick up the counter
                else

                    self.sinceSpawn = self.sinceSpawn + love.timer.getDelta()

                end
            end
        end
    end

    return orbTable
end


-- New function: Adjust speed for a SINGLE orb at a known grid position
-- Called once per orb from main.lua (no more double-adjusting!)
function Line:adjustOrbSpeedForSingleOrb(orb, orbGridX, orbGridY, lineTable)
    -- Count how many lines are at THIS ORB'S grid position (not self's position!)
    -- BUG FIX: Was checking self.gridX/gridY, should check orbGridX/orbGridY
    local linesAtPosition = 0
    if lineTable then
        for _, otherLine in ipairs(lineTable) do
            if otherLine.gridX == orbGridX and otherLine.gridY == orbGridY then
                linesAtPosition = linesAtPosition + 1
            end
        end
    end

    -- Calculate slowdown multiplier based on intersection complexity
    -- More lines = more slowdown (architectural debt!)
    local slowdownMultiplier = 1.0
    if linesAtPosition > 1 then
        -- Each additional line adds more slowdown
        -- 2 lines = 0.6x, 3 lines = 0.4x, 4+ lines = 0.3x
        slowdownMultiplier = math.max(0.3, 1.0 - (linesAtPosition - 1) * 0.2)

        -- DEBUG: Print slowdown info when crossing detected (only in debug mode)
        if debugMode then
            print(string.format("CROSSING at (%d,%d): %d lines, multiplier: %.2f",
                orbGridX, orbGridY, linesAtPosition, slowdownMultiplier))
        end
    end

    -- Calculate where orb was LAST frame (before this move)
    local orbLastGridX = math.floor((orb.x - girdXOffset - (orb.dx * love.timer.getDelta())) / gridSize) + 1
    local orbLastGridY = math.floor((orb.y - girdYOffset - (orb.dy * love.timer.getDelta())) / gridSize) + 1

    -- Only adjust velocity if orb JUST ENTERED this cell (wasn't here last frame)
    -- This prevents constantly re-setting velocity every frame
    if orbLastGridX ~= orbGridX or orbLastGridY ~= orbGridY then
        -- Normalize the orb's current velocity to get direction (-1, 0, or 1)
        local orbDirX = 0
        local orbDirY = 0

        if orb.dx > 0 then orbDirX = 1
        elseif orb.dx < 0 then orbDirX = -1 end

        if orb.dy > 0 then orbDirY = 1
        elseif orb.dy < 0 then orbDirY = -1 end

        -- Check ALL lines at this position to find one matching orb's direction
        local matchingLine = nil
        for _, line in ipairs(lineTable) do
            if line.gridX == orbGridX and line.gridY == orbGridY then
                -- Does this line's direction match orb's direction?
                if line.redirects then
                    -- Corner: check if any redirect accepts this incoming direction
                    for _, redirect in ipairs(line.redirects) do
                        if redirect.from.dx == orbDirX and redirect.from.dy == orbDirY then
                            matchingLine = line
                            break
                        end
                    end
                else
                    -- Straight line: check if direction matches
                    -- Normalize line direction to compare
                    local lineDirX = 0
                    local lineDirY = 0
                    if line.dx > 0 then lineDirX = 1
                    elseif line.dx < 0 then lineDirX = -1 end
                    if line.dy > 0 then lineDirY = 1
                    elseif line.dy < 0 then lineDirY = -1 end

                    if lineDirX == orbDirX and lineDirY == orbDirY then
                        matchingLine = line
                        break
                    end
                end
            end

            if matchingLine then break end
        end

        -- Apply effect based on what we found
        if matchingLine then
            -- Found a line matching orb's direction
            if matchingLine.redirects then
                -- It's a corner - redirect the orb
                for _, redirect in ipairs(matchingLine.redirects) do
                    if redirect.from.dx == orbDirX and redirect.from.dy == orbDirY then
                        orb.dx = redirect.to.dx * baseSpeed * slowdownMultiplier
                        orb.dy = redirect.to.dy * baseSpeed * slowdownMultiplier

                        -- Snap orb to center of grid cell to prevent drift after corner redirect
                        orb.x = (orbGridX - 1) * gridSize + girdXOffset + gridSize/2
                        orb.y = (orbGridY - 1) * gridSize + girdYOffset + gridSize/2
                        break
                    end
                end
            else
                -- It's a straight line matching direction - MAINTAIN direction with slowdown
                -- This is the key: don't change direction, just slow down!
                orb.dx = orb.dx * slowdownMultiplier
                orb.dy = orb.dy * slowdownMultiplier

                -- DEBUG: Show actual speed after slowdown applied (only in debug mode)
                if debugMode and slowdownMultiplier < 1.0 then
                    print(string.format("  Straight line: speed now (%.1f, %.1f)", orb.dx, orb.dy))
                end

                -- NO position snap on straight lines - let orbs move smoothly!
            end
        else
            -- No matching line - orb is crossing perpendicular or moving through empty space
            -- Just apply slowdown to current velocity (creates "traffic jam" effect)
            orb.dx = orb.dx * slowdownMultiplier
            orb.dy = orb.dy * slowdownMultiplier

            -- DEBUG: Show actual speed after slowdown applied (only in debug mode)
            if debugMode and slowdownMultiplier < 1.0 then
                print(string.format("  Perpendicular crossing: speed now (%.1f, %.1f)", orb.dx, orb.dy))
            end
        end
    end
end


-- OLD FUNCTION - kept for reference, but no longer called
function Line:adjustOrbSpeed(spellGrid, orbGrid, orbTable, lineTable)
    -- holding off on all that, since we want to check what the orbs are doing no matter where they are coming from

    -- Count how many lines are at this grid position (intersection detection)
    local linesAtPosition = 0
    if lineTable then
        for _, otherLine in ipairs(lineTable) do
            if otherLine.gridX == self.gridX and otherLine.gridY == self.gridY then
                linesAtPosition = linesAtPosition + 1
            end
        end
    end

    -- Calculate slowdown multiplier based on intersection complexity
    -- More lines = more slowdown (architectural debt!)
    local slowdownMultiplier = 1.0
    if linesAtPosition > 1 then
        -- Each additional line adds more slowdown
        -- 2 lines = 0.6x, 3 lines = 0.4x, 4+ lines = 0.3x
        slowdownMultiplier = math.max(0.3, 1.0 - (linesAtPosition - 1) * 0.2)
    end

    -- So first check if there is an orb on our square
    for _, currOrb in ipairs(orbGrid[self.gridX][self.gridY]) do

        orbNowGridX = math.floor((currOrb.x - girdXOffset) / gridSize) + 1
        orbNowGridY = math.floor((currOrb.y - girdYOffset) / gridSize) + 1

        orbLastGridX = math.floor((currOrb.x - girdXOffset - (currOrb.dx * love.timer.getDelta())) / gridSize) + 1
        orbLastGridY = math.floor((currOrb.y - girdYOffset - (currOrb.dy * love.timer.getDelta())) / gridSize) + 1

        -- Okay so if they just came from another grid space then we adjust them
        if orbLastGridX ~= self.gridX or orbLastGridY ~= self.gridY then
            -- Check if this is a corner piece (has redirects instead of fixed dx/dy)
            if self.redirects then
                -- Corner piece: determine direction based on where orb came from
                -- Normalize the orb's current velocity to get direction (-1, 0, or 1)
                local orbDirX = 0
                local orbDirY = 0

                if currOrb.dx > 0 then orbDirX = 1
                elseif currOrb.dx < 0 then orbDirX = -1 end

                if currOrb.dy > 0 then orbDirY = 1
                elseif currOrb.dy < 0 then orbDirY = -1 end

                -- Find matching redirect rule
                local redirected = false
                for _, redirect in ipairs(self.redirects) do
                    if redirect.from.dx == orbDirX and redirect.from.dy == orbDirY then
                        -- Apply the redirect with slowdown
                        currOrb.dx = redirect.to.dx * baseSpeed * slowdownMultiplier
                        currOrb.dy = redirect.to.dy * baseSpeed * slowdownMultiplier
                        redirected = true
                        break
                    end
                end

                -- Debug: warn if no redirect matched (shouldn't happen with proper routing)
                if not redirected then
                    print("WARNING: Orb entering corner from unexpected direction:", orbDirX, orbDirY)
                    -- Keep current velocity as fallback
                end
            else
                -- Straight line: apply this line's direction
                -- Apply slowdown multiplier based on intersection complexity
                currOrb.dx = self.dx * slowdownMultiplier
                currOrb.dy = self.dy * slowdownMultiplier
            end
        end
    end
end

function Line:Iam()
    return "Line"
end

function Line:is(Type)
    local mt = getmetatable(self)
    if mt == Type then
        return true
    end
    return false  
end