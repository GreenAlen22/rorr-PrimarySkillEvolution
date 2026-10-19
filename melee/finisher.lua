-- Добивание: попадания копят шкалу, полная шкала даёт взрыв, эффект героя и ярость.

PSE = PSE or {}

local C          = PSE.Config.melee.finisher
local NS         = PSE.Config.namespace
local Rage       = PSE.Rage
local Strikes    = PSE.Strikes
local Signatures = PSE.Signatures
local Rewards    = PSE.Rewards
local Assets     = PSE.Assets
local Prefs      = PSE.Prefs

local EXPLOSION = PSE.Vanilla.constant("oEfExplosion")

local F = {}

local function data_of(player)
    local data = Instance.get_data(player, "finisher", NS)
    data.charge = data.charge or 0
    return data
end

F.data = data_of

local function rage_left(data)
    if not data.fired or not data.rage_until then return 0 end
    local now = Global._current_frame
    if now < data.fired or now >= data.rage_until then
        data.rage_until = nil
        return 0
    end
    return data.rage_until - now
end

function F.raging(player)
    return rage_left(data_of(player)) > 0
end

function F.threshold(player)
    local entry = Strikes.of(player)
    return entry and entry.finisher or C.strikes
end

function F.share(player)
    local data = data_of(player)
    local left = rage_left(data)
    if left > 0 then return left / data.rage_length end
    return data.charge / F.threshold(player)
end

local function draw_modded(player, look)
    local shade = Instance.create(player.x, player.y, EXPLOSION)
    shade.sprite_index = look.shade.value
    shade.image_blend  = PSE.Bar.survivor_color(player)
    local core = Instance.create(player.x, player.y, EXPLOSION)
    core.sprite_index = look.core.value
end

function F.receive_strike(player)
    if not Instance.exists(player) or Util.bool(player.is_local) then return end
    local look = Assets.rage_strike_modded
    if look then draw_modded(Instance.wrap(player), look) end
end

local function add(player)
    if not Prefs.rule("finisher") then return end
    local data = data_of(player)
    if rage_left(data) > 0 then return end
    data.charge = math.min(F.threshold(player), data.charge + 1)
end

Strikes.on_hits(function(player, hits, kind)
    if hits > 0 and kind == "strike" then add(player) end
end)

local function fire(player, entry)
    local data = data_of(player)
    local now  = Global._current_frame
    data.charge     = 0
    data.fired      = now
    data.rage_length = Rage.duration(player)
    data.rage_until  = now + data.rage_length

    local x, y = player.x, player.y
    local info = Strikes.explode(player, "finisher", x, y, C.damage, entry.sparks, C.width, C.height)
    info.stun    = C.stun
    info.knockup = C.knockup

    local modded = not entry.hero and Assets.rage_strike_modded
    if modded then
        draw_modded(player, modded)
        if Net.online then PSE.Net.rage_strike:send_to_all(player) end
    else
        local look = entry.hero and Assets.rage_strike[entry.hero]
        local xscale = 1
        if look and look.mirrors and player.image_xscale < 0 then xscale = -1 end
        GM.SO.sparks_create_networked(player, player, x, y, look and look.sprite or entry.sparks,
            xscale, 1, true, false, 0, true)
    end
    Assets.shake(player, 4)
    Assets.play("perfect", player)

    Rewards.grant(player, "rage")
    if entry.hero then Signatures.fire(player, entry) end
end

Callback.add(Callback.ON_PLAYER_STEP, function(player)
    if not Util.bool(player.is_local) then return end
    local entry = Strikes.of(player)
    if not entry then return end

    local data = data_of(player)
    if not Prefs.rule("finisher") then
        data.charge = 0
        return
    end
    if data.charge >= F.threshold(player) then fire(player, entry) end
end)

PSE.Finisher = F
