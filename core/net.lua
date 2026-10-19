-- Сетевые пакеты. Создаются все сразу при загрузке: номер пакета зависит от порядка создания.

PSE = PSE or {}

local N = {}

N.reward = Packet.new("reward")
N.reward:set_serializers(
    function(buffer, index)
        buffer:write_byte(index)
    end,
    function(buffer, player)
        local index = buffer:read_byte()
        if not Net.host then return end
        if not player or not Instance.exists(player) then return end
        PSE.Rewards.receive(player, index)
    end
)

N.aim = Packet.new("aim")
N.aim:set_serializers(
    function(buffer, player, enabled, angle, distance)
        buffer:write_instance(player)
        buffer:write_bool(enabled)
        buffer:write_float(angle)
        buffer:write_float(distance)
    end,
    function(buffer, _)
        local player   = buffer:read_instance()
        local enabled  = buffer:read_bool()
        local angle    = buffer:read_float()
        local distance = buffer:read_float()
        PSE.Cursor.receive(player, enabled, angle, distance)
    end
)

N.chakram_ring = Packet.new("chakramRing")
N.chakram_ring:set_serializers(
    function(buffer, player)
        buffer:write_instance(player)
    end,
    function(buffer, _)
        local player = buffer:read_instance()
        PSE.Chakram.receive_ring(player)
    end
)

N.lunge = Packet.new("lunge")
N.lunge:set_serializers(
    function(buffer, player, angle)
        buffer:write_instance(player)
        buffer:write_float(angle)
    end,
    function(buffer, _)
        local player = buffer:read_instance()
        local angle  = buffer:read_float()
        PSE.Lunge.receive(player, angle)
    end
)

N.huntress_mark = Packet.new("huntressMark")
N.huntress_mark:set_serializers(
    function(buffer, huntress, target)
        buffer:write_instance(huntress)
        buffer:write_instance(target)
    end,
    function(buffer, _)
        local huntress = buffer:read_instance()
        local target   = buffer:read_instance()
        PSE.Huntress.receive_mark(huntress, target)
    end
)

N.signature = Packet.new("signature")
N.signature:set_serializers(
    function(buffer, player, hero, targets)
        buffer:write_instance(player)
        buffer:write_byte(hero)
        buffer:write_byte(#targets)
        for _, target in ipairs(targets) do buffer:write_instance(target) end
    end,
    function(buffer, _)
        local player  = buffer:read_instance()
        local hero    = buffer:read_byte()
        local targets = {}
        for i = 1, buffer:read_byte() do targets[i] = buffer:read_instance() end
        PSE.Signatures.receive(player, hero, targets)
    end
)

N.rules = Packet.new("rules")
N.rules:set_serializers(
    function(buffer, mask)
        buffer:write_byte(mask)
    end,
    function(buffer, _)
        local mask = buffer:read_byte()
        if Net.host then return end
        PSE.Prefs.receive(mask)
    end
)

N.rules_ask = Packet.new("rulesAsk")
N.rules_ask:set_serializers(
    function() end,
    function()
        if not Net.host then return end
        PSE.Prefs.broadcast()
    end
)

N.pick_hit = Packet.new("pickHit")
N.pick_hit:set_serializers(
    function(buffer, player)
        buffer:write_instance(player)
    end,
    function(buffer, _)
        local player = buffer:read_instance()
        if Net.host then return end
        PSE.Strikes.receive_thrown_hit(player)
    end
)

N.strike_hit = Packet.new("strikeHit")
N.strike_hit:set_serializers(
    function(buffer, player, hits)
        buffer:write_instance(player)
        buffer:write_byte(hits)
    end,
    function(buffer, _)
        local player = buffer:read_instance()
        local hits   = buffer:read_byte()
        if Net.host then return end
        PSE.Strikes.receive_strike_hit(player, hits)
    end
)

N.rage_strike = Packet.new("rageStrike")
N.rage_strike:set_serializers(
    function(buffer, player)
        buffer:write_instance(player)
    end,
    function(buffer, _)
        local player = buffer:read_instance()
        PSE.Finisher.receive_strike(player)
    end
)

PSE.Net = N
