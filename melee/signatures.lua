-- Особые эффекты каждого ближника при добивании.

PSE = PSE or {}

local C       = PSE.Config.melee.signatures
local V       = PSE.Vanilla
local Strikes = PSE.Strikes
local Rage    = PSE.Rage

local PACTOR         = V.constant("pActor")
local PICK           = V.constant("oMinerPick")
local DISEASE        = V.constant("oAcridDisease")
local DISEASE_MASTER = V.constant("oAcridDiseaseMaster")

local STANDOFF = Buff.find("banditSkull", "ror")
if not STANDOFF then error("vanilla buff ror-banditSkull not found") end

local GIFT_WEIGHTS, FOOD_WEIGHTS = 29, 30
local TEMP_BLUE, TEMP_RED = 1, 2

local SG = {}

local function center(actor)
    return (actor.bbox_left + actor.bbox_right) / 2, (actor.bbox_top + actor.bbox_bottom) / 2
end

local function enemies_near(player, reach)
    local found = {}
    for _, actor in ipairs(Instance.find_all(PACTOR)) do
        if actor.team ~= player.team and not Util.bool(actor.dead) and not Util.bool(actor.intangible) then
            local x, y = center(actor)
            local distance = gm.point_distance(player.x, player.y, x, y)
            if distance <= reach then found[#found + 1] = { actor = actor, distance = distance } end
        end
    end
    table.sort(found, function(a, b) return a.distance < b.distance end)
    local actors = {}
    for i, f in ipairs(found) do actors[i] = f.actor end
    return actors
end

local function drop_pickup(player, weights, kind, x, y, fx, fy)
    local object = gm.treasure_weights_roll_pickup(weights)
    if object == nil or (type(object) == "number" and object < 0) then return end
    gm.item_set_dibs(player.value)
    local pickup = Instance.create(x, y, object)
    pickup.item_stack_kind = kind
    pickup.xstart, pickup.ystart = fx, fy
    pickup.x, pickup.y = fx, fy
end

local sniper_marks = {}

local function marks_of(player)
    local m = sniper_marks[player.id]
    local now = Global._current_frame
    if not m or now < m.from or now > m.until_frame then
        sniper_marks[player.id] = nil
        return nil
    end
    return m
end

function SG.sniper_marks(player)
    local m = marks_of(player)
    local live = {}
    if not m then return live end
    for id in pairs(m.ids) do
        if Instance.exists(id) and not Util.bool(Instance.wrap(id).dead) then live[#live + 1] = Instance.wrap(id) end
    end
    return live
end

Strikes.on_damage(function(player, _, target, _, critical, api)
    if critical or not target then return end
    local m = marks_of(player)
    if m and m.ids[target.id] then api.set_critical(true) end
end)

local HEROES = {
    bandit = {
        host = function(player)
            player:buff_apply(STANDOFF, C.bandit.duration, C.bandit.stacks)
        end,
    },

    hand = {
        host = function(player)
            for _ = 1, C.hand.drones do gm.actor_skill_add_stock(player.value, 1, true, false) end
        end,
    },

    miner = {
        every = function(player)
            local step = C.miner.width / C.miner.picks
            for i = 1, C.miner.picks do
                local pick = Instance.create(player.x - C.miner.width / 2 + step * (i - 0.5),
                    player.y - C.miner.height, PICK)
                pick.parent       = player
                pick.team         = player.team
                pick.direction    = 270
                pick.speed        = 1
                pick.burning      = 1
                pick.damage_coeff = C.miner.damage
                pick.image_xscale = player.image_xscale >= 0 and 1 or -1
                pick.image_yscale = pick.image_xscale
            end
        end,
    },

    sniper = {
        pick = function(player)
            local targets = {}
            for i, actor in ipairs(enemies_near(player, C.sniper.reach)) do
                if i > C.sniper.marks then break end
                targets[i] = actor
            end
            return targets
        end,
        every = function(player, targets)
            local now = Global._current_frame
            local m = { ids = {}, from = now, until_frame = now + C.sniper.duration }
            for _, target in ipairs(targets) do
                if Instance.exists(target) then m.ids[Instance.wrap(target).id] = true end
            end
            sniper_marks[player.id] = m
        end,
    },

    acrid = {
        host = function(player)
            local target = enemies_near(player, C.acrid.reach)[1]
            if not target then return end
            local x, y = center(target)
            local disease = Instance.create(x, y, DISEASE)
            disease.parent    = player
            disease.team      = player.team
            disease.target    = target
            disease.direction = gm.point_direction(player.x, player.y, x, y)
            local master = Instance.create(x, y, DISEASE_MASTER)
            master.parent  = player
            disease.master = master
        end,
    },

    mercenary = {
        owner = function(player, entry)
            PSE.JudgementCut.start(player, entry)
        end,
    },

    loader = {
        owner = function(player, entry)
            local info = Strikes.explode(player, "finisher", player.x, player.y,
                C.loader.damage, entry.sparks, C.loader.width, C.loader.height)
            info.knockup = C.loader.knockup
            info.stun    = C.loader.stun
        end,
    },

    chef = {},

    drifter = {
        host = function(player)
            local side = player.image_xscale >= 0 and 1 or -1
            for i = 1, C.drifter.items do
                drop_pickup(player, GIFT_WEIGHTS, TEMP_BLUE,
                    player.x + (32 + (i - 1) * 38) * side, player.y,
                    player.x + 6 * side, player.y - 10)
            end
        end,
    },
}

local ORDER = { "bandit", "hand", "miner", "sniper", "acrid", "mercenary", "loader", "chef", "drifter" }
local index_of = {}
for i, hero in ipairs(ORDER) do
    if not HEROES[hero] then error("no signature for "..hero) end
    if not C[hero] then error("no signature numbers for "..hero.." in core/config.lua") end
    index_of[hero] = i
end

local function run(player, hero, targets)
    local def = HEROES[hero]
    if def.every then def.every(player, targets) end
    if Net.host and def.host then def.host(player, targets) end
end

function SG.fire(player, entry)
    local hero = entry.hero
    local def  = HEROES[hero]
    if not def then error("no signature for "..tostring(hero)) end

    local targets = def.pick and def.pick(player) or {}
    if def.owner then def.owner(player, entry) end
    run(player, hero, targets)
    if Net.online then PSE.Net.signature:send_to_all(player, index_of[hero], targets) end
end

function SG.receive(player, index, targets)
    if not Instance.exists(player) or Util.bool(player.is_local) then return end
    local hero = ORDER[index]
    if hero then run(Instance.wrap(player), hero, targets) end
end

Strikes.on_kill(function(player, target)
    if not Net.host or not target or not Rage.active(player) then return end
    local entry = Strikes.of(player)
    if not entry or entry.hero ~= "chef" then return end
    drop_pickup(player, FOOD_WEIGHTS, TEMP_RED, target.x, target.y, target.x, target.y - 15)
end)

PSE.Signatures = SG
