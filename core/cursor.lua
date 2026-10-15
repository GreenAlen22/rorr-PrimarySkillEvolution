-- Куда целится мышью каждый игрок. Владелец рассылает угол прицела остальным машинам.

PSE = PSE or {}

local C     = PSE.Config.cursor_share
local NS    = PSE.Config.namespace
local Prefs = PSE.Prefs

local CU = {}

function CU.enabled(player)
    return Prefs.rule("aim") and Util.bool(gm.player_util_get_use_mouse_aim(player.value))
end

function CU.local_angle(x, y)
    return gm.point_direction(x, y, Global.mouse_x, Global.mouse_y)
end

function CU.local_distance(x, y)
    return gm.point_distance(x, y, Global.mouse_x, Global.mouse_y)
end

local function shared(player)
    return Instance.get_data(player, "cursor", NS)
end

function CU.share(player)
    if not Net.online then return end
    if Global._current_frame % C.every ~= 0 then return end

    local enabled  = CU.enabled(player)
    local angle    = enabled and CU.local_angle(player.x, player.y) or 0
    local distance = enabled and CU.local_distance(player.x, player.y) or 0

    local sent = shared(player)
    if enabled == sent.enabled
        and (not enabled
            or (math.abs(gm.angle_difference(angle, sent.angle)) < C.min_change
                and math.abs(distance - sent.distance) < C.min_distance)) then
        return
    end

    sent.enabled  = enabled
    sent.angle    = angle
    sent.distance = distance
    PSE.Net.aim:send_to_all(player, enabled, angle, distance)
end

function CU.receive(player, enabled, angle, distance)
    if not Instance.exists(player) or Util.bool(player.is_local) then return end
    local data = shared(player)
    data.enabled  = enabled
    data.angle    = angle
    data.distance = distance
end

function CU.angle(player, x, y)
    if Util.bool(player.is_local) then
        if not CU.enabled(player) then return nil end
        return CU.local_angle(x, y)
    end
    local data = shared(player)
    return data.enabled and data.angle or nil
end

function CU.target(player)
    if Util.bool(player.is_local) then
        if not CU.enabled(player) then return nil end
        return CU.local_angle(player.x, player.y), CU.local_distance(player.x, player.y)
    end
    local data = shared(player)
    if not data.enabled then return nil end
    return data.angle, data.distance
end

PSE.Cursor = CU
