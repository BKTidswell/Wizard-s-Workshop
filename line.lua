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
    obj.sinceSpawn = 999

    if kind == "hLine" then
        obj.dx = baseSpeed
        obj.dy = 0
        obj.toCheck = {{x=-1, y=0},{x=1, y=0}}
        obj.legalConnects = {{"hLine0", "cLine0","cLine90"},{"hLine0", "cLine180","cLine270"}}
        obj.fullKind = "hLine0"
    elseif kind == "vLine" then
        obj.dx = 0
        obj.dy = baseSpeed
        obj.toCheck = {{x=0, y=-1},{x=0, y=1}}
        obj.legalConnects = {{"vLine0", "cLine90","cLine180"},{"vLine0", "cLine0","cLine270"}}
        obj.fullKind = "vLine0"
    elseif kind == "cLine" and angle == 0 then
        obj.dx = baseSpeed
        obj.dy = baseSpeed
        obj.toCheck = {{x=0, y=-1},{x=1, y=0}}
        obj.legalConnects = {{"vLine0", "cLine90","cLine180"},{"hLine0", "cLine180","cLine270"}}
        obj.fullKind = "cLine0"
    elseif kind == "cLine" and angle == 90 then
        obj.dx = baseSpeed
        obj.dy = -1*baseSpeed
        obj.toCheck = {{x=0, y=1},{x=1, y=0}}
        obj.legalConnects = {{"vLine0", "cLine0","cLine270"},{"hLine0", "cLine180","cLine270"}}
        obj.fullKind = "cLine90"
    elseif kind == "cLine" and angle == 180 then
        obj.dx = baseSpeed
        obj.dy = baseSpeed
        obj.toCheck = {{x=-1, y=0},{x=0, y=1}}
        obj.legalConnects = {{"hLine0", "cLine0","cLine90"},{"vLine0", "cLine0","cLine270"}}
        obj.fullKind = "cLine180"
    elseif kind == "cLine" and angle == 270 then
        obj.dx = baseSpeed
        obj.dy = -1*baseSpeed
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
    love.graphics.draw(self.img, self.x, self.y, self.rads, 1, 1, 32, 32)
end

function Line:spawnOrbs(spellGrid, orbGrid, orbTable)

    for i, locs in ipairs(self.toCheck) do

        checkX = self.gridX + locs.x
        checkY = self.gridY + locs.y

        -- First deal with orbs and check that there is an orb there
        if checkX >= 0 and checkX <= gridWidth and checkY >= 0 and checkY <= gridHeight and spellGrid[checkX] and spellGrid[checkX][checkY] then

            -- First see if we spawn an orb
            if spellGrid[checkX][checkY]:Iam() == "Spawner" and orbGrid[checkX][checkY][1] == nil then

                -- Make sure nothing has been spawned too soon
                if self.sinceSpawn >= minSpawnTime then
                    orbX = (checkX - 1) * gridSize + girdXOffset + -1*locs.x*gridSize*0.5
                    orbY = (checkY - 1) * gridSize + girdYOffset + -1*locs.y*gridSize*0.5

                    if i == 1 then
                        xSpeed = self.dx
                        ySpeed = self.dy
                    elseif i == 2 then
                        xSpeed = -1*self.dx
                        ySpeed = -1*self.dy
                    else
                        print("Help something is wrong")
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
end


function Line:adjustOrbSpeed(spellGrid, orbGrid, orbTable)
    -- holding off on all that, since we want to check what the orbs are doing no matter where they are coming from

    -- So first check if there is an orb on our square
    for _, currOrb in ipairs(orbGrid[self.gridX][self.gridY]) do

        orbNowGridX = math.floor((currOrb.x - girdXOffset + gridSize/2) / gridSize) + 1
        orbNowGridY = math.floor((currOrb.y - girdYOffset + gridSize/2) / gridSize) + 1

        orbLastGridX = math.floor((currOrb.x - girdXOffset + gridSize/2 - (currOrb.dx * love.timer.getDelta())) / gridSize) + 1
        orbLastGridY = math.floor((currOrb.y - girdYOffset + gridSize/2 - (currOrb.dy * love.timer.getDelta())) / gridSize) + 1

        -- Okay so if they just came from another grid space then we adjust them
        if orbLastGridX ~= self.gridX or orbLastGridY ~= self.gridY then
        
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
            if not legalEntrance then
                currOrb.x = -2*gridSize
                currOrb.y = -2*gridSize

            -- otherwise we change the orb's speed
            else
                -- pieces are made with the default speed designed for the first location
                if entranceNum == 1 then
                    currOrb.dx = self.dx
                    currOrb.dy = self.dy
                elseif entranceNum == 2 then
                    currOrb.dx = -1*self.dx
                    currOrb.dy = -1*self.dy
                else
                    print("Something is wrong")
                end
                
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