ObjMan = class(function(o)
        o.objects     = {}
        o.not_objects = {}
        for idx, kind in ipairs(object_kinds) do
            o.objects[kind]     = {}
            o.not_objects[kind] = {}
        end
        o.age = 0
        o.routines = {}
        o:add(Object({x=400, y=300, direction=facing_up, kind="player"}))
    end)

function ObjMan.draw(self)
    for i,kind in ipairs(object_kinds) do
        local objects = self.objects[kind]
        --set_color(unpack(default_colors[kind]))
        for j=1, #objects do
            objects[j]:draw()
        end
    end
end

function ObjMan.run(self)
    local player = self.objects["player"][1]
    if player then
        local pdx=0
        local pdy=0
        if keys["up"]    then pdy = pdy - 1 end
        if keys["down"]  then pdy = pdy + 1 end
        if keys["left"]  then pdx = pdx - 1 end
        if keys["right"] then pdx = pdx + 1 end

        local pspeed, pdirection = get_polar(pdx, pdy)
        pspeed = min(1, pspeed)
        pspeed = pspeed * 7
        if keys["lshift"] then pspeed = pspeed * 0.5 end

        player.speed=pspeed
        if pspeed ~= 0 then player.direction = pdirection end
    end

    -- Move all the objects
    for kind, objects in pairs(self.objects) do
        for j=1, #objects do
            objects[j]:run()
        end
    end

    -- Move the player back onto the screen...
    if player then
        player.x = min(player.x, 800-5)
        player.x = max(player.x, 5)
        player.y = min(player.y, 600-5)
        player.y = max(player.y, 5)
    end

    -- Run all of their scripts
    local routines = self.routines[self.age] or {}
    for i=1, #routines do
        local blob = routines[i]
        local routine, args = blob[1], blob[2]
        local status = nil
        local result = nil
        if args then
            status, result = coroutine.resume(routine, unpack(args))
        else
            status, result = coroutine.resume(routine)
        end
        if not status then
            error(result..'\n'..debug.traceback(routine))
        end
        if result and type(result) == "number" and result > 0 then
            result = result + self.age
            if not self.routines[result] then
                self.routines[result] = {}
            end
            local later_r = self.routines[result]
            later_r[#later_r + 1] = {routine}
        end
    end
    -- don't leave references to dead routines lying around...
    self.routines[self.age] = nil

    -- Make them crash into each other
    self:collision("enemy_bullet", "player")
    -- Get rid of the ones that died
    for kind, objects in pairs(self.objects) do
        local not_objects = {}
        for j=1, #objects do
            local object = objects[j]
            if object.dead then
                if kind=="player" or kind=="enemy_bullet" then
                    object.dead = false
                    local r, theta = v_add_polar({3, facing_right},
                        {object.speed, object.direction})
                    object:fire({speed=r, direction=theta, kind="top_fade"},
                        {later, 10, Object.vanish})
                    r, theta = v_add_polar({3, facing_left},
                        {object.speed, object.direction})
                    object:fire({speed=r, direction=theta, kind="bot_fade"},
                        {later, 10, Object.vanish})
                    object.dead = true
                end
            else
                not_objects[#not_objects + 1] = object
            end
        end
        self.not_objects[kind] = not_objects
    end

    self.objects, self.not_objects = self.not_objects, self.objects
    self.age = self.age + 1
end

function ObjMan.collision(self, kind_a, kind_b)
    local objs_a = self.objects[kind_a]
    local objs_b = self.objects[kind_b]
    for i=1, #objs_a do
        local a = objs_a[i]
        for j=1, #objs_b do
            local b = objs_b[j]
            local dx = abs(a.x - b.x)
            local dy = abs(a.y - b.y)
            -- TODO: lol, square collision detection with hard-coded radius
            if dx < 8 and dy < 8 then
                local damage = max(min(a.health, b.health), 0)
                a.health = a.health - damage
                b.health = b.health - damage
                if a.health <= 0 then a:core_vanish() end
                if b.health <= 0 then b:core_vanish() end
            end
        end
    end
end

function ObjMan.add(self, obj)
    --if not obj then return end
    local objects = self.objects[obj.kind]
    objects[#objects + 1] = obj
end

function ObjMan.register(self, obj, args)
    if not self.routines[self.age+1] then
        self.routines[self.age+1] = {}
    end
    local routines = self.routines[self.age+1]
    if type(args) == "function" then
        args = {args}
    end
    local func = args[1]
    args[1] = obj
    routines[#routines + 1] = {coroutine.create(func), args}
end
