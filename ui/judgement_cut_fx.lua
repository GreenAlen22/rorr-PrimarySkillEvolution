-- Картинка добивания Наёмника на экране владельца.

PSE = PSE or {}

local C  = PSE.Config.melee.signatures.mercenary
local JC = PSE.JudgementCut

local PR_TRIANGLELIST = 4
local DARK_ALPHA = 0.55
local SHARDS     = 12
local FLY        = 30
local SHARD_SPEED, SHARD_FALL = 2.5, 0.12

local COLOR_SHARD = Color.from_rgb(30, 30, 40)

local snap, snap_ok, shards = nil, false, nil

local function screen_size()
    local scale = Global.current_hud_scale
    if not scale or scale <= 0 then scale = 1 end
    return gm.display_get_gui_width() / scale, gm.display_get_gui_height() / scale
end

local function take_snapshot()
    local ok, err = pcall(function()
        local src = Global.display_surface
        if not gm.surface_exists(src) then error("display_surface is gone") end
        snap = gm.surface_create(gm.surface_get_width(src), gm.surface_get_height(src))
        gm.surface_copy(snap, 0, 0, src)
    end)
    snap_ok = ok
    if not ok then log.warning("PrimarySkillEvolution: judgement cut snapshot failed -> "..tostring(err)) end
end

local function free_snapshot()
    if snap then
        pcall(function() if gm.surface_exists(snap) then gm.surface_free(snap) end end)
    end
    snap, snap_ok = nil, false
end

local function build_shards(w, h)
    local cx, cy = w * (0.4 + math.random() * 0.2), h * (0.4 + math.random() * 0.2)
    local points = { { 0, 0 }, { w, 0 }, { w, h }, { 0, h } }
    for _ = 1, SHARDS - 4 do
        local r, edge = math.random(), math.random(4)
        if edge == 1 then points[#points + 1] = { r * w, 0 }
        elseif edge == 2 then points[#points + 1] = { w, r * h }
        elseif edge == 3 then points[#points + 1] = { r * w, h }
        else points[#points + 1] = { 0, r * h } end
    end
    for _, p in ipairs(points) do p.angle = gm.point_direction(cx, cy, p[1], p[2]) end
    table.sort(points, function(a, b) return a.angle < b.angle end)

    shards = {}
    for i, a in ipairs(points) do
        local b = points[i % #points + 1]
        local mx, my = (cx + a[1] + b[1]) / 3, (cy + a[2] + b[2]) / 3
        local out = gm.point_direction(cx, cy, mx, my)
        shards[i] = {
            verts = { { cx, cy }, { a[1], a[2] }, { b[1], b[2] } },
            mx = mx, my = my,
            vx = gm.lengthdir_x(SHARD_SPEED, out), vy = gm.lengthdir_y(SHARD_SPEED, out),
            spin = (math.random() - 0.5) * 0.08,
        }
    end
end

Callback.add(Callback.ON_PLAYER_STEP, function(player)
    if not Util.bool(player.is_local) then return end
    local st = JC.state()
    if not st or st.player ~= player.id then
        if shards then shards = nil; free_snapshot() end
        return
    end
    if st.shattered and not shards then
        take_snapshot()
        build_shards(screen_size())
    elseif snap_ok and not gm.surface_exists(snap) then
        snap, snap_ok = nil, false
    end
end)

local function slash_line(s, now, w, h)
    local age = now - s.frame
    local px, py = s.x * w, s.y * h
    local reach = w + h
    local dx, dy = gm.lengthdir_x(reach, s.angle), gm.lengthdir_y(reach, s.angle)
    gm.draw_set_alpha(age < 6 and 1 or 0.85)
    gm.draw_set_color(Color.WHITE)
    gm.draw_line_width(px - dx, py - dy, px + dx, py + dy, math.max(1, 6 - age))
end

local function draw_shards(age, w, h)
    gm.draw_set_alpha(1)
    gm.draw_set_color(Color.BLACK)
    gm.draw_rectangle(0, 0, w, h, false)

    local alpha = math.max(0, 1 - age / FLY)
    local tex = snap_ok and gm.surface_exists(snap) and gm.surface_get_texture(snap) or nil
    for _, s in ipairs(shards) do
        local ox, oy = s.vx * age, s.vy * age + SHARD_FALL * age * age
        local cos, sin = math.cos(s.spin * age), math.sin(s.spin * age)
        local placed = {}
        for i, v in ipairs(s.verts) do
            local rx, ry = v[1] - s.mx, v[2] - s.my
            placed[i] = { s.mx + rx * cos - ry * sin + ox, s.my + rx * sin + ry * cos + oy }
        end

        if tex then
            gm.draw_primitive_begin_texture(PR_TRIANGLELIST, tex)
            for i, v in ipairs(s.verts) do
                gm.draw_vertex_texture_color(placed[i][1], placed[i][2], v[1] / w, v[2] / h, Color.WHITE, alpha)
            end
            gm.draw_primitive_end()
        else
            gm.draw_set_alpha(alpha)
            gm.draw_set_color(COLOR_SHARD)
            gm.draw_triangle(placed[1][1], placed[1][2], placed[2][1], placed[2][2], placed[3][1], placed[3][2], false)
        end

        gm.draw_set_alpha(alpha)
        gm.draw_set_color(Color.WHITE)
        gm.draw_triangle(placed[1][1], placed[1][2], placed[2][1], placed[2][2], placed[3][1], placed[3][2], true)
    end

    if age < 8 then
        gm.draw_set_alpha(1 - age / 8)
        gm.draw_set_color(Color.WHITE)
        gm.draw_rectangle(0, 0, w, h, false)
    end
end

Callback.add(Callback.ON_HUD_DRAW, function()
    local st = JC.state()
    if not st then return end
    local player = Player.get_local()
    if not Instance.exists(player) or player.id ~= st.player then return end

    local now = Global._current_frame
    local t   = now - st.start
    local w, h = screen_size()

    if not st.shattered then
        gm.draw_set_alpha(DARK_ALPHA * math.min(1, t / 8))
        gm.draw_set_color(Color.BLACK)
        gm.draw_rectangle(0, 0, w, h, false)
        for _, s in ipairs(st.slashes) do slash_line(s, now, w, h) end
    elseif shards then
        local age = t - C.shatter
        if age < FLY then
            draw_shards(age, w, h)
        else
            local left = C.length - C.shatter - FLY
            gm.draw_set_alpha(DARK_ALPHA * math.max(0, 1 - (age - FLY) / math.max(left, 1)))
            gm.draw_set_color(Color.BLACK)
            gm.draw_rectangle(0, 0, w, h, false)
        end
    end

    gm.draw_set_alpha(1)
    gm.draw_set_color(Color.WHITE)
end)

PSE.JudgementCutFx = true
