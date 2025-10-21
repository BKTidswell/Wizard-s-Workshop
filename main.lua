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

    -- PART 2C: Create floating text font (larger, more visible than debug text)
    floatingTextFont = love.graphics.newFont(18)

    -- Mode hint font (for "Press P to switch modes")
    modeHintFont = love.graphics.newFont(14)

    -- PART 2B: Create particle systems for orb collection juice (one per color)
    -- Using a simple 2x2 white square as particle image (will be tinted)
    local particleImage = love.graphics.newCanvas(4, 4)
    love.graphics.setCanvas(particleImage)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("fill", 0, 0, 4, 4)
    love.graphics.setCanvas()

    -- Red particle system (for red orbs)
    redParticleSystem = love.graphics.newParticleSystem(particleImage, 100)
    redParticleSystem:setParticleLifetime(0.3, 0.5)  -- Short-lived sparkles
    redParticleSystem:setEmissionRate(0)  -- Manual emission (emit burst on demand)
    redParticleSystem:setSpeed(50, 100)  -- Burst outward speed
    redParticleSystem:setSpread(math.pi * 2)  -- Full 360 degree spread
    redParticleSystem:setSizes(1.5, 0)  -- Start large, shrink to 0 (fade out effect)
    redParticleSystem:setColors(1, 0, 0, 1, 1, 0, 0, 0)  -- Red, fade to transparent
    redParticleSystem:setLinearAcceleration(-20, -20, 20, 20)  -- Slight gravity/drag

    -- Green particle system (for green orbs)
    greenParticleSystem = love.graphics.newParticleSystem(particleImage, 100)
    greenParticleSystem:setParticleLifetime(0.3, 0.5)
    greenParticleSystem:setEmissionRate(0)
    greenParticleSystem:setSpeed(50, 100)
    greenParticleSystem:setSpread(math.pi * 2)
    greenParticleSystem:setSizes(1.5, 0)
    greenParticleSystem:setColors(0, 1, 0, 1, 0, 1, 0, 0)  -- Green, fade to transparent
    greenParticleSystem:setLinearAcceleration(-20, -20, 20, 20)

    -- Yellow particle system (for yellow orbs)
    yellowParticleSystem = love.graphics.newParticleSystem(particleImage, 100)
    yellowParticleSystem:setParticleLifetime(0.3, 0.5)
    yellowParticleSystem:setEmissionRate(0)
    yellowParticleSystem:setSpeed(50, 100)
    yellowParticleSystem:setSpread(math.pi * 2)
    yellowParticleSystem:setSizes(1.5, 0)
    yellowParticleSystem:setColors(1, 1, 0, 1, 1, 1, 0, 0)  -- Yellow, fade to transparent
    yellowParticleSystem:setLinearAcceleration(-20, -20, 20, 20)
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

    -- GAMEPLAY MODE SYSTEM
    -- "routing" = line drawing automation (current gameplay)
    -- "character" = wizard picks up and drops orbs manually
    gameplayMode = "routing"  -- Default to routing mode

    orbTable = {}
    lineTable = {}
    combinerTable = {}
    spawnerTable = {}  -- Track spawners for efficient updates
    score = 0  -- Initialize score

    -- Create a larger font for the score
    scoreFont = love.graphics.newFont(36)  -- 36 is the font size

    -- PART 2A: Screen shake variables (global for all rendering)
    shakeX = 0
    shakeY = 0
    shakeTimer = 0

    -- PART 2C: Floating text table (score popups when orbs collected)
    floatingTexts = {}  -- Each entry: {text, x, y, color, lifetime, maxLifetime}

    -- PART 3: Throughput-based adaptive feedback system
    -- Tracks recent orb collections to scale feedback intensity
    collectionHistory = {}  -- Timestamps of recent collections (last 2 seconds)
    currentThroughput = 0   -- Calculated orbs/second (updated on each collection)
    lastShakeTime = 0       -- Last time screen shake was triggered (for cooldown)
    SHAKE_COOLDOWN = 0.4    -- Minimum seconds between screen shakes (prevents nausea)

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
    table.insert(spawnerTable, spellArray[3][3])

    spellArray[3][7] = Spawner:new((3 - 1) * gridSize + girdXOffset,
                                   (7 - 1) * gridSize + girdYOffset,
                                   "green", greenSqr)
    table.insert(spawnerTable, spellArray[3][7])

    -- Add yellow spawner at position (7,3)
    spellArray[7][3] = Spawner:new((7 - 1) * gridSize + girdXOffset,
                                   (3 - 1) * gridSize + girdYOffset,
                                   "yellow", yellowCirc)
    table.insert(spawnerTable, spellArray[7][3])

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

    -- Create queue of orders that will spawn over time
    orderQueue = {
        Order:new({red = 5, green = 0, yellow = 0}, 60, 20,
                  "5 Red Orbs"),

        Order:new({red = 10, green = 0, yellow = 0}, 50, 25,
                  "10 Red Orbs"),

        Order:new({green = 8, red = 0, yellow = 0}, 55, 20,
                  "8 Green Orbs"),

        Order:new({red = 15, green = 0, yellow = 0}, 45, 30,
                  "15 Red RUSH"),

        Order:new({red = 12, green = 8, yellow = 0}, 60, 40,
                  "Mixed Colors"),

        Order:new({yellow = 5, red = 0, green = 0}, 70, 35,
                  "5 Yellow (Combine!)"),

        Order:new({red = 20, green = 12, yellow = 0}, 55, 50,
                  "Big Mixed Order"),

        Order:new({yellow = 8, red = 0, green = 0}, 60, 45,
                  "8 Yellow Rush"),

        Order:new({red = 25, green = 15, yellow = 5}, 75, 80,
                  "CHAOS ORDER"),

        Order:new({red = 30, green = 20, yellow = 10}, 80, 100,
                  "MAXIMUM CHAOS")
    }

    -- Active orders (multiple can be active at once!)
    activeOrders = {}

    -- Index of next order to spawn from queue
    nextOrderIndex = 1

    -- Timer for spawning next order
    orderSpawnTimer = 0
    orderSpawnDelay = 15  -- Start new order every 15 seconds (CHAOS!)

    -- Spawn first order immediately (good UX!)
    if orderQueue[1] then
        table.insert(activeOrders, orderQueue[1])
        highestOrderReached = 1
        nextOrderIndex = 2
    end

    -- Transition timer for countdown between orders
    transitionTimer = 0

    -- Track total money earned across all orders
    totalMoney = 0

    -- Track highest order reached for scoring
    highestOrderReached = 0

    -- WIZARD CHARACTER (for character mode)
    wizard = {
        x = windowWidth / 2,
        y = windowHeight / 2,
        radius = 16,
        carriedOrbs = {},  -- Orbs the wizard is carrying
        speed = 5,  -- Lerp speed for smooth following
        maxCarryCapacity = 5  -- Maximum orbs wizard can carry (upgradeable!)
    }

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

