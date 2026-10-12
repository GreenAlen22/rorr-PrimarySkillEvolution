-- Ванильный прицел, повёрнутый туда, куда реально полетит выстрел.

PSE = PSE or {}

local Aim = PSE.Aim

local SPRITE = gm.constants.sPlayerAiming
if not SPRITE then error("vanilla sprite sPlayerAiming not found") end

local DRAW_PRE  = gm.constants._player_aim_draw_pre
local DRAW_POST = gm.constants._player_aim_draw_post
if not DRAW_PRE or not DRAW_POST then error("vanilla _player_aim_draw_pre/_post not found") end

local enforcer_x3 = ActorState.find("enforcerX3", "ror")
if not enforcer_x3 then error("vanilla actor state ror-enforcerX3 not found") end
local ENFORCER_X3 = enforcer_x3.value

local LINE_W, LINE_H = 34, 4

local function turned(inst)
    if inst.object_index ~= gm.constants.oP or not Util.bool(inst.is_local) then return false end
    return Aim.cone_of(inst) ~= nil and Aim.enabled(inst)
end

local function rotate(dx, dy, angle)
    local r    = math.rad(angle)
    local c, s = math.cos(r), math.sin(r)
    return dx * c + dy * s, dy * c - dx * s
end

local function pivot(player)
    return player.ghost_x, player.ghost_y - 4 + player.aim_cursor_offs_y
end

local function reach(player)
    local idle = player.sprite_idle
    return 3 + gm.sprite_get_width(idle) - gm.sprite_get_xoffset(idle)
end

local function turn(player, dir)
    return Aim.turn(Aim.cone_of(player), dir == 1 and 0 or 180, Aim.cursor_angle(player.x, player.y))
end

Hook.add_pre(DRAW_PRE, function(self, other, result, args)
    if not self or not turned(self) then return end

    local aim = 0
    if Util.bool(args[1].value.show_aim_reticle) then
        local state = self.actor_state_current_id
        local hidden = Util.bool(gm.actor_state_is_climb_state(state))
            or (Util.bool(self.bunker) and state ~= ENFORCER_X3)
        if not hidden then aim = self.local_aim_dir end
    end

    if aim ~= self.aim_cursor_anim_dir then
        if aim ~= 0 then
            self.aim_cursor_anim_dir = aim
            self.aim_cursor_anim     = 0
        else
            self.aim_cursor_anim = self.aim_cursor_anim * 0.5
            if self.aim_cursor_anim < 0.1 then self.aim_cursor_anim_dir = 0 end
        end
    end

    if aim ~= 0 then
        for _ = 1, Util.bool(Global.__frameskip) and 2 or 1 do
            self.aim_cursor_anim = self.aim_cursor_anim + (1 - self.aim_cursor_anim) * 0.35
        end
    end

    local anim = self.aim_cursor_anim
    if anim ~= 0 and aim ~= 0 then
        local angle  = turn(self, aim)
        local px, py = pivot(self)
        local dx, dy = rotate(reach(self) * aim, -2, angle)
        local color  = gm.player_index_get_color(self.player_p_number, true)

        gm.draw_sprite_general(SPRITE, 0, 0, 0, LINE_W * anim, LINE_H,
            px + dx, py + dy, aim, 1, angle,
            color, color, color, color, 0.5 + anim * 0.5)
    end

    return false
end)

Hook.add_pre(DRAW_POST, function(self, other, result, args)
    if not self or not turned(self) then return end

    local anim = self.aim_cursor_anim
    local dir  = self.aim_cursor_anim_dir
    if anim ~= 0 and dir ~= 0
        and not Util.bool(gm.actor_state_is_climb_state(self.actor_state_current_id)) then
        local angle  = turn(self, dir)
        local px, py = pivot(self)
        local dx, dy = rotate((reach(self) - LINE_W * (1 - anim)) * dir, 0, angle)

        gm.draw_sprite_ext(SPRITE, 1, px + dx, py + dy, dir, 1, angle, Color.WHITE, 1)
    end

    return false
end)

PSE.AimReticle = true
