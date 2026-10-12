-- Артифисер: чакрам летит к курсору, Action ставит кольцо горящих чакрамов.

PSE = PSE or {}

local C      = PSE.Config.chakram
local CONE   = PSE.Config.aim_cone.artiZ
local NS     = PSE.Config.namespace
local V      = PSE.Vanilla
local Aim    = PSE.Aim
local Cursor = PSE.Cursor
local Assets = PSE.Assets

local CHAKRAMS = V.skill("artiZ").value
local CHAKRAM  = V.constant("oArtiChakram")
local BURNING  = V.constant("sArtiWheel2")
local THROW    = V.state("artiZ")

local CLAIM_RADIUS = 120
local HANGING = 1
local REWIND_AT = 10

local R = PSE.Config.chakram.ring

if not CONE then error("no aim cone for artiZ in core/config.lua") end
Aim.register_cone(CHAKRAMS, CONE)

local K = {}

function K.is_chakrams(player)
    return player:get_default_skill(Skill.Slot.PRIMARY).skill_id == CHAKRAMS
end

local function point(artificer)
    local angle, distance = Cursor.target(artificer)
    if not angle then return nil end

    local side = artificer.image_xscale >= 0 and 0 or 180
    angle    = side + Aim.turn(CONE, side, angle)
    distance = math.max(C.min_distance, math.min(C.max_distance, distance))
    return artificer.x + gm.lengthdir_x(distance, angle),
        artificer.y + gm.lengthdir_y(distance, angle),
        angle
end

Callback.add(ActorState.wrap(THROW).on_step, function(actor, _)
    local chakrams = V.claim(CHAKRAM, actor, actor.x, actor.y, CLAIM_RADIUS)
    if #chakrams == 0 then return end

    local x, y, angle = point(actor)
    if not x then return end

    for i, chakram in ipairs(chakrams) do
        chakram.tX = x
        chakram.tY = y + (i - 1) * 18
        chakram.direction = angle
    end
end)

Callback.add(Callback.ON_PLAYER_STEP, function(player)
    if Util.bool(player.is_local) and K.is_chakrams(player) then Cursor.share(player) end
end)

local function data_of(player)
    return Instance.get_data(player, "chakram", NS)
end

function K.ring_cooldown(player)
    return data_of(player).cooldown or 0
end

local function make_ring(artificer)
    local ring = Instance.get_data(artificer, "ring", NS)
    ring.start = Global._current_frame
    ring.ids   = {}

    local coeff = artificer:get_default_skill(Skill.Slot.PRIMARY).skill_id == CHAKRAMS
        and Skill.wrap(CHAKRAMS).damage or 1
    for i = 1, R.count do
        local chakram = Instance.create(artificer.x, artificer.y, CHAKRAM)
        chakram.parent       = artificer
        chakram.team         = artificer.team
        chakram.damage_coeff = coeff
        chakram.shadow       = true
        chakram.state        = HANGING
        chakram.sprite_index = BURNING
        chakram.image_index  = 0
        chakram.image_speed  = math.min(0.3 * artificer.attack_speed, 1)
        chakram.image_angle  = 0
        Instance.get_data(chakram, "owner", NS).id = artificer.id
        ring.ids[i] = chakram.id
    end
end

Callback.add(Callback.ON_PLAYER_STEP, function(player)
    local ring = Instance.get_data(player, "ring", NS)
    if not ring.ids then return end

    local now = Global._current_frame
    local over = now < ring.start or now - ring.start >= R.duration
    local count = #ring.ids
    for i, id in ipairs(ring.ids) do
        if Instance.exists(id) then
            local chakram = Instance.wrap(id)
            if over then
                chakram:destroy()
            else
                local angle = (now - ring.start) * R.spin + (i - 1) * 360 / count
                chakram.x = player.x + gm.lengthdir_x(R.radius, angle)
                chakram.y = player.y + gm.lengthdir_y(R.radius, angle)
                if chakram.state ~= HANGING then
                    chakram.state        = HANGING
                    chakram.sprite_index = BURNING
                end
                if math.floor(chakram.image_index) >= REWIND_AT then
                    chakram.image_index  = 0
                    chakram.activity_var1 = 0
                end
            end
        end
    end
    if over then ring.ids = nil end
end)

function K.receive_ring(artificer)
    if not Instance.exists(artificer) or Util.bool(artificer.is_local) then return end
    make_ring(artificer)
end

Callback.add(Callback.ON_PLAYER_STEP, function(player)
    if not Util.bool(player.is_local) or not K.is_chakrams(player) then return end

    local data = data_of(player)
    if (data.cooldown or 0) > 0 then
        data.cooldown = data.cooldown - 1
        return
    end
    if not Util.bool(player:control(PSE.Options.action.verb, 1)) then return end

    data.cooldown = R.cooldown
    make_ring(player)
    Assets.play("perfect", player)
    if Net.online then PSE.Net.chakram_ring:send_to_all(player) end
end)

PSE.Chakram = K
