require("Stack")

-- Mvmt provides recorded movement and backtracking functionality
Mvmt = {
    FORWARD    = turtle.forward,
    BACK       = turtle.back,
    UP         = turtle.up,
    DOWN       = turtle.down,
    TURN_LEFT  = turtle.turnLeft,
    TURN_RIGHT = turtle.turnRight,

    _history = Stack.new(),
}

function Mvmt.inverse(action)
    if     action == Mvmt.FORWARD    then return Mvmt.BACK
    elseif action == Mvmt.BACK       then return Mvmt.FORWARD
    elseif action == Mvmt.UP         then return Mvmt.DOWN
    elseif action == Mvmt.DOWN       then return Mvmt.UP
    elseif action == Mvmt.TURN_LEFT  then return Mvmt.TURN_RIGHT
    elseif action == Mvmt.TURN_RIGHT then return Mvmt.TURN_LEFT
    else error("invalid action")
    end
end

-- performs a move and adds it to history
function Mvmt:_move(action)
    if not action() then return false end
    self._history:push(action)
    return true
end

-- convenience functions wrapping _move
function Mvmt:forward()    return self:_move(Mvmt.FORWARD)    end
function Mvmt:back()       return self:_move(Mvmt.BACK)       end
function Mvmt:up()         return self:_move(Mvmt.UP)         end
function Mvmt:down()       return self:_move(Mvmt.DOWN)       end
function Mvmt:turnLeft()   return self:_move(Mvmt.TURN_LEFT)  end
function Mvmt:turnRight()  return self:_move(Mvmt.TURN_RIGHT) end

-- n: number of moves to undo (default 1)
-- returns (success, n) where
--   success: true iff n moves were undone
--   n: number of moves actually undone
function Mvmt:undo(n)
    n = n or 1

    local nMovesUndone = 0
    while nMovesUndone < n and not self._history:empty() do
        if not Mvmt.inverse(self._history:peek())() then return false, nMovesUndone end
        self._history:pop() -- remove from history
        nMovesUndone = nMovesUndone + 1
    end

    return nMovesUndone == n, nMovesUndone
end

return Mvmt