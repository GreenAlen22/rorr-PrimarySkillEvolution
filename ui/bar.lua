-- Общая полоска над игроком: подложка, окно, маркер.

PSE = PSE or {}

local COLOR_PLATE = Color.from_rgb(20, 20, 28)

local B = {}

B.W, B.H = 40, 4

function B.survivor_color(player)
    return Survivor.wrap(player.class).primary_color
end

function B.draw(player, progress, from, to, window_color)
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
