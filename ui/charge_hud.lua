-- Окно на полоске заряда.

PSE = PSE or {}

local Charge = PSE.Charge
local Bar    = PSE.Bar

local LOADER_BAR_DX, LOADER_BAR_DY = -30, -60
local LOADER_OFFSET_DY             = 80
local LOADER_BAR_W,  LOADER_BAR_H  = 58, 10
local WINDOW_ALPHA = 0.6

local function round(v)
    return math.floor(v + 0.5)
end

local function huntress(player, attack, charge)
    local from, to
    if Charge.has_window(player) then
        from, to = Charge.window(player, attack)
        from, to = from / Charge.full, to / Charge.full
    end
    Bar.draw(player, charge / Charge.full, from, to, Bar.survivor_color(player))
end

local function loader(player, attack)
    if not Charge.has_window(player) then return end

    local from, to = Charge.window(player, attack)
    local x  = round(player.ghost_x + LOADER_BAR_DX)
    local y0 = round(player.ghost_y + LOADER_BAR_DY) + LOADER_OFFSET_DY
    local y1 = y0 + LOADER_BAR_H

    gm.draw_set_alpha(WINDOW_ALPHA)
    gm.draw_set_color(Bar.survivor_color(player))
    gm.draw_rectangle(x + math.floor(LOADER_BAR_W * from / Charge.full), y0,
        x + math.floor(LOADER_BAR_W * to / Charge.full), y1, false)
    gm.draw_set_alpha(1)
    gm.draw_set_color(Color.WHITE)
end

Hook.add_post("gml_Object_oP_Draw_73", function(self, other)
    if not Util.bool(self.is_local) then return end

    local attack, charge = Charge.drawing(self)
    if not attack or not PSE.Prefs.rule("chargeWindow") then return end

    if attack.name == "huntressZ2" then
        huntress(self, attack, charge)
    elseif attack.name == "loaderZ2" then
        loader(self, attack)
    end
end)

PSE.ChargeHud = true
