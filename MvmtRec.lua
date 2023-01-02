require("Stack")
require("math")

-- MvmtRec provides recorded movement and backtracking functionality
MvmtRec = {
    FORWARD    = turtle.forward,
    BACK       = turtle.back,
    UP         = turtle.up,
    DOWN       = turtle.down,
    TURN_LEFT  = turtle.turnLeft,
    TURN_RIGHT = turtle.turnRight,
}

local function inverse(action)
    if     action == MvmtRec.FORWARD    then return MvmtRec.BACK
    elseif action == MvmtRec.BACK       then return MvmtRec.FORWARD
    elseif action == MvmtRec.UP         then return MvmtRec.DOWN
    elseif action == MvmtRec.DOWN       then return MvmtRec.UP
    elseif action == MvmtRec.TURN_LEFT  then return MvmtRec.TURN_RIGHT
    elseif action == MvmtRec.TURN_RIGHT then return MvmtRec.TURN_LEFT
    else error("invalid action")
    end
end

function MvmtRec.new()
    local mvmt = {
        _history = Stack.new(),
    }

    -- performs a move and adds it to history
    function mvmt:_move(action)
        if not action() then return false end
        self._history:push(action)
        return true
    end

    -- convenience functions wrapping _move
    function mvmt:forward()    return self:_move(MvmtRec.FORWARD)    end
    function mvmt:back()       return self:_move(MvmtRec.BACK)       end
    function mvmt:up()         return self:_move(MvmtRec.UP)         end
    function mvmt:down()       return self:_move(MvmtRec.DOWN)       end
    function mvmt:turnLeft()   return self:_move(MvmtRec.TURN_LEFT)  end
    function mvmt:turnRight()  return self:_move(MvmtRec.TURN_RIGHT) end

    -- forget the last n moves (default 1)
    -- if there are fewer than n moves in history, forgets all moves
    function mvmt:forget(n)
        n = n or 1
        n = math.min(n, self._history:size())

        for _ = 1,n do self._history:pop() end
    end

    -- n: number of moves to undo (default 1)
    -- returns (success, n) where
    --   success: true iff n moves were undone
    --   n: number of moves actually undone
    function mvmt:undo(n)
        n = n or 1

        local nMovesUndone = 0
        while nMovesUndone < n and not self._history:empty() do
            if not inverse(self._history:peek())() then return false, nMovesUndone end
            self._history:pop() -- remove from history
            nMovesUndone = nMovesUndone + 1
        end

        return nMovesUndone == n, nMovesUndone
    end
    function mvmt:undoAll() return self:undo(self._history:size()) end

    function mvmt:empty() return self._history:empty() end

    return mvmt
end

return MvmtRec