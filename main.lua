-- main.lua

require "orb"
require "line"
require "spawner"
require "cauldron"

function love.load()
    resetGame()
end

function resetGame()
    redSqr = love.graphics.newImage("red_sqr.png")
    redCirc = love.graphics.newImage("red_circ.png")
    greenCirc = love.graphics.newImage("green_circ.png")  -- Add green square image
    hLine = love.graphics.newImage("h_line.png")
    vLine = love.graphics.newImage("v_line.png")

    orbTable = {}
    score = 0  -- Initialize score

    -- Create a larger font for the score
    scoreFont = love.graphics.newFont(36)  -- 36 is the font size

    windowWidth = 1000
    windowHeight = 800

    love.window.setMode(1000, 800)
    love.graphics.setBackgroundColor(255,255,255,0)

    gridSize = 64
    gridWidth = 10
    gridHeight = 5

    girdXOffset = (windowWidth - gridSize*gridWidth) / 2
    girdYOffset = (windowHeight - gridSize*gridHeight) / 4

    -- Create a grid to hold squares
    spellArray = {}
    blankOrbArray = {}

    for x = 1, gridWidth do
        spellArray[x] = {}
        blankOrbArray[x] = {}
        for y = 1, gridHeight do
            spellArray[x][y] = nil
            blankOrbArray[x][y] = nil
        end
    end

    -- Add red spawner at position (3,3)
    spellArray[3][3] = Spawner:new((3 - 1) * gridSize + girdXOffset, 
                                   (3 - 1) * gridSize + girdYOffset,
                                   "red", redSqr)
                                   
    -- Add green spawner at position (5,3)
    spellArray[5][3] = Spawner:new((5 - 1) * gridSize + girdXOffset,
                                   (3 - 1) * gridSize + girdYOffset,
                                   "green", greenCirc)

    -- Add cauldron at position (10,3)
    spellArray[10][3] = Cauldron:new((10 - 1) * gridSize + girdXOffset,
                                   (3 - 1) * gridSize + girdYOffset,
                                   nil)

    -- Create a list of free red squares to place
    squarePool = {
        Line:new(100, 425, 100, 0, "hLine", hLine),
        Line:new(100, 500, 0, 100, "vLine", vLine)
    }

    heldSquare = nil
end


function updateGrid(spellGrid, orbList)
    local orbGrid = {}

    for x = 1, gridWidth do
        orbGrid[x] = {}
        for y = 1, gridHeight do
            orbGrid[x][y] = nil
        end
    end

    -- Check for orb collisions with cauldron
    for i = #orbList, 1, -1 do
        local orb = orbList[i]
        local gridX = math.floor((orb.x - girdXOffset + gridSize/2) / gridSize) + 1
        local gridY = math.floor((orb.y - girdYOffset + gridSize/2) / gridSize) + 1

        if gridX > gridWidth or gridX < 0 or gridY > gridHeight or gridY < 0 or spellGrid[gridX] == nil or spellGrid[gridX][gridY] == nil then
            table.remove(orbList, i)
        else 
            -- Check if orb is on a cauldron
            if spellGrid[gridX][gridY]:is(Cauldron) then
                table.remove(orbList, i)
                score = score + 1  -- Increment score when orb is absorbed
            else
                orbGrid[gridX][gridY] = "Orb"
            end
        end
    end

    for x = 1, gridWidth do
        for y = 1, gridHeight do

            curSqr = spellGrid[x][y]
            curOrb = orbGrid[x][y]

            if curSqr ~= nil then
                if curSqr:is(Line) then

                    if curSqr.kind == "hLine" and spellGrid[x-1] ~= nil and spellGrid[x-1][y] ~= nil and spellGrid[x-1][y]:is(Spawner) and orbGrid[x-1][y] == nil and curOrb == nil then

                        orbX = (x - 2) * gridSize + girdXOffset
                        orbY = (y - 1) * gridSize + girdYOffset
                        local spawnerKind = spellGrid[x-1][y].kind
                        local orbImage = spawnerKind == "red" and redCirc or greenCirc

                        table.insert(orbTable, Orb:new(orbX, orbY, curSqr.dx, curSqr.dy, spawnerKind, orbImage))

                    elseif curSqr.kind == "hLine" and spellGrid[x+1] ~= nil and spellGrid[x+1][y] ~= nil and spellGrid[x+1][y]:is(Spawner) and orbGrid[x+1][y] == nil and curOrb == nil  then

                        orbX = (x) * gridSize + girdXOffset
                        orbY = (y - 1) * gridSize + girdYOffset
                        local spawnerKind = spellGrid[x+1][y].kind
                        local orbImage = spawnerKind == "red" and redCirc or greenCirc

                        table.insert(orbTable, Orb:new(orbX, orbY, -1*curSqr.dx, curSqr.dy, spawnerKind, orbImage))

                    elseif curSqr.kind == "vLine" and spellGrid[x][y-1] ~= nil and spellGrid[x][y-1]:is(Spawner) and orbGrid[x][y-1] == nil and curOrb == nil  then

                        orbX = (x - 1) * gridSize + girdXOffset
                        orbY = (y - 2) * gridSize + girdYOffset
                        local spawnerKind = spellGrid[x][y-1].kind
                        local orbImage = spawnerKind == "red" and redCirc or greenCirc

                        table.insert(orbTable, Orb:new(orbX, orbY, curSqr.dx, curSqr.dy, spawnerKind, orbImage))

                    elseif curSqr.kind == "vLine" and spellGrid[x][y+1] ~= nil and spellGrid[x][y+1]:is(Spawner) and orbGrid[x][y+1] == nil and curOrb == nil  then

                        orbX = (x - 1) * gridSize + girdXOffset
                        orbY = (y) * gridSize + girdYOffset
                        local spawnerKind = spellGrid[x][y+1].kind
                        local orbImage = spawnerKind == "red" and redCirc or greenCirc

                        table.insert(orbTable, Orb:new(orbX, orbY, curSqr.dx, -1*curSqr.dy, spawnerKind, orbImage))
                    end
                end
            end
        end
    end

    -- return spellGrid

