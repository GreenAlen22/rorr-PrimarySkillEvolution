-- Следы повёрнутых и увеличенных стрел.

PSE = PSE or {}

local C      = PSE.Config
local V      = PSE.Vanilla
local Charge = PSE.Charge

local STRAFE_STEP = "gml_Object_oHuntressBolt1_Step_2"
local PIERCE_STEP = "gml_Object_oHuntressBolt1B2_Step_2"

local AFTER_HOMING = -100

local QUALITY_TRAIL, QUALITY_SPARKLE = 2, 3

local strafe_trail = Global.pHuntressBolt1
if type(strafe_trail) ~= "number" then error("vanilla particle type pHuntressBolt1 not found") end
local laid = false

Hook.add_pre(STRAFE_STEP, AFTER_HOMING, function(self)
    if not V.owner(self) then return end
    local direction = self.direction
    if direction == 0 or direction == 180 then return end
    gm.part_type_orientation(strafe_trail, direction, direction, 0, 0, false)
    laid = true
end)

Hook.add_post(STRAFE_STEP, function(self)
    if not laid then return end
    gm.part_type_orientation(strafe_trail, 0, 0, 0, 0, false)
    laid = false
end)

local SCALE = C.charge_window.pierce_scale

local big_trail = Particle.new("pierceTrail")
big_trail:set_shape(Particle.Shape.LINE)
big_trail:set_life(20, 20)
big_trail:set_alpha2(1, 0)
big_trail:set_size(0.2, 0.2, -0.001, 0)
big_trail:set_scale(1.25 * SCALE, 1 * SCALE)
big_trail:set_color3(16777215, 8828542, 8421376)

local sparkle = Global.pPoison
if type(sparkle) ~= "number" then error("vanilla particle type pPoison not found") end
local SPARKLE = 0xC9ED6A
local WHITE   = 0xFFFFFF

Hook.add_pre(PIERCE_STEP, function(self)
    if not Charge.grown(self) then return end

    self.image_angle = self.direction

    local quality = Global.__pref_graphics_quality
    local x, y = self.x, self.y
    if quality >= QUALITY_TRAIL then
        big_trail:create(x, y - 4 * SCALE, 1, Particle.System.BELOW)
        big_trail:create(x, y + 4 * SCALE, 1, Particle.System.BELOW)
        if quality >= QUALITY_SPARKLE then
            gm.part_particles_create_color(Particle.System.ABOVE,
                x - 6 * SCALE + math.random() * 12 * SCALE,
                y - 4 * SCALE + math.random() * 8 * SCALE,
                sparkle, gm.merge_color(WHITE, SPARKLE, math.random()), 1)
        end
    end

    if not V.owner(self) then self:destroy() end
    return false
end)

PSE.Trails = true
