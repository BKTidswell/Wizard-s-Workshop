-- cauldron.lua

Cauldron = {}
Cauldron.__index = Cauldron

function Cauldron:new(x, y, img)
    local obj = setmetatable({}, self)
    obj.x = x
    obj.y = y
    obj.img = img

    obj.valueTbl = {red = 1, green = 2, yellow = 5}

    -- Heat mechanic properties
    obj.heat = 0           -- Current heat (0-100)
    obj.maxHeat = 100      -- Maximum heat before burning
    obj.heatRate = 15      -- Heat increase per second
    obj.clickCooldown = 40 -- Heat reduction per click

    return obj
end

function Cauldron:update(dt)
    -- Increase heat over time
    self.heat = self.heat + self.heatRate * dt

    -- Cap at max heat
    if self.heat > self.maxHeat then
        self.heat = self.maxHeat
    end
end

function Cauldron:isBurning()
    return self.heat >= self.maxHeat
end

function Cauldron:stir()
    -- Reduce heat when clicked
    self.heat = self.heat - self.clickCooldown

    -- Don't go below 0
    if self.heat < 0 then
        self.heat = 0
    end
end

function Cauldron:getHeatColor()
    -- Return color based on heat level (0-1 RGB range)
    local heatPercent = self.heat / self.maxHeat

    if heatPercent < 0.33 then
        -- Green (safe)
        return {0.2, 0.8, 0.2, 1}
    elseif heatPercent < 0.66 then
        -- Yellow (warning)
        return {1, 1, 0, 1}
    else
        -- Red (danger)
        return {1, 0.2, 0.2, 1}
    end
end

function Cauldron:draw()
    -- Draw with heat-based color tint
    local color = self:getHeatColor()
    love.graphics.setColor(color)
    love.graphics.draw(self.img, self.x, self.y)

    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

function Cauldron:drawHeatMeter()
    -- Draw heat meter below the cauldron
    local meterWidth = 60
    local meterHeight = 8
    local meterX = self.x + 2  -- Offset to center under cauldron
    local meterY = self.y + 68 -- Below the 64px cauldron

    -- Background (dark gray)
    love.graphics.setColor(0.2, 0.2, 0.2, 1)
    love.graphics.rectangle("fill", meterX, meterY, meterWidth, meterHeight)

    -- Heat fill (colored based on level)
    local heatPercent = self.heat / self.maxHeat
    local fillWidth = meterWidth * heatPercent
    local fillColor = self:getHeatColor()
    love.graphics.setColor(fillColor)
    love.graphics.rectangle("fill", meterX, meterY, fillWidth, meterHeight)

    -- Border
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle("line", meterX, meterY, meterWidth, meterHeight)

    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

function Cauldron:returnValue(orbType)
    return self.valueTbl[orbType]
end

function Cauldron:Iam()
    return "Cauldron"
end

function Cauldron:is(Type)
    local mt = getmetatable(self)
    if mt == Type then
        return true
    end
    return false
end 