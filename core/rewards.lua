-- Баффы, которые ставит только хост. Клиент просит их пакетом.

PSE = PSE or {}

local NAMES = {
    "perfectReload", "steadyHand", "sharpCleaver",
    "secondWind", "breathless", "breathlessEnd",
    "rage",
}

local index_of = {}
for i, name in ipairs(NAMES) do index_of[name] = i end

local handlers = {}

local R = {}

function R.define(name, apply)
    local index = index_of[name]
    if not index then error("reward "..name.." is not listed in core/rewards.lua") end
    handlers[index] = apply
end

function R.refresh(actor, buff, duration)
    if actor:buff_count(buff) > 0 then
        actor:buff_set_time(buff, duration)
    else
        actor:buff_apply(buff, duration)
    end
end

function R.grant(actor, name)
    local index = index_of[name]
    local apply = index and handlers[index]
    if not apply then error("reward "..name.." has no handler") end

    if Net.host then
        apply(actor)
    else
        PSE.Net.reward:send_to_host(index)
    end
end

function R.receive(player, index)
    local apply = handlers[index]
    if apply then apply(player) end
end

PSE.Rewards = R
