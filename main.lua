-- main.lua

require "orb"
require "line"
require "spawner"
require "cauldron"
require "combiner"
require "order"

function love.load()
    resetGame()

    -- Initialize debug mode (persistent across resets)
    debugMode = false

    -- Create debug font ONCE (LÖVE performance gotcha: never create fonts in draw loop!)
    debugFont = love.graphics.newFont(12)
    debugFontSmall = love.graphics.newFont(10)
end

function resetGame()
    redSqr = love.graphics.newImage("imgs/red_sqr.png")
    greenSqr = love.graphics.newImage("imgs/green_sqr.png")
    redCirc = love.graphics.newImage("imgs/red_circ.png")
    greenCirc = love.graphics.newImage("imgs/green_circ.png")
    yellowCirc = love.graphics.newImage("imgs/yellow_circ.png")
    cauldron = love.graphics.newImage("imgs/cauldron.png")
    combiner = love.graphics.newImage("imgs/combiner.png")
    hLine = love.graphics.newImage("imgs/h_line.png")
    vLine = love.graphics.newImage("imgs/v_line.png")
    cLine = love.graphics.newImage("imgs/c_line.png")

    orbTable = {}
    lineTable = {}
    combinerTable = {}
    score = 0  -- Initialize score

    -- Create a larger font for the score
    scoreFont = love.graphics.newFont(36)  -- 36 is the font size

    windowWidth = 1000
    windowHeight = 800

    love.window.setMode(1000, 800)
    love.graphics.setBackgroundColor(1, 1, 1, 1)  -- Fixed: LÖVE 11+ uses 0-1 range, not 0-255

    gridSize = 64
    gridWidth = 10
    gridHeight = 9

    baseSpeed = 100

    minSpawnTime = 1  -- Orb spawn interval

    girdXOffset = (windowWidth - gridSize*gridWidth) / 2
    girdYOffset = (windowHeight - gridSize*gridHeight) / 4

    -- Create a grid to hold squares
    spellArray = {}

    for x = 1, gridWidth do
        spellArray[x] = {}
        for y = 1, gridHeight do
            spellArray[x][y] = nil
        end
    end

    -- Add red spawner at position (3,3)
    spellArray[3][3] = Spawner:new((3 - 1) * gridSize + girdXOffset, 
                                   (3 - 1) * gridSize + girdYOffset,
                                   "red", redSqr)
                                   
    spellArray[3][7] = Spawner:new((3 - 1) * gridSize + girdXOffset,
                                   (7 - 1) * gridSize + girdYOffset,
                                   "green", greenSqr)

    -- Add yellow spawner at position (7,3)
    spellArray[7][3] = Spawner:new((7 - 1) * gridSize + girdXOffset,
                                   (3 - 1) * gridSize + girdYOffset,
                                   "yellow", yellowCirc)

    -- Add cauldron at position (10,3)
    spellArray[9][5] = Cauldron:new((9 - 1) * gridSize + girdXOffset,
                                   (5 - 1) * gridSize + girdYOffset,
                                   cauldron)

    isDraggingLine = false
    dragStartGrid = nil


    holdingArray = {}

    table.insert(holdingArray, Combiner:new(girdXOffset+gridSize, girdYOffset+gridSize*(gridHeight+2), 0, {"red", "green"}, "yellow", combiner))

    -- Initialize game state and order queue
    gameState = "playing"  -- States: "playing", "orderComplete", "orderFailed", "orderTransition", "allOrdersComplete"

    -- Create queue of 6 throughput-based escalating orders
    orderQueue = {
        Order:new({red = 5, green = 0, yellow = 0}, 40, 100,
                  "Order 1: 5 Red (Tutorial)"),

        Order:new({red = 15, green = 0, yellow = 0}, 30, 150,
                  "Order 2: 15 Red RUSH"),

        Order:new({green = 8, red = 0, yellow = 0}, 25, 100,
                  "Order 3: 8 Green"),

        Order:new({red = 20, green = 12, yellow = 0}, 40, 300,
                  "Order 4: Mixed Rush"),

        Order:new({yellow = 8, red = 0, green = 0}, 45, 200,
                  "Order 5: 8 Yellow"),

        Order:new({red = 30, green = 20, yellow = 10}, 60, 500,
                  "Order 6: MAXIMUM CHAOS")
    }

    currentOrderIndex = 1
    currentOrder = orderQueue[1]

    -- Transition timer for countdown between orders
    transitionTimer = 0

    -- Track total money earned across all orders
    totalMoney = 0