-- PART 3: Determine feedback tier based on current throughput
-- Returns 1, 2, or 3 based on orbs collected per second
-- This adapts the feedback intensity to prevent sensory overload at high throughput
function getFeedbackTier()
    if currentThroughput <= 1 then
        return 1  -- TIER 1: Individual feedback (≤1 orb/sec)
                  -- Each orb feels special, building the machine
    elseif currentThroughput <= 3 then
        return 2  -- TIER 2: Flow state (2-3 orbs/sec)
                  -- Machine is singing, smooth operation
    else
        return 3  -- TIER 3: Hyperspeed (4+ orbs/sec)
                  -- Machine roaring, big numbers
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

        -- CHARACTER MODE: Skip orbs carried by wizard (they're managed separately)
        local isCarried = false
        if gameplayMode == "character" then
            for _, carriedOrb in ipairs(wizard.carriedOrbs) do
                if carriedOrb == orb then
                    isCarried = true
                    break
                end
            end
        end

        if isCarried then
            -- Skip this orb, it's being carried by wizard
            -- Don't add to orbOut grid, don't check for removal
        else
            -- Normal routing mode logic
            local gridX = math.floor((orb.x - girdXOffset) / gridSize) + 1
            local gridY = math.floor((orb.y - girdYOffset) / gridSize) + 1

            if gridX > gridWidth or gridX < 0 or gridY > gridHeight or gridY < 0 or spellGrid[gridX] == nil or spellGrid[gridX][gridY] == nil then
                table.remove(orbList, i)
            elseif spellGrid[gridX][gridY]:is(Cauldron) then
            -- Calculate score value BEFORE adding to score (need for floating text)
            local orbValue = spellGrid[gridX][gridY]:returnValue(orb.kind)
            score = score + orbValue

            -- Notify ALL active orders that we collected an orb
            for _, order in ipairs(activeOrders) do
                if order.state == "active" then
                    order:addOrb(orb.kind)
                end
            end

            -- PART 3: ADAPTIVE FEEDBACK SYSTEM
            -- Tracks throughput and scales feedback intensity to prevent sensory overload

            -- STEP 1: Track this collection timestamp
            local now = love.timer.getTime()
            table.insert(collectionHistory, now)

            -- STEP 2: Clean up old timestamps (only keep last 2 seconds for accuracy)
            while #collectionHistory > 0 and (now - collectionHistory[1]) > 2.0 do
                table.remove(collectionHistory, 1)
            end

            -- STEP 3: Calculate current throughput (orbs collected in last 1 second)
            local recentCount = 0
            for j = #collectionHistory, 1, -1 do
                if (now - collectionHistory[j]) <= 1.0 then
                    recentCount = recentCount + 1
                end
            end
            currentThroughput = recentCount

            -- STEP 4: Determine feedback tier based on throughput
            local tier = getFeedbackTier()

            -- STEP 5: Calculate positions for particle bursts and floating text
            local cauldron = spellGrid[gridX][gridY]
            local burstX = cauldron.x + 32  -- Center of cauldron (64px sprite)
            local burstY = cauldron.y + 32

            -- Get color-matched particle system and floating text color
            local particleSystem
            local floatingColor
            if orb.kind == "red" then
                particleSystem = redParticleSystem
                floatingColor = {1, 0, 0, 1}
            elseif orb.kind == "green" then
                particleSystem = greenParticleSystem
                floatingColor = {0, 1, 0, 1}
            elseif orb.kind == "yellow" then
                particleSystem = yellowParticleSystem
                floatingColor = {1, 1, 0, 1}
            end

            -- TIER-BASED FEEDBACK EXECUTION
            if tier == 1 then
                -- TIER 1: Individual feedback (1-5 orbs/sec)
                -- FEEL: Each orb is special, building the machine
                -- Full feedback: particles, text, shake (with cooldown)

                -- Particles: Full burst (12 particles)
                particleSystem:setPosition(burstX, burstY)
                particleSystem:emit(12)

                -- Floating text: Show score value
                table.insert(floatingTexts, {
                    text = "+" .. orbValue,
                    x = burstX,
                    y = burstY - 20,
                    color = floatingColor,
                    lifetime = 1.0,
                    maxLifetime = 1.0
                })

                -- Screen shake: With cooldown to prevent earthquake
                -- Max 2.5 shakes/second even in tier 1
                if now - lastShakeTime >= SHAKE_COOLDOWN then
                    shakeTimer = 0.1
                    lastShakeTime = now
                end

            elseif tier == 2 then
                -- TIER 2: Flow state (6-15 orbs/sec)
                -- FEEL: Machine is singing, smooth operation
                -- Particles only, no text clutter, no shake

                -- Particles: Reduced burst (8 particles)
                particleSystem:setPosition(burstX, burstY)
                particleSystem:emit(8)

                -- NO floating text (reduces visual clutter)
                -- NO screen shake (prevents nauseating motion)

            elseif tier == 3 then
                -- TIER 3: Hyperspeed (16+ orbs/sec)
                -- FEEL: Machine roaring, big numbers
                -- Minimal particles, no text, no shake

                -- Particles: Minimal burst (4 particles)
                particleSystem:setPosition(burstX, burstY)
                particleSystem:emit(4)

                -- NO floating text (too much clutter at this speed)
                -- NO screen shake (would cause nausea)
            end

                table.remove(orbList, i)
            else
                table.insert(orbOut[gridX][gridY], orb)
            end
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

    -- PART 3: Show throughput and feedback tier
    -- Position below debug HUD for clear separation
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", windowWidth - 250, windowHeight - 180, 240, 25)

    local tier = getFeedbackTier()
    local tierColor
    if tier == 1 then
        tierColor = {0, 1, 0, 1}  -- Green: Individual feedback
    elseif tier == 2 then
        tierColor = {1, 1, 0, 1}  -- Yellow: Flow state
    else
        tierColor = {1, 0.5, 0, 1}  -- Orange: Hyperspeed
    end

    love.graphics.setColor(tierColor[1], tierColor[2], tierColor[3], tierColor[4])
    love.graphics.print(string.format("Throughput: %.1f/s | Tier %d", currentThroughput, tier),
                        windowWidth - 240, windowHeight - 175)

    -- Reset graphics state
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(origFont)
end

dtotal = 0
function love.update(dt)

    -- PART 2A: Update screen shake (decays over time)
    if shakeTimer > 0 then
        shakeTimer = shakeTimer - dt
        -- Random shake offset (2-4 pixels feels punchy without being nauseating)
        shakeX = (math.random() - 0.5) * 6
        shakeY = (math.random() - 0.5) * 6
    else
        -- No shake, reset to zero
        shakeX = 0
        shakeY = 0
    end

    -- PART 2B: Update particle systems (animate particles)
    redParticleSystem:update(dt)
    greenParticleSystem:update(dt)
    yellowParticleSystem:update(dt)

    -- PART 2C: Update floating texts (rise upward, fade out, then remove)
    for i = #floatingTexts, 1, -1 do
        local text = floatingTexts[i]
        text.lifetime = text.lifetime - dt
        text.y = text.y - 30 * dt  -- Rise 30 pixels per second

        -- Remove expired texts
        if text.lifetime <= 0 then
            table.remove(floatingTexts, i)
        end
    end

    -- CHARACTER MODE: Update wizard position to follow mouse
    if gameplayMode == "character" then
        local mouseX, mouseY = love.mouse.getPosition()

        -- Calculate speed based on carried orbs (more orbs = slower movement)
        -- Base speed: 5, reduces by 15% per orb carried
        -- 0 orbs = 100% speed, 5 orbs = 25% speed
        local weightFactor = 1.0 - (#wizard.carriedOrbs * 0.15)
        weightFactor = math.max(0.25, weightFactor)  -- Never slower than 25% speed
        local currentSpeed = wizard.speed * weightFactor

        -- Smooth lerp toward mouse (feels better than instant snap)
        -- Higher speed value = snappier follow, lower = smoother lag
        wizard.x = wizard.x + (mouseX - wizard.x) * currentSpeed * dt
        wizard.y = wizard.y + (mouseY - wizard.y) * currentSpeed * dt

        -- Update carried orb positions (orbit around wizard)
        for i, orb in ipairs(wizard.carriedOrbs) do
            -- Calculate orbit position based on index (evenly spaced around circle)
            local angle = (i - 1) * (math.pi * 2 / math.max(#wizard.carriedOrbs, 1))
            local orbitRadius = 30  -- Distance from wizard

            orb.x = wizard.x + math.cos(angle) * orbitRadius
            orb.y = wizard.y + math.sin(angle) * orbitRadius

            -- Set orb velocity to 0 (not moving independently)
            orb.dx = 0
            orb.dy = 0
        end

        -- Check collision with cauldrons (auto-drop orbs)
        for x = 1, gridWidth do
            for y = 1, gridHeight do
                if spellArray[x][y] and spellArray[x][y]:is(Cauldron) then
                    local cauldron = spellArray[x][y]

                    -- Calculate distance from wizard to cauldron center
                    local cauldronCenterX = cauldron.x + 32  -- 64px sprite, center is +32
                    local cauldronCenterY = cauldron.y + 32
                    local distance = math.sqrt((wizard.x - cauldronCenterX)^2 +
                                              (wizard.y - cauldronCenterY)^2)

                    -- Drop orbs if wizard is close enough (64px = width of one grid cell)
                    if distance < 64 then
                        -- Drop all carried orbs into cauldron
                        for i = #wizard.carriedOrbs, 1, -1 do
                            local orb = wizard.carriedOrbs[i]

                            -- Add to score and notify orders (same as normal collection)
                            local orbValue = cauldron:returnValue(orb.kind)
                            score = score + orbValue

                            -- Notify ALL active orders
                            for _, order in ipairs(activeOrders) do
                                if order.state == "active" then
                                    order:addOrb(orb.kind)
                                end
                            end

                            -- ADAPTIVE FEEDBACK (same as routing mode)
                            local now = love.timer.getTime()
                            table.insert(collectionHistory, now)

                            while #collectionHistory > 0 and (now - collectionHistory[1]) > 2.0 do
                                table.remove(collectionHistory, 1)
                            end

                            local recentCount = 0
                            for j = #collectionHistory, 1, -1 do
                                if (now - collectionHistory[j]) <= 1.0 then
                                    recentCount = recentCount + 1
                                end
                            end
                            currentThroughput = recentCount

                            local tier = getFeedbackTier()

                            -- Particle burst
                            local particleSystem
                            if orb.kind == "red" then
                                particleSystem = redParticleSystem
                            elseif orb.kind == "green" then
                                particleSystem = greenParticleSystem
                            elseif orb.kind == "yellow" then
                                particleSystem = yellowParticleSystem
                            end

                            if tier == 1 then
                                particleSystem:setPosition(cauldronCenterX, cauldronCenterY)
                                particleSystem:emit(12)

                                if now - lastShakeTime >= SHAKE_COOLDOWN then
                                    shakeTimer = 0.1
                                    lastShakeTime = now
                                end
                            elseif tier == 2 then
                                particleSystem:setPosition(cauldronCenterX, cauldronCenterY)
                                particleSystem:emit(8)
                            elseif tier == 3 then
                                particleSystem:setPosition(cauldronCenterX, cauldronCenterY)
                                particleSystem:emit(4)
                            end

                            -- Remove from wizard's inventory
                            table.remove(wizard.carriedOrbs, i)
                        end
                    end
                end
            end
        end
    end

    -- Handle different game states
    if gameState == "playing" then
        -- Spawn new orders on a timer
        orderSpawnTimer = orderSpawnTimer + dt

        if orderSpawnTimer >= orderSpawnDelay and nextOrderIndex <= #orderQueue then
            -- Spawn next order
            local newOrder = orderQueue[nextOrderIndex]
            table.insert(activeOrders, newOrder)
            highestOrderReached = nextOrderIndex

            nextOrderIndex = nextOrderIndex + 1
            orderSpawnTimer = 0

            -- Speed up order spawning as game progresses (escalation!)
            if nextOrderIndex > 3 then
                orderSpawnDelay = 12  -- Faster after order 3
            end
            if nextOrderIndex > 6 then
                orderSpawnDelay = 10  -- Even faster after order 6
            end
        end

        -- Update all active orders
        for i = #activeOrders, 1, -1 do
            local order = activeOrders[i]
            order:update(dt)

            -- Check if order is complete
            if order:isComplete() and order.state == "active" then
                order.state = "success"
                totalMoney = totalMoney + order.baseReward

                -- Visual/audio feedback for completion
                print("ORDER COMPLETE: +" .. order.baseReward .. " money!")

                -- Remove from active orders after brief delay (so player sees it)
                table.remove(activeOrders, i)

            -- Check if order failed (time ran out)
            elseif order:hasFailed() and order.state == "active" then
                order.state = "failed"

                -- CASCADE FAILURE: Reduce time on all other active orders
                local timePenalty = 10  -- Lose 10 seconds on other orders (reduced from 20 for better balance)
                print("ORDER FAILED! -" .. timePenalty .. "s penalty on all orders!")

                for _, otherOrder in ipairs(activeOrders) do
                    if otherOrder ~= order and otherOrder.state == "active" then
                        otherOrder.timeRemaining = otherOrder.timeRemaining - timePenalty

                        -- Prevent negative time (immediate fail)
                        if otherOrder.timeRemaining < 0 then
                            otherOrder.timeRemaining = 0
                        end
                    end
                end

                -- Remove failed order
                table.remove(activeOrders, i)

                -- Check if cascade caused all orders to fail
                local anyActiveOrders = false
                for _, checkOrder in ipairs(activeOrders) do
                    if checkOrder.state == "active" then
                        anyActiveOrders = true
                        break
                    end
                end

                -- If no active orders remain and we've spawned all orders, game over
                if not anyActiveOrders and nextOrderIndex > #orderQueue then
                    gameState = "allOrdersComplete"
                end
            end
        end

        -- Check if all orders are done (victory condition)
        if nextOrderIndex > #orderQueue and #activeOrders == 0 then
            gameState = "allOrdersComplete"
        end

        -- Update spawners (color switching mechanic) - optimized with direct table
        for _, spawner in ipairs(spawnerTable) do
            spawner:update(dt)
        end

        -- Update cauldrons (heat mechanic)
        for x = 1, gridWidth do
            for y = 1, gridHeight do
                if spellArray[x][y] and spellArray[x][y]:is(Cauldron) then
                    spellArray[x][y]:update(dt)
                end
            end
        end

        -- ROUTING MODE ONLY: Auto-routing and line spawning
        if gameplayMode == "routing" then
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
        end

        -- CHARACTER MODE ONLY: Orbs don't auto-route, they wait at spawners
        -- (Orbs that are carried by wizard were already updated above in character mode block)

        if heldSquare then
            -- Follow mouse if holding a square
            heldSquare.x = love.mouse.getX()
            heldSquare.y = love.mouse.getY()
        end

    elseif gameState == "orderFailed" or gameState == "allOrdersComplete" then
        -- Paused - waiting for player to press SPACE to restart
        -- Game objects don't update in these states
    end
end

function love.draw()
    -- PART 2A: Apply screen shake to ALL rendering
    -- This creates physical feedback when orbs are collected
    love.graphics.push()  -- Save original transform
    love.graphics.translate(shakeX, shakeY)  -- Offset everything by shake amount

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

    -- Draw wizard (CHARACTER MODE ONLY)
    if gameplayMode == "character" then
        -- Draw wizard as a purple circle (magical!)
        love.graphics.setColor(0.6, 0.2, 0.8, 1)  -- Purple
        love.graphics.circle("fill", wizard.x, wizard.y, wizard.radius)

        -- Draw wizard outline (white border for visibility)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setLineWidth(2)
        love.graphics.circle("line", wizard.x, wizard.y, wizard.radius)
        love.graphics.setLineWidth(1)

        -- Draw orbs in wizard's inventory (orbiting around wizard)
        -- (They're already in orbTable and draw above, this is just for clarity)

        -- Draw "Carrying: X/Y orbs" text below wizard
        local carriedText = "Carrying: " .. #wizard.carriedOrbs .. "/" .. wizard.maxCarryCapacity
        local textWidth = love.graphics.getFont():getWidth(carriedText)
        local textHeight = love.graphics.getFont():getHeight()

        -- Color text based on capacity (red when full)
        local textColor
        if #wizard.carriedOrbs >= wizard.maxCarryCapacity then
            textColor = {1, 0.3, 0.3, 1}  -- Red when full
        elseif #wizard.carriedOrbs > 0 then
            textColor = {1, 1, 1, 1}  -- White when carrying
        else
            textColor = {0.6, 0.6, 0.6, 1}  -- Gray when empty
        end

        -- Background rectangle
        love.graphics.setColor(0, 0, 0, 0.8)
        love.graphics.rectangle("fill", wizard.x - textWidth/2 - 4, wizard.y + 25,
                               textWidth + 8, textHeight + 4)

        -- Text
        love.graphics.setColor(textColor)
        love.graphics.print(carriedText, wizard.x - textWidth/2, wizard.y + 27)

        love.graphics.setColor(1, 1, 1, 1)  -- Reset color
    end

    for _, item in ipairs(holdingArray) do
        item:draw()
    end

    -- Draw all active orders stacked vertically (left side)
    if gameState == "playing" then
        local orderY = 20
        for i, order in ipairs(activeOrders) do
            -- Save graphics state
            love.graphics.push()

            -- Offset each order vertically
            love.graphics.translate(0, orderY)

            -- Draw the order UI
            order:draw()

            love.graphics.pop()

            -- Space orders 180 pixels apart (enough for UI + padding)
            orderY = orderY + 180
        end
    end

    -- Draw gameplay mode indicator (top-center)
    love.graphics.setFont(scoreFont)
    local modeText
    local modeColor
    if gameplayMode == "routing" then
        modeText = "MODE: ROUTING"
        modeColor = {0.2, 0.6, 1, 1}  -- Blue
    else
        modeText = "MODE: CHARACTER"
        modeColor = {0.6, 0.2, 0.8, 1}  -- Purple (matches wizard)
    end

    love.graphics.setColor(0, 0, 0, 0.8)  -- Background
    local modeTextWidth = scoreFont:getWidth(modeText)
    love.graphics.rectangle("fill", (windowWidth - modeTextWidth) / 2 - 10, 10,
                           modeTextWidth + 20, 40)

    love.graphics.setColor(modeColor)
    love.graphics.print(modeText, (windowWidth - modeTextWidth) / 2, 15)

    -- Draw instruction hint (below mode)
    love.graphics.setFont(modeHintFont)
    local hintText = "Press 'P' to switch modes"
    local hintWidth = modeHintFont:getWidth(hintText)
    love.graphics.setColor(0.7, 0.7, 0.7, 0.8)
    love.graphics.print(hintText, (windowWidth - hintWidth) / 2, 55)

    -- Draw score/money (top-right)
    love.graphics.setColor(0, 0, 0, 1)  -- Black color for text
    local scoreText = "Score: " .. score .. " | Money: $" .. totalMoney
    local defaultFont = love.graphics.getFont()  -- Store the default font
    love.graphics.setFont(scoreFont)  -- Set the larger font
    local textWidth = love.graphics.getFont():getWidth(scoreText)
    love.graphics.print(scoreText, windowWidth - textWidth - 20, 20)  -- Top-right corner
    love.graphics.setColor(1, 1, 1, 1)  -- Reset color to white
    love.graphics.setFont(defaultFont)  -- Reset to default font

    -- Draw highest order reached (below score)
    love.graphics.setColor(0, 0, 0, 1)
    local orderProgressText = "Highest Order: " .. highestOrderReached .. " / " .. #orderQueue
    love.graphics.print(orderProgressText, windowWidth - 250, 70)
    love.graphics.setColor(1, 1, 1, 1)

    -- Draw game over screen (workshop collapsed!)
    if gameState == "allOrdersComplete" then
        -- Full screen overlay
        love.graphics.setColor(0, 0, 0, 0.8)
        love.graphics.rectangle("fill", 0, 0, windowWidth, windowHeight)

        love.graphics.setFont(scoreFont)

        -- Draw main title
        love.graphics.setColor(1, 0.5, 0, 1)  -- Orange (workshop collapsed!)
        local titleText = "WORKSHOP COLLAPSED!"
        local textWidth = scoreFont:getWidth(titleText)
        love.graphics.print(titleText, (windowWidth - textWidth) / 2, windowHeight / 2 - 120)

        -- Draw highest order reached
        love.graphics.setColor(1, 1, 0, 1)  -- Yellow
        local orderText = "Reached Order " .. highestOrderReached .. " / " .. #orderQueue
        textWidth = scoreFont:getWidth(orderText)
        love.graphics.print(orderText, (windowWidth - textWidth) / 2, windowHeight / 2 - 60)

        -- Draw total money earned
        love.graphics.setColor(0, 1, 0, 1)  -- Green
        local moneyText = "Total Earned: $" .. totalMoney
        textWidth = scoreFont:getWidth(moneyText)
        love.graphics.print(moneyText, (windowWidth - textWidth) / 2, windowHeight / 2)

        -- Draw score
        love.graphics.setColor(1, 1, 1, 1)  -- White
        local scoreText = "Final Score: " .. score
        textWidth = scoreFont:getWidth(scoreText)
        love.graphics.print(scoreText, (windowWidth - textWidth) / 2, windowHeight / 2 + 60)

        -- Draw restart instruction
        local defaultFont = love.graphics.getFont()
        love.graphics.setFont(defaultFont)
        local instructText = "Press SPACE to rebuild and try again!"
        textWidth = defaultFont:getWidth(instructText)
        love.graphics.print(instructText, (windowWidth - textWidth) / 2, windowHeight / 2 + 140)

        love.graphics.setColor(1, 1, 1, 1)  -- Reset color
        love.graphics.setFont(defaultFont)  -- Reset font
    end

    -- PART 2B: Draw particle systems (color-matched bursts)
    -- These create visual "pop" when orbs are collected
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(redParticleSystem, 0, 0)
    love.graphics.draw(greenParticleSystem, 0, 0)
    love.graphics.draw(yellowParticleSystem, 0, 0)

    -- PART 2C: Draw floating score texts (rise and fade out)
    love.graphics.setFont(floatingTextFont)
    for _, text in ipairs(floatingTexts) do
        -- Calculate alpha based on remaining lifetime (fade out)
        local alpha = text.lifetime / text.maxLifetime
        love.graphics.setColor(text.color[1], text.color[2], text.color[3], alpha)

        -- Center text horizontally
        local textWidth = floatingTextFont:getWidth(text.text)
        love.graphics.print(text.text, text.x - textWidth/2, text.y)
    end
    love.graphics.setColor(1, 1, 1, 1)  -- Reset color

    -- PART 2A: Restore original transform (end screen shake effect)
    love.graphics.pop()

    -- ALWAYS DRAW DEBUG OVERLAY LAST (after all game rendering, outside shake transform)
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
    elseif key == "p" then
        -- TOGGLE GAMEPLAY MODE
        if gameplayMode == "routing" then
            gameplayMode = "character"
            print("Switched to CHARACTER mode - wizard picks up orbs!")
        else
            gameplayMode = "routing"
            print("Switched to ROUTING mode - lines automate delivery!")
        end
    elseif key == "space" then
        -- Handle different states
        if gameState == "allOrdersComplete" then
            -- Full restart of entire game
            resetGame()
        end
    end
end

function love.mousepressed(x, y, button)
    if button == 1 then -- Left mouse button

            -- CHARACTER MODE: Click spawner to pickup orb
            if gameplayMode == "character" then
                local gridX = math.floor((x - girdXOffset) / gridSize) + 1
                local gridY = math.floor((y - girdYOffset) / gridSize) + 1

                -- Check if clicking on a spawner
                if gridX >= 1 and gridX <= gridWidth and gridY >= 1 and gridY <= gridHeight then
                    if spellArray[gridX][gridY] and spellArray[gridX][gridY]:is(Spawner) then
                        local spawner = spellArray[gridX][gridY]

                        -- Check if wizard can carry more orbs
                        if #wizard.carriedOrbs >= wizard.maxCarryCapacity then
                            print("Can't carry more! Capacity: " .. wizard.maxCarryCapacity .. "/" .. wizard.maxCarryCapacity)
                            return
                        end

                        -- Create a new orb at spawner position
                        local newOrb = Orb:new(
                            spawner.x + 32,  -- Center of spawner (64px sprite)
                            spawner.y + 32,
                            0,  -- No velocity
                            0,
                            "spawner",
                            spawner.kind,
                            spawner.kind == "red" and redCirc or
                            spawner.kind == "green" and greenCirc or
                            yellowCirc
                        )

                        -- Add to wizard's carried orbs
                        table.insert(wizard.carriedOrbs, newOrb)

                        -- Also add to global orbTable so it renders
                        table.insert(orbTable, newOrb)

                        print("Picked up " .. spawner.kind .. " orb! Carrying: " .. #wizard.carriedOrbs .. "/" .. wizard.maxCarryCapacity)

                        -- Don't process other click logic in character mode
                        return
                    end
                end

                -- In character mode, don't allow line drawing or combiner placement
                return
            end

            -- ROUTING MODE: Normal line drawing and combiner placement
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

    elseif button == 2 then -- Right mouse button - DELETE LINES (costs money!)
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
                    -- Count how many lines we're about to delete
                    local deletedCount = 0
                    for i = #lineTable, 1, -1 do
                        local line = lineTable[i]
                        if line.gridX == gridX and line.gridY == gridY then
                            deletedCount = deletedCount + 1
                        end
                    end

                    -- Calculate deletion cost ($5 per line segment)
                    local deletionCost = deletedCount * 5

                    -- Check if player can afford it
                    if totalMoney >= deletionCost then
                        -- Charge the player
                        totalMoney = totalMoney - deletionCost

                        -- Remove from spellArray (grid-based lookup)
                        spellArray[gridX][gridY] = nil

                        -- Remove ALL lines at this position from lineTable (handles intersections)
                        -- Iterate BACKWARDS for safe removal during iteration (LÖVE best practice!)
                        for i = #lineTable, 1, -1 do
                            local line = lineTable[i]
                            if line.gridX == gridX and line.gridY == gridY then
                                table.remove(lineTable, i)
                            end
                        end

                        -- Console feedback (useful for testing/debugging)
                        print(string.format("Deleted %d line(s) at (%d, %d) for $%d",
                                            deletedCount, gridX, gridY, deletionCost))
                    else
                        -- Can't afford to delete!
                        print(string.format("Cannot afford to delete! Need $%d, have $%d",
                                            deletionCost, totalMoney))
                    end
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
