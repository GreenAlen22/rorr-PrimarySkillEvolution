-- Какие ванильные атаки считаются стрелковыми и откуда они стреляют.

PSE = PSE or {}

local C = PSE.Config
local V = PSE.Vanilla

local VANILLA = {
    commandoZ  = { states = { "commandoZ" },  tracers = { "COMMANDO1" } },
    banditZ    = { states = { "banditZ" },    tracers = { "BANDIT1" } },
    enforcerZ  = { states = { "enforcerZ" },  tracers = { "ENFORCER1" } },
    robomandoZ = { states = { "robomandoZ" }, tracers = { "ROBOMANDO1" } },

    pilotZ = {
        states    = { "pilotZA", "pilotZB", "pilotZC" },
        tracers   = { "PILOT_PRIMARY", "PILOT_PRIMARY_STRONG" },
        combo_end = true,
    },

    pilotZ2 = {
        states  = { "pilotZ2" },
        tracers = { "PILOT_PRIMARY_ALT" },
        release = "pilotZ2Release",
    },

    sniperZ = { activity = 1.1, vanilla_reload = true },

    enforcerZ2 = { states = { "enforcerZ2" }, vanilla_reload = true, grenade = true },

    engineerZ  = { states = { "engineerZ" },  shot = "volley", no_aim = true },
    engineerZ2 = { states = { "engineerZ2" }, shot = "shell",  no_aim = true, release = "engineerZ2End" },
}

local R = {
    by_skill        = {},
    primary_tracers = {},
}

for name, v in pairs(VANILLA) do
    local tuning = C.gunners[name]
    if not tuning and not v.vanilla_reload then
        error("no tuning for gunner "..name.." in core/config.lua")
    end

    local cone = C.aim_cone[name]
    if not cone and not v.no_aim then
        error("no aim cone for gunner "..name.." in core/config.lua")
    end

    local skill = V.skill(name)

    local entry = {
        name      = name,
        tuning    = tuning,
        cone      = cone,
        shot      = v.shot or "bullet",
        states    = {},
        activity  = v.activity,
        grenade   = v.grenade or false,
        combo_end = v.combo_end or false,
        release   = v.release and V.state(v.release) or nil,
    }
    for _, s in ipairs(v.states or {}) do entry.states[V.state(s)] = true end
    for _, t in ipairs(v.tracers or {}) do R.primary_tracers[V.tracer(t)] = true end

    R.by_skill[skill.value] = entry
end

R.primary_tracers[V.tracer("DRILL")] = true

R.pilot_cling = V.state("pilotCling")

function R.of(actor)
    return R.by_skill[actor:get_default_skill(Skill.Slot.PRIMARY).skill_id]
end

function R.firing_primary(inst)
    if inst.object_index ~= gm.constants.oP or not Util.bool(inst.is_local) then return nil end

    local entry = R.of(inst)
    if not entry or entry.shot ~= "bullet" then return nil end

    if entry.states[inst.actor_state_current_id] then return entry end
    if entry.activity and inst.activity == entry.activity then return entry end
    return nil
end

PSE.Roster = R
