-- main.lua

require "orb"
require "line"
require "spawner"

function love.load()
    redSqr = love.graphics.newImage("red_sqr.png")
    redCirc = love.graphics.newImage("red_circ.png")
    hLine = love.graphics.newImage("h_line.png")
    vLine = love.graphics.newImage("v_line.png")

    orbTable = {}

    -- newOrb = Orb:new(200, 200, 200, 100, "red", redCirc)

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

    spellArray[3][3] = Spawner:new((3 - 1) * gridSize + girdXOffset, 
                                   (3 - 1) * gridSize + girdYOffset,
                                   "red", redSqr)

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

    for i, orb in ipairs(orbList) do
        local gridX = math.floor((orb.x - girdXOffset + gridSize/2) / gridSize) + 1
        local gridY = math.floor((orb.y - girdYOffset + gridSize/2) / gridSize) + 1

        if gridX > gridWidth or gridX < 0 or gridY > gridHeight or gridY < 0 or spellGrid[gridX] == nil or spellGrid[gridX][gridY] == nil then
            table.remove(orbList, i)
        else 
            orbGrid[gridX][gridY] = "Orb"
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

                        table.insert(orbTable, Orb:new(orbX, orbY, curSqr.dx, curSqr.dy, "red", redCirc))

                    elseif curSqr.kind == "hLine" and spellGrid[x+1] ~= nil and spellGrid[x+1][y] ~= nil and spellGrid[x+1][y]:is(Spawner) and orbGrid[x+1][y] == nil and curOrb == nil  then

                        orbX = (x) * gridSize + girdXOffset
                        orbY = (y - 1) * gridSize + girdYOffset

                        table.insert(orbTable, Orb:new(orbX, orbY, -1*curSqr.dx, curSqr.dy, "red", redCirc))

                    elseif curSqr.kind == "vLine" and spellGrid[x][y-1] ~= nil and spellGrid[x][y-1]:is(Spawner) and orbGrid[x][y-1] == nil and curOrb == nil  then

                        orbX = (x - 1) * gridSize + girdXOffset
                        orbY = (y - 2) * gridSize + girdYOffset

                        table.insert(orbTable, Orb:new(orbX, orbY, curSqr.dx, curSqr.dy, "red", redCirc))

                    elseif curSqr.kind == "vLine" and spellGrid[x][y+1] ~= nil and spellGrid[x][y+1]:is(Spawner) and orbGrid[x][y+1] == nil and curOrb == nil  then

                        orbX = (x - 1) * gridSize + girdXOffset
                        orbY = (y) * gridSize + girdYOffset

                        table.insert(orbTable, Orb:new(orbX, orbY, curSqr.dx, -1*curSqr.dy, "red", redCirc))
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
