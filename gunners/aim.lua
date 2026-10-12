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

Hook.add_pre(gm.constants.fire_bullet, function(self, other, result, args)
    if not self then return end
    local entry = Roster.firing_primary(self)
    if not entry or not entry.cone or not A.enabled(self) then return end

    local direction = args[ARG_DIRECTION].value
    local side      = math.cos(math.rad(direction)) >= 0 and 0 or 180
    local cursor    = A.cursor_angle(args[ARG_X].value, args[ARG_Y].value)

    args[ARG_DIRECTION].value = direction + A.turn(entry.cone, side, cursor)
end)

PSE.Aim = A
