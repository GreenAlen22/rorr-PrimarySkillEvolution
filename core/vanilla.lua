-- Ванильные имена в id для всех модулей.

PSE = PSE or {}

local V = {}

function V.state(name)
    local state = ActorState.find(name, "ror")
    if not state then error("vanilla actor state ror-"..name.." not found") end
    return state.value
end

function V.skill(name)
    local skill = Skill.find(name, "ror")
    if not skill then error("vanilla skill ror-"..name.." not found") end
    return skill
end

function V.tracer(name)
    local id = Tracer[name]
    if not id then error("vanilla tracer "..name.." not found") end
    return id
end

function V.constant(name)
    local id = gm.constants[name]
    if not id then error("vanilla asset "..name.." not found") end
    return id
end

local NS = PSE.Config.namespace

function V.claim(object, actor, x, y, radius)
    local claimed = {}
    for _, inst in ipairs(Instance.find_all(object)) do
        local record = Instance.get_data(inst, "owner", NS)
        if not record.id and inst.team == actor.team
            and gm.point_distance(inst.x, inst.y, x, y) <= radius then
            record.id = actor.id
            claimed[#claimed + 1] = inst
        end
    end
    return claimed
end

function V.owner(inst)
    local id = Instance.get_data(inst, "owner", NS).id
    if not id or not Instance.exists(id) then return nil end
    return Instance.wrap(id)
end

PSE.Vanilla = V
