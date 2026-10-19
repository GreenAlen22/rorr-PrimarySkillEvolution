-- API для других модов: чужая основная атака регистрируется как стрелок или ближник и дальше живёт по механикам PSE.

PSE = PSE or {}

local C        = PSE.Config
local Roster   = PSE.Roster
local Magazine = PSE.Magazine
local Aim      = PSE.Aim
local Strikes  = PSE.Strikes
local Charge   = PSE.Charge

if not Roster or not Magazine or not Aim or not Strikes or not Charge then
    error("core/api: the gunner roster, the magazine, the aim, the melee strikes or the charge window did not load")
end

local A = {}

local function fail(what, msg, level)
    error("Primary Skill Evolution API, "..what..": "..msg, level + 1)
end

local function check_skill(skill, fn_name)
    if Util.type(skill) ~= "Skill" then
        fail(fn_name, "expected a Skill, got "..Util.type(skill), 3)
    end
    local what = fn_name.." "..skill.namespace.."-"..skill.identifier
    if Roster.by_skill[skill.value] then fail(what, "already registered as a gunner", 3) end
    if Strikes.by_skill[skill.value] then fail(what, "already registered as a melee strike", 3) end
    return what
end

local function state_set(list, what, field, optional, level)
    if list == nil and optional then return {} end
    if type(list) ~= "table" or #list == 0 then fail(what, field.." must be a non-empty list of ActorStates", level) end
    local set = {}
    for i, state in ipairs(list) do
        if Util.type(state) ~= "ActorState" then
            fail(what, field.."["..i.."] is a "..Util.type(state)..", not an ActorState", level)
        end
        set[state.value] = true
    end
    return set
end

local function whole(n, min)
    return type(n) == "number" and n == math.floor(n) and n >= min
end

local function one_of(value, choices)
    for _, c in ipairs(choices) do
        if value == c then return true end
    end
    return false
end

local function where(def, what)
    local states = state_set(def.states, what, "states", def.activity ~= nil, 4)
    if def.activity ~= nil and type(def.activity) ~= "number" then fail(what, "activity must be a number", 3) end
    if def.states == nil and def.activity == nil then fail(what, "needs states or activity: where the primary is fired from", 3) end
    return states
end

local SHOTS = { "bullet", "enter", "custom" }
local AIMS  = { "bullet", "host", "custom", "none" }

function A.gunner(skill, def)
    local what = check_skill(skill, "gunner")
    if type(def) ~= "table" then fail(what, "def must be a table", 2) end
    if type(def.name) ~= "string" or def.name == "" then fail(what, "name must be a non-empty string", 2) end

    local states = where(def, what)

    local shot = def.shot or "bullet"
    local aim  = def.aim or "bullet"
    if not one_of(shot, SHOTS) then fail(what, "shot must be bullet, enter or custom", 2) end
    if not one_of(aim, AIMS) then fail(what, "aim must be bullet, host, custom or none", 2) end
    if shot == "enter" and def.states == nil then fail(what, "shot enter needs states", 2) end
    if aim == "bullet" and shot ~= "bullet" then fail(what, "aim bullet needs shot bullet", 2) end
    if shot == "bullet" and aim ~= "bullet" and aim ~= "none" then fail(what, "shot bullet aims as bullet or none", 2) end

    local tracers = {}
    if def.tracers ~= nil then
        if type(def.tracers) ~= "table" then fail(what, "tracers must be a list of tracer ids", 2) end
        for i, t in ipairs(def.tracers) do
            if type(t) ~= "number" then fail(what, "tracers["..i.."] must be a tracer id", 2) end
            tracers[t] = true
        end
    end

    local tuning = nil
    if def.magazine ~= nil or def.reload ~= nil then
        if not whole(def.magazine, 1) then fail(what, "magazine must be a whole number from 1", 2) end
        if type(def.reload) ~= "number" or def.reload <= 0 then fail(what, "reload must be seconds above 0", 2) end
        tuning = { magazine = def.magazine, reload = math.floor(def.reload * C.fps + 0.5) }
    end

    local cone = nil
    if aim ~= "none" then
        if type(def.cone) ~= "number" or def.cone < 0 or def.cone > 90 then fail(what, "cone must be 0 to 90 degrees", 2) end
        cone = def.cone
    end
    if def.release ~= nil and Util.type(def.release) ~= "ActorState" then fail(what, "release must be an ActorState", 2) end
    if def.cut ~= nil and type(def.cut) ~= "boolean" then fail(what, "cut must be true or false", 2) end

    local entry = {
        name      = def.name,
        skill     = skill,
        tuning    = tuning,
        cone      = cone,
        shot      = shot,
        states    = states,
        activity  = def.activity,
        grenade   = false,
        combo_end = def.cut == true,
        release   = def.release and def.release.value or nil,
        tracers   = tracers,
        aim       = aim,
        share_aim = aim == "host" or aim == "custom",
    }
    Roster.add(entry)
    if shot == "enter" then Magazine.watch_enter(entry) end
