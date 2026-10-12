-- CHEF: поймать возвращающийся тесак.

PSE = PSE or {}

local C       = PSE.Config.chef
local NS      = PSE.Config.namespace
local V       = PSE.Vanilla
local Assets  = PSE.Assets
local Rewards = PSE.Rewards

local DICE    = V.skill("chefZ").value
local KNIFE   = V.constant("oChefKnife")
local NORMAL  = V.state("chefZ")
local MINCE   = V.state("chefZEmpowered")

local CLAIM_RADIUS = 160

local CH = {}

CH.buff = Buff.new("sharpCleaver")
CH.buff.icon_sprite   = Assets.sharp_cleaver_icon.sprite
CH.buff.icon_subimage = Assets.sharp_cleaver_icon.subimage
CH.buff.is_debuff     = false

Rewards.define("sharpCleaver", function(actor)
    Rewards.refresh(actor, CH.buff, C.duration)
end)

function CH.is_dice(player)
    return player:get_default_skill(Skill.Slot.PRIMARY).skill_id == DICE
end

Callback.add(ActorState.wrap(NORMAL).on_step, function(actor, _)
    local knives = V.claim(KNIFE, actor, actor.x, actor.y, CLAIM_RADIUS)
    if #knives == 0 or actor:buff_count(CH.buff) <= 0 then return end

    for _, knife in ipairs(knives) do
        knife.damage_coeff = knife.damage_coeff * C.damage
        knife.max_speed    = knife.max_speed * C.speed
        knife.speed        = knife.max_speed
    end
    if Net.host then actor:buff_remove(CH.buff) end
end)

Callback.add(ActorState.wrap(MINCE).on_step, function(actor, _)
    V.claim(KNIFE, actor, actor.x, actor.y, CLAIM_RADIUS)
end)

local function frames_to_arrive(knife, chef)
    local distance = gm.point_distance(knife.x, knife.y, chef.x, chef.y)
    return distance / math.max(knife.speed, 1)
end

local function scan(chef)
    local found = {}
    for _, knife in ipairs(Instance.find_all(KNIFE)) do
        local owner = V.owner(knife)
        if owner and owner.id == chef.id and knife.rebound == 1
            and frames_to_arrive(knife, chef) <= C.window then
            found[knife.id] = knife.pass == 1 and "mince" or "normal"
        end
    end
    return found
end

local function data_of(player)
    return Instance.get_data(player, "chef", NS)
end

function CH.in_window(player)
    local data = data_of(player)
    return data.normal == true, data.mince == true
end

function CH.cooldown(player)
    return data_of(player).cooldown or 0
end

Callback.add(Callback.ON_PLAYER_STEP, function(player)
    if not Util.bool(player.is_local) or not CH.is_dice(player) then return end

    local data = data_of(player)
    local now  = Global._current_frame
    if (data.cooldown or 0) > 0 then data.cooldown = data.cooldown - 1 end

    local seen = scan(player)
    for id, kind in pairs(data.seen or {}) do
        if not seen[id] and not Instance.exists(id) then
            data.arrived = data.arrived or {}
            data.arrived[kind] = now
        end
    end
    data.seen = seen

    local function open(kind)
        for _, k in pairs(seen) do if k == kind then return true end end
        local frame = data.arrived and data.arrived[kind]
        return frame ~= nil and now >= frame and now - frame <= C.grace
    end
    data.mince  = open("mince")
    data.normal = open("normal") and (data.cooldown or 0) <= 0

    if not Util.bool(player:control("skill1", 1)) then return end

    if data.mince then
        data.arrived = nil
        data.recast  = true
        Assets.play("perfect", player)
    elseif data.normal then
        data.arrived  = nil
        data.cooldown = C.cooldown
        Assets.play("perfect", player)
        Rewards.grant(player, "sharpCleaver")
    end
end)

Hook.add_pre(gm.constants.skill_system_update, function(self)
    if not self or self.object_index ~= gm.constants.oP or not Util.bool(self.is_local) then return end
    local data = data_of(self)
    if not data.recast then return end
    data.recast = nil
    gm.actor_set_state_networked(self.value, MINCE)
end)

PSE.Chef = CH
