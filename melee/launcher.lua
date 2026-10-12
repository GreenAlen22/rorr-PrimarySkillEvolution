-- Удар с земли: Action на земле подбрасывает и оглушает врагов рядом.

PSE = PSE or {}

local C       = PSE.Config.melee.launcher
local NS      = PSE.Config.namespace
local Strikes = PSE.Strikes
local Stamina = PSE.Stamina
local Lunge   = PSE.Lunge
local Assets  = PSE.Assets

local LA = {}

local function data_of(player)
    local data = Instance.get_data(player, "launcher", NS)
    data.cooldown = data.cooldown or 0
    return data
end

function LA.cooldown_share(player)
    return data_of(player).cooldown / C.cooldown
end

local function fire(player, entry)
    local x, y = player.x, player.y
    local info = Strikes.explode(player, "launcher", x, y, C.damage, entry.sparks, C.width, C.height)
    info.knockup = C.knockup
    info.stun    = C.stun

    GM.SO.sparks_create_networked(player, player, x, y, entry.sparks,
        C.sparks_scale, C.sparks_scale, true, false, 0, true)
    player:screen_shake(3)
    Assets.play("launcher", player)
end

Callback.add(Callback.ON_PLAYER_STEP, function(player)
    if not Util.bool(player.is_local) then return end
    local entry = Strikes.of(player)
    if not entry then return end

    local data = data_of(player)
    if data.cooldown > 0 then data.cooldown = data.cooldown - 1 end

    if Util.bool(player.free) or not Util.bool(player:control(PSE.Options.action.verb, 1)) then return end
    if Stamina.took_action(player) or data.cooldown > 0 or Strikes.busy(player)
        or Lunge.moving(player) then return end

    data.cooldown = C.cooldown
    fire(player, entry)
    Stamina.spend(player)
end)

PSE.Launcher = LA
