
-- orb.lua

Line = {}
Line.__index = Line

function Line:new(x, y, angle, kind, img)
    local obj = setmetatable({}, self)
    obj.x = x
    obj.y = y
    obj.gridX = math.floor((x - girdXOffset) / gridSize) + 1
    obj.gridY = math.floor((y - girdYOffset) / gridSize) + 1
    obj.kind = kind
    obj.img = img
    obj.rads = angle / 180 * math.pi

    if kind == "hLine" then
        obj.dx = -1*baseSpeed
        obj.dy = 0
        obj.toCheck = {{x=-1, y=0},{x=1, y=0}}
    elseif kind == "vLine" then
        obj.dx = 0
        obj.dy = -1*baseSpeed
        obj.toCheck = {{x=0, y=-1},{x=0, y=1}}
    elseif kind == "cLine" and angle == 0 then
        obj.dx = -1*baseSpeed
        obj.dy = -1*baseSpeed
        obj.toCheck = {{x=0, y=-1},{x=1, y=0}}
    elseif kind == "cLine" and angle == 90 then
        obj.dx = baseSpeed
        obj.dy = -1 * baseSpeed
        obj.toCheck = {{x=0, y=1},{x=1, y=0}}
    elseif kind == "cLine" and angle == 180 then
        obj.dx = baseSpeed
        obj.dy = baseSpeed
        obj.toCheck = {{x=-1, y=0},{x=0, y=1}}
    elseif kind == "cLine" and angle == 270 then
        obj.dx = baseSpeed
        obj.dy = -1 * baseSpeed
        obj.toCheck = {{x=-1, y=0},{x=0, y=-1}}
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
    love.graphics.draw(self.img, self.x, self.y, self.rads, 1, 1, 32, 32)
end

function Line:checkSqrs(spellGrid, orbGrid, orbTable)

    for _, locs in ipairs(self.toCheck) do

        checkX = self.gridX + locs.x
        checkY = self.gridY + locs.y

        -- First deal with orbs and check that there is an orb there
        if checkX >= 0 and checkX <= gridWidth and checkY >= 0 and checkY <= gridHeight and spellGrid[checkX] and spellGrid[checkX][checkY] then

            -- First see if we spawn an orb
            if spellGrid[checkX][checkY]:Iam() == "Spawner" and orbGrid[checkX][checkY] == nil and orbGrid[self.gridX][self.gridY] == nil then

                orbX = (checkX - 1) * gridSize + girdXOffset
                orbY = (checkY - 1) * gridSize + girdYOffset

                orbTable = spellGrid[checkX][checkY]:addOrb(orbX, orbY, self.dx*locs.x + self.dx*(locs.x+1), self.dy*locs.y + self.dy*(locs.y+1), orbTable)
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