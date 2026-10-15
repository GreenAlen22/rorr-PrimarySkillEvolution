-- Страница мода в настройках игры: клавиша «Действие», выключатели механик, интерфейс и сброс. Значения хранит core/prefs.lua.

PSE = PSE or {}

local C = PSE.Config

local O = {}

O.page = ModOptions.new()

O.action = O.page:find("action") or O.page:add_keybind("action", C.action_key)

local GROUPS = {
    { "gunners", { "magazine", "perfectReload", "aim" } },
    { "special", { "chargeWindow", "chefCatch" } },
    { "melee",   { "stamina", "finisher", "lungeLauncher" } },
}

local PRESETS = { "topRight", "topLeft", "bottomRight", "bottomLeft", "custom" }

local on_page = {}
for _, group in ipairs(GROUPS) do
    for _, rule in ipairs(group[2]) do
        if on_page[rule] then error("options: rule "..rule.." is on the page twice") end
        on_page[rule] = true
    end
end
for _, rule in ipairs(PSE.Prefs.RULES) do
    if not on_page[rule] then error("options: rule "..rule.." is not on the page") end
    on_page[rule] = nil
end
if next(on_page) then error("options: rule "..next(on_page).." is not in core/prefs.lua") end

local in_dropdown = {}
for _, name in ipairs(PRESETS) do
    if name ~= "custom" and not C.options.presets[name] then
        error("options: preset "..name.." has no place in core/config.lua")
    end
    in_dropdown[name] = true
end
for name in pairs(C.options.presets) do
    if not in_dropdown[name] then error("options: preset "..name.." is not in the dropdown") end
end

local shown = {}

local function bind(id, kind, add, get, set)
    shown[id] = { kind = kind, get = get }
    local element = O.page:find(id)
    if element then return element, false end
    element = add(id)
    element:add_getter(get)
    element:add_setter(set)
    return element, true
end

local function checkbox(id, get, set)
    return bind(id, "toggle", function(i) return O.page:add_checkbox(i) end,
        get, function(value) set(Util.bool(value)) end)
end

for _, group in ipairs(GROUPS) do
    for _, rule in ipairs(group[2]) do
        checkbox(group[1].."."..rule,
            function() return PSE.Prefs.own_rule(rule) end,
            function(value) PSE.Prefs.set_rule(rule, value) end)
    end
end

local preset, new = bind("hud.preset", "dropdown",
    function(id) return O.page:add_dropdown(id) end,
    function()
        local name = PSE.Prefs.hud("preset")
        for i, p in ipairs(PRESETS) do
            if p == name then return i - 1 end
        end
        error("options: preset "..tostring(name).." is not in the dropdown")
    end,
    function(value)
        local name = PRESETS[math.floor(tonumber(value) or -1) + 1]
        if not name then error("options: no preset at "..tostring(value)) end
        PSE.Prefs.set_hud("preset", name)
    end)
if new then
    local tokens = {}
    for i, name in ipairs(PRESETS) do
        tokens[i] = "ui.options."..C.namespace..".hud.presetChoice."..name
    end
    preset:add_choice(tokens)
end

for _, axis in ipairs({ "x", "y" }) do
    bind("hud."..axis, "slider",
        function(id)
            return O.page:add_slider(id, ModOptionsSlider.DisplayType.PERCENTAGE, 0, 1, false)
        end,
        function() return PSE.Prefs.hud(axis) end,
        function(value) PSE.Prefs.set_hud(axis, tonumber(value)) end)
end

for _, name in ipairs({ "series", "screenFx", "barAtCursor" }) do
    checkbox("hud."..name,
        function() return PSE.Prefs.hud(name) end,
        function(value) PSE.Prefs.set_hud(name, value) end)
end

local function refresh_open_page()
    local menu = Instance.find(gm.constants.oOptionsMenu)
    if not Instance.exists(menu) then return end
    local options = menu.menu_pages[3].options
    local prefix = C.namespace.."."
    for i = 1, #options do
        local opt  = options[i]
        local name = opt.name
        local s = type(name) == "string" and name:sub(1, #prefix) == prefix
            and shown[name:sub(#prefix + 1)]
        if s then
            local value = s.get()
            gm.variable_struct_set(opt.value, "value", value)
            if s.kind ~= "dropdown" then gm.ui_set_element_value(name, value) end
        end
    end
end

function O.reset()
    PSE.Prefs.reset()
    local ok, err = pcall(refresh_open_page)
    if not ok then
        log.warning("PrimarySkillEvolution: open options page not refreshed -> "..tostring(err))
    end
end

local reset, reset_new = O.page:find("reset"), false
if not reset then reset, reset_new = O.page:add_button("reset"), true end
if reset_new then reset:add_callback(function() PSE.Options.reset() end) end

PSE.Options = O
