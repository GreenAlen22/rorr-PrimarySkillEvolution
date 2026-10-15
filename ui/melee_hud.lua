-- Интерфейс ближнего боя: шкалы там, где их поставил игрок, окно, откаты, буква серии.

PSE = PSE or {}

local Strikes  = PSE.Strikes
local Stamina  = PSE.Stamina
local Finisher = PSE.Finisher
local Series   = PSE.Series
local Lunge    = PSE.Lunge
local Launcher = PSE.Launcher
local Bar      = PSE.Bar
local Meter    = PSE.Assets.meter
local Prefs    = PSE.Prefs
local PRESETS  = PSE.Config.options.presets

local FA_LEFT, FA_RIGHT, FA_TOP = 0, 2, 0
local BM_NORMAL, BM_ADD = 0, 1

local COLOR_EMPTY    = Color.from_rgb(20, 20, 28)
local COLOR_STAMINA  = Color.from_rgb(120, 220, 120)
local COLOR_OVERFLOW = Color.from_rgb(255, 215, 90)
local COLOR_LOW      = Color.from_rgb(200, 70, 60)
local COLOR_FINISHER = Color.from_rgb(240, 140, 40)

local function screen_size()
    local scale = Global.current_hud_scale
    if not scale or scale <= 0 then scale = 1 end
    return gm.display_get_gui_width() / scale, gm.display_get_gui_height() / scale
end

local METER_GAP = 4

local TROUGH_Y = 11
local EMBLEM_RAGE, EMBLEM_STAMINA = 0, 1

local FLASH_STEP = 4

local function flash_frame(flash, started)
    if not flash or not started then return nil end
    local age = Global._current_frame - started
    if age < 0 then return nil end
    local i = age // FLASH_STEP
    return i < flash.subimages and i or nil
end

local function fill(x, y, share, color)
    local w = math.floor(math.min(share, 1) * Meter.fill.width)
    if w <= 0 then return end
    local fx = x + (Meter.frame.width - Meter.fill.width) // 2
    gm.draw_sprite_part_ext(Meter.fill.value, 0, 0, 0, w, Meter.fill.height,
        fx, y + TROUGH_Y, 1, 1, color, 1)
end

local function meter(x, y, share, color, emblem, flash, flash_i, overflow)
    gm.draw_sprite(Meter.frame.value, 0, x, y)
    fill(x, y, share, color)
    if overflow > 0 then fill(x, y, overflow, COLOR_OVERFLOW) end

    local ex = x + (Meter.frame.width - Meter.emblem.width) // 2
    gm.draw_sprite_ext(Meter.emblem.value, emblem, ex, y, 1, 1, 0, color, 1)

    if flash_i then
        gm.gpu_set_blendmode(BM_ADD)
        gm.draw_sprite_ext(flash.value, flash_i, x, y, 1, 1, 0,
            gm.merge_colour(color, Color.WHITE, 0.5), 1)
        gm.gpu_set_blendmode(BM_NORMAL)
    end
end

local meters_ready = Meter.frame and Meter.fill and Meter.emblem

local function meters_origin(w, h, width, height)
    local preset = Prefs.hud("preset")
    if preset == "custom" then
        local x = math.max(0, math.min(w - width, Prefs.hud("x") * w))
        local y = math.max(0, math.min(h - height, Prefs.hud("y") * h))
        return math.floor(x), math.floor(y)
    end
    local p = PRESETS[preset]
    local x = p.left or (w - p.right - width)
    local y = p.top or (h - p.bottom - height)
    return math.floor(x), math.floor(y)
end

Callback.add(Callback.ON_HUD_DRAW, function()
    if not meters_ready then return end
    local player = Player.get_local()
    if not Instance.exists(player) or player.object_index ~= gm.constants.oP then return end
    if not Strikes.of(player) then return end

    local stamina = Prefs.rule("stamina")
    local rage    = Prefs.rule("finisher")
    local count   = (stamina and 1 or 0) + (rage and 1 or 0)
    if count == 0 then return end

    local fw = Meter.frame.width
    local w, h = screen_size()
    local x, y = meters_origin(w, h, count * fw + (count - 1) * METER_GAP, Meter.frame.height)

    if stamina then
        local share = Stamina.share(player)
        local color = share < PSE.Config.melee.low and COLOR_LOW or COLOR_STAMINA
        local flash = Meter.flash.stamina
        meter(x, y, share, color, EMBLEM_STAMINA, flash,
            flash_frame(flash, Stamina.data(player).caught), math.max(0, share - 1))
        x = x + fw + METER_GAP
    end

    if rage then
        local flash = Meter.flash.rage
        meter(x, y, Finisher.share(player), Bar.survivor_color(player), EMBLEM_RAGE,
            flash, flash_frame(flash, Finisher.data(player).fired), 0)
    end

    gm.draw_set_color(Color.WHITE)
end)

local FEET_W, FEET_GAP, FEET_STEP = 16, 3, 3

local function cooldown_mark(player, row, share, color)
    if share <= 0 then return end

    local x0 = math.floor(player.ghost_x + 0.5) - FEET_W // 2
    local y  = math.floor(player.ghost_y + 0.5) + (player.bbox_bottom - player.y) + FEET_GAP + row * FEET_STEP
    gm.draw_set_color(COLOR_EMPTY)
    gm.draw_rectangle(x0 - 1, y - 1, x0 + FEET_W, y + 1, false)
    local w = math.floor((1 - share) * FEET_W)
    if w > 0 then
        gm.draw_set_color(color)
        gm.draw_rectangle(x0, y, x0 + w - 1, y, false)
    end
    gm.draw_set_color(Color.WHITE)
end

Hook.add_post("gml_Object_oP_Draw_73", function(self, other)
    if not Util.bool(self.is_local) or not Strikes.of(self) then return end

    cooldown_mark(self, 0, Lunge.cooldown_share(self), Bar.survivor_color(self))
    cooldown_mark(self, 1, Launcher.cooldown_share(self), COLOR_FINISHER)

    local progress, from, to = Stamina.window_bar(self)
    if progress then Bar.draw(self, progress, from, to, Bar.survivor_color(self)) end
end)

local MARGIN = 12

local FONT_LETTER = gm.constants.fntHugeSquare
local FONT_WORD   = gm.constants.fntNormal

local function shadowed(x, y, text)
    gm.draw_set_color(Color.BLACK)
    gm.draw_text_w(x + 1, y + 1, text)
    gm.draw_set_color(Color.WHITE)
    gm.draw_text_w(x, y, text)
end

Callback.add(Callback.ON_HUD_DRAW, function()
    local player = Player.get_local()
    if not Instance.exists(player) or player.object_index ~= gm.constants.oP then return end
    if not Strikes.of(player) then return end

    if not Prefs.hud("series") then return end
    local rank = Series.rank(player)
    if rank <= 0 then return end

    local w, h = screen_size()
    local x = math.floor(w - MARGIN)
    local y = math.floor(h / 3)
    local letter = Series.LETTERS[rank]

    gm.draw_set_halign(FA_RIGHT)
    gm.draw_set_valign(FA_TOP)
    gm.draw_set_font_w(FONT_LETTER)
    shadowed(x, y, letter)
    local below = y + gm.string_height_w(letter)
    gm.draw_set_font_w(FONT_WORD)
    shadowed(x, below, gm.translate("PrimarySkillEvolution.series.rank"..rank))

    gm.draw_set_halign(FA_LEFT)
    gm.draw_set_color(Color.WHITE)
end)

PSE.MeleeHud = true
