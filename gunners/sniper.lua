-- Снайпер: идеальная ванильная перезарядка даёт «Идеальную перезарядку» мода, не чаще раза в 7 секунд.

PSE = PSE or {}

local C     = PSE.Config.perfect_reload
local NS    = PSE.Config.namespace
local Prefs = PSE.Prefs

local SN = {}

local SNIPE   = PSE.Vanilla.skill("sniperZ").value
local PERFECT = 2

local function data_of(player)
    return Instance.get_data(player, "sniper", NS)
end

function SN.holds(player)
    return player:get_default_skill(Skill.Slot.PRIMARY).skill_id == SNIPE
end

function SN.cooldown(player)
    return data_of(player).cooldown or 0
end

Callback.add(Callback.ON_PLAYER_STEP, function(player)
    if not Util.bool(player.is_local) or not SN.holds(player) then return end

    local data = data_of(player)
    if (data.cooldown or 0) > 0 then data.cooldown = data.cooldown - 1 end

    local bonus = tonumber(player.sniper_bonus) or 0
    local was = data.bonus
    data.bonus = bonus
    if was == nil or bonus ~= PERFECT or was == PERFECT then return end

    if not Prefs.rule("perfectReload") or (data.cooldown or 0) > 0 then return end
    data.cooldown = C.duration
    PSE.PerfectReload.grant(player)
end)

PSE.Sniper = SN
