-- Строки мода на английском.

return {
    PrimarySkillEvolution = {
        languageCheck = "english",

        series = {
            rank1 = "Drizzle",
            rank2 = "Shower",
            rank3 = "Rainstorm",
            rank4 = "Thunderstorm",
            rank5 = "Monsoon",
            rank6 = "Typhoon",
            rank7 = "Deluge",
        },

        reloadSkill = {
            name        = "Reload",
            description = "Reloading. Press <y>Action</c> while the marker is inside the window for a <y>Perfect Reload</c>. After any try, hit or miss, the window is gone for <y>7</c> seconds.",
        },
    },

    ui = {
        options = {
            PrimarySkillEvolution = {
                header = "PRIMARY SKILL EVOLUTION",

                gunners = {
                    header           = "Gunners",
                    magazine         = "Magazine and reload",
                    ["magazine.desc"] = "Commando, Bandit, Enforcer, Pilot, Robomando and Engineer. When off, they shoot as in vanilla - no rounds to count, no reload. Online, the host's setting applies to everyone.",
                    perfectReload    = "Perfect Reload",
                    ["perfectReload.desc"] = "When off, a reload has no window to hit, and Sniper's perfect reload gives only its own bonus. Online, the host's setting applies to everyone.",
                    aim              = "Aim at cursor",
                    ["aim.desc"]     = "Primary shots fly toward the cursor - gunners, Snipe, Shrapnel Grenade, Strafe and Flame Chakrams. Needs the vanilla mouse aim option on. Online, the host's setting applies to everyone.",
                },

                special = {
                    header           = "Special primaries",
                    chargeWindow     = "Charge window",
                    ["chargeWindow.desc"] = "Huntress's Pierce and Loader's Bullet Punch. When off, they charge as in vanilla, with no window and no Steady Hand. Online, the host's setting applies to everyone.",
                    chefCatch        = "Cleaver catch",
                    ["chefCatch.desc"] = "CHEF's DICE. When off, the cleaver comes back as in vanilla. Online, the host's setting applies to everyone.",
                },

                melee = {
                    header           = "Melee",
                    stamina          = "Stamina",
                    ["stamina.desc"] = "When off, strikes spend nothing - no Breathless, no refill window, no Second Wind. Online, the host's setting applies to everyone.",
                    finisher         = "Finisher and Rage",
                    ["finisher.desc"] = "When off, the bar does not fill - no blow, no signature effect, no Rage. Online, the host's setting applies to everyone.",
                    lungeLauncher    = "Lunge and Launcher",
                    ["lungeLauncher.desc"] = "The Action key in the air and on the ground. When off, Action only catches the stamina window. Online, the host's setting applies to everyone.",
                },

                hud = {
                    header           = "Interface",
                    preset           = "Meters position",
                    ["preset.desc"]  = "Where the stamina and rage meters sit. The interface settings are yours alone, online too.",
                    presetChoice = {
                        topRight    = "Top right",
                        topLeft     = "Top left",
                        bottomRight = "Bottom right",
                        bottomLeft  = "Bottom left",
                        custom      = "Custom",
                    },
                    x                = "Custom position X",
                    ["x.desc"]       = "Only with the Custom position. 0% is the left edge, 100% the right.",
                    y                = "Custom position Y",
                    ["y.desc"]       = "Only with the Custom position. 0% is the top edge, 100% the bottom.",
                    series           = "Series rank",
                    ["series.desc"]  = "The D to SSS letter on the right of the screen.",
                    screenFx         = "Screen effects",
                    ["screenFx.desc"] = "Mercenary's darkened screen, cuts and shatter, and the mod's screen shake. Damage stays the same.",
                    barAtCursor      = "Reload bar at cursor",
                    ["barAtCursor.desc"] = "The reload bar, the stamina window and Pierce's charge are drawn as a ring around the cursor instead of a bar over the hero. Only with the vanilla mouse aim option on. Only on your screen: online, every player sets it for themselves.",
                },

                reset           = "Reset settings",
                ["reset.desc"]  = "Puts every setting on this page back to default. The Action key stays.",
            },
        },
    },

    control = {
        PrimarySkillEvolution = {
            action          = "Action",
            ["action.desc"] = "Gunners and Engineer: starts a reload, and pressed again inside the window, makes it perfect. Huntress: marks the enemy nearest the cursor. Artificer: a ring of burning chakrams around her. Melee: in the air, a lunge toward the cursor; on the ground, a blow that throws nearby enemies up and stuns them.",
        },
    },
}
