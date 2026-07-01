local Battle, super = HookSystem.hookScript(Battle)

function Battle:onDefendingState(...)
    local result = { super.onDefendingState(self, ...) }
    WaveVideoDebug:attachToBattle(self)
    return unpack(result)
end

function Battle:endWaves(...)
    WaveVideoDebug:clear(self)
    return super.endWaves(self, ...)
end

function Battle:onKeyPressed(key)
    if WaveVideoDebug:handleKeyPressed(key, false, self) then
        return
    end
    return super.onKeyPressed(self, key)
end

function Battle:onRemove(...)
    WaveVideoDebug:clear(self)
    return super.onRemove(self, ...)
end

return Battle
