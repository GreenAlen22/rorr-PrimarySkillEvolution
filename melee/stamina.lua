-- Выносливость ближника, окно восстановления и баффы «Одышка» и «Второе дыхание».

PSE = PSE or {}

local C       = PSE.Config.melee
local NS      = PSE.Config.namespace
local Strikes = PSE.Strikes
local Reload  = PSE.Reload
local Assets  = PSE.Assets
local Rewards = PSE.Rewards

local ST = {}

ST.breathless = Buff.new("breathless")
ST.breathless.icon_sprite   = Assets.breathless_icon.sprite
ST.breathless.icon_subimage = Assets.breathless_icon.subimage
ST.breathless.is_debuff     = true

ST.second_wind = Buff.new("secondWind")
ST.second_wind.icon_sprite   = Assets.second_wind_icon.sprite
ST.second_wind.icon_subimage = Assets.second_wind_icon.subimage
ST.second_wind.is_debuff     = false

Rewards.define("breathless", function(actor)
    Rewards.refresh(actor, ST.breathless, C.breathless.duration)
end)
Rewards.define("breathlessEnd", function(actor)
    actor:buff_remove(ST.breathless)
end)
Rewards.define("secondWind", function(actor)
    Rewards.refresh(actor, ST.second_wind, C.second_wind.duration)
end)

RecalculateStats.add(function(actor, api)
    if actor:buff_count(ST.second_wind) > 0 then
        api.armor_add(C.second_wind.armor)
    end
end)

local function breathe(actor, attack_info)
    if actor:buff_count(ST.breathless) <= 0 then return end
    local damage = tonumber(attack_info.damage)
    if not damage then error("stamina: a strike's attack_info has no damage") end
    attack_info.damage = math.ceil(damage * C.breathless.damage)
end

Strikes.on_attack(function(player, kind, attack_info)
    if kind == "strike" then breathe(player, attack_info) end
end)

local PICK_COLLISION = "gml_Object_oMinerPick_Collision_pActorCollisionBase"
local EXEMPT = "notStrike"
local thrown_pick = false

function ST.exempt(inst)
    Instance.get_data(inst, EXEMPT, NS).on = true
end

Hook.add_pre(PICK_COLLISION, function(self)
    thrown_pick = Instance.get_data(self, EXEMPT, NS).on ~= true
end)
Hook.add_post(PICK_COLLISION, function()
    thrown_pick = false
end)

Hook.add_post(gm.constants.fire_direct, function(self, other, result, args)
    if not thrown_pick or not Net.host then return end
    if not self or self.object_index ~= gm.constants.oP then return end
    breathe(self, result.value)
end)

local function data_of(player, entry)
    local data = Instance.get_data(player, "stamina", NS)
    if data.entry ~= entry then
        data.entry       = entry
        data.value       = entry.strikes
        data.last_strike = -1
        data.breathless  = false
        data.cooldown    = 0
        data.window      = nil
    end
    return data
end

function ST.data(player)
    local entry = Strikes.of(player)
    return entry and data_of(player, entry) or nil
end

function ST.share(player)
    local entry = Strikes.of(player)
    if not entry then return 0 end
    local data = data_of(player, entry)
    return data.value / entry.strikes
end

local function set_breathless(player, data, on)
    if data.breathless == on then return end
    data.breathless = on
    Rewards.grant(player, on and "breathless" or "breathlessEnd")
end

function ST.spend(player)
    local entry = Strikes.of(player)
    if not entry then return end
    local data = data_of(player, entry)
    data.value       = math.max(0, data.value - 1)
    data.last_strike = Global._current_frame

    if data.value <= 0 then set_breathless(player, data, true) end

    if data.value / entry.strikes < C.low and data.cooldown <= 0 and not data.window then
        local from, to = Reload.window(C.window_bar)
        data.window = { start = data.last_strike, from = from, to = to }
    end
end

Strikes.on_strike(ST.spend)

function ST.window_bar(player)
    local entry = Strikes.of(player)
    if not entry then return nil end
    local window = data_of(player, entry).window
    if not window then return nil end
    return (Global._current_frame - window.start) / C.window_bar, window.from, window.to
end

function ST.took_action(player)
    local entry = Strikes.of(player)
    return entry ~= nil and data_of(player, entry).action_frame == Global._current_frame
end

local function refill(player, entry)
    local data = data_of(player, entry)
    data.value  = entry.strikes
    data.window = nil
    set_breathless(player, data, false)
end

Callback.add(Callback.ON_PLAYER_STEP, function(player)
    if not Util.bool(player.is_local) then return end
    local entry = Strikes.of(player)
    if not entry then return end

    local data = data_of(player, entry)
    local now  = Global._current_frame
    if now < data.last_strike then data.last_strike = now end
    if data.cooldown > 0 then data.cooldown = data.cooldown - 1 end

    if now - data.last_strike >= C.regen_delay and data.value < entry.strikes then
        data.value = math.min(entry.strikes, data.value + entry.strikes / C.regen_time)
    end
    if data.value / entry.strikes >= C.low then set_breathless(player, data, false) end

    local window = data.window
    if not window then return end

    local progress = (now - window.start) / C.window_bar
    if progress > 1 then
        data.window = nil
        return
    end

    local action = Util.bool(player:control(PSE.Options.action.verb, 1))
    if not action and not Util.bool(player:control("interact", 1)) then return end
    if action then data.action_frame = now end
    data.window   = nil
    data.cooldown = C.second_wind.duration

    if progress >= window.from and progress <= window.to then
        data.value  = entry.strikes * C.overflow
        data.caught = now
        set_breathless(player, data, false)
        Assets.play("perfect", player)
        Rewards.grant(player, "secondWind")
    else
        Assets.play("miss", player)
    end
end)

Callback.add(Callback.ON_STAGE_START, function()
    for _, player in ipairs(Instance.find_all(gm.constants.oP)) do
        local entry = Util.bool(player.is_local) and Strikes.of(player)
        if entry then refill(player, entry) end
    end
end)

Callback.add(Callback.ON_PLAYER_DEATH, function(player)
    local entry = Util.bool(player.is_local) and Strikes.of(player)
    if entry then refill(player, entry) end
end)

PSE.Stamina = ST
