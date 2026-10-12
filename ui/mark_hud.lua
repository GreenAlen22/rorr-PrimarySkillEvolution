-- Метки Охотницы и Снайпера на экране владельца.

PSE = PSE or {}

local Huntress = PSE.Huntress

local MARGIN, LEG = 3, 4
local TRACE_FRAMES = 10

local function brackets(target, color)
    local x0 = math.floor(target.bbox_left) - MARGIN
    local y0 = math.floor(target.bbox_top) - MARGIN
    local x1 = math.floor(target.bbox_right) + MARGIN
    local y1 = math.floor(target.bbox_bottom) + MARGIN

    gm.draw_set_color(color)
    for _, corner in ipairs({ { x0, y0, 1, 1 }, { x1, y0, -1, 1 }, { x0, y1, 1, -1 }, { x1, y1, -1, -1 } }) do
        local x, y, sx, sy = corner[1], corner[2], corner[3], corner[4]
        gm.draw_rectangle(x, y, x + LEG * sx, y, false)
        gm.draw_rectangle(x, y, x, y + LEG * sy, false)
    end
end

Hook.add_post("gml_Object_oP_Draw_73", function(self, other)
    if not Util.bool(self.is_local) or not Huntress.is_strafe(self) then return end

    local color  = gm.player_index_get_color(self.player_p_number, true)
    local target = Huntress.mark_of(self)
    if target then brackets(target, color) end

    local now    = Global._current_frame
    local traces = Huntress.traces
    for i = #traces, 1, -1 do
        local t   = traces[i]
        local age = now - t[5]
        if age < 0 or age >= TRACE_FRAMES then
            table.remove(traces, i)
        else
            gm.draw_set_alpha(1 - age / TRACE_FRAMES)
            gm.draw_set_color(color)
            gm.draw_line(t[1], t[2], t[3], t[4])
        end
    end

    gm.draw_set_alpha(1)
    gm.draw_set_color(Color.WHITE)
end)

Hook.add_post("gml_Object_oP_Draw_73", function(self, other)
    if not Util.bool(self.is_local) then return end
    local targets = PSE.Signatures.sniper_marks(self)
    if #targets == 0 then return end

    local color = gm.player_index_get_color(self.player_p_number, true)
    for _, target in ipairs(targets) do brackets(target, color) end
    gm.draw_set_color(Color.WHITE)
end)

PSE.MarkHud = true
