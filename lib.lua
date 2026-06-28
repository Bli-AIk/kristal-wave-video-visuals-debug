local lib = {}

local LIB_ID = "wave-video-debug"

Registry.registerGlobal("WaveVideoDebug", lib)

local function trimSlashes(value)
    value = tostring(value or "")
    value = value:gsub("^/+", "")
    value = value:gsub("/+$", "")
    return value
end

local function config(key)
    return Kristal.getLibConfig(LIB_ID, key)
end

function lib:getConfig(key)
    return config(key)
end

function lib:isEnabled()
    return config("enabled") == true
end

function lib:getAlpha()
    local alpha = tonumber(config("alpha"))
    if alpha == nil then
        return 0.3
    end
    return math.max(0, math.min(1, alpha))
end

function lib:getLayer()
    local layer = config("layer")
    if type(layer) == "number" then
        return layer
    end
    if type(layer) == "string" then
        return BATTLE_LAYERS[layer] or tonumber(layer) or BATTLE_LAYERS["top"]
    end
    return BATTLE_LAYERS["top"]
end

function lib:getVideoId(wave)
    local wave_id = wave and wave.id
    if not wave_id then
        return nil
    end

    local dir = trimSlashes(config("video_dir") or "waves")
    if dir == "" then
        return wave_id
    end
    return dir .. "/" .. wave_id
end

function lib:getFirstWaveVideo(waves)
    for _, wave in ipairs(waves or {}) do
        local video_id = self:getVideoId(wave)
        if video_id and Assets.getVideoPath(video_id) then
            return video_id, wave
        end
    end
end

function lib:clear(battle)
    if battle and battle.wave_video_debug_overlay then
        battle.wave_video_debug_overlay:remove()
        battle.wave_video_debug_overlay = nil
    end
end

function lib:attachToBattle(battle)
    self:clear(battle)

    if not self:isEnabled() then
        return
    end

    local video_id, wave = self:getFirstWaveVideo(battle and battle.waves)
    if not video_id then
        return
    end

    local overlay = WaveVideoDebugOverlay(video_id, wave)
    battle.wave_video_debug_overlay = overlay
    battle:addChild(overlay)
    overlay:play()
end

return lib