end

function myround(x, base)
    return base * math.floor(x/base)
end

function math.sign(x)
    if x >= 0 then return 1
    elseif x < 0 then return -1
    else return 0 end
end

function safeChecker(grid, x, y, obj)
    return grid[x] and grid[x][y] and grid[x][y]:is(obj)
end

function cLineAngle(x1, y1, x2, y2)
    local dx = x1 - x2
    local dy = y1 - y2
    local angle = math.deg(math.atan2(dy, dx)) + 45
    if angle < 0 then
        angle = angle + 360
    end
    return angle
end

function in_tbl(tbl, x)
    found = false
    for _, v in pairs(tbl) do
        if v == x then 
            found = true 
        end
    end
    return found
end

function lineCleanUp(tbl, x, y)
    -- NOTE: Currently disabled to allow multiple lines per grid cell
    -- This enables line crossing slowdown and architectural debt mechanics
    -- TODO: Consider removing this function entirely or repurposing for selective cleanup
    for i = #tbl, 1, -1 do
        local lineSeg = tbl[i]

        if lineSeg.gridX == x and lineSeg.gridY == y then
            table.remove(tbl, i)
        end
    end
end

function updateOrbGrid(orbList, spellGrid)

    local orbOut = {}

    for x = 1, gridWidth do
        orbOut[x] = {}
        for y = 1, gridHeight do
            orbOut[x][y] = {}
        end
    end

    for i = #orbList, 1, -1 do
        local orb = orbList[i]
        local gridX = math.floor((orb.x - girdXOffset) / gridSize) + 1
        local gridY = math.floor((orb.y - girdYOffset) / gridSize) + 1

        if gridX > gridWidth or gridX < 0 or gridY > gridHeight or gridY < 0 or spellGrid[gridX] == nil or spellGrid[gridX][gridY] == nil then
            table.remove(orbList, i)
        elseif spellGrid[gridX][gridY]:is(Cauldron) then
            score = score + spellGrid[gridX][gridY]:returnValue(orb.kind)
            -- Also notify the current order that we collected an orb
            if currentOrder and currentOrder.state == "active" then
                currentOrder:addOrb(orb.kind)
            end
            table.remove(orbList, i)
        else
            table.insert(orbOut[gridX][gridY], orb)
        end
    end

    return orbOut
end

-- Helper: Count lines at a grid position
function countLinesAt(gridX, gridY)
    local count = 0
    for _, line in ipairs(lineTable) do
        if line.gridX == gridX and line.gridY == gridY then
            count = count + 1
        end
    end
    return count
end

-- Helper: Draw an arrow (simple triangle)
function drawArrow(x, y, dirX, dirY, size, color)
    love.graphics.setColor(color[1], color[2], color[3], color[4] or 1)

    -- Calculate arrow angle from direction vector
    local angle = math.atan2(dirY, dirX)

    -- Arrow is an isosceles triangle pointing in direction
    local arrowTip = {x + math.cos(angle) * size, y + math.sin(angle) * size}
    local arrowBase1 = {
        x + math.cos(angle + 2.5) * (size * 0.6),
        y + math.sin(angle + 2.5) * (size * 0.6)
    }
    local arrowBase2 = {
        x + math.cos(angle - 2.5) * (size * 0.6),
        y + math.sin(angle - 2.5) * (size * 0.6)
    }

    love.graphics.polygon("fill", arrowTip[1], arrowTip[2], arrowBase1[1], arrowBase1[2], arrowBase2[1], arrowBase2[2])
    love.graphics.setColor(1, 1, 1, 1)  -- Reset color
