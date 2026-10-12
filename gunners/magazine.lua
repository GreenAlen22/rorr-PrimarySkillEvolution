-- Магазин: сколько патронов осталось. Считается на машине владельца.

PSE = PSE or {}

local C      = PSE.Config
local V      = PSE.Vanilla
local Roster = PSE.Roster

local M = {}

function M.get(actor)
    local entry = Roster.of(actor)
    if not entry or not entry.tuning then return nil end

    local data = Instance.get_data(actor, "magazine", C.namespace)
    if data.entry ~= entry then
        data.entry           = entry
        data.ammo            = entry.tuning.magazine
        data.last_shot_frame = -1
        data.reload          = nil
        data.window_cooldown = 0
    end
    return data
end

function M.spend(actor, data)
    if data.ammo <= 0 then
        PSE.Reload.start(actor, data)
        return
    end
    data.ammo = data.ammo - 1

    if data.ammo == 0 then PSE.Reload.start(actor, data) end
end

Hook.add_pre(gm.constants.fire_bullet, function(self, other, result, args)
    if not self or not Roster.firing_primary(self) then return end

    local data = M.get(self)
    if not data then return end

    local frame = Global._current_frame
    if frame == data.last_shot_frame then return end
    data.last_shot_frame = frame

    M.spend(self, data)
end)

local function engineer(actor, shot)
    if not Util.bool(actor.is_local) then return nil end
    local data = M.get(actor)
    if not data or data.entry.shot ~= shot then return nil end
    return data
end

local volley_state = ActorState.wrap(V.state("engineerZ"))
Callback.add(volley_state.on_enter, function(actor, _)
    local data = engineer(actor, "volley")
    if data then M.spend(actor, data) end
end)

local shell_state = ActorState.wrap(V.state("engineerZ2"))
Callback.add(shell_state.on_enter, function(actor, _)
    local data = engineer(actor, "shell")
    if data then data.last_shell_frame = nil end
end)
Callback.add(shell_state.on_step, function(actor, _)
    local data = engineer(actor, "shell")
    if not data then return end

    local frame = actor.activity_var1
    if frame == data.last_shell_frame then return end
    data.last_shell_frame = frame
    if frame == 2 or frame == 6 then M.spend(actor, data) end
end)

Callback.add(Callback.ON_PLAYER_STEP, function(player)
    if not Util.bool(player.is_local) then return end

    local data = M.get(player)
    if not data or (data.ammo > 0 and not data.reload) then return end

    local entry = data.entry
    if not (entry.release or entry.combo_end) then return end
    if not entry.states[player.actor_state_current_id] then return end

    local target = entry.release
    if not target then
        local state_data = player.actor_state_current_data_table
        local cling = state_data and Util.bool(state_data.cling)
        target = cling and Roster.pilot_cling or -1
    end

    gm.actor_set_state_networked(player.value, target)
end)

PSE.Magazine = M
