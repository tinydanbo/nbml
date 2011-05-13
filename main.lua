require("class")
require("queue")
require("globals")
require("objman")
require("object")
require("graphics")
require("mainloop")
require("enemies")

local N_FRAMES = 0

function love.run()
    love.load(arg)

    local dt  = 0        -- time for current frame
    local tau = 15       -- initial value for delay between frames

    while true do
        love.timer.step()
        dt = math.min(0.1, love.timer.getDelta() )

        love.graphics.clear()
        love.graphics.setColor(unpack(colors.dgray))
        love.graphics.rectangle("fill",-5,-5,900,900)
        set_color(unpack(colors.white))
        love.update(dt)
        love.draw()
       -- delay: ["..math.floor(tau).."ms] idle:["..math.floor(100 * (tau/1000)/dt).."%]", 10, 10)
        if(N_FRAMES > 100) then
            tau = tau + (love.timer.getFPS()-60)*0.2*dt
        end

        for e,a,b,c in love.event.poll() do
            if e == "q" then
                if love.audio then love.audio.stop() end
                return
            end
            love.handlers[e](a,b,c)
        end

        love.timer.sleep(tau)
        love.graphics.present()

        N_FRAMES = N_FRAMES + 1
    end
end

function love.load()
    math.randomseed(os.time(os.date("*t")))
    graphics_init() -- load images and set up stuff
    --skidfin = love.audio.newSource("skidfin.mp3")
    --skidfin:setLooping(true)
    --skidfin:play()
    mainloop = coroutine.create(fmainloop)
end

function love.update()
    local status, err, ret = coroutine.resume(mainloop)
    if not status then
        error(err..'\n'..debug.traceback(mainloop))
    end
    if ret then error(tostring(ret)) end
    this_frame_keys = {}
end

function love.draw()
    --love.timer.step()
    --print("update: "..tostring(love.timer.getDelta()*1000))
    set_color(unpack(colors.white))
    gprint("FPS: ["..love.timer.getFPS().."]", 10, 10)
    for i=gfx_q.first,gfx_q.last do
        --[[local tab = {}
        tab[love.graphics.print] = "print"
        tab[love.graphics.rectangle] = "rectangle"
        tab[love.graphics.setColor] = "set_color"
        tab[love.graphics.draw] = "draw"
        print(tab[gfx_q[i][1] ], unpack(gfx_q[i][2]))--]]
        gfx_q[i][1](unpack(gfx_q[i][2]))
    end
    gfx_q:clear()
    --love.timer.step()
    --print("draw: "..tostring(love.timer.getDelta()*1000))
end

function love.keypressed(key, unicode)
    keys[key] = true
    this_frame_keys[key] = true
    if key == "m" then
   --     skidfin:setVolume(1-skidfin:getVolume())
    end
end

function love.keyreleased(key, unicode)
    keys[key] = false
end
