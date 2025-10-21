
-- orb.lua

Spawner = {}
Spawner.__index = Spawner

function Spawner:new(x, y, kind, img)
    local obj = setmetatable({}, self)
    obj.x = x
    obj.y = y
    obj.kind = kind
    obj.img = img

    -- Color switching mechanic
    obj.switchTimer = 0
    obj.switchInterval = 10  -- Switch colors every 10 seconds
    obj.warningTime = 5  -- Start warning 5 seconds before switch

    -- All possible colors this spawner can produce
    obj.possibleColors = {"red", "green", "yellow"}

    return obj
end

function Spawner:addOrb(x, y, dx, dy, oTable)
    if self.kind == "red" then
        table.insert(oTable, Orb:new(x, y, dx, dy, "spawner", "red", redCirc))
        return oTable
    elseif self.kind == "green" then
        table.insert(oTable, Orb:new(x, y, dx, dy, "spawner", "green", greenCirc))
        return oTable
    elseif self.kind == "yellow" then
        table.insert(oTable, Orb:new(x, y, dx, dy, "spawner", "yellow", yellowCirc))
        return oTable
    end
end

-- Update spawner (handles color switching)
function Spawner:update(dt)
    self.switchTimer = self.switchTimer + dt

    -- Time to switch colors!
    if self.switchTimer >= self.switchInterval then
        self:switchColor()
        self.switchTimer = 0
    end
end

-- Switch to a different random color
function Spawner:switchColor()
    -- Choose a new color different from current
    local availableColors = {}
    for _, color in ipairs(self.possibleColors) do
        if color ~= self.kind then
            table.insert(availableColors, color)
        end
    end

    -- Pick random color from available options
    if #availableColors > 0 then
        local newColor = availableColors[math.random(#availableColors)]
        self.kind = newColor

        -- Update image to match new color
        if newColor == "red" then
            self.img = redSqr
        elseif newColor == "green" then
            self.img = greenSqr
        elseif newColor == "yellow" then
            self.img = yellowCirc
        end

        print("Spawner switched to: " .. newColor)
    end
end

function Spawner:draw()
    -- Draw the spawner image first
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(self.img, self.x, self.y)

    -- Calculate warning state (before switch)
    local timeUntilSwitch = self.switchInterval - self.switchTimer
    local isWarning = timeUntilSwitch <= self.warningTime

    if isWarning then
        -- Draw pulsing border that gets thicker as switch approaches
        local warningProgress = 1 - (timeUntilSwitch / self.warningTime)  -- 0 to 1

        -- Pulse effect using sine wave (1-2 Hz for visibility)
        local pulseSpeed = 1.5 + warningProgress * 1.5  -- Speed increases as switch approaches
        local pulseFactor = (math.sin(love.timer.getTime() * pulseSpeed * math.pi * 2) + 1) / 2  -- 0 to 1

        -- Border thickness increases with warning progress and pulse
        local baseThickness = 2 + warningProgress * 6  -- 2px to 8px
        local thickness = baseThickness * (0.7 + pulseFactor * 0.3)  -- Pulse between 70% and 100%

        -- Color shifts from orange to red as switch approaches
        local red = 1
        local green = 0.5 - warningProgress * 0.5  -- Orange (0.5) to red (0)
        local blue = 0
        local alpha = 0.8 + pulseFactor * 0.2  -- Pulse alpha too

        love.graphics.setColor(red, green, blue, alpha)
        love.graphics.setLineWidth(thickness)
        love.graphics.rectangle("line", self.x, self.y, 64, 64)

        -- Reset line width
        love.graphics.setLineWidth(1)
    end

    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

function Spawner:Iam()
    return "Spawner"
end

function Spawner:is(Type)
    local mt = getmetatable(self)
    if mt == Type then
        return true
    end
    return false  
end