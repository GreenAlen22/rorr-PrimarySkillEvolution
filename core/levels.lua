-- Уровень навыка в Skills++, если он установлен. От него растут магазин и окно стрелков, выносливость и ярость ближников.

PSE = PSE or {}

local SKILLS = "GreenAlen22-SkillPlusPlus"

local L = {}

local warned = false

function L.of(actor, skill)
    local mod = mods[SKILLS]
    if mod == nil then return 0 end
    local rank = rawget(mod.api, "rank")
    if not rank then
        if not warned then
            warned = true
            log.warning("PrimarySkillEvolution: Skills++ is loaded but its API has no rank; its levels are left out")
        end
        return 0
    end
    return rank(actor, skill)
end

PSE.Levels = L
