local lib = {}

local LIB_ID = "wave-video-debug"

local VIDEO_EXTS = { ".ogv", ".ogg" }
local IMAGE_EXTS = { ".png", ".jpg", ".jpeg" }

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

function lib:getDebugBasePath()
    local dir = trimSlashes(config("debug_dir") or "debug")
    local mod_path = Mod and Mod.info and Mod.info.path
    if mod_path then
        return mod_path .. "/" .. dir
    end
    return dir
end

function lib:getVideoPath(wave)
    local wave_id = wave and wave.id
    if not wave_id then
        return nil
    end

    local base = self:getDebugBasePath()
    for _, ext in ipairs(VIDEO_EXTS) do
        local path = base .. "/" .. wave_id .. ext
        if love.filesystem.getInfo(path) then
            return path
        end
    end
    return nil
end

function lib:getImagePath(wave)
    local wave_id = wave and wave.id
    if not wave_id then
        return nil
    end

    local base = self:getDebugBasePath()
    for _, ext in ipairs(IMAGE_EXTS) do
        local path = base .. "/" .. wave_id .. ext
        if love.filesystem.getInfo(path) then
            return path
        end
    end
    return nil
end

function lib:getPriority()
    local priority = config("priority")
    if priority == "image" then
        return "image"
    end
    return "video"
end

function lib:getWaveVisual(wave)
    local video_path = self:getVideoPath(wave)
    local image_path = self:getImagePath(wave)

    if self:getPriority() == "image" then
        if image_path then
            return "image", image_path, wave
        end
        if video_path then
            return "video", video_path, wave
        end
    else
        if video_path then
            return "video", video_path, wave
        end
        if image_path then
            return "image", image_path, wave
        end
    end
end

function lib:getFirstWaveVisual(waves)
    for _, wave in ipairs(waves or {}) do
        local source_type, asset_path = self:getWaveVisual(wave)
        if source_type then
            return source_type, asset_path, wave
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

    local source_type, asset_path, wave = self:getFirstWaveVisual(battle and battle.waves)
    if not source_type then
        return
    end

    local overlay = WaveVideoDebugOverlay(source_type, asset_path, wave)
    battle.wave_video_debug_overlay = overlay
    battle:addChild(overlay)
    if overlay.play then
        overlay:play()
    end
end

return lib
