Stack = {}

-- we internally use 1-based indexing, so _size is the index of the last entry
function Stack.new()
    local s = {
        _size = 0,
        _entries = {},
    }

    function s:empty()
        return self._size == 0
    end

    function s:push(item)
        self._size = self._size + 1
        self._entries[self._size] = item
    end

    function s:pop()
        assert(not self:empty(), "attempt to pop from empty stack")

        local item = self._entries[self._size]

        self._entries[self._size] = nil
        self._size = self._size - 1

        return item
    end

    function s:peek()
        assert(not self:empty(), "attempt to peek at empty stack")
        return self._entries[self._size]
    end

    function s:size()
        return self._size
    end

    return s
end

return Stack