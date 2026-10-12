-- Какие атаки — удары ближнего боя, и учёт их попаданий.

PSE = PSE or {}

local C  = PSE.Config
local V  = PSE.Vanilla

local MELEE = {
    acridZ     = { hero = "acrid",     sparks = "sBite2" },
    acridZ2    = { hero = "acrid",     sparks = "sBite1" },
    handZ      = { hero = "hand",      sparks = "sSparks1" },
    minerZ     = { hero = "miner",     sparks = "sSparks7" },
    minerZ2    = { hero = "miner",     thrown = true, sparks = "sSparks12" },
    mercenaryZ = { hero = "mercenary", sparks = "sSparks9" },
    loaderZ    = { hero = "loader",    sparks = "sSparks7" },
    drifterZ   = { hero = "drifter",   sparks = "sSparks7" },
    banditZ2   = { hero = "bandit",    sparks = "sSparks13" },
    sniperZ2   = { hero = "sniper",    sparks = "sSparks14" },
    chefZ2     = { hero = "chef",      sparks = "sSparks10" },
}

local S = { by_skill = {} }

S.counters = { strikes = 0, claimed = 0, steps = 0, handled = 0, posthit = 0, hits = 0 }

for name, v in pairs(MELEE) do
    local strikes = C.melee.stamina[name]
    if not strikes then error("no stamina for melee primary "..name.." in core/config.lua") end

    local entry = {
        name    = name,
        hero    = v.hero,
        skill   = V.skill(name),
        strikes = strikes,
        sparks  = V.constant(v.sparks),
        thrown  = v.thrown or false,
    }
    S.by_skill[entry.skill.value] = entry
end

function S.of(actor)
    return S.by_skill[actor:get_default_skill(Skill.Slot.PRIMARY).skill_id]
end

function S.busy(actor)
    return actor.actor_state_current_id ~= -1 or tonumber(actor.activity) ~= 0
end

local on_strike = {}

