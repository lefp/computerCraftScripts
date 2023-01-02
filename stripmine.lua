require("util")

local MIN_FUEL_LEVEL = 200
local FUEL_SOURCE = "minecraft:coal"
local CONTAINER_TO_PLACE = "minecraft:barrel"

local DO_NOT_DESTROY = {
    -- containers
    "minecraft:barrel",
    "minecraft:chest",
    "ironchest:iron_chest",
    "quark:birch_chest",
}
-- stuff to throw away if obtained
local COLLECTION_BLACKLIST = {"minecraft:cobblestone", "quark:cobbled_deepslate"}
-- ore veins to mine
local ORES_OF_INTEREST = {
    "minecraft:coal_ore",
    "minecraft:iron_ore",
    "minecraft:gold_ore",
      "thermal:copper_ore",
      "thermal:tin_ore",
}

-- check whether block is an ore
-- inspectedBlock must be the second return value of a `turtle.inspect` function
local function isOre(inspectedBlock)
    return inspectedBlock.tags ~= nil and inspectedBlock.tags["forge:ores"]
end

-- @todo also use non-coal fuel sources?
local function refuel()
    if not util.selectItem(FUEL_SOURCE) then
        print("ran out of fuel")
        return false
    end
    turtle.refuel()
    return true
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
local function digIfInventorySpace(direction)
    direction = direction or util.FRONT

    if not anyFreeInventorySlots() then return false end
    turtle.select(1)

    return util.dig(direction)
end

local function dropNonEssential(direction)
    direction = direction or util.FRONT

    local fuelFound      = false
    local containerFound = false

    for slot = 1,16 do
        local item = turtle.getItemDetail(slot, false)
        if item ~= nil then
            local drop = false

            if     item.name == FUEL_SOURCE        and not fuelFound      then fuelFound    = true
            elseif item.name == CONTAINER_TO_PLACE and not containerFound then containerFound = true
            else drop = true
            end

            if drop then assert(util.drop(direction), "failed to drop item") end
        end
    end
end

-- dig a straight stripmine of length n
-- mines out exposed ores of interest
-- returns (reason for stopping, distance actually travelled)
local RetReason = {
    SUCCESS = "SUCCESS",
    CANNOT_REFUEL = "CANNOT_REFUEL",
    INVENTORY_FULL = "INVENTORY_FULL",
    CANNOT_MOVE = "CANNOT_MOVE",
}
local function straightStripmine(n)
    local FRONT = util.FRONT
    local UP    = util.UP
    local DOWN  = util.DOWN

    local distanceTravelled = 0
    while distanceTravelled < n do
        discardBlacklistedItems()

        -- store items if inventory "full"
        -- @todo we don't check if it's near lava! But I think e.g. barrels aren't destroyed by fire
        if not anyFreeInventorySlots() then
            print("inventory full; storing items")

            select(1) -- so that the dug block goes into first possible inventory slot
            assert(util.digUntilNonSolid(DOWN), "failed to dig")
            assert(util.selectItem(CONTAINER_TO_PLACE), "no container in inventory")
            assert(util.place(DOWN), "failed to place container")
            assert(dropNonEssential(DOWN), "failed to store items")
        end

        -- mine exposed resources of interest
        for _,direction in ipairs({UP, DOWN}) do
            local exists, block = util.inspect(direction)
            if exists and isOre(block) then
                util.mineVein(block.name)
            end
        end
        -- same for front and sides
        for _ = 1,4 do
            local exists, block = util.inspect()
            if exists and isOre(block) then
                util.mineVein(block.name)
            end
            assert(turtle.turnLeft(), "failed to turn")
        end

        -- mine front and top blocks
        for _,direction in ipairs({FRONT, UP}) do
            local exists, block = util.inspect(direction)
            if exists and not inList(block.name, DO_NOT_DESTROY) then
                turtle.select(1) -- select first slot so that mined item enters an existing stack if there is one
                util.digUntilNonSolid(direction)
            end
        end

        -- refuel if necessary
        if turtle.getFuelLevel() <= MIN_FUEL_LEVEL then
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

local function straightStripmineWithAssert(n)
    local retReason, distanceTravelled = straightStripmine(n)
    assert(retReason == RetReason.SUCCESS, "stripmine failed: " .. retReason)
    return distanceTravelled
end
local STRIPMINE_LEN = 30
while true do
    straightStripmineWithAssert(STRIPMINE_LEN)
    turtle.turnLeft()
    straightStripmineWithAssert(5)
    turtle.turnLeft()
    straightStripmineWithAssert(STRIPMINE_LEN)
    turtle.turnRight()
    straightStripmineWithAssert(5)
    turtle.turnRight()
end