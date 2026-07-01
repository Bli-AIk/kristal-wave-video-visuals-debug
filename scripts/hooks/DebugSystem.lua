local DebugSystem, super = HookSystem.hookScript(DebugSystem)

function DebugSystem:onKeyPressed(key, is_repeat)
    if WaveVideoDebug:consumeNudgeKeyEvent(key, is_repeat) then
        return
    end

    if WaveVideoDebug:nudgeOverlayForKey(key) then
        return
    end

    return super.onKeyPressed(self, key, is_repeat)
end

return DebugSystem
