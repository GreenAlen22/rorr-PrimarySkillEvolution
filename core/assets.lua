-- Спрайты и звуки мода. Ванильное имя, которого нет в игре, останавливает загрузку здесь.

PSE = PSE or {}

local C     = PSE.Config
local Prefs = PSE.Prefs

local A = {}

A.failed = {}

local ROOT = _ENV["!plugins_mod_folder_path"]
local SPRITES = ROOT and path.combine(ROOT, "assets/sprites")
if not SPRITES then A.failed[1] = "mod folder unknown, no sprite path" end

local function sprite(identifier, frames)
    if not SPRITES then return nil end
    local ok, res = pcall(function()
        return Sprite.new(identifier, path.combine(SPRITES, identifier..".png"), frames)
    end)
    if not ok or not res then
        A.failed[#A.failed + 1] = identifier..": "..tostring(res)
        return nil
    end
    return res
end

A.meter = {
    frame  = sprite("meleeMeter", 1),
    fill   = sprite("meleeMeterFill", 1),
    emblem = sprite("meleeMeterEmblem", 2),
    flash  = {
        rage    = sprite("rageFlash", 8),
        stamina = sprite("staminaFlash", 8),
    },
}

local rage_icon = sprite("rageIcon", 1)
if rage_icon then rage_icon:set_origin(rage_icon.width // 2, rage_icon.height // 2) end

local frame = A.meter.frame
for _, flash in pairs(A.meter.flash) do
    if frame and flash then
        flash:set_origin((flash.width - frame.width) // 2, (flash.height - frame.height) // 2)
    end
end

A.rage_strike = {}
for hero, mirrors in pairs{
    loader = false, chef = false, mercenary = false, miner = false, acrid = false,
    hand = false, bandit = true, sniper = false, drifter = false,
} do
    local s = sprite("rageStrike"..hero:sub(1, 1):upper()..hero:sub(2), 8)
    if s then
        s:set_origin(s.width // 2, s.height // 2)
        A.rage_strike[hero] = { sprite = s, mirrors = mirrors }
    end
end

if #A.failed > 0 then
    log.warning("PrimarySkillEvolution: sprites FAILED -> "..table.concat(A.failed, "; "))
end

A.reload_icon = { sprite = gm.constants.sSniperSkills, subimage = 1 }

local function buff_icon(name)
    local buff = Buff.find(name, "ror")
    if not buff then error("vanilla buff ror-"..name.." not found") end
    return { sprite = buff.icon_sprite, subimage = buff.icon_subimage }
end

A.buff_icon          = buff_icon("attackSpeed")
A.steady_hand_icon   = buff_icon("burstSpeed")
A.sharp_cleaver_icon = buff_icon("sunder")
A.breathless_icon    = buff_icon("slow")
A.second_wind_icon   = buff_icon("shield")
A.rage_icon          = rage_icon and { sprite = rage_icon, subimage = 0 } or buff_icon("warbanner")

A.sounds = {}

for event, c in pairs(C.sounds) do
    local id = gm.constants[c[1]]
    if not id then error("vanilla sound "..c[1].." not found") end
    A.sounds[event] = { sound = Sound.wrap(id), volume = c[2], pitch = c[3] }
end

function A.play(event, actor)
    local c = A.sounds[event]
    c.sound:play(actor.x, actor.y, c.volume, c.pitch)
end

function A.shake(actor, amount)
    if Prefs.hud("screenFx") then actor:screen_shake(amount) end
end

PSE.Assets = A