end

local STRIKES = { "hc", "attack" }

function A.melee(skill, def)
    local what = check_skill(skill, "melee")
    if type(def) ~= "table" then fail(what, "def must be a table", 2) end
    if type(def.name) ~= "string" or def.name == "" then fail(what, "name must be a non-empty string", 2) end
    local states = where(def, what)

    local strike = def.strike or "hc"
    if not one_of(strike, STRIKES) then fail(what, "strike must be hc or attack", 2) end
    if def.gap ~= nil and not whole(def.gap, 0) then fail(what, "gap must be a whole number of frames from 0", 2) end
    if def.host ~= nil and type(def.host) ~= "boolean" then fail(what, "host must be true or false", 2) end
    if not whole(def.stamina, 1) then fail(what, "stamina must be a whole number from 1", 2) end
    if def.finisher ~= nil and not whole(def.finisher, 1) then fail(what, "finisher must be a whole number from 1", 2) end
    if type(def.sparks) ~= "number" or not Util.bool(gm.sprite_exists(def.sparks)) then
        fail(what, "sparks must be a sprite id", 2)
    end

    Strikes.add({
        name     = def.name,
        hero     = nil,
        skill    = skill,
        strikes  = def.stamina,
        sparks   = def.sparks,
        states   = states,
        activity = def.activity,
        strike   = strike,
        gap      = def.gap or 0,
        host     = def.host == true,
        finisher = def.finisher,
    })
end

local function check_actor(actor, fn_name)
    if actor == nil or not Instance.exists(actor) then fail(fn_name, "expected a live actor", 3) end
end

function A.spend(actor, rounds)
    check_actor(actor, "spend")
    if rounds ~= nil and not whole(rounds, 1) then fail("spend", "rounds must be a whole number from 1", 2) end
    if not Util.bool(actor.is_local) then return end
    local data = Magazine.get(actor)
    if not data then return end
    if data.entry.shot ~= "custom" then fail("spend", data.entry.name.." counts its rounds itself (shot "..data.entry.shot..")", 2) end
    Magazine.spend(actor, data, rounds)
end

function A.aim(actor, x, y, side)
    check_actor(actor, "aim")
    if type(x) ~= "number" or type(y) ~= "number" then fail("aim", "x and y must be numbers", 2) end
    if side ~= 0 and side ~= 180 then fail("aim", "side must be 0 or 180", 2) end
    return Aim.direction(actor, x, y, side)
end

function A.charge(actor, progress, rate)
    check_actor(actor, "charge")
    if type(progress) ~= "number" or type(rate) ~= "number" or rate <= 0 then
        fail("charge", "progress must be a number and rate a number above 0", 2)
    end
    if not Util.bool(actor.is_local) then return end
    Charge.report(actor, math.max(0, math.min(1, progress)), rate)
end

function A.charge_release(actor)
    check_actor(actor, "charge_release")
    if not Util.bool(actor.is_local) then return false end
    return Charge.release(actor)
end

api.version        = 2
api.gunner         = A.gunner
api.melee          = A.melee
api.spend          = A.spend
api.aim            = A.aim
api.charge         = A.charge
api.charge_release = A.charge_release
setmetatable(api, { __index = function(_, key)
    if key == "RAPI" then return nil end
    error("Primary Skill Evolution API has no "..tostring(key)
        .."; it has version, gunner, melee, spend, aim, charge, charge_release", 2)
end })

PSE.Api = A
