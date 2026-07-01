local lib = {}

local LIB_ID = "wave-video-debug"

local VIDEO_EXTS = { ".ogv", ".ogg" }
local IMAGE_EXTS = { ".png", ".jpg", ".jpeg" }
local IMAGE_EXT_LOOKUP = {}

for _, ext in ipairs(IMAGE_EXTS) do
    IMAGE_EXT_LOOKUP[ext] = true
end

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

function lib:getKeyConfig(key, default)
    local value = config(key)
    if type(value) == "string" and value ~= "" then
        return value
    end
    return default
end

function lib:isEnabled()
    if self.runtime_enabled == nil then
        self.runtime_enabled = config("enabled") == true
    end
    return self.runtime_enabled == true
end

function lib:setEnabled(enabled, battle)
    self.runtime_enabled = enabled == true

    battle = battle or (Game and Game.battle)
    if not battle then
        return
    end

    if self.runtime_enabled then
        self:attachToBattle(battle)
    else
        self:clear(battle)
    end
end

function lib:toggleEnabled(battle)
    self:setEnabled(not self:isEnabled(), battle)
    return self.runtime_enabled
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

function lib:getExtension(filename)
    local ext = filename and filename:match("(%.[^%.]+)$")
    return ext and ext:lower() or nil
end

function lib:isImageFile(filename)
    return IMAGE_EXT_LOOKUP[self:getExtension(filename)] == true
end

function lib:getFileInfo(path)
    local ok, info = pcall(function()
        return love.filesystem.getInfo(path)
    end)
    if ok then
        return info
    end
end

function lib:getVideoPath(wave)
    local wave_id = wave and wave.id
    if not wave_id then
        return nil
    end

    local base = self:getDebugBasePath()
    for _, ext in ipairs(VIDEO_EXTS) do
        local path = base .. "/" .. wave_id .. ext
        if self:getFileInfo(path) then
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
        if self:getFileInfo(path) then
            return path
        end
    end
    return nil
end

function lib:getFallbackImages()
    local base = self:getDebugBasePath()
    local ok, items = pcall(function()
        return love.filesystem.getDirectoryItems(base)
    end)
    if not ok or type(items) ~= "table" then
        return {}
    end

    local images = {}
    for _, filename in ipairs(items) do
        if self:isImageFile(filename) then
            local path = base .. "/" .. filename
            local info = self:getFileInfo(path)
            if info and info.type ~= "directory" then
                table.insert(images, {
                    filename = filename,
                    path = path,
                    modtime = tonumber(info.modtime) or 0,
                })
            end
        end
    end

    table.sort(images, function(a, b)
        if a.modtime ~= b.modtime then
            return a.modtime > b.modtime
        end
        return a.filename > b.filename
    end)

    return images
end

function lib:getFallbackImagePath()
    local images = self:getFallbackImages()
    if #images == 0 then
        self.fallback_image_index = nil
        self.fallback_image_path = nil
        return nil
    end

    local index = self.fallback_image_index
    if self.fallback_image_path then
        for i, image in ipairs(images) do
            if image.path == self.fallback_image_path then
                index = i
                break
            end
        end
    end

    if not index or index < 1 or index > #images then
        index = 1
    end

    self.fallback_image_index = index
    self.fallback_image_path = images[index].path
    return self.fallback_image_path
end

function lib:cycleFallbackImage(direction, battle)
    local images = self:getFallbackImages()
    if #images == 0 then
        self.fallback_image_index = nil
        self.fallback_image_path = nil
        return nil
    end

    battle = battle or (Game and Game.battle)
    local overlay = battle and battle.wave_video_debug_overlay
    local showing_fallback = overlay and not overlay.source_wave
    local index = 1
    if showing_fallback and self.fallback_image_path then
        for i, image in ipairs(images) do
            if image.path == self.fallback_image_path then
                index = i
                break
            end
        end
    elseif showing_fallback and self.fallback_image_index and self.fallback_image_index >= 1 and self.fallback_image_index <= #images then
        index = self.fallback_image_index
    end

    if showing_fallback then
        direction = direction or 1
        index = ((index - 1 + direction) % #images) + 1
    end

    self.fallback_image_index = index
    self.fallback_image_path = images[index].path

    if battle and self:isEnabled() then
        self:replaceOverlay(battle, "image", self.fallback_image_path, nil)
    end

    return self.fallback_image_path
end

function lib:getPriority()
    local priority = self.current_priority or config("priority")
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

function lib:getAlternateWaveVisual(wave, current_source_type)
    if not wave then
        return nil
    end

    if current_source_type == "video" then
        local image_path = self:getImagePath(wave)
        if image_path then
            return "image", image_path, wave
        end
    elseif current_source_type == "image" then
        local video_path = self:getVideoPath(wave)
        if video_path then
            return "video", video_path, wave
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

    local fallback_image_path = self:getFallbackImagePath()
    if fallback_image_path then
        return "image", fallback_image_path, nil
    end
end

function lib:clear(battle)
    if battle and battle.wave_video_debug_overlay then
        battle.wave_video_debug_overlay:remove()
        battle.wave_video_debug_overlay = nil
        if battle.updateChildList then
            battle:updateChildList()
            battle.update_child_list = false
        end
    end
end

function lib:replaceOverlay(battle, source_type, asset_path, wave)
    if not battle or not source_type or not asset_path then
        return nil
    end

    self:clear(battle)

    local overlay = WaveVideoDebugOverlay(source_type, asset_path, wave)
    battle.wave_video_debug_overlay = overlay
    battle:addChild(overlay)
    if overlay.play then
        overlay:play()
    end
    return overlay
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

    self:replaceOverlay(battle, source_type, asset_path, wave)
end

function lib:switchWaveMedia(battle)
    battle = battle or (Game and Game.battle)
    if not battle or not self:isEnabled() then
        return nil
    end

    local overlay = battle.wave_video_debug_overlay
    if not overlay or not overlay.source_wave then
        return nil
    end

    local source_type, asset_path, wave = self:getAlternateWaveVisual(overlay.source_wave, overlay.source_type)
    if not source_type then
        return nil
    end

    self.current_priority = source_type
    self:replaceOverlay(battle, source_type, asset_path, wave)

    return source_type, asset_path
end

function lib:handleKeyPressed(key, is_repeat, battle)
    if is_repeat then
        return false
    end

    if key == self:getKeyConfig("toggle_key", "h") then
        self:toggleEnabled(battle)
        return true
    end

    if key == self:getKeyConfig("cycle_image_key", "j") then
        self:cycleFallbackImage(1, battle)
        return true
    end

    if key == self:getKeyConfig("switch_media_key", "k") then
        self:switchWaveMedia(battle)
        return true
    end

    return false
end

function lib:onKeyPressed(key, is_repeat)
    return self:handleKeyPressed(key, is_repeat)
end

return lib