end

-- Main debug overlay function
function drawDebugOverlay()
    if not debugMode then return end

    local origFont = love.graphics.getFont()

    -- 1. GRID COORDINATES (top-left corner of each cell)
    love.graphics.setFont(debugFontSmall)
    love.graphics.setColor(0.5, 0.5, 0.5, 0.8)
    for x = 1, gridWidth do
        for y = 1, gridHeight do
            local screenX = (x - 1) * gridSize + girdXOffset + 2
            local screenY = (y - 1) * gridSize + girdYOffset + 2
            love.graphics.print(string.format("%d,%d", x, y), screenX, screenY)
        end
    end

    -- 2. INTERSECTION COUNT INDICATORS (bottom-right corner of each cell)
    love.graphics.setFont(debugFont)
    for x = 1, gridWidth do
        for y = 1, gridHeight do
            local lineCount = countLinesAt(x, y)
            if lineCount > 1 then
                local screenX = (x - 1) * gridSize + girdXOffset + gridSize - 25
                local screenY = (y - 1) * gridSize + girdYOffset + gridSize - 18

                -- Color code: x2 = yellow, x3+ = red
                if lineCount == 2 then
                    love.graphics.setColor(1, 1, 0, 1)  -- Yellow
                else
                    love.graphics.setColor(1, 0, 0, 1)  -- Red
                end

                love.graphics.print(string.format("x%d", lineCount), screenX, screenY)
            end
        end
    end

    -- 3. LINE DIRECTION ARROWS
    for _, line in ipairs(lineTable) do
        local centerX = (line.gridX - 1) * gridSize + girdXOffset + gridSize / 2
        local centerY = (line.gridY - 1) * gridSize + girdYOffset + gridSize / 2

        if line.redirects then
            -- CORNER: Draw two small arrows (input -> output)
            for _, redirect in ipairs(line.redirects) do
                -- Input arrow (where orbs come from)
                local inputX = centerX - redirect.from.dx * 15
                local inputY = centerY - redirect.from.dy * 15
                drawArrow(inputX, inputY, redirect.from.dx, redirect.from.dy, 12, {0, 1, 1, 0.8})  -- Cyan

                -- Output arrow (where orbs go to)
                local outputX = centerX + redirect.to.dx * 8
                local outputY = centerY + redirect.to.dy * 8
                drawArrow(outputX, outputY, redirect.to.dx, redirect.to.dy, 12, {1, 0.5, 0, 0.8})  -- Orange
            end
        else
            -- STRAIGHT LINE: Single arrow showing flow direction
            local dirX = 0
            local dirY = 0
            if line.dx > 0 then dirX = 1
            elseif line.dx < 0 then dirX = -1 end
            if line.dy > 0 then dirY = 1
            elseif line.dy < 0 then dirY = -1 end

            drawArrow(centerX, centerY, dirX, dirY, 15, {0, 1, 0, 0.8})  -- Green
        end
    end

    -- 4. ORB VELOCITY DISPLAY (floating text above each orb)
    love.graphics.setFont(debugFontSmall)
    for _, orb in ipairs(orbTable) do
        love.graphics.setColor(0, 0, 0, 0.9)  -- Black background for readability
        local velocityText = string.format("dx:%.1f dy:%.1f", orb.dx, orb.dy)
        local textWidth = debugFontSmall:getWidth(velocityText)
        local textHeight = debugFontSmall:getHeight()

        -- Background rectangle
        love.graphics.rectangle("fill", orb.x - textWidth/2 - 2, orb.y - 30, textWidth + 4, textHeight + 2)

        -- Text in contrasting color (cyan/yellow)
        love.graphics.setColor(0, 1, 1, 1)  -- Cyan
        love.graphics.print(velocityText, orb.x - textWidth/2, orb.y - 29)
    end

    -- 5. DEBUG HUD (top-right corner, above score)
    love.graphics.setFont(debugFont)
    love.graphics.setColor(0, 0, 0, 0.7)  -- Semi-transparent black background
    love.graphics.rectangle("fill", windowWidth - 250, windowHeight - 150, 240, 140)

    love.graphics.setColor(0, 1, 0, 1)  -- Green
    love.graphics.print("DEBUG MODE ACTIVE", windowWidth - 240, windowHeight - 145)

    love.graphics.setColor(1, 1, 1, 1)  -- White
    local fps = love.timer.getFPS()
    local fpsColor = fps >= 50 and {0, 1, 0, 1} or fps >= 30 and {1, 1, 0, 1} or {1, 0, 0, 1}
    love.graphics.setColor(fpsColor[1], fpsColor[2], fpsColor[3], fpsColor[4])
    love.graphics.print(string.format("FPS: %d", fps), windowWidth - 240, windowHeight - 120)

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(string.format("Orbs: %d", #orbTable), windowWidth - 240, windowHeight - 95)
    love.graphics.print(string.format("Lines: %d", #lineTable), windowWidth - 240, windowHeight - 70)

    -- Calculate total intersections
    local totalIntersections = 0
    for x = 1, gridWidth do
        for y = 1, gridHeight do
            local count = countLinesAt(x, y)
            if count > 1 then
                totalIntersections = totalIntersections + 1
            end
        end
    end
    love.graphics.print(string.format("Intersections: %d", totalIntersections), windowWidth - 240, windowHeight - 45)

    -- Show game state
    love.graphics.setColor(0.7, 0.7, 1, 1)  -- Light blue
    love.graphics.print(string.format("State: %s", gameState), windowWidth - 240, windowHeight - 20)

    -- Reset graphics state
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(origFont)
end

dtotal = 0
function love.update(dt)

    -- Handle different game states
    if gameState == "playing" then
        -- Update the current order
        if currentOrder then
            currentOrder:update(dt)

            -- Check if order is complete
            if currentOrder:isComplete() then
                gameState = "orderTransition"
                currentOrder.state = "success"
                totalMoney = totalMoney + currentOrder.baseReward
                transitionTimer = 3  -- 3 second countdown before next order
            -- Check if order failed
            elseif currentOrder:hasFailed() then
                gameState = "orderFailed"
            end
        end

        -- Update all cauldrons (heat mechanic)
        -- for x = 1, gridWidth do
        --    for y = 1, gridHeight do
        --        if spellArray[x][y] and spellArray[x][y]:is(Cauldron) then
        --            spellArray[x][y]:update(dt)

        --            -- Check for burn failure
        --            if spellArray[x][y]:isBurning() then
        --                gameState = "orderFailed"
        --                if currentOrder then
        --                    currentOrder.state = "burned"  -- Mark as burned (vs time failure)
        --                end
        --            end
        --        end
        --    end
        -- end
    

        -- Update game objects (only when playing)
        for _, orb in ipairs(orbTable) do
            orb:move()
        end

        orbArray = updateOrbGrid(orbTable, spellArray)

        for _, line in ipairs(lineTable) do
            orbTable = line:spawnOrbs(spellArray, orbArray, orbTable)
        end

        -- Route orbs using spellArray (only ONE line per grid cell controls each orb)
        for _, orb in ipairs(orbTable) do
            -- Calculate which grid cell this orb is in
            local orbGridX = math.floor((orb.x - girdXOffset) / gridSize) + 1
            local orbGridY = math.floor((orb.y - girdYOffset) / gridSize) + 1

            -- Check if there's a line at this position in spellArray
            if spellArray[orbGridX] and spellArray[orbGridX][orbGridY] then
                local cellObject = spellArray[orbGridX][orbGridY]

                -- Only adjust speed if it's a Line (not spawner/cauldron/combiner)
                if cellObject:is(Line) then
                    cellObject:adjustOrbSpeedForSingleOrb(orb, orbGridX, orbGridY, lineTable)
                end
            end
        end

        for _, combiner in ipairs(combinerTable) do
            combiner:combine(spellArray, orbArray, orbTable)
        end

        if heldSquare then
            -- Follow mouse if holding a square
            heldSquare.x = love.mouse.getX()
            heldSquare.y = love.mouse.getY()
        end

    elseif gameState == "orderTransition" then
        -- Countdown between orders
        transitionTimer = transitionTimer - dt

        if transitionTimer <= 0 then
            -- Advance to next order
            currentOrderIndex = currentOrderIndex + 1

            if currentOrderIndex <= #orderQueue then
                -- Load next order
                currentOrder = orderQueue[currentOrderIndex]

                -- Clear orbs but KEEP lines and combiners (persistent machine!)
                orbTable = {}

                -- Reset cauldron heat
                for x = 1, gridWidth do
                    for y = 1, gridHeight do
                        if spellArray[x][y] and spellArray[x][y]:is(Cauldron) then
                            spellArray[x][y].heat = 0
                        end
                    end
                end

                gameState = "playing"
            else
                -- All orders complete!
                gameState = "allOrdersComplete"
            end
        end

    elseif gameState == "orderFailed" or gameState == "allOrdersComplete" then
        -- Paused - waiting for player to press SPACE to restart
        -- Game objects don't update in these states
    end
end

function love.draw()
    -- Draw the grid
    love.graphics.setColor(1, 1, 1, 1)  -- Fixed: Added alpha channel
    for x = 1, gridWidth do
        for y = 1, gridHeight do
            love.graphics.setColor(0, 0, 0, 1)  -- Fixed: 0-1 range with alpha
            love.graphics.rectangle("line", (x-1) * gridSize + girdXOffset, (y-1) * gridSize + girdYOffset, gridSize, gridSize)
        end
    end

    -- Draw placed squares
    for x = 1, gridWidth do
        for y = 1, gridHeight do
            if spellArray[x][y] ~= nil then
                love.graphics.setColor(1, 1, 1, 1)  -- Fixed: 0-1 range
                spellArray[x][y]:draw()

                -- Draw heat meters for cauldrons
                if spellArray[x][y]:is(Cauldron) then
                    spellArray[x][y]:drawHeatMeter()
                end
            end
        end
    end

    -- Draw held square
    if heldSquare then
        love.graphics.setColor(1, 1, 1, 1)  -- Fixed: 0-1 range
        heldSquare:draw()
    end

    for _, orb in ipairs(orbTable) do
        orb:draw()
    end

    for _, item in ipairs(holdingArray) do
        item:draw()
    end

    -- Draw current order UI (top-left)
    if currentOrder and gameState == "playing" then
        currentOrder:draw()
    end

    -- Draw score/money (top-right)
    love.graphics.setColor(0, 0, 0, 1)  -- Black color for text
    local scoreText = "Score: " .. score .. " | Money: $" .. totalMoney
    local defaultFont = love.graphics.getFont()  -- Store the default font
    love.graphics.setFont(scoreFont)  -- Set the larger font
    local textWidth = love.graphics.getFont():getWidth(scoreText)
    love.graphics.print(scoreText, windowWidth - textWidth - 20, 20)  -- Top-right corner
    love.graphics.setColor(1, 1, 1, 1)  -- Reset color to white
    love.graphics.setFont(defaultFont)  -- Reset to default font

    -- Draw order progress indicator (below score)
    love.graphics.setColor(0, 0, 0, 1)
    local orderProgressText = "Order " .. currentOrderIndex .. " of " .. #orderQueue
    love.graphics.print(orderProgressText, windowWidth - 200, 70)
    love.graphics.setColor(1, 1, 1, 1)

    -- Draw transition screen (between orders)
    if gameState == "orderTransition" and currentOrder then
        -- Show success overlay
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", 0, 0, windowWidth, windowHeight)

        -- Draw success message
        love.graphics.setColor(0, 1, 0, 1)  -- Green
        local successText = "ORDER COMPLETE!"
        love.graphics.setFont(scoreFont)
        local textWidth = scoreFont:getWidth(successText)
        love.graphics.print(successText, (windowWidth - textWidth) / 2, windowHeight / 2 - 100)

        -- Draw reward
        love.graphics.setColor(1, 1, 0, 1)  -- Yellow
        local rewardText = "+$" .. currentOrder.baseReward
        textWidth = scoreFont:getWidth(rewardText)
        love.graphics.print(rewardText, (windowWidth - textWidth) / 2, windowHeight / 2 - 40)

        -- Check if there's a next order
        if currentOrderIndex < #orderQueue then
            -- Draw next order preview
            love.graphics.setColor(1, 1, 1, 1)  -- White
            local nextOrder = orderQueue[currentOrderIndex + 1]
            local nextOrderText = "Next: " .. nextOrder.description
            local defaultFont = love.graphics.getFont()
            textWidth = defaultFont:getWidth(nextOrderText)
            love.graphics.setFont(defaultFont)
            love.graphics.print(nextOrderText, (windowWidth - textWidth) / 2, windowHeight / 2 + 20)

            -- Draw countdown
            love.graphics.setColor(0.8, 0.8, 0.8, 1)  -- Light gray
            local countdownText = "Starting in " .. math.ceil(transitionTimer) .. "..."
            textWidth = defaultFont:getWidth(countdownText)
            love.graphics.print(countdownText, (windowWidth - textWidth) / 2, windowHeight / 2 + 60)

            -- Draw skip instruction
            love.graphics.setColor(0.6, 0.6, 0.6, 1)  -- Gray
            local skipText = "(Press SPACE to skip)"
            textWidth = defaultFont:getWidth(skipText)
            love.graphics.print(skipText, (windowWidth - textWidth) / 2, windowHeight / 2 + 100)
        end

        love.graphics.setColor(1, 1, 1, 1)  -- Reset color
        love.graphics.setFont(defaultFont)  -- Reset font
    end

    -- Draw failure screen
    if gameState == "orderFailed" and currentOrder then
        currentOrder:drawFailure()
    end

    -- Draw final victory screen
    if gameState == "allOrdersComplete" then
        -- Full screen overlay
        love.graphics.setColor(0, 0, 0, 0.8)
        love.graphics.rectangle("fill", 0, 0, windowWidth, windowHeight)

        love.graphics.setFont(scoreFont)

        -- Draw main title
        love.graphics.setColor(1, 1, 0, 1)  -- Gold
        local titleText = "ALL ORDERS COMPLETE!"
        local textWidth = scoreFont:getWidth(titleText)
        love.graphics.print(titleText, (windowWidth - textWidth) / 2, windowHeight / 2 - 100)

        -- Draw total money earned
        love.graphics.setColor(0, 1, 0, 1)  -- Green
        local moneyText = "Total Earned: $" .. totalMoney
        textWidth = scoreFont:getWidth(moneyText)
        love.graphics.print(moneyText, (windowWidth - textWidth) / 2, windowHeight / 2 - 20)

        -- Draw score
        love.graphics.setColor(1, 1, 1, 1)  -- White
        local scoreText = "Final Score: " .. score
        textWidth = scoreFont:getWidth(scoreText)
        love.graphics.print(scoreText, (windowWidth - textWidth) / 2, windowHeight / 2 + 40)

        -- Draw restart instruction
        local defaultFont = love.graphics.getFont()
        love.graphics.setFont(defaultFont)
        local instructText = "Press SPACE to play again"
        textWidth = defaultFont:getWidth(instructText)
        love.graphics.print(instructText, (windowWidth - textWidth) / 2, windowHeight / 2 + 120)

        love.graphics.setColor(1, 1, 1, 1)  -- Reset color
        love.graphics.setFont(defaultFont)  -- Reset font
    end

    -- ALWAYS DRAW DEBUG OVERLAY LAST (after all game rendering)
    drawDebugOverlay()
end

function love.keypressed(key, scancode, isrepeat)
    if key == "x" then
        heldSquare = nil
    elseif key == "r" and heldSquare then
        heldSquare:turn()
    elseif key == "d" then
        -- Toggle debug mode
        debugMode = not debugMode
        print("Debug mode:", debugMode and "ON" or "OFF")
    elseif key == "space" then
        -- Handle different states
        if gameState == "orderTransition" then
            -- Skip countdown, immediately advance to next order
            transitionTimer = 0
        elseif gameState == "orderFailed" or gameState == "allOrdersComplete" then
            -- Full restart of entire game
            resetGame()
        end
    end
end

function love.mousepressed(x, y, button)
    if button == 1 then -- Left mouse button

            -- Check for dragging on grid
            -- Mouse clicks are absolute positions, no center offset needed
            local gridX = math.floor((x - girdXOffset) / gridSize) + 1
            local gridY = math.floor((y - girdYOffset) / gridSize) + 1

            if gridX >= 1 and gridX <= gridWidth and gridY >= 1 and gridY <= gridHeight then
                -- Check if clicking on a cauldron to stir it
                if spellArray[gridX][gridY] and spellArray[gridX][gridY]:is(Cauldron) and gameState == "playing" then
                    spellArray[gridX][gridY]:stir()
                    -- Don't start line dragging if we clicked a cauldron
                    return
                end

                if not heldSquare then
                    dragLastGrid = {x = gridX, y = gridY, xDir = 0, yDir = 0, lastLine = nil}
                    isDraggingLine = true
                else
                    spellArray[gridX][gridY] = Combiner:new((gridX-1) * gridSize + girdXOffset + gridSize/2,
                                                            (gridY-1) * gridSize + girdYOffset + gridSize/2,
                                                            heldSquare.rads, heldSquare.intakes, heldSquare.output, heldSquare.img)
                    table.insert(combinerTable, spellArray[gridX][gridY])
                    heldSquare = nil
                end
            end

            -- Then check for item picked up
            for i, item in ipairs(holdingArray) do
                if x >= item.x-gridSize/2 and x <= item.x+gridSize/2 and y >= item.y-gridSize/2 and y <= item.y+gridSize/2 then
                    heldSquare = Combiner:new(item.x, item.y, item.rads, item.intakes, item.output, item.img)
                end
            end

    elseif button == 2 then -- Right mouse button - DELETE LINES
        -- Stop any active line dragging (prioritize deletion)
        isDraggingLine = false
        dragLastGrid = nil

        -- Calculate which grid cell was clicked
        local gridX = math.floor((x - girdXOffset) / gridSize) + 1
        local gridY = math.floor((y - girdYOffset) / gridSize) + 1

        -- Check if click is within grid bounds
        if gridX >= 1 and gridX <= gridWidth and gridY >= 1 and gridY <= gridHeight then

            -- Check if there's an object at this cell
            if spellArray[gridX][gridY] then
                local cellObject = spellArray[gridX][gridY]

                -- ONLY delete if it's a Line (protect spawners, cauldrons, combiners)
                if cellObject:is(Line) then
                    -- Remove from spellArray (grid-based lookup)
                    spellArray[gridX][gridY] = nil

                    -- Remove ALL lines at this position from lineTable (handles intersections)
                    -- Iterate BACKWARDS for safe removal during iteration (LÖVE best practice!)
                    local deletedCount = 0
                    for i = #lineTable, 1, -1 do
                        local line = lineTable[i]
                        if line.gridX == gridX and line.gridY == gridY then
                            table.remove(lineTable, i)
                            deletedCount = deletedCount + 1
                        end
                    end

                    -- Console feedback (useful for testing/debugging)
                    print(string.format("Deleted %d line(s) at grid position (%d, %d)",
                                        deletedCount, gridX, gridY))
                else
                    -- Clicked on spawner/cauldron/combiner - do nothing, but give feedback
                    print(string.format("Cannot delete %s at (%d, %d) - protected object",
                                        cellObject:Iam(), gridX, gridY))
                end
            else
                -- Empty cell - no feedback needed (silent fail)
            end
        end
    end
end

function love.mousemoved(x, y, dx, dy, istouch)

    -- Mouse clicks are absolute positions, no center offset needed
    local gridX = math.floor((x - girdXOffset) / gridSize) + 1
    local gridY = math.floor((y - girdYOffset) / gridSize) + 1

    if gridX >= 0 and gridX <= gridWidth+1 and gridY >= 0 and gridY <= gridHeight+1 and isDraggingLine and dragLastGrid then

        lastX = dragLastGrid.x
        lastY = dragLastGrid.y
        xDir = dragLastGrid.xDir
        yDir = dragLastGrid.yDir
        lastLine = dragLastGrid.lastLine

        if gridX ~= lastX or gridY ~= lastY then
            -- Check which way we are dragging the line
            -- First we do horizontal
            if gridY == lastY and yDir == 0 and lastLine ~= "vLine" then
                if not safeChecker(spellArray, lastX, lastY, Spawner) and not safeChecker(spellArray, lastX, lastY, Cauldron) and not safeChecker(spellArray, lastX, lastY, Combiner) then
                    -- Determine direction based on actual drag direction, not grid comparison
                    local direction = math.sign(gridX - lastX)
                    spellArray[lastX][lastY] = Line:new((lastX-1) * gridSize + girdXOffset + gridSize/2,
                                                        (lastY-1) * gridSize + girdYOffset + gridSize/2,
                                                        0, "hLine", hLine, direction)
                    -- lineCleanUp(lineTable, lastX, lastY)  -- DISABLED: Allow multiple lines per cell for intersections
                    table.insert(lineTable, spellArray[lastX][lastY])
                end

                dragLastGrid = {x = gridX, y = gridY, xDir = gridX-lastX, yDir = gridY-lastY, lastLine = "hLine"}

            -- -- Then vertical
            elseif gridX == lastX and xDir == 0 and lastLine ~= "hLine" then
                if not safeChecker(spellArray, lastX, lastY, Spawner) and not safeChecker(spellArray, lastX, lastY, Cauldron) and not safeChecker(spellArray, lastX, lastY, Combiner) then
                    -- Determine direction based on actual drag direction, not grid comparison
                    local direction = math.sign(gridY - lastY)
                    spellArray[lastX][lastY] = Line:new((lastX-1) * gridSize + girdXOffset + gridSize/2,
                                                        (lastY-1) * gridSize + girdYOffset + gridSize/2,
                                                        0, "vLine", vLine, direction)
                    -- lineCleanUp(lineTable, lastX, lastY)  -- DISABLED: Allow multiple lines per cell for intersections
                    table.insert(lineTable, spellArray[lastX][lastY])
                end

                dragLastGrid = {x = gridX, y = gridY, xDir = gridX-lastX, yDir = gridY-lastY, lastLine = "vLine"}

            -- -- Then we check for curved
            else
                if not safeChecker(spellArray, lastX, lastY, Spawner) and not safeChecker(spellArray, lastX, lastY, Cauldron) and not safeChecker(spellArray, lastX, lastY, Combiner) then
                    local angle = cLineAngle(gridX-lastX, gridY-lastY, xDir, yDir)

                    spellArray[lastX][lastY] = Line:new((lastX-1) * gridSize + girdXOffset + gridSize/2,
                                                        (lastY-1) * gridSize + girdYOffset + gridSize/2,
                                                        angle, "cLine", cLine)
                    -- lineCleanUp(lineTable, lastX, lastY)  -- DISABLED: Allow multiple lines per cell for intersections
                    table.insert(lineTable, spellArray[lastX][lastY])
                end

                dragLastGrid = {x = gridX, y = gridY, xDir = gridX-lastX, yDir = gridY-lastY, lastLine = "cLine"}
            end
        end
    end
end


function love.mousereleased(x, y, button)
    dragLastGrid = nil
    isDraggingLine = false
end
