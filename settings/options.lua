-- Страница мода в настройках игры.

PSE = PSE or {}

local C = PSE.Config

local O = {}

O.page = ModOptions.new()

O.action = O.page:find("action") or O.page:add_keybind("action", C.action_key)

PSE.Options = O
