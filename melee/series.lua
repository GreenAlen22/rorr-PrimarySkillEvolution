-- Серия: буква стиля от D до SSS. Только картинка у владельца, на игру не влияет.

PSE = PSE or {}

local C       = PSE.Config.melee.series
local NS      = PSE.Config.namespace
local Strikes = PSE.Strikes

for _, kind in ipairs({ "strike", "skill", "lunge", "launcher", "finisher" }) do
    if not C[kind] then error("no series worth for "..kind.." in core/config.lua") end
end

local S = {}

S.LETTERS = { "D", "C", "B", "A", "S", "SS", "SSS" }

local function data_of(player)
    local data = Instance.get_data(player, "series", NS)
    if not data.points then
        data.points     = 0
        data.last_point = -1
        data.last_drop  = -1
        data.last_kill  = -1
        data.streak     = 0
        data.repeats    = 0
    end
    return data
end

local function rank_of(points)
    local rank = 0
    for i, threshold in ipairs(C.thresholds) do
        if points >= threshold then rank = i end
    end
    return rank
end

local function drop(data)
    local rank = rank_of(data.points)
    data.points = rank <= 1 and 0 or C.thresholds[rank] - 1
end

function S.rank(player)
    return rank_of(data_of(player).points)
end

function S.add(player, points)
    local data = data_of(player)
    data.points     = math.min(data.points + points, C.thresholds[#C.thresholds])
    data.last_point = Global._current_frame
    data.last_drop  = data.last_point
end

local function counted(player)
    return Util.bool(player.is_local) and Strikes.of(player) ~= nil
end

Strikes.on_damage(function(player, kind, target, damage, critical)
    if not counted(player) then return end
    local data = data_of(player)
    kind = kind or "skill"

    local points = C[kind]
    local maxhp  = target and tonumber(target.maxhp or 0) or 0
    if maxhp > 0 then
        points = points * (C.weight_floor + math.min(damage / maxhp * C.weight, C.weight_cap))
    end
    if critical then points = points * C.crit end

    if kind == data.last_kind then
        data.repeats = data.repeats + 1
    else
        data.last_kind, data.repeats = kind, 1
    end
    if data.repeats > C.repeats then points = points * C.repeat_mult end

    S.add(player, points)
end)

Strikes.on_kill(function(player, _)
    if not counted(player) then return end
    local data = data_of(player)
    local now  = Global._current_frame

    if now < data.last_kill or now - data.last_kill > C.streak_window then data.streak = 0 end
    data.streak    = data.streak + 1
    data.last_kill = now
    S.add(player, C.kill + math.min(data.streak - 1, C.streak_cap) * C.streak_step)
end)

Callback.add(Callback.ON_PLAYER_STEP, function(player)
    if not counted(player) then return end

    local data = data_of(player)
    local now  = Global._current_frame
    if now < data.last_point then data.last_point, data.last_drop = now, now end

    local hp = player.hp
    if data.hp and hp < data.hp - 0.5 then
        drop(data)
        local maxhp = tonumber(player.maxhp or 0) or 0
        if maxhp > 0 and (data.hp - hp) / maxhp >= C.hurt_heavy then drop(data) end
    end
    data.hp = hp

    if data.points > 0 and now - data.last_point >= C.decay_delay
        and now - data.last_drop >= C.decay_step then
        drop(data)
        data.last_drop = now
    end
end)

PSE.Series = S
