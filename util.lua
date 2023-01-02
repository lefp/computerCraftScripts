require("MvmtRec")

util = {}

local FRONT = "FRONT"
local UP = "UP"
local DOWN = "DOWN"

local inspect     = turtle.inspect
local inspectUp   = turtle.inspectUp
local inspectDown = turtle.inspectDown
local detect      = turtle.detect
local detectUp    = turtle.detectUp
local detectDown  = turtle.detectDown
local dig         = turtle.dig
local digUp       = turtle.digUp
local digDown     = turtle.digDown

-- convenience functions with direction as argument
--
function util.dig(direction)
    direction = direction or FRONT

    if     direction == FRONT then return dig()
    elseif direction == UP    then return digUp()
    elseif direction == DOWN  then return digDown()
    else error("invalid direction")
    end
end
--
function util.detect(direction)
    direction = direction or FRONT

    if     direction == FRONT then return detect()
    elseif direction == UP    then return detectUp()
    elseif direction == DOWN  then return detectDown()
    else error("invalid direction")
    end
end
--
function util.inspect(direction)
    direction = direction or FRONT

    if     direction == FRONT then return inspect()
    elseif direction == UP    then return inspectUp()
    elseif direction == DOWN  then return inspectDown()
    else error("invalid direction")
    end
end
-- @todo this doesn't include "BACK"... maybe should keep it that way to keep compatibility with the other
-- directional functions
function util.move(direction)
    direction = direction or FRONT

    if     direction == FRONT then return turtle.forward()
    elseif direction == UP    then return turtle.up()
    elseif direction == DOWN  then return turtle.down()
    else error("invalid direction")
    end
end

-- dig block until it isn't a solid block
-- for handling falling blocks like gravel
-- direction: FRONT/UP/DOWN
function util.digUntilNonSolid(direction)
    direction = direction or FRONT

    while detect(direction) do
        if not dig(direction) then return false end
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
    local upExists, upBlock = inspectUp()
    if upExists and upBlock.name == targetBlockName then
        if not util.digUntilNonSolid(UP) then return false end
        if not moveRecorder:up() then return false end
        if not DFS_mine(targetBlockName, moveRecorder) then return false end
        if not moveRecorder:undo() then return false end
    end
    -- down
    local downExists, downBlock = inspectDown()
    if downExists and downBlock == targetBlockName then
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
        assert(moveRecorder.turnLeft(), "failed to turn")
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
    local moveRecorder = MvmtRec.new()

    if not DFS_mine(oreName, moveRecorder) then
        -- error encountered while mining; see if we can still return to starting position
        return moveRecorder:undoAll(), true
    end

    return moveRecorder:empty(), true
end

return util