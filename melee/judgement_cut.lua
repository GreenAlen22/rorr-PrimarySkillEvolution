-- Добивание Наёмника: время замирает, экран режется и раскалывается.

PSE = PSE or {}

local C       = PSE.Config.melee.signatures.mercenary
local Strikes = PSE.Strikes
local Assets  = PSE.Assets

local JC = {}

local active = nil

function JC.state()
    return active
end

local function view()
    return Global.___view_l_x, Global.___view_l_y, Global.___view_l_w, Global.___view_l_h
end

local function strike(player, damage)
    local x, y, w, h = view()
    local info = Strikes.explode(player, "finisher", x + w / 2, y + h / 2, damage, active.sparks, w, h)
    info.stun = C.stun
end

function JC.start(player, entry)
    active = {
        player    = player.id,
        start     = Global._current_frame,
        sparks    = entry.sparks,
        fired     = 0,
        shattered = false,
        slashes   = {},
    }
    player.invincible = math.max(tonumber(player.invincible or 0) or 0, C.length)
end

Callback.add(Callback.ON_PLAYER_STEP, function(player)
    if not active or active.player ~= player.id then return end
    local now = Global._current_frame
    local t   = now - active.start
    if t < 0 then
        active = nil
        return
    end

    while active.fired < C.slashes and t >= C.first_slash + active.fired * C.slash_every do
        active.fired = active.fired + 1
        strike(player, C.slash_damage)
        active.slashes[#active.slashes + 1] = {
            frame = now,
            x     = 0.25 + math.random() * 0.5,
            y     = 0.25 + math.random() * 0.5,
            angle = math.random() * 180,
        }
        Assets.play("slash", player)
        player:screen_shake(2)
    end

    if not active.shattered and t >= C.shatter then
        active.shattered = true
        strike(player, C.final_damage)
        Assets.play("shatter", player)
        player:screen_shake(10)
    end

    if t >= C.length then active = nil end
end)

PSE.JudgementCut = JC