end

dtotal = 0
function love.update(dt)

    for _, orb in ipairs(orbTable) do
        orb:move()
    end

    if heldSquare then
        -- Follow mouse if holding a square
        heldSquare.x = love.mouse.getX()
        heldSquare.y = love.mouse.getY()
    end

    updateGrid(spellArray, orbTable)

   --  dtotal = dtotal + dt
   --  if dtotal > 1 then
   --    dtotal = dtotal - 1
   --    updateGrid(spellArray, orbTable)
   -- end
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
                -- love.graphics.draw(spellArray[x][y], (x-1) * gridSize + girdXOffset, (y-1) * gridSize + girdYOffset)
            end
        end
    end

    -- Draw free squares
    for _, square in ipairs(squarePool) do
        love.graphics.setColor(255,255,255,255)
        love.graphics.draw(square.img, square.x, square.y)
    end

    -- Draw held square
    if heldSquare then
        love.graphics.setColor(255,255,255,255)
        love.graphics.draw(heldSquare.img, heldSquare.x - 20, heldSquare.y - 20)
    end

    for _, orb in ipairs(orbTable) do
        orb:draw()
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

function love.mousepressed(x, y, button)
    if button == 1 then -- Left mouse button
        if heldSquare then
            -- Place the held square onto the grid

            local gridX = math.floor((x - girdXOffset) / gridSize) + 1
            local gridY = math.floor((y - girdYOffset) / gridSize) + 1

            if gridX >= 1 and gridX <= gridWidth and gridY >= 1 and gridY <= gridHeight then
                if spellArray[gridX][gridY] == nil then
                    spellArray[gridX][gridY] = heldSquare
                    spellArray[gridX][gridY].x = (gridX-1) * gridSize + girdXOffset
                    spellArray[gridX][gridY].y = (gridY-1) * gridSize + girdYOffset

                    heldSquare = nil
                end
            end
        else
            -- Pick up a free square if clicked on one
            for i, square in ipairs(squarePool) do
                if x > square.x - gridSize and x < square.x + gridSize and y > square.y - gridSize and y < square.y + gridSize then
                    heldSquare = {x = squarePool[i].x, y = squarePool[i].y, img = squarePool[i].img}
                    heldSquare = Line:new(squarePool[i].x, squarePool[i].y, 
                                          squarePool[i].dx, squarePool[i].dy,
                                          squarePool[i].kind, squarePool[i].img)
                    break
                end
            end
        end
    end
end

function love.keypressed(key)
    if key == "r" then
        resetGame()
    end
end
