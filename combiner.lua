
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
    storedOrbs = {nil, nil}

    -- First look at orbs on the current square
    for _, currOrb in ipairs(orbGrid[self.gridX][self.gridY]) do

        orbLastGridX = math.floor((currOrb.x - girdXOffset + gridSize/2 - (currOrb.dx * love.timer.getDelta() * 30)) / gridSize) + 1
        orbLastGridY = math.floor((currOrb.y - girdYOffset + gridSize/2 - (currOrb.dy * love.timer.getDelta() * 30)) / gridSize) + 1

        orbNextGridX = math.floor((currOrb.x - girdXOffset + gridSize/2 + (currOrb.dx * love.timer.getDelta() * 1)) / gridSize) + 1
        orbNextGridY = math.floor((currOrb.y - girdYOffset + gridSize/2 + (currOrb.dy * love.timer.getDelta() * 1)) / gridSize) + 1

        -- Okay so if they just came from another grid space then we combine them
        if (orbLastGridX ~= self.gridX or orbLastGridY ~= self.gridY) and currOrb.kind ~= self.output then
        
            legalEntrance = false
            entranceNum = nil

            -- if the square that the grid came from isn't a legal connection then remove the orb
            for i, locs in ipairs(self.toCheck) do

                checkX = self.gridX + locs.x
                checkY = self.gridY + locs.y

                if orbLastGridX == checkX and orbLastGridY == checkY then
                    legalEntrance = true
                    entranceNum = i
                end
            end

            -- remove the orb here
            if (not legalEntrance or currOrb.kind ~= self.intakes[entranceNum]) then
                currOrb.x = -2*gridSize
                currOrb.y = -2*gridSize

                print(currOrb.kind)

            -- otherwise we note that it's the right orb and check the other orb
            else
                orbCheck[entranceNum] = true
                storedOrbs[entranceNum] = currOrb
            end
        -- If they are about to leave we remove them
        -- But not if it's our own color
        elseif (orbNextGridX ~= self.gridX or orbNextGridY ~= self.gridY) and currOrb.kind ~= self.output then
            currOrb.x = -2*gridSize
            currOrb.y = -2*gridSize
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