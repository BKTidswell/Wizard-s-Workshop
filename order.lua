-- order.lua
-- Manages a single order (quest/objective) for the player to complete

Order = {}
Order.__index = Order

function Order:new(requirements, timeLimit, baseReward, description)
    local obj = setmetatable({}, self)

    -- What the player needs to collect
    -- Example: {red = 5, green = 0, yellow = 0}
    obj.requirements = requirements or {red = 5, green = 0, yellow = 0}

    -- Current progress toward requirements
    obj.progress = {red = 0, green = 0, yellow = 0}

    -- Time limit in seconds
    obj.timeLimit = timeLimit or 60
    obj.timeRemaining = timeLimit or 60

    -- Money reward for completing this order
    obj.baseReward = baseReward or 100

    -- Human-readable description
    obj.description = description or "Collect orbs"

    -- Order state: "active", "success", "failed"
    obj.state = "active"

    return obj
end

-- Update timer (call every frame with dt)
function Order:update(dt)
    if self.state == "active" then
        self.timeRemaining = self.timeRemaining - dt

        -- Check for time-out failure
        if self.timeRemaining <= 0 then
            self.timeRemaining = 0
            self.state = "failed"
        end
    end
end

-- Add an orb to progress (called when cauldron collects orb)
function Order:addOrb(orbType)
    if self.state == "active" then
        self.progress[orbType] = self.progress[orbType] + 1
    end
end

-- Check if all requirements are met
function Order:isComplete()
    for orbType, required in pairs(self.requirements) do
        if required > 0 then  -- Only check types that are actually required
            if self.progress[orbType] < required then
                return false
            end
        end
    end
    return true
end

-- Check if order has failed (time ran out)
function Order:hasFailed()
    return self.state == "failed"
end

-- Draw the order UI (top of screen)
function Order:draw()
    -- Position for UI elements
    local uiX = 20
    local uiY = 20
    local lineHeight = 30

    -- Draw order description
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.print("ORDER: " .. self.description, uiX, uiY)

    -- Draw timer (with color change when low)
    uiY = uiY + lineHeight
    if self.timeRemaining < 10 then
        love.graphics.setColor(1, 0, 0, 1)  -- Red when urgent
    else
        love.graphics.setColor(0, 0, 0, 1)  -- Black normally
    end
    love.graphics.print(string.format("TIME: %.1fs", self.timeRemaining), uiX, uiY)

    -- Draw progress for each orb type
    uiY = uiY + lineHeight
    love.graphics.setColor(0, 0, 0, 1)

    for orbType, required in pairs(self.requirements) do
        if required > 0 then  -- Only show types that are required
            local current = self.progress[orbType]
            local progressText = string.format("%s: %d/%d", orbType:upper(), current, required)

            -- Color code the progress
            if current >= required then
                love.graphics.setColor(0, 0.7, 0, 1)  -- Green when complete
            else
                love.graphics.setColor(0, 0, 0, 1)  -- Black when incomplete
            end

            love.graphics.print(progressText, uiX, uiY)
            uiY = uiY + lineHeight
        end
    end

    -- Draw simple progress bar
    local barX = uiX
    local barY = uiY + 10
    local barWidth = 200
    local barHeight = 20

    -- Calculate total progress percentage
    local totalRequired = 0
    local totalCollected = 0
    for orbType, required in pairs(self.requirements) do
        if required > 0 then
            totalRequired = totalRequired + required
            totalCollected = totalCollected + math.min(self.progress[orbType], required)
        end
    end

    local progressPercent = 0
    if totalRequired > 0 then
        progressPercent = totalCollected / totalRequired
    end

    -- Draw bar background
    love.graphics.setColor(0.3, 0.3, 0.3, 1)
    love.graphics.rectangle("fill", barX, barY, barWidth, barHeight)

    -- Draw bar fill
    if progressPercent >= 1 then
        love.graphics.setColor(0, 0.8, 0, 1)  -- Green when complete
    else
        love.graphics.setColor(0, 0.5, 1, 1)  -- Blue when in progress
    end
    love.graphics.rectangle("fill", barX, barY, barWidth * progressPercent, barHeight)

    -- Draw bar outline
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle("line", barX, barY, barWidth, barHeight)

    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

-- Draw success screen
function Order:drawSuccess()
    -- Get screen dimensions
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()

    -- Draw semi-transparent overlay
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)

    -- Draw success message
    love.graphics.setColor(0, 1, 0, 1)  -- Green
    local successText = "ORDER COMPLETE!"
    local font = love.graphics.getFont()
    local textWidth = font:getWidth(successText)
    love.graphics.print(successText, (screenWidth - textWidth) / 2, screenHeight / 2 - 60)

    -- Draw reward
    love.graphics.setColor(1, 1, 0, 1)  -- Yellow
    local rewardText = "+$" .. self.baseReward
    textWidth = font:getWidth(rewardText)
    love.graphics.print(rewardText, (screenWidth - textWidth) / 2, screenHeight / 2 - 20)

    -- Draw instruction
    love.graphics.setColor(1, 1, 1, 1)  -- White
    local instructText = "Press SPACE to continue"
    textWidth = font:getWidth(instructText)
    love.graphics.print(instructText, (screenWidth - textWidth) / 2, screenHeight / 2 + 40)

    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

-- Draw failure screen
function Order:drawFailure()
    -- Get screen dimensions
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()

    -- Draw semi-transparent overlay
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)

    -- Draw failure message
    love.graphics.setColor(1, 0, 0, 1)  -- Red
    local failText = "ORDER FAILED!"
    local font = love.graphics.getFont()
    local textWidth = font:getWidth(failText)
    love.graphics.print(failText, (screenWidth - textWidth) / 2, screenHeight / 2 - 60)

    -- Draw reason (different message based on failure type)
    love.graphics.setColor(1, 1, 1, 1)  -- White
    local reasonText = "Time ran out..."
    if self.state == "burned" then
        reasonText = "The potion burned!"
    end
    textWidth = font:getWidth(reasonText)
    love.graphics.print(reasonText, (screenWidth - textWidth) / 2, screenHeight / 2 - 20)

    -- Draw instruction
    local instructText = "Press SPACE to try again"
    textWidth = font:getWidth(instructText)
    love.graphics.print(instructText, (screenWidth - textWidth) / 2, screenHeight / 2 + 40)

    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

-- Type checking
function Order:is(Type)
    local mt = getmetatable(self)
    return mt == Type
end
