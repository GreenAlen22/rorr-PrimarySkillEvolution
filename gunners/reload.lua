-- Перезарядка: таймер, полоска и окно удачи на клавише Action.

PSE = PSE or {}

local C        = PSE.Config
local Assets   = PSE.Assets
local Magazine = PSE.Magazine

local SLOT     = Skill.Slot.PRIMARY
local PRIORITY = Skill.OverridePriority.RELOAD

local R = {}

R.skill = Skill.new("reload")
R.skill.sprite            = Assets.reload_icon.sprite
R.skill.subimage          = Assets.reload_icon.subimage
R.skill.cooldown          = 0
R.skill.is_primary        = true
R.skill.require_key_press = true
R.skill.disable_aim_stall = true
R.skill.token_name        = C.namespace..".reloadSkill.name"
R.skill.token_description = C.namespace..".reloadSkill.description"

function R.frames(actor, data)
    return data.entry.tuning.reload / math.max(actor.attack_speed, 0.01)
end

function R.window(frames)
    local width = math.min(1, math.max(C.window.width, C.window.min_frames / frames))
    return 0.5 - width / 2, 0.5 + width / 2
end

function R.start(actor, data)
    if data.reload then return end
    data.reload = {
        progress  = 0,
        attempted = false,
        missed    = false,
        window    = data.window_cooldown <= 0,
    }
    actor:add_skill_override(SLOT, R.skill, PRIORITY)
    Assets.play("start", actor)
end

local function finish(actor, data, full)
    local magazine = data.entry.tuning.magazine
    if full then
        data.ammo = magazine
    else
        data.ammo = data.ammo + math.ceil((magazine - data.ammo) * C.miss_refill)
    end
    data.reload = nil
    actor:remove_skill_override(SLOT, R.skill, PRIORITY)
end

function R.reset(actor)
    local data = Magazine.get(actor)
    if not data then return end
    if data.reload then actor:remove_skill_override(SLOT, R.skill, PRIORITY) end
    data.reload = nil
    data.ammo   = data.entry.tuning.magazine
end

Callback.add(Callback.ON_PLAYER_STEP, function(player)
    if not Util.bool(player.is_local) then return end

    local data = Magazine.get(player)
    if not data then return end

    if data.window_cooldown > 0 then data.window_cooldown = data.window_cooldown - 1 end

    local pressed = Util.bool(player:control(PSE.Options.action.verb, 1))
    local reload  = data.reload

    if not reload then
        if pressed and data.ammo < data.entry.tuning.magazine then R.start(player, data) end
        return
    end

    local frames = R.frames(player, data)

    if pressed and reload.window and not reload.attempted then
        reload.attempted = true
        local from, to = R.window(frames)
        if reload.progress >= from and reload.progress <= to then
            finish(player, data, true)
            data.window_cooldown = C.perfect_reload.duration
            Assets.play("perfect", player)
            PSE.PerfectReload.grant(player)
            return
        end
        reload.missed = true
        data.window_cooldown = C.perfect_reload.duration
        Assets.play("miss", player)
    end

    reload.progress = reload.progress + 1 / frames
    if reload.progress >= 1 then
        finish(player, data, not reload.missed)
        Assets.play("finish", player)
    end
end)

Callback.add(Callback.ON_STAGE_START, function()
    for _, player in ipairs(Instance.find_all(gm.constants.oP)) do
        if Util.bool(player.is_local) then R.reset(player) end
    end
end)

Callback.add(Callback.ON_PLAYER_DEATH, function(player)
    if Util.bool(player.is_local) then R.reset(player) end
end)

PSE.Reload = R
