-- Консольные команды pse_*.

PSE = PSE or {}

local function say(msg)
    Console.print("[pse] "..msg)
end

local function role()
    if Net.client then return "client" end
    if Net.online then return "host" end
    return "offline"
end

local function local_player()
    local p = Player.get_local()
    if not Instance.exists(p) or p.object_index ~= gm.constants.oP then
        say("no local player - start a run first")
        return nil
    end
    return p
end

Console.new{
    "pse_status",
    {
        "Prints whether Primary Skill Evolution loaded in full, this machine's "
        .."network role, which language table answered, whether the sprites "
        .."loaded, the rules in force and whose they are, the HUD settings "
        .."and, in a run, whether shots aim at the cursor.",
    },
    function(args)
        local boot = PSE.Boot
        if boot then
            say(string.format("modules %d/%d, missing: %s", boot.loaded, boot.total, boot.missing))
        else
            say("no boot report - main.lua did not reach the end of loading")
        end

        say("role: "..role())

        say("language: "..tostring(gm.translate("PrimarySkillEvolution.languageCheck")))

        local failed = PSE.Assets.failed
        say("sprites: "..(#failed == 0 and "all loaded" or "FAILED "..table.concat(failed, "; ")))

        local Prefs = PSE.Prefs
        local rules = {}
        for _, name in ipairs(Prefs.RULES) do
            rules[#rules + 1] = name.." "..(Prefs.rule(name) and "on" or "off")
        end
        say("rules ("..Prefs.source().."): "..table.concat(rules, ", "))
        say(string.format("hud: preset %s (x %d%%, y %d%%), series %s, screen fx %s, bar at cursor %s",
            Prefs.hud("preset"),
            math.floor(Prefs.hud("x") * 100 + 0.5), math.floor(Prefs.hud("y") * 100 + 0.5),
            Prefs.hud("series") and "on" or "off", Prefs.hud("screenFx") and "on" or "off",
            Prefs.hud("barAtCursor") and "on" or "off"))

        local p = Player.get_local()
        if Instance.exists(p) and p.object_index == gm.constants.oP then
            say("aim at cursor: "..(PSE.Aim.enabled(p) and "on" or "off"))
        end
    end
}

Console.new{
    "pse_ammo [count]",
    {
        "Prints the local player's magazine. With a count, sets it; 0 starts a reload.",
        {"[count]", "number", "Rounds to leave in the magazine."},
    },
    function(args)
        local p = local_player()
        if not p then return end

        if PSE.Sniper.holds(p) then
            local left = PSE.Sniper.cooldown(p)
            say("Snipe: vanilla reload, Perfect Reload "
                ..(left > 0 and string.format("pays again in %.1f s", left / PSE.Config.fps) or "ready"))
            return
        end

        local data = PSE.Magazine.get(p)
        if not data then
            say("no magazine: not a gunner, a gunner with the vanilla reload, or the magazine rule is off")
            return
        end

        local magazine = PSE.Magazine.size(p, data)
        if args[1] ~= nil then
            data.ammo = math.max(0, math.min(magazine, math.floor(tonumber(args[1]) or 0)))
            if data.ammo == 0 then PSE.Reload.start(p, data) end
        end

        local reload = data.reload
        say(string.format("%s: %d/%d (Skills++ level %d, window %d%%), %s, window %s",
            data.entry.name, data.ammo, magazine, PSE.Levels.of(p, data.entry.skill),
            math.floor(PSE.Reload.width(p, data) * 100 + 0.5),
            reload and string.format("reloading %d%%%s%s", math.floor(reload.progress * 100),
                reload.window and "" or " (no window)",
                reload.missed and ", missed" or "")
            or "not reloading",
            data.window_cooldown > 0 and string.format("back in %.1f s", data.window_cooldown / PSE.Config.fps)
            or "ready"))
    end
}

Console.new{
    "pse_perfect",
    {
        "Grants Perfect Reload to the local player through the same path a hit window takes.",
    },
    function(args)
        local p = local_player()
        if not p then return end
        PSE.PerfectReload.grant(p)
        say("perfect reload requested ("..role()..")")
    end
}

Console.new{
    "pse_mark",
    {
        "Prints the mark every Strafe Huntress in the run has on this machine.",
    },
    function(args)
        local count = 0
        for _, p in ipairs(Instance.find_all(gm.constants.oP)) do
            if PSE.Huntress.is_strafe(p) then
                count = count + 1
                local target = PSE.Huntress.mark_of(p)
                say(string.format("huntress m_id %d%s: %s", math.floor(p.m_id),
                    Util.bool(p.is_local) and " (local)" or "",
                    target and string.format("%s, id %d", gm.object_get_name(target.object_index), target.id)
                    or "no mark"))
            end
        end
        if count == 0 then say("no Strafe Huntress in the run") end
    end
}

Console.new{
    "pse_melee [low|full|rank]",
    {
        "Prints the local player's stamina, finisher, series and hit-count links. low: one strike left; full: finisher fires; rank: series at S.",
        {"[low|full|rank]", "string", "What to set first."},
    },
    function(args)
        local p = local_player()
        if not p then return end

        local stamina = PSE.Stamina.data(p)
        if not stamina then
            say("no stamina: the primary is not a melee strike")
            return
        end
        if args[1] == "low"  then stamina.value = 1 end
        if args[1] == "full" then PSE.Finisher.data(p).charge = PSE.Config.melee.finisher.strikes end
        if args[1] == "rank" then PSE.Series.add(p, PSE.Config.melee.series.thresholds[5]) end

        local entry = stamina.entry
        local window
        if stamina.window then
            window = "running"
        elseif stamina.cooldown > 0 then
            window = string.format("back in %.1f s", stamina.cooldown / PSE.Config.fps)
        else
            window = "ready"
        end
        say(string.format("%s (%s, Skills++ level %d): stamina %.1f/%.1f%s, window %s, finisher %d/%d%s (rage %.1f s), series %s",
            entry.name, entry.hero, PSE.Levels.of(p, entry.skill),
            stamina.value, PSE.Stamina.capacity(p, entry),
            stamina.breathless and " (breathless)" or "",
            window, PSE.Finisher.data(p).charge, PSE.Config.melee.finisher.strikes,
            PSE.Finisher.raging(p) and ", rage" or "",
            PSE.Rage.duration(p) / PSE.Config.fps,
            PSE.Series.LETTERS[PSE.Series.rank(p)] or "-"))

        local c = PSE.Strikes.counters
        say(string.format("hit count: strikes %d, attacks claimed %d, stepped %d, "
            .."handle-end %d, posthit %d, hits %d",
            c.strikes, c.claimed, c.steps, c.handled, c.posthit, c.hits))
        say(string.format("hits seen: %d (target read %d, owner from parent %d), deaths %d, kills %d",
            c.damage, c.targets, c.by_parent, c.deaths, c.kills))
    end
}

local CANDIDATES = {
    cue = {
        { "wCrit2",                     1.0, 1.5 },
        { "wSniperScan",                1.0, 1.0 },
    },
    lunge = {
        { "wMinerShoot2",               1.0, 1.45 },
        { "wMercenary_EviscerateWhiff", 1.0, 1.0 },
    },
    launcher = {
        { "wLizardR_DiveImpact",        1.0, 1.0 },
        { "wGolemAttack1",              1.0, 1.2 },
    },
    slash = {
        { "wMercenary_Parry_SuccessfulSlash", 0.8, 1.2 },
        { "wMercenaryShoot1_3",               0.8, 1.3 },
    },
    shatter = {
        { "wMercenary_Parry_Release",      1.0, 0.7 },
        { "wMercenary_EviscerateActivate", 1.0, 0.8 },
    },
}

local EVENTS = "cue, lunge, launcher, slash or shatter"

Console.new{
    "pse_sound <event> [n]",
    {
        "Plays sound candidate n for an event and makes it that event's sound until restart. Events: "..EVENTS..".",
        {"<event>", "string", EVENTS.."."},
        {"[n]",     "number", "Candidate to play and use, 1 by default."},
    },
    function(args)
        local list = CANDIDATES[args[1] or ""]
        if not list then
            say("no event "..tostring(args[1]).." - "..EVENTS)
            return
        end
        local n = math.floor(tonumber(args[2]) or 1)
        local c = list[n]
        if not c then
            say(string.format("%s has candidates 1 to %d", args[1], #list))
            return
        end
        PSE.Assets.sounds[args[1]] = {
            sound = Sound.wrap(PSE.Vanilla.constant(c[1])), volume = c[2], pitch = c[3],
        }
        local p = local_player()
        if p then PSE.Assets.play(args[1], p) end
        say(string.format("%s %d: %s at pitch %.2f", args[1], n, c[1], c[3]))
    end
}

PSE.Debug = true
