-- Бафф «Идеальная перезарядка» и его эффект.

PSE = PSE or {}

local C       = PSE.Config.perfect_reload
local NS      = PSE.Config.namespace
local Assets  = PSE.Assets
local Roster  = PSE.Roster
local Rewards = PSE.Rewards

local P = {}

P.buff = Buff.new("perfectReload")
P.buff.icon_sprite   = Assets.buff_icon.sprite
P.buff.icon_subimage = Assets.buff_icon.subimage
P.buff.is_debuff     = false

function P.apply(actor)
    Rewards.refresh(actor, P.buff, C.duration)
end

Rewards.define("perfectReload", P.apply)

function P.grant(actor)
    Rewards.grant(actor, "perfectReload")
end

RecalculateStats.add(function(actor, api)
    if actor:buff_count(P.buff) <= 0 then return end
    api.attack_speed_add(C.attack_speed)
    api.pHmax_mult(C.move_speed)
end)

local PRIMARY_KEY = NS.."_primaryExplosion"

local inside_destroy = 0

for _, object in ipairs({ "oEngiGrenade", "oEngiMortar" }) do
    local event = "gml_Object_"..object.."_Destroy_0"
    Hook.add_pre(event, function() inside_destroy = inside_destroy + 1 end)
    Hook.add_post(event, function() inside_destroy = math.max(0, inside_destroy - 1) end)
end

Hook.add_post(gm.constants.fire_explosion, function(self, other, result, args)
    if inside_destroy <= 0 or not Net.host then return end
    local info = result.value
    if info then info[PRIMARY_KEY] = true end
end)

Callback.add(Callback.ON_HIT_PROC, function(attacker, target, hit_info)
    if not Net.host then return end
    if not attacker or not Instance.exists(attacker) then return end
    if attacker:buff_count(P.buff) <= 0 then return end

    local info = hit_info.attack_info
    local entry = Roster.of(attacker)
    if not (entry and entry.tracers[info.tracer_kind]) and not Util.bool(info[PRIMARY_KEY]) then return end

    attacker:heal(hit_info.damage_true * C.lifesteal)
end)

PSE.PerfectReload = P
