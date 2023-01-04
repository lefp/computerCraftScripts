-- dig out a FRONTxRIGHTxUP space around and including the turtle's starting position
-- use a negative number to indicate left or down. FRONT cannot be negative

require("util")
require("math")

local LEFT  = "LEFT"
local RIGHT = "RIGHT"
local UP   = util.UP
local DOWN = util.DOWN

local function turn(turnDirection)
    if     turnDirection == LEFT  then assert(turtle.turnLeft() , "failed to turn")
    elseif turnDirection == RIGHT then assert(turtle.turnRight(), "failed to turn")
    else error("invalid direction")
    end
end
local function inverse(direction)
    if     direction == LEFT  then return RIGHT
    elseif direction == RIGHT then return LEFT
    elseif direction == DOWN  then return UP
    elseif direction == UP    then return DOWN
    else error("invalid direction")
    end
end

local DEPTH  = assert(tonumber(arg[1]), "failed to convert input to number")
local WIDTH  = assert(tonumber(arg[2]), "failed to convert input to number")
local HEIGHT = assert(tonumber(arg[3]), "failed to convert input to number")
--
assert(DEPTH  >  0, "depth must be positive")
assert(WIDTH  ~= 0, "width  can't be 0")
assert(HEIGHT ~= 0, "height can't be 0")

local WIDTH_DIRECTION  = RIGHT
local HEIGHT_DIRECTION = UP
--
if WIDTH  < 0 then DEPTH_DIRECTION  = LEFT end
if HEIGHT < 0 then HEIGHT_DIRECTION = DOWN end
--
WIDTH  = math.abs(DEPTH)
HEIGHT = math.abs(DEPTH)

for _ = 2,WIDTH do
    for _ = 2,DEPTH do
        for _ = 2,HEIGHT do
            assert(util.digUntilNonSolid(HEIGHT_DIRECTION))
            assert(util.move(HEIGHT_DIRECTION))
            HEIGHT_DIRECTION = inverse(HEIGHT_DIRECTION)
        end
        assert(util.digUntilNonSolid())
        assert(turtle.forward())
    end
    assert(turn(WIDTH_DIRECTION))
    assert(util.digUntilNonSolid())
    assert(turtle.forward())
    assert(turn(WIDTH_DIRECTION))
    WIDTH_DIRECTION = inverse(WIDTH_DIRECTION)
end