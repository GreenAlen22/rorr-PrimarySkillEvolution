-- Окно на заряде у Pierce Охотницы и у Лоадера. Отпуск в окне — полный заряд и бафф.

PSE = PSE or {}

local C       = PSE.Config
local V       = PSE.Vanilla
local Assets  = PSE.Assets
local Rewards = PSE.Rewards
local Prefs   = PSE.Prefs

local FULL = 150

local HUNTRESS_FIRE  = V.state("huntressZ2Fire")
local HUNTRESS_FIRE2 = V.state("huntressZ2Fire2")
local LOADER_FIRE    = V.state("loaderZ2Fire")
local FULL_ARROW     = V.constant("oHuntressBolt1B2")

local CH = {}

CH.full = FULL

CH.attacks = {
    [V.state("huntressZ2Draw")] = { name = "huntressZ2", rate = 1.5, release = HUNTRESS_FIRE },
    [V.state("loaderZ2Start")]  = { name = "loaderZ2",   rate = 1,   release = LOADER_FIRE },
}

CH.buff = Buff.new("steadyHand")
CH.buff.icon_sprite   = Assets.steady_hand_icon.sprite
CH.buff.icon_subimage = Assets.steady_hand_icon.subimage
CH.buff.is_debuff     = false

Rewards.define("steadyHand", function(actor)
    Rewards.refresh(actor, CH.buff, C.steady_hand.duration)
end)

RecalculateStats.add(function(actor, api)
    if actor:buff_count(CH.buff) <= 0 then return end
    api.attack_speed_add(C.steady_hand.attack_speed)
end)

local function data_of(actor)
    return Instance.get_data(actor, "charge", C.namespace)
end

function CH.drawing(actor)
    local attack = CH.attacks[actor.actor_state_current_id]
    if not attack then return nil end
    local state_data = actor.actor_state_current_data_table
    return attack, (state_data and state_data.charge) or 0
end

function CH.window(actor, attack)
    local from = C.charge_window.from * FULL
    local to   = C.charge_window.to * FULL
    local min_width = C.window.min_frames * attack.rate * actor.attack_speed
    if to - from < min_width then
        local middle = (from + to) / 2
        from, to = middle - min_width / 2, middle + min_width / 2
    end
    return from, math.min(to, FULL)
end

function CH.has_window(actor)
    return Prefs.rule("chargeWindow") and (data_of(actor).cooldown or 0) <= 0
end

Callback.add(Callback.ON_PLAYER_STEP, function(player)
    if not Util.bool(player.is_local) then return end
    local data = data_of(player)
    if (data.cooldown or 0) > 0 then data.cooldown = data.cooldown - 1 end

    local attack, charge = CH.drawing(player)
    local previous = data.last_charge
    data.last_charge = attack and charge or nil
    if not attack or not previous or not CH.has_window(player) then return end

    local from = CH.window(player, attack)
    if previous < from and charge >= from then Assets.play("cue", player) end
end)

Hook.add_pre(gm.constants.actor_set_state_networked, function(self, other, result, args)
    local target = args[2].value
    if target ~= HUNTRESS_FIRE and target ~= LOADER_FIRE then return end

    local actor = args[1].value
    if type(actor) == "number" then actor = Instance.wrap(actor) end
    if not actor or actor.object_index ~= gm.constants.oP or not Util.bool(actor.is_local) then return end

    local attack, charge = CH.drawing(actor)
    if not attack or attack.release ~= target or not CH.has_window(actor) then return end

    local from, to = CH.window(actor, attack)
    if charge < from or charge > to then return end

    if target == HUNTRESS_FIRE then
        actor.image_xscale = actor.image_xscale2
        args[2].value = HUNTRESS_FIRE2
    else
        actor.actor_state_current_data_table.charge = FULL
    end

    data_of(actor).cooldown = C.steady_hand.duration
    Assets.play("perfect", actor)
    Rewards.grant(actor, "steadyHand")
end)

local fire2 = ActorState.wrap(HUNTRESS_FIRE2)
local ARROW_CLAIM_RADIUS = 160

Callback.add(fire2.on_step, function(actor, state_data)
    local arrows = V.claim(FULL_ARROW, actor, actor.x, actor.y, ARROW_CLAIM_RADIUS)
    if #arrows == 0 or (state_data.charge or FULL) >= FULL then return end

    local scale = C.charge_window.pierce_scale
    for _, arrow in ipairs(arrows) do
        arrow.image_xscale = arrow.image_xscale * scale
        arrow.image_yscale = arrow.image_yscale * scale
        Instance.get_data(arrow, "pierce", C.namespace).grown = true
    end
end)

function CH.grown(arrow)
    return Instance.get_data(arrow, "pierce", C.namespace).grown == true
end

PSE.Charge = CH
