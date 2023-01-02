local MINING_BLACKLIST = {
    "minecraft:stone",
    "minecraft:cobblestone",
    "quark:deepslate",
    "minecraft:water",
    "minecraft:lava",
    "minecraft:diamond_ore",
}
local COLLECTION_BLACKLIST = {"minecraft:cobblestone", "quark:cobbled_deepslate"}

-- @todo also use non-coal fuel sources?
local function refuel()
    for slot = 1,16 do
        local item = turtle.getItemDetail(slot, false)
        if item ~= nil and item.name == "minecraft:coal" then
            turtle.select(slot)
            return turtle.refuel(1)
        end
    end

    print("ran out of fuel")
    return false
end

local function inList(x, list)
    for _,listItem in ipairs(list) do
        if x == listItem then return true end
    end
    return false
end

local function inCollectionBlacklist(slot)
    local item = turtle.getItemDetail(slot, false)
    if item == nil then return false end
    return inList(item.name, COLLECTION_BLACKLIST)
end

local function discardBlacklistedItems()
    for slot = 1,16 do
        if inCollectionBlacklist(slot) then
            turtle.select(slot)
            turtle.drop()
        end
    end
end

local function anyFreeInventorySlots()
    for slot = 1,16 do
        if turtle.getItemCount(slot) == 0 then return true end
    end
    return false
end

-- returns boolean indicating success
local DigDirection = {
    FRONT = 1,
    UP = 2,
    DOWN = 3,
}
local function digIfInventorySpace(digDirection)
    if not anyFreeInventorySlots() then return false end
    turtle.select(1)

    digDirection = digDirection or DigDirection.FRONT -- default

    if     digDirection == DigDirection.FRONT then return turtle.dig()
    elseif digDirection == DigDirection.UP    then return turtle.digUp()
    elseif digDirection == DigDirection.DOWN  then return turtle.digDown()
    else error("invalid dig direction")
    end
end

-- mines blocks next to the turtle
-- @todo error-checking? (e.g. return INVENTORY_FULL if out of space)
local function mineAdjacentResources()
    local upExists,   upBlock = turtle.inspectUp()
    local downExists, downBlock = turtle.inspectDown()
    if upExists   and not inList(upBlock.name  , MINING_BLACKLIST) then digIfInventorySpace(DigDirection.UP)   end
    if downExists and not inList(downBlock.name, MINING_BLACKLIST) then digIfInventorySpace(DigDirection.DOWN) end

    for _ = 1,4 do
        assert(turtle.turnLeft(), "failed to turn")
        local exists, block = turtle.inspect()
        if exists and not inList(block.name, MINING_BLACKLIST) then digIfInventorySpace() end
    end
end

-- dig a straight stripmine of length n
-- returns (reason for stopping, distance actually travelled)
local RetReason = {
    SUCCESS = 1,
    CANNOT_REFUEL = 2,
    INVENTORY_FULL = 3,
    CANNOT_MOVE = 4,
}
local function straightStripmine(n)
    local distanceTravelled = 0
    while distanceTravelled < n do
        local blockExists   = turtle.detect()
        local upBlockExists = turtle.detectUp()

        -- dig block if there is one
        discardBlacklistedItems()
        if not anyFreeInventorySlots() then return RetReason.INVENTORY_FULL, distanceTravelled end
        turtle.select(1) -- select first slot so that mined item enters an existing stack if there is one
        -- loop to handle falling blocks like gravel
        while blockExists do
            turtle.dig()
            blockExists = turtle.detect()
        end
        --
        -- same for block above
        discardBlacklistedItems()
        if not anyFreeInventorySlots() then return RetReason.INVENTORY_FULL, distanceTravelled end
        turtle.select(1)
        while upBlockExists do
            turtle.digUp()
            upBlockExists = turtle.detectUp()
        end

        -- mine exposed resources
        mineAdjacentResources()

        -- refuel if necessary
        if turtle.getFuelLevel() == 0 then
            if not refuel() then return RetReason.CANNOT_REFUEL, distanceTravelled end
        end

        -- move forward
        if not turtle.forward() then return RetReason.CANNOT_MOVE, distanceTravelled end
        distanceTravelled = distanceTravelled + 1
    end
    return RetReason.SUCCESS, distanceTravelled
end


-- MAIN
-- @todo a way to clean up lava and water for the player would be good
-- @todo add to existing stacks in inventory if possible even if there aren't any empty slots
-- @todo handle gravel falling in front of turtle after digging, which prevents forward movement

local function straightStripmineWithAssert(n)
    local retReason, distanceTravelled = straightStripmine(n)
    assert(retReason == RetReason.SUCCESS, "stripmine failed: " .. retReason)
    return distanceTravelled
end
local STRIPMINE_LEN = 30
while true do
    straightStripmineWithAssert(STRIPMINE_LEN)
    turtle.turnLeft()
    straightStripmineWithAssert(4)
    turtle.turnLeft()
    straightStripmineWithAssert(STRIPMINE_LEN)
    turtle.turnRight()
    straightStripmineWithAssert(4)
    turtle.turnRight()
end