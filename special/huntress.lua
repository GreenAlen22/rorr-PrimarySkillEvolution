-- Охотница, Strafe: стрелы к курсору, метка на Action, рикошет каждым третьим попаданием.

PSE = PSE or {}

local C      = PSE.Config.huntress_mark
local CONE   = PSE.Config.aim_cone.huntressZ
local NS     = PSE.Config.namespace
local V      = PSE.Vanilla
local Aim    = PSE.Aim
local Cursor = PSE.Cursor

local STRAFE = V.skill("huntressZ").value
local PACTOR = V.constant("pActor")
local HITBOX = V.constant("pActorHitbox")
local ARROW  = V.constant("oHuntressBolt1")
local BLOCK  = V.constant("pBlock")
local SPARKS = V.constant("sSparks13")

local BOLT_STEP      = "gml_Object_oHuntressBolt1_Step_2"
local BOLT_COLLISION = "gml_Object_oHuntressBolt1_Collision_pActorCollisionBase"

local H = {}

H.traces = {}

if not CONE then error("no aim cone for huntressZ in core/config.lua") end
Aim.register_cone(STRAFE, CONE)

local function alive(id)
    if type(id) ~= "number" or not Instance.exists(id) then return nil end
    local actor = Instance.wrap(id)
    if Util.bool(actor.dead) then return nil end
    return actor
end

local function center(actor)
    return (actor.bbox_left + actor.bbox_right) / 2, (actor.bbox_top + actor.bbox_bottom) / 2
end

local function box_distance(actor, x, y)
    local dx = math.max(actor.bbox_left - x, 0, x - actor.bbox_right)
    local dy = math.max(actor.bbox_top - y, 0, y - actor.bbox_bottom)
    return math.sqrt(dx * dx + dy * dy)
end

local function nearest_enemy(team, x, y, reach, except)
    local best, best_distance = nil, reach
    for _, actor in ipairs(Instance.find_all(PACTOR)) do
        if actor.team ~= team and not Util.bool(actor.dead) and not Util.bool(actor.intangible)
            and not (except and actor.id == except.id) then
            local distance = box_distance(actor, x, y)
            if distance <= best_distance then best, best_distance = actor, distance end
        end
    end
    return best
end

function H.is_strafe(player)
    return player:get_default_skill(Skill.Slot.PRIMARY).skill_id == STRAFE
end

local function mark_data(huntress)
    return Instance.get_data(huntress, "mark", NS)
end

function H.mark_of(huntress)
    local data   = mark_data(huntress)
    local target = alive(data.target)
    if not target then data.target = nil end
    return target
end

function H.set_mark(huntress, target)
    mark_data(huntress).target = target and target.id or nil
end

function H.receive_mark(huntress, target)
    if not Instance.exists(huntress) or Util.bool(huntress.is_local) then return end
    H.set_mark(huntress, Instance.exists(target) and target or nil)
end

Callback.add(Callback.ON_PLAYER_STEP, function(player)
    if not Util.bool(player.is_local) or not H.is_strafe(player) then return end
    Cursor.share(player)

    if not Util.bool(player:control(PSE.Options.action.verb, 1)) then return end
    if not Cursor.enabled(player) then return end

    local target = nearest_enemy(player.team, Global.mouse_x, Global.mouse_y, C.reach)
    H.set_mark(player, target)
    if Net.online then PSE.Net.huntress_mark:send_to_all(player, target or -4) end
end)

local ARROW_CLAIM_RADIUS = 160
local strafe_state = ActorState.wrap(V.state("huntressZ"))

Callback.add(strafe_state.on_step, function(actor, _)
    V.claim(ARROW, actor, actor.x, actor.y, ARROW_CLAIM_RADIUS)
end)

local function steer(self, arrow, target)
    local speed = self.speed
    if speed <= 0 then return end

    local x, y = self.x, self.y
    local cx, cy = center(target)
    local distance = math.max(gm.point_distance(x, y, cx, cy), 1)

    local want  = gm.point_direction(x, y, cx, cy)
    local diff  = (want - self.direction + 540) % 360 - 180
    local limit = math.max(C.turn_rate, math.deg(2 * speed / distance))
    self.direction = self.direction + math.max(-limit, math.min(limit, diff))

    local vx = gm.lengthdir_x(speed, self.direction)
    local vy = gm.lengthdir_y(speed, self.direction)
    local t  = ((cx - x) * vx + (cy - y) * vy) / (speed * speed)
    if t <= 0 or t >= 1 then return end
    if box_distance(target, x + vx * t, y + vy * t) > 0 then return end
    arrow.full_speed  = speed
    arrow.short_speed = math.max(speed * t, 1)
    self.speed = arrow.short_speed
