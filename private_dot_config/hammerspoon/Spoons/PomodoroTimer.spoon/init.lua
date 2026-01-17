local obj = {}
obj.__index = obj

-- Metadata
obj.name = "PomodoroTimer"
obj.version = "1.0"
obj.author = "Ein Verne"
obj.homepage = "https://github.com/einverne/dotfiles"
obj.license = "MIT - https://opensource.org/licenses/MIT"

-- Default settings
obj.workDuration = 25 * 60  -- 25 minutes work time
obj.breakDuration = 5 * 60  -- 5 minutes break time
obj.timer = nil
obj.isWorking = true

obj.startSound = hs.sound.getByName("Submarine")  -- Start sound
obj.endSound = hs.sound.getByName("Glass")  -- End sound

function obj:toggle()
    if self.timer == nil then
        self:start()
        log.d("PomodoroTimer started")
    else
        self:stop()
        log.d("PomodoroTimer stopped")
    end
end

function obj:start()
    log.d("PomodoroTimer start")
    hs.alert.show("Pomodoro Timer started", 2)
    self.startSound:play()  -- Play start sound
    self:startTimer()
end

function obj:startTimer()
    local duration = self.isWorking and self.workDuration or self.breakDuration
    self.timer = hs.timer.doAfter(duration, function()
        self.endSound:play()  -- Play end sound
        if self.isWorking then
            hs.alert.show("Work time ended, take a break!", 5)
            hs.notify.new({title="Pomodoro Timer", informativeText="Work time ended, take a break!"}):send()
            self.isWorking = false
        else
            hs.alert.show("Break time ended, back to work!", 5)
            hs.notify.new({title="Pomodoro Timer", informativeText="Break time ended, back to work!"}):send()
            self.isWorking = true
        end
        self:startTimer()  -- Start next timer cycle
    end)
end

function obj:stop()
    if self.timer then
        self.timer:stop()
        self.timer = nil
    end
    self.isWorking = true  -- Reset to work state
    hs.alert.show("Pomodoro Timer stopped", 2)
    self.endSound:play()  -- Play end sound
end

return obj
