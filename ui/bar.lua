-- Общая полоска над игроком: подложка, окно, маркер. По настройке — кольцо вокруг курсора.

PSE = PSE or {}

local Prefs = PSE.Prefs

local COLOR_PLATE = Color.from_rgb(20, 20, 28)

local B = {}

B.W, B.H = 40, 4

local RING_R, RING_W   = 22, 7
local MARK_OUT, MARK_W = 3, 2
local RING_STEPS       = 64
local PR_TRIANGLESTRIP = 5

function B.survivor_color(player)
    return Survivor.wrap(player.class).primary_color
end

local function ring_angle(share)
    return 90 - 360 * share
end

local function arc(cx, cy, r0, r1, from, to, color, alpha)
    local steps = math.max(1, math.ceil(RING_STEPS * (to - from)))
    gm.draw_primitive_begin(PR_TRIANGLESTRIP)
    for i = 0, steps do
        local a = ring_angle(from + (to - from) * i / steps)
        gm.draw_vertex_color(cx + gm.lengthdir_x(r0, a), cy + gm.lengthdir_y(r0, a), color, alpha)
        gm.draw_vertex_color(cx + gm.lengthdir_x(r1, a), cy + gm.lengthdir_y(r1, a), color, alpha)
    end
    gm.draw_primitive_end()
end

local function ring(cx, cy, progress, from, to, window_color)
    local r0, r1 = RING_R - RING_W, RING_R
    arc(cx, cy, r0 - 1, r1 + 1, 0, 1, COLOR_PLATE, 0.8)
    if from then arc(cx, cy, r0, r1, from, to, window_color, 1) end

    local a = ring_angle(math.min(progress, 1))
    gm.draw_set_alpha(1)
    gm.draw_set_color(Color.WHITE)
    gm.draw_line_width(cx + gm.lengthdir_x(r0 - MARK_OUT, a), cy + gm.lengthdir_y(r0 - MARK_OUT, a),
        cx + gm.lengthdir_x(r1 + MARK_OUT, a), cy + gm.lengthdir_y(r1 + MARK_OUT, a), MARK_W)
end

function B.draw(player, progress, from, to, window_color)
    if Prefs.hud("barAtCursor") and Util.bool(gm.player_util_get_use_mouse_aim(player.value)) then
        ring(math.floor(Global.mouse_x + 0.5), math.floor(Global.mouse_y + 0.5),
            progress, from, to, window_color)
        return
    end

    local cx = math.floor(player.ghost_x + 0.5)
    local x0 = cx - B.W // 2
    local x1 = x0 + B.W
    local y1 = math.floor(player.ghost_y + 0.5) + (player.bbox_top - player.y) - 6
    local y0 = y1 - B.H

    gm.draw_set_alpha(0.8)
    gm.draw_set_color(COLOR_PLATE)
    gm.draw_rectangle(x0 - 1, y0 - 1, x1 + 1, y1 + 1, false)

    gm.draw_set_alpha(1)
    if from then
        gm.draw_set_color(window_color)
        gm.draw_rectangle(x0 + math.floor(from * B.W), y0, x0 + math.floor(to * B.W), y1, false)
    end

    local mx = x0 + math.floor(math.min(progress, 1) * B.W)
    gm.draw_set_color(Color.WHITE)
    gm.draw_rectangle(mx, y0 - 2, mx, y1 + 2, false)
end

PSE.Bar = B
