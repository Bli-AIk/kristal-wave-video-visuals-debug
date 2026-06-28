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

function lib:getImageId(wave)
    local wave_id = wave and wave.id
    if not wave_id then
        return nil
    end

    local dir = trimSlashes(config("image_dir") or "waves")
    if dir == "" then
        return wave_id
    end
    return dir .. "/" .. wave_id
end

function lib:getPriority()
    local priority = config("priority")
    if priority == "image" then
        return "image"
    end
    return "video"
end

function lib:getWaveVisual(wave)
    local video_id = self:getVideoId(wave)
    local image_id = self:getImageId(wave)
    local has_video = video_id and Assets.getVideoPath(video_id)
    local has_image = image_id and Assets.getTexture(image_id)

    if self:getPriority() == "image" then
        if has_image then
            return "image", image_id, wave
        end
        if has_video then
            return "video", video_id, wave
        end
    else
        if has_video then
            return "video", video_id, wave
        end
        if has_image then
            return "image", image_id, wave
        end
    end
end

function lib:getFirstWaveVisual(waves)
    for _, wave in ipairs(waves or {}) do
        local source_type, asset_id = self:getWaveVisual(wave)
        if source_type then
            return source_type, asset_id, wave
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

    local source_type, asset_id, wave = self:getFirstWaveVisual(battle and battle.waves)
    if not source_type then
        return
    end

    local overlay = WaveVideoDebugOverlay(source_type, asset_id, wave)
    battle.wave_video_debug_overlay = overlay
    battle:addChild(overlay)
    if overlay.play then
        overlay:play()
    end
end

return lib
