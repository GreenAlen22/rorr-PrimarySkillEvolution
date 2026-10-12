-- Кольцо вокруг CHEF, пока тесак в окне ловли.

PSE = PSE or {}

local Chef = PSE.Chef
local Bar  = PSE.Bar

local RADIUS = 24

Hook.add_post("gml_Object_oP_Draw_73", function(self, other)
    if not Util.bool(self.is_local) or not Chef.is_dice(self) then return end

    local normal, mince = Chef.in_window(self)
    if not mince and not normal then return end

    local x = math.floor(self.ghost_x + 0.5)
    local y = math.floor(self.ghost_y + 0.5) + (self.bbox_top + self.bbox_bottom) / 2 - self.y

    gm.draw_set_color(Bar.survivor_color(self))
    gm.draw_circle(x, y, RADIUS, true)
    gm.draw_circle(x, y, RADIUS + 1, true)
    gm.draw_set_color(Color.WHITE)
end)

PSE.CatchHud = true
