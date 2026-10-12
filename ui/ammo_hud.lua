-- Патроны над иконкой атаки и полоска перезарядки над игроком.

PSE = PSE or {}

local Magazine = PSE.Magazine
local Reload   = PSE.Reload
local Bar      = PSE.Bar

local FA_LEFT, FA_CENTER, FA_TOP, FA_MIDDLE = 0, 1, 0, 1

local COLOR_MISSED = Color.from_rgb(110, 40, 40)

local reload_color = Bar.survivor_color

Callback.add(Callback.ON_PLAYER_HUD_DRAW, function(player, x, y)
    if not Util.bool(player.is_local) then return end

    local data = Magazine.get(player)
    if not data then return end

    local text = data.ammo.."/"..data.entry.tuning.magazine
    local tx, ty = x + 13, y - 7

    gm.draw_set_font(Global.fntSquareSmall)
    gm.draw_set_halign(FA_CENTER)
    gm.draw_set_valign(FA_MIDDLE)

    gm.draw_set_color(Color.BLACK)
    gm.draw_text(tx + 1, ty + 1, text)
    gm.draw_set_color(data.reload and reload_color(player) or Color.WHITE)
    gm.draw_text(tx, ty, text)

    gm.draw_set_halign(FA_LEFT)
    gm.draw_set_valign(FA_TOP)
    gm.draw_set_color(Color.WHITE)
end)

Hook.add_post("gml_Object_oP_Draw_73", function(self, other)
    if not Util.bool(self.is_local) then return end

    local data = Magazine.get(self)
    if not data or not data.reload then return end

    local reload = data.reload
    local from, to
    if reload.window then from, to = Reload.window(Reload.frames(self, data)) end
    Bar.draw(self, reload.progress, from, to,
        reload.missed and COLOR_MISSED or reload_color(self))
end)

PSE.AmmoHud = true
