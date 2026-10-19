-- Выстрел стрелка летит к курсору, в пределах его конуса. Только с ванильным прицелом мышью.

PSE = PSE or {}

local Roster = PSE.Roster
local Cursor = PSE.Cursor

local ARG_X, ARG_Y, ARG_DIRECTION = 2, 3, 8

local A = {}

A.enabled      = Cursor.enabled
A.cursor_angle = Cursor.local_angle

local other_cones = {}

function A.register_cone(skill_id, cone)
    other_cones[skill_id] = cone
end

function A.cone_of(player)
    local entry = Roster.of(player)
    if entry then return entry.cone end
    return other_cones[player:get_default_skill(Skill.Slot.PRIMARY).skill_id]
end

function A.turn(cone, side, angle)
    local turn = gm.angle_difference(angle, side)
    return math.max(-cone, math.min(cone, turn))
end

function A.direction(player, x, y, side)
    local entry = Roster.of(player)
    if not entry or not entry.cone then return nil end
    local angle = Cursor.angle(player, x, y)
    if not angle then return nil end
    return side + A.turn(entry.cone, side, angle)
end

Hook.add_pre(gm.constants.fire_bullet, function(self, other, result, args)
    if not self or self.object_index ~= gm.constants.oP then return end

    local entry = Roster.firing_primary(self)
    local angle
    if entry then
        if not entry.cone or not A.enabled(self) then return end
        angle = A.cursor_angle(args[ARG_X].value, args[ARG_Y].value)
    else
        if Net.client then return end
        entry = Roster.of(self)
        if not entry or entry.aim ~= "host" or not Roster.in_states(self, entry) then return end
        angle = Cursor.angle(self, args[ARG_X].value, args[ARG_Y].value)
        if not angle then return end
    end

    local direction = args[ARG_DIRECTION].value
    local side      = math.cos(math.rad(direction)) >= 0 and 0 or 180
    args[ARG_DIRECTION].value = direction + A.turn(entry.cone, side, angle)
end)

Callback.add(Callback.ON_PLAYER_STEP, function(player)
    if not Util.bool(player.is_local) then return end
    local entry = Roster.of(player)
    if entry and entry.share_aim then Cursor.share(player) end
end)

PSE.Aim = A
