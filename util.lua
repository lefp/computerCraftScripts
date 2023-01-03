require("MvmtRec")

util = {
    FRONT = "FRONT",
    UP    = "UP",
    DOWN  = "DOWN",
}

local FRONT = util.FRONT
local UP    = util.UP
local DOWN  = util.DOWN

-- convenience functions with direction as argument
--
function util.dig(direction)
    direction = direction or FRONT

    if     direction == FRONT then return turtle.dig()
    elseif direction == UP    then return turtle.digUp()
    elseif direction == DOWN  then return turtle.digDown()
    else error("invalid direction")
    end
end
--
function util.detect(direction)
    direction = direction or FRONT

    if     direction == FRONT then return turtle.detect()
    elseif direction == UP    then return turtle.detectUp()
    elseif direction == DOWN  then return turtle.detectDown()
    else error("invalid direction")
    end
end
--
function util.inspect(direction)
    direction = direction or FRONT

    if     direction == FRONT then return turtle.inspect()
    elseif direction == UP    then return turtle.inspectUp()
    elseif direction == DOWN  then return turtle.inspectDown()
    else error("invalid direction")
    end
end
-- @todo this doesn't include "BACK"... maybe should keep it that way to keep compatibility with the other
-- directional functions
function util.move(direction)
    direction = direction or FRONT

    if     direction == FRONT then return turtle.turtle.forward()
    elseif direction == UP    then return turtle.turtle.up()
    elseif direction == DOWN  then return turtle.turtle.down()
    else error("invalid direction")
    end
end
--
function util.place(direction, text)
    direction = direction or FRONT

    if     direction == FRONT then return turtle.place(text)
    elseif direction == UP    then return turtle.placeUp(text)
    elseif direction == DOWN  then return turtle.placeDown(text)
    else error("invalid direction")
    end
end
--
function util.drop(direction, count)
    direction = direction or FRONT

    if     direction == FRONT then return turtle.drop(count)
    elseif direction == UP    then return turtle.dropUp(count)
    elseif direction == DOWN  then return turtle.dropDown(count)
    else error("invalid direction")
    end
end

local dig     = util.dig
local detect  = util.detect
local inspect = util.inspect

-- dig block until it isn't a solid block
-- for handling falling blocks like gravel
-- direction: FRONT/UP/DOWN
function util.digUntilNonSolid(direction)
    direction = direction or FRONT

    while detect(direction) do
        if not dig(direction) then return false end
        sleep(1) -- give falling entity a second to become a block
    end

    return true
end

-- helper for mineOreVein()
-- uses depth-first-search
-- returns true iff no errors encountered (also returns true if no blocks found)
-- args:
--     targetBlockName: e.g. "minecraft:iron_ore"
--     moveRecorder: a MvmtRec object
local function DFS_mine(targetBlockName, moveRecorder)
    -- up
    local upExists, upBlock = inspect(UP)
    if upExists and upBlock.name == targetBlockName then
        if not util.digUntilNonSolid(UP) then return false end
        if not moveRecorder:up() then return false end
        if not DFS_mine(targetBlockName, moveRecorder) then return false end
        if not moveRecorder:undo() then return false end
    end
    -- down
    local downExists, downBlock = inspect(DOWN)
    if downExists and downBlock.name == targetBlockName then
        if not util.digUntilNonSolid(DOWN) then return false end
        if not moveRecorder:down() then return false end
        if not DFS_mine(targetBlockName, moveRecorder) then return false end
        if not moveRecorder:undo() then return false end
    end
    -- left, back, right
    for _ = 1,4 do
        local exists, block = inspect()
        if exists and block.name == targetBlockName then
            if not util.digUntilNonSolid() then return false end
            if not moveRecorder:forward() then return false end
            if not DFS_mine(targetBlockName, moveRecorder) then return false end
            if not moveRecorder:undo() then return false end
        end
        assert(moveRecorder:turnLeft(), "failed to turn")
    end
    -- we just did 4 left turns; the movement recorder doesn't need to backtrack through them
    moveRecorder:forget(4)

    return true
end

-- mines out the vein of `oreName` (e.g. "minecraft:iron_ore") adjacent to the turtle
-- returns without error if there is no such block
-- goes back to exactly the position it was in when the function was called
-- returns (returned, error)
--     returned: true iff returned to starting position
--     error:   true iff an error was encountered while attempting to mine the ore vein
-- if an error is encountered while mining the ore vein, attempts to return to the starting position
function util.mineVein(oreName)
    turtle.select(1) -- select first slot so that mined items stack into first possible slot
    local moveRecorder = MvmtRec.new()

    if not DFS_mine(oreName, moveRecorder) then
        -- error encountered while mining; see if we can still return to starting position
        return moveRecorder:undoAll(), true
    end

    return moveRecorder:empty(), false
end

-- selects the slot containing the item
-- returns false iff that item isn't in the inventory
-- e.g.: selectItem("minecraft:coal")
function util.selectItem(itemName)
    for slot = 1,16 do
        local item = turtle.getItemDetail(slot)
        if item ~= nil and item.name == itemName then
            turtle.select(slot)
            return true
        end
    end

    return false
end

return util