local WaveVideoDebugOverlay, super = Class(Object)

function WaveVideoDebugOverlay:init(source_type, asset_id, source_wave)
    super.init(self, 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)

    if source_type == "video" then
        self.video = Assets.newVideo(asset_id, WaveVideoDebug:getConfig("audio") == true)
        self.visual_width = self.video:getWidth()
        self.visual_height = self.video:getHeight()
        self.video_duration = self:getVideoDuration()
    else
        self.texture = Assets.getTexture(asset_id)
        self.visual_width = self.texture:getWidth()
        self.visual_height = self.texture:getHeight()
    end

    self.source_type = source_type
    self.asset_id = asset_id
    self.source_wave = source_wave
    self.debug_select = false
    self.layer = WaveVideoDebug:getLayer()
    self.alpha = WaveVideoDebug:getAlpha()
    self.fit = WaveVideoDebug:getConfig("fit") or "stretch"
    self.looping = WaveVideoDebug:getConfig("loop") == true
    self.sync_timescale = WaveVideoDebug:getConfig("sync_timescale") ~= false
    self.queued_play = false
    self.was_playing = false
    self.video_time = 0
    self:updateFit()
end

function WaveVideoDebugOverlay:getVideoDuration()
    local ok, duration = pcall(function()
        return self.video:getStream():getDuration()
    end)
    if ok and type(duration) == "number" and duration > 0 then
        return duration
    end
end

function WaveVideoDebugOverlay:seekVideo(time)
    self.video_time = time
    pcall(function()
        self.video:seek(self.video_time)
    end)
end

function WaveVideoDebugOverlay:play()
    if self.source_type ~= "video" then
        return
    end

    if self.sync_timescale then
        self.queued_play = false
        self.video:pause()
        self:seekVideo(self.video_time)
        return
    end

    if not self.stage then
        self.queued_play = true
    else
        self.video:play()
        self.was_playing = true
    end
end

function WaveVideoDebugOverlay:onRemoveFromStage(stage)
    super.onRemoveFromStage(self, stage)

    if self.video and self.video:isPlaying() then
        self.video:pause()
    end
end

function WaveVideoDebugOverlay:updateFit()
    local fit = self.fit
    local target_w, target_h = SCREEN_WIDTH, SCREEN_HEIGHT

    if fit == "contain" or fit == "cover" then
        local scale_x = target_w / self.visual_width
        local scale_y = target_h / self.visual_height
        local scale = fit == "cover" and math.max(scale_x, scale_y) or math.min(scale_x, scale_y)
        self.width = self.visual_width * scale
        self.height = self.visual_height * scale
        self.x = (target_w - self.width) / 2
        self.y = (target_h - self.height) / 2
    else
        self.x = 0
        self.y = 0
        self.width = target_w
        self.height = target_h
    end
end

function WaveVideoDebugOverlay:update()
    self.layer = WaveVideoDebug:getLayer()
    self.alpha = WaveVideoDebug:getAlpha()
    self.fit = WaveVideoDebug:getConfig("fit") or "stretch"
    self.sync_timescale = WaveVideoDebug:getConfig("sync_timescale") ~= false
    self:updateFit()

    if self.source_type == "video" then
        if self.sync_timescale then
            if self.video:isPlaying() then
                self.video:pause()
            end

            if DT > 0 then
                local next_time = self.video_time + DT
                if self.video_duration and next_time >= self.video_duration then
                    if self.looping then
                        next_time = next_time % self.video_duration
                    else
                        next_time = self.video_duration
                    end
                end
                self:seekVideo(next_time)
                self.was_playing = true
            end
            super.update(self)
            return
        end

        if self.queued_play then
            self.queued_play = false
            if not self.video:isPlaying() then
                self.video:play()
            end
        end

        local timescale = Game.stage and Game.stage.timescale or 1
        if timescale <= 0.01 then
            self.queued_play = false
            if self.video:isPlaying() then
                self.paused_for_timescale = true
                self.video:pause()
            end
        elseif self.paused_for_timescale and not self.video:isPlaying() then
            self.paused_for_timescale = false
            self.video:play()
            self.was_playing = true
        end

        if self.looping and self.was_playing and not self.video:isPlaying() then
            self.video:rewind()
            self.video:play()
        end
    end

    super.update(self)

    if self.source_type == "video" then
        self.was_playing = self.video:isPlaying()
    end
end

function WaveVideoDebugOverlay:draw()
    if self.source_type == "image" then
        Draw.draw(self.texture, 0, 0, 0, self.width / self.visual_width, self.height / self.visual_height)
    else
        Draw.draw(self.video, 0, 0, 0, self.width / self.visual_width, self.height / self.visual_height)
    end
end

function WaveVideoDebugOverlay:fullDraw()
    if not self.visible then
        return
    end

    local old_r, old_g, old_b, old_a = love.graphics.getColor()
    love.graphics.push()
    love.graphics.origin()
    Draw.setColor(self:getDrawColor())
    self:draw()
    love.graphics.pop()
    Draw.setColor(old_r, old_g, old_b, old_a)
end

return WaveVideoDebugOverlay
