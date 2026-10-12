-- Осколочная граната Энфорсера летит к курсору. Её создаёт хост, поэтому прицел клиента идёт к хосту.

PSE = PSE or {}

local V      = PSE.Vanilla
local Roster = PSE.Roster
local Aim    = PSE.Aim
local Cursor = PSE.Cursor

local GRENADE     = V.constant("oEnforcerGrenadePrimary")
local THROW_STATE = V.state("enforcerZ2")

local SPAWN_DY = -6
local CLAIM_RADIUS = 32

local G = {}

Callback.add(Callback.ON_PLAYER_STEP, function(player)
    if not Util.bool(player.is_local) then return end
    local entry = Roster.of(player)
    if entry and entry.grenade then Cursor.share(player) end
end)

Hook.add_pre(gm.constants.sound_play, function(self, other, result, args)
    if Net.client then return end
    if not self or self.actor_state_current_id ~= THROW_STATE then return end
    if self.object_index ~= gm.constants.oP then return end

    local entry = Roster.of(self)
    if not entry or not entry.grenade then return end

    local x, y  = self.x, self.y + SPAWN_DY
    local angle = Cursor.angle(self, x, y)
    for _, grenade in ipairs(V.claim(GRENADE, self, x, y, CLAIM_RADIUS)) do
        if angle then
            local direction = grenade.direction
            local side      = math.cos(math.rad(direction)) >= 0 and 0 or 180
            grenade.direction = direction + Aim.turn(entry.cone, side, angle)
        end
    end
end)

PSE.Grenade = G