function S.on_strike(fn)
    on_strike[#on_strike + 1] = fn
end

local current = nil

Hook.add_post(gm.constants.skill_util_update_heaven_cracker, function(self, other, result, args)
    if not self or self.object_index ~= gm.constants.oP or not Util.bool(self.is_local) then return end
    local entry = S.of(self)
    if not entry then return end

    current = { player = self.id, frame = Global._current_frame }
    S.counters.strikes = S.counters.strikes + 1
    for _, fn in ipairs(on_strike) do fn(self, entry) end
end)

local ATTACKS = {
    { fire = gm.constants.fire_explosion, object = V.constant("oExplosionAttack"),
      step = "gml_Object_oExplosionAttack_Step_1" },
    { fire = gm.constants.fire_bullet,    object = V.constant("oBulletAttack"),
      step = "gml_Object_oBulletAttack_Step_1" },
    { fire = gm.constants.fire_direct,    object = V.constant("oDirectAttack"),
      step = "gml_Object_oDirectAttack_Step_1" },
}
local EXPLOSION = ATTACKS[1].object

local claimed = {}
local STALE = 30

local last_claim = nil

local function claim(object, player, kind, x, y)
    local now = Global._current_frame
    for id, c in pairs(claimed) do
        if now < c.frame or now - c.frame > STALE then claimed[id] = nil end
    end
    for _, inst in ipairs(Instance.find_all(object)) do
        if not claimed[inst.id] and math.abs(inst.x - x) < 0.5 and math.abs(inst.y - y) < 0.5 then
            claimed[inst.id] = { player = player.id, kind = kind, frame = now }
            S.counters.claimed = S.counters.claimed + 1
            last_claim = inst
            return inst
        end
    end
    return nil
end

local own_kind = nil

for _, attack in ipairs(ATTACKS) do
    Hook.add_post(attack.fire, function(self, other, result, args)
        if not self or self.object_index ~= gm.constants.oP or not Util.bool(self.is_local) then return end
        if not S.of(self) then return end

        local kind = own_kind
        if not kind then
            local strike = current
            kind = (attack.object == EXPLOSION and strike and self.id == strike.player
                and Global._current_frame == strike.frame) and "strike" or "skill"
        end
        claim(attack.object, self, kind, args[2].value, args[3].value)
    end)
end

local MASK_W, MASK_H = 78, 16

function S.explode(player, kind, x, y, damage, sparks, width, height)
    own_kind, last_claim = kind, nil
    local ok, err = pcall(function()
        GM.SO.fire_explosion(player, player, 0, x, y, damage, sparks, 2, -1, width / MASK_W, height / MASK_H)
    end)
    own_kind = nil
    if not ok then error(err, 0) end

    local inst = last_claim or claim(EXPLOSION, player, kind, x, y)
    if not inst then error("melee: the "..kind.." explosion is not at its point") end
    return inst.attack_info
end

local on_hits = {}

function S.on_hits(fn)
    on_hits[#on_hits + 1] = fn
end

local processing = nil

local function begin(self)
    local c = claimed[self.id]
    processing = c and { player = c.player, kind = c.kind, hits = 0 } or nil
end

Callback.add(Callback.ON_ATTACK_HANDLE_END, function(attack_info)
    if not processing then return end
    S.counters.handled = S.counters.handled + 1
    processing.hits = math.max(processing.hits, tonumber(attack_info.hit_number or 0) or 0)
end)

Hook.add_pre(gm.constants.damager_proc_posthit_clientandserver, function(self, other, result, args)
    if not processing then return end
    S.counters.posthit = S.counters.posthit + 1
    processing.hits = math.max(processing.hits, tonumber(args[4].value or 0) or 0)
end)

local function finish()
    local p = processing
    processing = nil
    if not p then return end
    S.counters.steps = S.counters.steps + 1
    if p.hits <= 0 then return end

    S.counters.hits = S.counters.hits + p.hits
    if not Instance.exists(p.player) then return end
    local player = Instance.wrap(p.player)
    for _, fn in ipairs(on_hits) do fn(player, p.hits, p.kind) end
end

for _, attack in ipairs(ATTACKS) do
    Hook.add_pre(attack.step, begin)
    Hook.add_post(attack.step, finish)
end

S.counters.damage, S.counters.by_parent, S.counters.targets = 0, 0, 0
S.counters.deaths, S.counters.kills = 0, 0

local on_damage, on_kill = {}, {}

function S.on_damage(fn)
    on_damage[#on_damage + 1] = fn
end

function S.on_kill(fn)
    on_kill[#on_kill + 1] = fn
end

local last_hit = {}
local last_prune = 0

local function readable(inst)
    if inst == nil or not Instance.exists(inst) then return nil end
    return Instance.wrap(inst)
end

DamageCalculate.add(function(api)
    S.counters.damage = S.counters.damage + 1
    local now = Global._current_frame

    local player, kind
    if processing then
        player, kind = Instance.exists(processing.player) and Instance.wrap(processing.player), processing.kind
    else
        player = readable(api.parent)
        if player and player.object_index ~= gm.constants.oP then player = nil end
        if player then S.counters.by_parent = S.counters.by_parent + 1 end
    end
    if not player then return end

    local target = readable(api.hit)
    if target then
        S.counters.targets = S.counters.targets + 1
        last_hit[target.id] = { player = player.id, frame = now }
    end

    if now < last_prune or now - last_prune > C.melee.kill_window * 10 then
        for id, h in pairs(last_hit) do
            if now < h.frame or now - h.frame > C.melee.kill_window then last_hit[id] = nil end
        end
        last_prune = now
    end

    local damage, critical = tonumber(api.damage or 0) or 0, Util.bool(api.critical)
    for _, fn in ipairs(on_damage) do fn(player, kind, target, damage, critical, api) end
end)

local function killed(player, target)
    if not player or player.object_index ~= gm.constants.oP then return end
    S.counters.kills = S.counters.kills + 1
    for _, fn in ipairs(on_kill) do fn(player, target) end
end

Callback.add(Callback.ON_KILL_PROC, function(target, attacker)
    if not Net.host then return end
    killed(readable(attacker), readable(target))
end)

Callback.add(Callback.ON_DEATH, function(actor, _)
    S.counters.deaths = S.counters.deaths + 1
    local h = actor and last_hit[actor.id]
    if not h then return end
    last_hit[actor.id] = nil
    if Net.host then return end

    local now = Global._current_frame
    if now < h.frame or now - h.frame > C.melee.kill_window then return end
    if not Instance.exists(h.player) then return end
    killed(Instance.wrap(h.player), actor)
end)

PSE.Strikes = S
