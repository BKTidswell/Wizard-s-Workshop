
-- orb.lua

Combiner = {}
Combiner.__index = Combiner

baseSpeed = 100

combinerSettings = {{toCheck = {{x=0, y=-1}, {x=0, y=1}}, dx = baseSpeed, dy = 0},
                    {toCheck = {{x=1, y=0}, {x=-1, y=0}}, dx = 0, dy = baseSpeed},
                    {toCheck = {{x=0, y=1}, {x=0, y=-1}}, dx = -1*baseSpeed, dy = 0},
                    {toCheck = {{x=-1, y=0}, {x=1, y=0}}, dx = 0, dy = -1*baseSpeed}}

function Combiner:new(x, y, rads, intakes, output, img)
    local obj = setmetatable({}, self)
    obj.x = x
    obj.y = y
    obj.gridX = math.floor((x - girdXOffset) / gridSize) + 1
    obj.gridY = math.floor((y - girdYOffset) / gridSize) + 1
    obj.intakes = intakes
    obj.output = output
    obj.img = img
    obj.rads = rads

    radInt = math.floor(obj.rads / (math.pi / 2))

    obj.toCheck = combinerSettings[radInt+1].toCheck
    obj.dx = combinerSettings[radInt+1].dx
    obj.dy = combinerSettings[radInt+1].dy

    return obj
end

function Combiner:combine(spellGrid, orbGrid, orbTable)

    orbCheck = {false, false}
    storedOrbs = {0, 0}

    for i, locs in ipairs(self.toCheck) do

        checkX = self.gridX + locs.x
        checkY = self.gridY + locs.y

        -- First deal with orbs and check that there is an orb there
        if checkX >= 0 and checkX <= gridWidth and checkY >= 0 and checkY <= gridHeight and spellGrid[checkX] and spellGrid[checkX][checkY] then

            -- now check if there is the correct orb
            if orbGrid[checkX][checkY] then

                if orbGrid[checkX][checkY].kind == self.intakes[i] then
                    orbCheck[i] = true
                    storedOrbs[i] = orbGrid[checkX][checkY]
                else
                    orbGrid[checkX][checkY].x = -2*gridSize
                    orbGrid[checkX][checkY].y = -2*gridSize
                end
            end
        end
    end

    -- If they are both true, then make a new of the right type
    if orbCheck[1] and orbCheck[2] then

        table.insert(orbTable, Orb:new(self.x - gridSize/2, self.y - gridSize/2,
                                       self.dx, self.dy, "combiner", "yellow", yellowCirc))

        storedOrbs[1].x = -2*gridSize
        storedOrbs[1].y = -2*gridSize

        storedOrbs[2].x = -2*gridSize
        storedOrbs[2].y = -2*gridSize

    end
end

function Combiner:turn()
    self.rads = self.rads + (math.pi / 2)

    radInt = math.floor(self.rads / (math.pi / 2))

    self.toCheck = combinerSettings[radInt%4+1].toCheck
end

-- Methods
function Combiner:move()
    self.x = self.x + self.dx * love.timer.getDelta()
    self.y = self.y + self.dy * love.timer.getDelta()
end

function Combiner:draw()
    love.graphics.draw(self.img, self.x, self.y, self.rads, 1, 1, 32, 32)
end

function Combiner:Iam()
    return "Combiner"
end

function Combiner:is(Type)
    local mt = getmetatable(self)
    if mt == Type then
        return true
    end
    return false  
end