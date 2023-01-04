-- dig out a FRONTxRIGHTxUP space around and including the turtle's starting position
-- use a negative number to indicate left or down. FRONT cannot be negative

require("util")
require("math")

local LEFT  = "LEFT"
local RIGHT = "RIGHT"
local UP   = util.UP
local DOWN = util.DOWN

local function turn(turnDirection)
    if     turnDirection == LEFT  then return turtle.turnLeft() 
    elseif turnDirection == RIGHT then return turtle.turnRight()
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

local widthDirection  = RIGHT
local heightDirection = UP
--
if WIDTH  < 0 then widthDirection  = LEFT end
if HEIGHT < 0 then heightDirection = DOWN end
--
WIDTH  = math.abs(DEPTH)
HEIGHT = math.abs(DEPTH)

local function verticalSection(hDirection)
    for _ = 2,HEIGHT do
        assert(util.digUntilNonSolid(hDirection))
        assert(util.move(hDirection))
    end
    heightDirection = inverse(heightDirection)
end
for _i = 1,WIDTH do
    for _j = 2,DEPTH do
        verticalSection(heightDirection)
        assert(util.digUntilNonSolid())
        assert(turtle.forward())
    end
    verticalSection(heightDirection)
    assert(turn(widthDirection))
    assert(util.digUntilNonSolid())
    assert(turtle.forward())
    assert(turn(widthDirection))
    widthDirection = inverse(widthDirection)
end