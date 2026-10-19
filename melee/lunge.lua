-- Выпад: Action в воздухе — рывок к курсору с ударом по пути.

PSE = PSE or {}

local C        = PSE.Config.melee.lunge
local NS       = PSE.Config.namespace
local V        = PSE.Vanilla
local Strikes  = PSE.Strikes
local Stamina  = PSE.Stamina
local Cursor   = PSE.Cursor
local Assets   = PSE.Assets
local Prefs    = PSE.Prefs

local BLOCK = V.constant("pBlock")

local MARGIN = 24

local L = {}

local function data_of(player)
    local data = Instance.get_data(player, "lunge", NS)
    data.cooldown = data.cooldown or 0
    return data
end

function L.cooldown_share(player)
    return data_of(player).cooldown / C.cooldown
end

function L.moving(player)
    return data_of(player).moving ~= nil
end

local function start(player, data, angle)
    player.invincible = math.max(tonumber(player.invincible) or 0, C.guard)
    data.moving = {
        frame = 0,
        x0 = player.x, y0 = player.y,
        dx = gm.lengthdir_x(C.distance, angle) / C.frames,
        dy = gm.lengthdir_y(C.distance, angle) / C.frames,
    }
end

local function step(player, data)
    local m = data.moving
    local steps = math.max(1, math.ceil(math.max(math.abs(m.dx), math.abs(m.dy))))
    local sx, sy = m.dx / steps, m.dy / steps
    local x, y = player.x, player.y
    local blocked = false
    for _ = 1, steps do
        if player:is_colliding(BLOCK, x + sx, y + sy) then
            blocked = true
            break
        end
        x, y = x + sx, y + sy
    end
    player.x, player.y = x, y
    player.pHspeed, player.pVspeed = 0, 0

    m.frame = m.frame + 1
    return blocked or m.frame >= C.frames
end

local function strike(player, entry, m)
    local x, y = player.x, player.y
    local damage = C.damage_of[entry.name] or entry.skill.damage
    Strikes.explode(player, "lunge", (x + m.x0) / 2, (y + m.y0) / 2, damage, entry.sparks,
        math.abs(x - m.x0) + MARGIN, math.abs(y - m.y0) + MARGIN)
end

function L.receive(player, angle)
    if not Instance.exists(player) or Util.bool(player.is_local) then return end
    start(player, data_of(player), angle)
end

Callback.add(Callback.ON_PLAYER_STEP, function(player)
    local entry = Strikes.of(player)
    if not entry then return end
    local data = data_of(player)
    local mine = Util.bool(player.is_local)

    if data.moving then
        if step(player, data) then
            if mine then strike(player, entry, data.moving) end
            data.moving = nil
        end
        return
    end
    if not mine then return end

    if data.cooldown > 0 then data.cooldown = data.cooldown - 1 end
    local airborne = Util.bool(player.free)
    if not airborne then data.air_used = false end

    if not airborne or not Prefs.rule("lungeLauncher")
        or not Util.bool(player:control(PSE.Options.action.verb, 1)) then return end

    if Stamina.took_action(player) or data.cooldown > 0 or data.air_used
        or Strikes.busy(player) then return end

    data.cooldown = C.cooldown
    data.air_used = true

    local angle = Cursor.angle(player, player.x, player.y)
        or (player.image_xscale >= 0 and 0 or 180)
    start(player, data, angle)
    Assets.play("lunge", player)
    if Net.online then PSE.Net.lunge:send_to_all(player, angle) end
end)

PSE.Lunge = L