end

local TUNNEL_STEP = 2

local function tunnel(self)
    local speed = self.speed
    if speed <= 0 or not Util.bool(self.visible) then return end
    local dx = gm.lengthdir_x(1, self.direction)
    local dy = gm.lengthdir_y(1, self.direction)
    local x, y = self.x, self.y
    if not self:is_colliding(BLOCK, x + dx * speed, y + dy * speed) then return end

    local entry = speed
    for d = TUNNEL_STEP, speed, TUNNEL_STEP do
        if self:is_colliding(BLOCK, x + dx * d, y + dy * d) then
            entry = d
            break
        end
    end
    for d = entry, entry + C.wall_pass, TUNNEL_STEP do
        if not self:is_colliding(BLOCK, x + dx * d, y + dy * d) then
            self.x, self.y = x + dx * (d - speed), y + dy * (d - speed)
            return
        end
    end
end

Hook.add_pre(BOLT_STEP, function(self)
    local huntress = V.owner(self)
    if not huntress then return end
    local arrow = Instance.get_data(self, "strafe", NS)

    if arrow.full_speed then
        if self.speed == arrow.short_speed then self.speed = arrow.full_speed end
        arrow.full_speed, arrow.short_speed = nil, nil
    end

    if not arrow.aimed then
        arrow.aimed = true
        local angle = Cursor.angle(huntress, self.x, self.y)
        if angle then
            local direction = self.direction
            local side      = math.cos(math.rad(direction)) >= 0 and 0 or 180
            self.direction  = direction + Aim.turn(CONE, side, angle)
        end
    end

    local target = H.mark_of(huntress)
    if target and not arrow.homing
        and box_distance(target, self.x, self.y) <= C.homing_radius then
        arrow.homing = true
    end
    if target and arrow.homing then steer(self, arrow, target) end

    tunnel(self)
end)

local pending = nil

Hook.add_pre(BOLT_COLLISION, function(self, other)
    pending = nil
    if not other or not Instance.exists(other) then return end
    if Util.bool(gm.object_is_ancestor(other.object_index, HITBOX)) then return end
    local hit = other

    local huntress = V.owner(self)
    if not huntress then return end

    local mark = H.mark_of(huntress)
    if mark and hit.id ~= mark.id then return false end

    if Util.bool(self.local_client_is_authority) then
        pending = {
            huntress = huntress.id,
            target   = hit.id,
            coeff    = self.damage_coeff,
            climb    = self.climb,
        }
    end
end)

Hook.add_post(gm.constants.fire_direct, function(self, other, result, args)
    local p = pending
    if not p or p.attack or not self or self.id ~= p.huntress then return end
    p.attack = result.value
end)

local function ricochet(huntress, target, coeff, climb)
    local tx, ty = center(target)
    local next_target = nearest_enemy(huntress.team, tx, ty, C.ricochet, target)
    if not next_target then return end

    local nx, ny = center(next_target)
    local info = GM.SO.fire_direct(huntress, huntress, 0, nx, ny,
        gm.point_direction(tx, ty, nx, ny), coeff, SPARKS, next_target)
    local attack = AttackInfo.wrap(info)
    attack.climb = climb
    attack:set_critical(true)

    H.traces[#H.traces + 1] = { tx, ty, nx, ny, Global._current_frame }
end

local function count_hit(huntress, target, attack_info, coeff, climb)
    local streaks = Instance.get_data(huntress, "streaks", NS)
    local now = Global._current_frame

    for id, streak in pairs(streaks) do
        if now < streak.frame or now - streak.frame > C.streak_reset then streaks[id] = nil end
    end

    local streak = streaks[target.id] or { count = 0 }
    streak.count = streak.count + 1
    streak.frame = now
    streaks[target.id] = streak
    if streak.count < 3 then return end

    streaks[target.id] = nil
    AttackInfo.wrap(attack_info):set_critical(true)
    ricochet(huntress, target, coeff, climb)
end

Hook.add_post(BOLT_COLLISION, function(self, other)
    local p = pending
    pending = nil
    if not p or not p.attack then return end

    local huntress = alive(p.huntress)
    local target   = alive(p.target)
    if not huntress or not target then return end

    count_hit(huntress, target, p.attack, p.coeff, p.climb)
end)

PSE.Huntress = H
