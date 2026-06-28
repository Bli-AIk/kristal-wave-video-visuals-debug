local WaveVideoDebugOverlay, super = Class(Video)

function WaveVideoDebugOverlay:init(video_id, source_wave)
    super.init(self, video_id, WaveVideoDebug:getConfig("audio") == true, 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)

    self.video_id = video_id
    self.source_wave = source_wave
    self.debug_select = false
    self:setParallax(0)
    self:setParallaxOrigin(0, 0)
    self.layer = WaveVideoDebug:getLayer()
    self.alpha = WaveVideoDebug:getAlpha()
    self.fit = WaveVideoDebug:getConfig("fit") or "stretch"
    self:setLooping(WaveVideoDebug:getConfig("loop") == true)
    self:updateFit()
end

function WaveVideoDebugOverlay:updateFit()
    local fit = self.fit
    local target_w, target_h = SCREEN_WIDTH, SCREEN_HEIGHT

    if fit == "contain" or fit == "cover" then
        local scale_x = target_w / self.video_width
        local scale_y = target_h / self.video_height
        local scale = fit == "cover" and math.max(scale_x, scale_y) or math.min(scale_x, scale_y)
        self.width = self.video_width * scale
        self.height = self.video_height * scale
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
    self:updateFit()

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

    super.update(self)
end

return WaveVideoDebugOverlay
