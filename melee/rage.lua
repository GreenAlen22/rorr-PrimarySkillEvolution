-- Ярость после добивания: больше урона и лечение от урона.

PSE = PSE or {}

local C       = PSE.Config.melee.rage
local Assets  = PSE.Assets
local Rewards = PSE.Rewards

local RA = {}

RA.buff = Buff.new("rage")
RA.buff.icon_sprite   = Assets.rage_icon.sprite
RA.buff.icon_subimage = Assets.rage_icon.subimage
RA.buff.is_debuff     = false

Rewards.define("rage", function(actor)
    Rewards.refresh(actor, RA.buff, C.duration)
end)

function RA.active(actor)
    return actor:buff_count(RA.buff) > 0
end

RecalculateStats.add(function(actor, api)
    if RA.active(actor) then api.damage_mult(C.damage) end
end)

Callback.add(Callback.ON_HIT_PROC, function(attacker, target, hit_info)
    if not Net.host then return end
    if not attacker or not Instance.exists(attacker) or not RA.active(attacker) then return end
    attacker:heal(hit_info.damage_true * C.lifesteal)
end)

PSE.Rage = RA
