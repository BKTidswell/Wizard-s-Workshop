-- main.lua
function love.load()
    gridSize = 64
    gridWidth = 10
    gridHeight = 10

    -- Create a grid to hold squares
    grid = {}
    for y = 1, gridHeight do
        grid[y] = {}
        for x = 1, gridWidth do
            grid[y][x] = nil -- no square initially
        end
    end

    -- Create a list of free red squares to place
    squarePool = {
        {x = 100, y = 500}
    }

    heldSquare = nil
end

function love.update(dt)
    if heldSquare then
        -- Follow mouse if holding a square
        heldSquare.x = love.mouse.getX()
        heldSquare.y = love.mouse.getY()
    end
end

function love.draw()
    -- Draw the grid
    love.graphics.setColor(1, 1, 1)
    for y = 0, gridHeight-1 do
        for x = 0, gridWidth-1 do
            love.graphics.rectangle("line", x * gridSize, y * gridSize, gridSize, gridSize)
        end
    end

    -- Draw placed squares
    for y = 1, gridHeight do
        for x = 1, gridWidth do
            if grid[y][x] then
                love.graphics.setColor(1, 0, 0)
                love.graphics.rectangle("fill", (x-1) * gridSize, (y-1) * gridSize, gridSize, gridSize)
            end
        end
    end

    -- Draw free squares
    for _, square in ipairs(squarePool) do
        love.graphics.setColor(1, 0, 0)
        love.graphics.rectangle("fill", square.x - 20, square.y - 20, 100, 100)
    end

    -- Draw held square
    if heldSquare then
        love.graphics.setColor(1, 0, 0)
        love.graphics.rectangle("fill", heldSquare.x - 20, heldSquare.y - 20, gridWidth, gridHeight)
    end
end

function love.mousepressed(x, y, button)
    if button == 1 then -- Left mouse button
        if heldSquare then
            -- Place the held square onto the grid
            local gridX = math.floor(x / gridSize) + 1
            local gridY = math.floor(y / gridSize) + 1

            if gridX >= 1 and gridX <= gridWidth and gridY >= 1 and gridY <= gridHeight then
                if not grid[gridY][gridX] then
                    grid[gridY][gridX] = true
                    heldSquare = nil
                end
            end
        else
            -- Pick up a free square if clicked on one
            for i, square in ipairs(squarePool) do
                if x > square.x - 20 and x < square.x + 20 and y > square.y - 20 and y < square.y + 20 then
                    heldSquare = {x = squarePool[i].x, y = squarePool[i].y}
                    break
                end
            end
        end
    end
end
