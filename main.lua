-- main.lua

require "orb"
require "line"
require "spawner"
require "cauldron"
require "combiner"

function love.load()
    resetGame()
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
    love.graphics.setBackgroundColor(255,255,255,0)

    gridSize = 64
    gridWidth = 10
    gridHeight = 9

    baseSpeed = 100

    minSpawnTime = 1

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

    -- Add cauldron at position (10,3)
    spellArray[9][5] = Cauldron:new((9 - 1) * gridSize + girdXOffset,
                                   (5 - 1) * gridSize + girdYOffset,
                                   cauldron)

    isDraggingLine = false
    dragStartGrid = nil


    holdingArray = {}

    table.insert(holdingArray, Combiner:new(girdXOffset+gridSize, girdYOffset+gridSize*(gridHeight+2), 0, {"red", "green"}, "yellow", combiner))


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
        local gridX = math.floor((orb.x - girdXOffset + gridSize/2) / gridSize) + 1
        local gridY = math.floor((orb.y - girdYOffset + gridSize/2) / gridSize) + 1

        if gridX > gridWidth or gridX < 0 or gridY > gridHeight or gridY < 0 or spellGrid[gridX] == nil or spellGrid[gridX][gridY] == nil then
            table.remove(orbList, i)
        elseif spellGrid[gridX][gridY]:is(Cauldron) then
            score = score + spellGrid[gridX][gridY]:returnValue(orb.kind)
            table.remove(orbList, i)
        else
            table.insert(orbOut[gridX][gridY], orb)
        end
    end

    return orbOut
end

dtotal = 0
function love.update(dt)

    for _, orb in ipairs(orbTable) do
        orb:move()
    end

    orbArray = updateOrbGrid(orbTable, spellArray)

    for _, line in ipairs(lineTable) do
        line:spawnOrbs(spellArray, orbArray, orbTable)
    end

    for _, line in ipairs(lineTable) do
        line:adjustOrbSpeed(spellArray, orbArray, orbTable)
    end

     for _, combiner in ipairs(combinerTable) do
        combiner:combine(spellArray, orbArray, orbTable)
    end

    if heldSquare then
        -- Follow mouse if holding a square
        heldSquare.x = love.mouse.getX()
        heldSquare.y = love.mouse.getY()
    end
end

function love.draw()
    -- Draw the grid
    love.graphics.setColor(1, 1, 1)
    for x = 1, gridWidth do
        for y = 1, gridHeight do
            love.graphics.setColor(0,0,0)
            love.graphics.rectangle("line", (x-1) * gridSize + girdXOffset, (y-1) * gridSize + girdYOffset, gridSize, gridSize)
        end
    end

    -- Draw placed squares
    for x = 1, gridWidth do
        for y = 1, gridHeight do
            if spellArray[x][y] ~= nil then
                love.graphics.setColor(255,255,255,255)
                spellArray[x][y]:draw()
            end
        end
    end

    -- Draw held square
    if heldSquare then
        love.graphics.setColor(255,255,255,255)
        heldSquare:draw()
    end

    for _, orb in ipairs(orbTable) do
        orb:draw()
    end

    for _, item in ipairs(holdingArray) do
        item:draw()
    end

    -- Draw score
    love.graphics.setColor(0, 0, 0)  -- Black color for text
    local scoreText = "Score: " .. score
    local defaultFont = love.graphics.getFont()  -- Store the default font
    love.graphics.setFont(scoreFont)  -- Set the larger font
    local textWidth = love.graphics.getFont():getWidth(scoreText)
    love.graphics.print(scoreText, (windowWidth - textWidth) / 2, 20)  -- Center horizontally and vertically
    love.graphics.setColor(1, 1, 1)  -- Reset color to white
    love.graphics.setFont(defaultFont)  -- Reset to default font
end

function love.keypressed(key, scancode, isrepeat)
    if key == "x" then
      heldSquare = nil
    elseif key == "r" and heldSquare then
      heldSquare:turn()
   end
end

function love.mousepressed(x, y, button)
    if button == 1 then -- Left mouse button

            -- Check for dragging on grid
            local gridX = math.floor((x - girdXOffset) / gridSize) + 1
            local gridY = math.floor((y - girdYOffset) / gridSize) + 1

            if gridX >= 1 and gridX <= gridWidth and gridY >= 1 and gridY <= gridHeight then
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

    end
end

function love.mousemoved(x, y, dx, dy, istouch)

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
                    spellArray[lastX][lastY] = Line:new((lastX-1) * gridSize + girdXOffset + gridSize/2, 
                                                        (lastY-1) * gridSize + girdYOffset + gridSize/2,
                                                        0, "hLine", hLine)
                    lineCleanUp(lineTable, lastX, lastY)
                    table.insert(lineTable, spellArray[lastX][lastY])
                end

                dragLastGrid = {x = gridX, y = gridY, xDir = gridX-lastX, yDir = gridY-lastY, lastLine = "hLine"}

            -- -- Then vertical
            elseif gridX == lastX and xDir == 0 and lastLine ~= "hLine" then
                if not safeChecker(spellArray, lastX, lastY, Spawner) and not safeChecker(spellArray, lastX, lastY, Cauldron) and not safeChecker(spellArray, lastX, lastY, Combiner) then 
                    spellArray[lastX][lastY] = Line:new((lastX-1) * gridSize + girdXOffset + gridSize/2, 
                                                        (lastY-1) * gridSize + girdYOffset + gridSize/2,
                                                        0, "vLine", vLine)
                    lineCleanUp(lineTable, lastX, lastY)
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
                    lineCleanUp(lineTable, lastX, lastY)
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
