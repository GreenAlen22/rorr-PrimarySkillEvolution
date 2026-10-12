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
