-- Primary Skill Evolution — переделка основной атаки выживших.
-- Загрузчик: модули грузятся строго по списку, порядок важен.
-- В конце проверяется, что каждый модуль завёл свою ветку в PSE.

mods["ReturnsAPI-ReturnsAPI"].auto{
    namespace = "PrimarySkillEvolution",
    mp        = true,
}

local PATH = _ENV["!plugins_mod_folder_path"].."\\"

local modules = {
    "core/config",
    "core/vanilla",

    "core/net",
    "core/rewards",

    "core/prefs",

    "core/levels",

    "core/cursor",

    "core/assets",

    "gunners/roster",
    "gunners/magazine",
    "gunners/reload",
    "gunners/perfect_reload",
    "gunners/sniper",
    "gunners/aim",
    "gunners/grenade",

    "special/charge",
    "special/huntress",
    "special/chef",
    "special/chakram",

    "melee/strikes",
    "melee/stamina",
    "melee/series",
    "melee/rage",
    "melee/judgement_cut",
    "melee/signatures",
    "melee/finisher",
    "melee/lunge",
    "melee/launcher",

    "ui/bar",
    "ui/ammo_hud",
    "ui/aim_reticle",
    "ui/charge_hud",
    "ui/mark_hud",
    "ui/trails",
    "ui/catch_hud",
    "ui/melee_hud",
    "ui/judgement_cut_fx",

    "settings/options",

    "settings/debug",
}

local function load(name)
    local file = (PATH..name..".lua"):gsub("/", "\\")

    local f = io.open(file, "r")
    if not f then
        log.warning("PrimarySkillEvolution: file not found -> "..file)
        return false
    end
    f:close()

    local ok, err = pcall(function() require(file) end)
    if not ok then
        log.warning("PrimarySkillEvolution: FAILED to load "..name.." -> "..tostring(err))
        return false
    end
    return true
end

local expected = {
    "Config", "Vanilla", "Net", "Rewards", "Prefs", "Levels", "Cursor", "Assets",
    "Roster", "Magazine", "Reload", "PerfectReload", "Sniper", "Aim", "Grenade",
    "Charge", "Huntress", "Chef", "Chakram",
    "Strikes", "Stamina", "Series", "Rage", "JudgementCut", "Signatures", "Finisher",
    "Lunge", "Launcher",
    "Bar", "AmmoHud", "AimReticle", "ChargeHud", "MarkHud", "Trails", "CatchHud", "MeleeHud",
    "JudgementCutFx",
    "Options", "Debug",
}

Initialize.add_hotloadable(Callback.Priority.BEFORE, function()
    PSE = PSE or {}

    local loaded = 0
    for _, name in ipairs(modules) do
        if load(name) then loaded = loaded + 1 end
    end

    local missing = {}
    for _, key in ipairs(expected) do
        if not PSE[key] then missing[#missing + 1] = key end
    end

    PSE.Boot = {
        loaded  = loaded,
        total   = #modules,
        missing = #missing > 0 and table.concat(missing, ", ") or "-",
    }

    if loaded == #modules and #missing == 0 then
        log.info("PrimarySkillEvolution: initialized ("..loaded.."/"..#modules.." modules)")
    else
        log.warning("PrimarySkillEvolution: initialized PARTIALLY ("..loaded.."/"..#modules
            .." modules; missing PSE: "..PSE.Boot.missing..")")
    end
end)
