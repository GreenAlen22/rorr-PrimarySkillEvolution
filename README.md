A mod that reworks the primary attack (Z) of every vanilla survivor.  
Gunners get magazines and an active reload, special primaries get a twist of their own, and melee survivors get stamina, a finisher and a style rank.

---
## Action key
The mod adds one new key - Action (R by default). Go to Game settings > Mods tab to rebind it.  
Gunners - reload. Huntress - mark. Artificer - ring of chakrams. Melee - lunge in the air, launcher on the ground.

---
## Settings
Game settings > Mods tab > Primary Skill Evolution.

Switch off any mechanic: magazine and reload, Perfect Reload, aim at cursor, charge window, cleaver catch, stamina, finisher and Rage, Lunge and Launcher. Online, the host's settings apply to everyone.  
Move the stamina and rage meters to any corner or to a spot of your own. Hide the series rank or the screen effects. Draw the reload bar as a ring around the cursor.

---
## Gunners
Commando, Bandit, Enforcer, Pilot, Robomando, Engineer, and Huntress with Pierce.

Magazine - the primary has limited ammo. An empty magazine reloads on its own, Action reloads early.  
Active reload - press Action again while the marker is inside the window. Hit it and get Perfect Reload: +25% attack speed, +10% movement speed and 4% lifesteal for 7 seconds. Miss it and only half of the ammo comes back.  
Sniper keeps his vanilla reload, and a perfect one also gives Perfect Reload, once every 7 seconds.  
With Skills++, each level of the primary adds ammo and widens the window.  

![Active reload](https://github.com/GreenAlen22/rorr-PrimarySkillEvolution/blob/main/reload.gif?raw=true)

Mouse aim - with the vanilla mouse aim option on, primary shots fly toward the cursor. Sniper's Snipe and Enforcer's Shrapnel Grenade too.

![Mouse aim](https://github.com/GreenAlen22/rorr-PrimarySkillEvolution/blob/main/aim.png?raw=true)

---
## Special primaries
Huntress (Strafe) - Action marks the enemy nearest the cursor. Arrows home on the mark and fly through thin walls. Every third hit on one target crits and ricochets.  

![Strafe mark](https://github.com/GreenAlen22/rorr-PrimarySkillEvolution/blob/main/strafe.gif?raw=true)

Huntress (Pierce) and Loader (Bullet Punch) - release the charge inside the window, 65-85% of the charge, for a full charge and Steady Hand: +30% attack speed. With Skills++, each level of the primary widens the window.  
CHEF (Dice) - press the primary as the cleaver comes back to catch it. The next throw is sharpened: more damage, faster and farther. A caught MINCE is thrown again for free.  

![CHEF catch](https://github.com/GreenAlen22/rorr-PrimarySkillEvolution/blob/main/chef.gif?raw=true)

Artificer (Flame Chakrams) - the chakram flies to the cursor. Action sets a ring of four burning chakrams around her.

---
## Melee
Acrid, HAN-D, Miner, Mercenary, Loader with either primary, Drifter and the melee alternatives of Bandit, Sniper and CHEF.

Stamina - every strike that hits spends it. Empty stamina makes you Breathless: your primary deals half damage. When it runs low, hit the window with Action to refill it and get Second Wind: +20 armor.  
Finisher - hits fill a bar. When it is full, an explosion knocks up and stuns enemies around you, and you get Rage: +35% damage and 10% lifesteal for 8 seconds.  
Signatures - every hero has its own finisher effect. Miner rains pickaxes, Mercenary stops time and cuts the whole screen, Loader throws everyone sky-high, CHEF's kills drop snacks, and more.  
Series - a style rank from D to SSS. Hit hard, crit, kill in streaks and mix your attacks.  
Lunge - Action in the air dashes toward the cursor, hits everything on the way and makes you untouchable for a moment.  
Launcher - Action on the ground throws nearby enemies up and stuns them.  
With Skills++, each level of the primary adds 10% stamina and 10% to Rage's length.

![Melee HUD](https://github.com/GreenAlen22/rorr-PrimarySkillEvolution/blob/main/melee.png?raw=true)

---
## For mod authors
Primary Skill Evolution gives other mods `mods["GreenAlen22-PrimarySkillEvolution"].api`, version 2 (`api.version`). Call it inside `Initialize.add(Callback.Priority.AFTER, ...)`, when your skills and states already exist. Each primary is registered once; a wrong argument raises an error naming the skill.

`api.gunner(skill, def)` - magazine, active reload, Perfect Reload and mouse aim.  
`def.name` - a name for the debug commands. `def.states` - list of ActorState the shot is fired from, or `def.activity` - the activity number. `def.tracers` - list of tracer ids its bullets carry: Perfect Reload's lifesteal knows the shot by them. `def.magazine` - rounds. `def.reload` - seconds at attack speed 1; without both the primary only aims. `def.cone` - aim cone in degrees either side. `def.release` - optional ActorState that ends a held burst, or `def.cut = true` - a burst still going when the magazine runs dry ends.  
`def.shot` - what a round is: `"bullet"` (default) - a `fire_bullet` from the owner while the survivor is in one of `states`; `"enter"` - entering one of `states`; `"custom"` - your call to `api.spend(actor, rounds)`.  
`def.aim` - `"bullet"` (default) - PSE turns those bullets; `"host"` - the host fires every player's bullets from `states` and turns them; `"custom"` - you turn your projectiles on every machine with `api.aim(actor, x, y, side)`, which returns the direction or nil; `"none"`.

`api.melee(skill, def)` - stamina, finisher and Rage, series, Lunge and Launcher.  
`def.name`, `def.states` - list of ActorState, or `def.activity`: a strike counts only inside them. `def.stamina` - strikes in a full bar. `def.finisher` - optional, strikes that fill the finisher bar (30 by default). `def.sparks` - sprite id for the finisher, Lunge and Launcher look.  
`def.strike` - `"hc"` (default) - a `skill_util_update_heaven_cracker` call followed by a `fire_explosion` from the survivor in the same frame; `"attack"` - a `fire_explosion` from the survivor. `def.gap` - frames after a strike in which another explosion of the same press is the same strike; a new press of the primary is a new strike. Only explosions within 160 px of the survivor count. `def.host = true` - the host makes every player's strikes; it counts their hits for the owner.  
Registered survivors have no signature. Their finisher shows one shared blast in the survivor's color, and their Rage is stronger: +50% damage, 15% lifesteal and +20% attack speed.

`api.charge(actor, progress, rate)` and `api.charge_release(actor)` - the charge window, as Pierce's. Each step of the draw report the charge, 0 to 1, and its gain per frame at attack speed 1; at the release ask whether it was inside the window - `true` means fire a full-charge shot.

---
## Todo
- Own sounds.
- Visual updating of marks and effects.
- Balance adjustment.
- More multiplayer testing.

---
## Credits
* GreenAlen22 - Programming, Ideas, Art

## Contacts
My discord: greenalen22  
Multiplayer is supported, but it has not been tested much yet. If there are any errors, please report them to discord.

## Special thanks
Thanks to Klehrik, RoRRModdingToolkit, RandomCatDude and the rest of the ror returns mod developers who helped us understand how modding works.
