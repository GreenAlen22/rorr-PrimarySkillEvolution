-- Все числа баланса в одном месте.

PSE = PSE or {}

local FPS = 60

PSE.Config = {

    namespace = "PrimarySkillEvolution",

    fps = FPS,

    gunners = {
        commandoZ  = { magazine = 16, reload = 1.2 * FPS },
        banditZ    = { magazine = 8,  reload = 1.3 * FPS },
        enforcerZ  = { magazine = 5,  reload = 1.8 * FPS },
        pilotZ     = { magazine = 9,  reload = 1.4 * FPS },
        pilotZ2    = { magazine = 30, reload = 1.6 * FPS },
        robomandoZ = { magazine = 10, reload = 1.2 * FPS },
        engineerZ  = { magazine = 4,  reload = 1.5 * FPS },
        engineerZ2 = { magazine = 16, reload = 1.6 * FPS },
        huntressZ2 = { magazine = 4,  reload = 1.5 * FPS },
    },

    aim_cone = {
        commandoZ  = 35,
        banditZ    = 25,
        enforcerZ  = 20,
        enforcerZ2 = 40,
        pilotZ     = 35,
        pilotZ2    = 30,
        robomandoZ = 30,
        sniperZ    = 85,
        huntressZ  = 25,
        artiZ      = 30,
    },

    cursor_share = {
        every        = 6,
        min_change   = 1,
        min_distance = 4,
    },

    window = {
        width      = 0.20,
        min_frames = 8,
    },

    miss_refill = 0.5,

    skill_levels = {
        magazine   = 0.10,
        window     = 0.02,
        window_max = 0.40,
    },

    perfect_reload = {
        duration     = 7 * FPS,
        attack_speed = 0.25,
        move_speed   = 1.10,
        lifesteal    = 0.04,
    },

    action_key = 82,

    options = {
        rules = {
            magazine      = true,
            perfectReload = true,
            aim           = true,
            chargeWindow  = true,
            chefCatch     = true,
            stamina       = true,
            finisher      = true,
            lungeLauncher = true,
        },
        hud = {
            preset   = "topRight",
            x        = 0.5,
            y        = 0.15,
            series   = true,
            screenFx = true,
            barAtCursor = false,
        },
        presets = {
            topRight    = { right = 104, top = 30 },
            topLeft     = { left = 150, top = 30 },
            bottomRight = { right = 16, bottom = 100 },
            bottomLeft  = { left = 16, bottom = 100 },
        },
    },

    melee = {
        stamina = {
            acridZ     = 10,
            acridZ2    = 10,
            handZ      = 5,
            minerZ     = 10,
            minerZ2    = 10,
            mercenaryZ = 14,
            loaderZ    = 12,
            loaderZ2   = 4,
            drifterZ   = 9,
            banditZ2   = 6,
            sniperZ2   = 5,
            chefZ2     = 8,
        },
        skill_levels = {
            stamina = 0.10,
            rage    = 0.10,
        },
        regen_delay = 2 * FPS,
        regen_time  = 1.5 * FPS,
        low = 1 / 3,
        window_bar = 1.2 * FPS,
        overflow = 1.5,

        breathless = {
            damage       = 0.5,
            duration     = 30 * FPS,
        },

        second_wind = {
            armor    = 20,
            duration = 7 * FPS,
        },

        finisher = {
            strikes = 30,
            damage  = 5,
            width   = 240,
            height  = 112,
            stun    = 1,
            knockup = 6,
        },

        rage = {
            duration  = 8 * FPS,
            damage    = 1.35,
            lifesteal = 0.10,
            modded = {
                damage       = 1.5,
                lifesteal    = 0.15,
                attack_speed = 0.20,
            },
        },

        signatures = {
            bandit = { stacks = 2, duration = 15 * FPS },
            hand = { drones = 6 },
            miner = { picks = 10, width = 240, height = 200, damage = 2 },
            sniper = { marks = 6, reach = 600, duration = 8 * FPS },
            acrid = { reach = 600 },
            mercenary = {
                slashes      = 8,
                first_slash  = 12,
                slash_every  = 6,
                shatter      = 66,
                length       = 110,
                slash_damage = 0.75,
                final_damage = 3,
                stun         = 2,
            },
            loader = { damage = 10, knockup = 22, width = 480, height = 200, stun = 1 },
            chef = {},
            drifter = { items = 4 },
        },

        lunge = {
            distance = 150,
            frames   = 12,
            cooldown = 1.5 * FPS,
            guard    = 20,
            damage_of = {
                loaderZ2 = 1,
            },
        },

        launcher = {
            damage   = 1,
            width    = 160,
            height   = 64,
            knockup  = 9,
            stun     = 1.333,
            cooldown = 12 * FPS,
            sparks_scale = 2.5,
        },

        strike_reach = 160,

        kill_window = 1 * FPS,

        series = {
            thresholds  = { 4, 10, 20, 35, 55, 80, 110 },
            strike      = 1,
            skill       = 1,
            lunge       = 2,
            launcher    = 2,
            finisher    = 3,
            weight_floor = 0.5,
            weight       = 5,
            weight_cap   = 2.5,
            crit         = 1.5,
            kill          = 3,
            streak_window = 2 * FPS,
            streak_step   = 2,
            streak_cap    = 5,
            repeats     = 8,
            repeat_mult = 0.6,
            decay_delay = 2 * FPS,
            decay_step  = 1.5 * FPS,
            hurt_heavy  = 0.2,
        },
    },

    charge_window = {
        width = 0.20,
        to    = 0.85,
        pierce_scale = 2,
    },

    steady_hand = {
        duration     = 7 * FPS,
        attack_speed = 0.30,
    },

    chef = {
        window   = 14,
        grace    = 8,
        cooldown = 3 * FPS,
        damage   = 1.5,
        speed    = 1.25,
        duration = 10 * FPS,
    },

    chakram = {
        min_distance = 30,
        max_distance = 320,
        ring = {
            count    = 4,
            radius   = 40,
            spin     = 4,
            duration = 4 * FPS,
            cooldown = 12 * FPS,
        },
    },

    huntress_mark = {
        reach        = 120,
        streak_reset = 2 * FPS,
        ricochet     = 150,
        homing_radius = 300,
        turn_rate     = 8,
        wall_pass    = 5 * 16,
    },

    sounds = {
        start    = { "wSniperReload", 1.0, 1.0 },
        perfect  = { "wReload",       1.0, 1.0 },
        miss     = { "wClick",        1.0, 1.0 },
        finish   = { "wReload",       0.4, 1.0 },
        cue      = { "wCrit2",        1.0, 1.5 },
        lunge    = { "wMinerShoot2",  1.0, 1.45 },
        launcher = { "wLizardR_DiveImpact", 1.0, 1.0 },
        slash    = { "wMercenary_Parry_SuccessfulSlash", 0.8, 1.2 },
        shatter  = { "wMercenary_Parry_Release", 1.0, 0.7 },
    },
}
