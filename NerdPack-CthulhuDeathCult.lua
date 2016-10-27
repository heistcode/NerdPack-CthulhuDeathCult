-- luacheck: globals NeP
local _, CDC = ...

local GetTime                 = GetTime
local UnitCastingInfo         = UnitCastingInfo
local UnitAura                = UnitAura
local GetSpellCooldown        = GetSpellCooldown
local IsSpellUsable           = IsSpellUsable
local CastSpellByName         = CastSpellByName
local UnitGUID                = UnitGUID
local IsMouseButtonDown       = IsMouseButtonDown
local CreateFrame             = CreateFrame
local SetOverrideBindingClick = SetOverrideBindingClick
local select                  = select
local pairs                   = pairs
local NeP                     = NeP

local MovementKeyDown, CreatedKeybinds, LastCheck = {}, {}

local Move = {
	W = { MoveForwardStart, MoveForwardStop },
	S = { MoveBackwardStart, MoveBackwardStop },
	A = { StrafeLeftStart, StrafeLeftStop },
	D = { StrafeRightStart, StrafeRightStop }
}

local DoNotInterrupt = {
	["Fireball"]      = true,
	["Rune of Power"] = true,
	["Cinderstorm"]   = true,
}

local CreateKeybind = function(key, hook)
	CreatedKeybinds[key] = CreateFrame("BUTTON", "CDCKeybind"..key)
	SetOverrideBindingClick(CreatedKeybinds[key], true, key, CreatedKeybinds[key]:GetName())
	CreatedKeybinds[key]:SetScript("OnClick", function(_, _, down) hook(key, down) end)
	CreatedKeybinds[key]:RegisterForClicks("AnyUp", "AnyDown")
end

local SpamCheck = function()
	local time = GetTime()
	if LastCheck == nil or time - LastCheck > 0.5 then
		LastCheck = time
		return true
	else
		return false
	end
end

local IceFloesListener = function(_, event, _, sourceGUID, ...)
	if event == "SPELL_AURA_APPLIED" and sourceGUID == UnitGUID("player") and select(8, ...) == 108839 then
		for button in pairs(CDC.MovementKeyDown) do
			Move[button][1]()
		end
		NeP.Listener:Remove("CDC_IceFloesListener", "COMBAT_LOG_EVENT_UNFILTERED")
	end
end

local MovementHook = function(button, down)
	if down then
		MovementKeyDown[button] = true
		if DoNotInterrupt[UnitCastingInfo("player")] and not UnitAura("player", "Ice Floes") and GetSpellCooldown("Ice Floes") == 0 and IsSpellUsable("Ice Floes") then
			NeP.Listener:Add("CDC_IceFloesListener", "COMBAT_LOG_EVENT_UNFILTERED", IceFloesListener)
			if SpamCheck() then CastSpellByName("Ice Floes") end
			return
		else
			NeP.Listener:Remove("CDC_IceFloesListener", "COMBAT_LOG_EVENT_UNFILTERED")
			return Move[button][1]()
		end
	else
		MovementKeyDown[button] = nil
		NeP.Listener:Remove("CDC_IceFloesListener", "COMBAT_LOG_EVENT_UNFILTERED")
		Move[button][2]()
	end
end

local IsKeybordButtonDown = function(key)
end

NeP.DSL:Register("mouse3", function() return IsMouseButtonDown(3) end)

local GUI = {
	--[[{
		type    = "dropdown",
		text    = "Main Defense",
		key     = "shield",
		list    = {
			{
				text  = "Ironfur",
				key   = 1,
			},
			{
				text  = "Mark of Ursol",
				key   = 2,
			},
		},
		default = 1,
		desc    = "Used ASAP"
	}]]
}

local ExeOnLoad = function()
	CreateKeybind("W", MovementHook)
	CreateKeybind("A", MovementHook)
	CreateKeybind("S", MovementHook)
	CreateKeybind("D", MovementHook)

	NeP.Interface:AddToggle({
		key  = 'xCombustion',
		name = 'Combustion',
		text = 'ON/OFF using Combustion in rotation',
		icon = 'Interface\\Icons\\Spell_fire_sealoffire',
	})
end

--[[local cancast = "{xmoving = 0 || player.buff(Ice Floes) || prev_gcd(Ice Floes) || cooldown(Ice Floes).remains = 0}"

local castFireball = {
	{'Ice Floes', 'cooldown(61304).remains < 0.5 & xmoving = 1 & !prev_gcd(Ice Floes) & !player.buff(Ice Floes)'},
	{'Fireball'}
}

local Main = {
	{"Pyroblast", "player.buff(Hot Streak!) & !lastcast(Pyroblast) & {lastgcd(Fireball) || player.casting(Fireball) || !"..cancast.."}"},
	{'&Fire Blast', 'player.buff(Heating Up) & !lastcast(Fire Blast)'},
	{'Scorch', 'target.health<=25&equipped(132454)'},
	{castFireball, cancast},
	{'Ice Barrier', '!player.buff(Ice Barrier)&!player.buff(Combustion)&!player.buff(Rune of Power)'},
	{'Scorch', 'xmoving=1&!player.buff(Ice Floes)'}
}

local InCombat = {
	{Main, "mouse3&target.range<40&target.infront"},
}

local OutOfCombat = {
	{"&/stopcasting", "!mouse3&player.casting(Fireball)"},
	{"Fireball", "mouse3"}
}

local Keybinds = {
	-- Pause
	{'%pause', 'keybind(alt)'}
}--]]

local Keybinds = {
	-- Pause
	{'%pause', 'keybind(alt)'}
}


-- luacheck: ignore
local PreCombat = {
	--actions.precombat=flask,type=flask_of_the_whispered_pact
	--actions.precombat+=/food,type=the_hungry_magister
	--actions.precombat+=/augmentation,type=defiled
	--actions.precombat+=/snapshot_stats
	--actions.precombat+=/mirror_image
	--actions.precombat+=/potion,name=deadly_grace
	--actions.precombat+=/pyroblast
}

local Interrupts = {
	{'Counterspell'},
	{'Arcane Torrent', 'target.range<=8&spell(Counterspell).cooldown>gcd&!prev_gcd(Counterspell)'},
}


local Cooldowns = {
	--# Executed every time the actor is available.
	--actions=counterspell,if=target.debuff.casting.react
	--actions+=/time_warp,if=target.health.pct<25|time=0
	--actions+=/shard_of_the_exodar_warp,if=buff.bloodlust.down
	--actions+=/mirror_image,if=buff.combustion.down
}
-- luacheck: ignore
local Survival = {

}

local Talents = {
	--actions.active_talents=flame_on,if=action.fire_blast.charges=0&(cooldown.combustion.remains>40+(talent.kindling.enabled*25)||target.time_to_die.remains<cooldown.combustion.remains)
	{'Flame On', 'talent(4,2)&{action(Fire Blast).charges<0.2&{cooldown(Combustion).remains>65||target.time_to_die<cooldown(Combustion).remains}}'},
	--actions.active_talents+=/blast_wave,if=(buff.combustion.down)||(buff.combustion.up&action.fire_blast.charges<1&action.phoenixs_flames.charges<1)
	{'Blast Wave', 'talent(4,1)&{{!player.buff(Combustion)}||{player.buff(Combustion)&action(Fire Blast).charges<1&action(Phoenix\'s Flames).charges<1}}'},
	--actions.active_talents+=/meteor,if=cooldown.combustion.remains>30||(cooldown.combustion.remains>target.time_to_die)||buff.rune_of_power.up
	{'Meteor', 'talent(7,3)&{cooldown(Combustion).remains>30||{cooldown(Combustion).remains>target.time_to_die}||player.buff(Rune of Power)}'},
	--actions.active_talents+=/cinderstorm,if=cooldown.combustion.remains<cast_time&(buff.rune_of_power.up||!talent.rune_on_power.enabled)||cooldown.combustion.remains>10*spell_haste&!buff.combustion.up
	{'Cinderstorm', 'talent(7,2)&{cooldown(Combustion).remains<action(Cinderstorm).cast_time&{player.buff(Rune of Power)||!talent(3,2)}||cooldown(Combustion).remains>10*spell_haste&!player.buff(Combustion)}'},
	--actions.active_talents+=/dragons_breath,if=equipped.132863
	{'Dragon\'s Breath', 'equipped(132863)'},
	--actions.active_talents+=/living_bomb,if=active_enemies>3&buff.combustion.down
	{'Living Bomb', 'talent(6,1)&target.area(10).enemies>3&!player.buff(Combustion)'}
}

local Combustion = {
	--actions.combustion_phase=rune_of_power,if=buff.combustion.down
	{'Rune of Power', '!player.buff(Combustion)'},
	--actions.combustion_phase+=/call_action_list,name=active_talents
	{Talents},
	--actions.combustion_phase+=/combustion
	{'Combustion', 'player.buff(Rune of Power)||player.casting(Rune of Power).percent>90'},
	--actions.combustion_phase+=/potion,name=deadly_grace
	--actions.combustion_phase+=/blood_fury
	{'Blood Fury'},
	--actions.combustion_phase+=/berserking
	{'Berserking'},
	--actions.combustion_phase+=/pyroblast,if=buff.hot_streak.up
	{'Pyroblast', 'player.buff(Hot Streak!)'},
	--actions.combustion_phase+=/fire_blast,if=buff.heating_up.up
	{'&Fire Blast', 'player.buff(Heating Up)&!prev_off_gcd(Fire Blast)&player.buff(Combustion)'},
	--actions.combustion_phase+=/phoenixs_flames
	{'Phoenix\'s Flames', 'artifact(Phoenix\'s Flames).equipped'},
	--actions.combustion_phase+=/scorch,if=buff.combustion.remains>cast_time
	{'Scorch', 'player.buff(Combustion).remains>action(Scorch).cast_time'},
	--actions.combustion_phase+=/scorch,if=target.health.pct<=25&equipped.132454
	{'Scorch', 'target.health<=25&equipped(132454)'}
}

local RoP = {
	--actions.rop_phase=rune_of_power
	{'Rune of Power'},
	--actions.rop_phase+=/pyroblast,if=buff.hot_streak.up
	{'Pyroblast', 'player.buff(Hot Streak!)'},
	--actions.rop_phase+=/call_action_list,name=active_talents
	{Talents},
	--actions.rop_phase+=/pyroblast,if=buff.kaelthas_ultimate_ability.react
	{'Pyroblast', 'player.buff(Kael\'thas\'s Ultimate Ability)'},
	--actions.rop_phase+=/fire_blast,if=!prev_off_gcd.fire_blast
	{'&Fire Blast', 'player.buff(Heating Up)&!prev_off_gcd(Fire Blast)'},
	--actions.rop_phase+=/phoenixs_flames,if=!prev_gcd.phoenixs_flames
	{'Phoenix\'s Flames', 'artifact(Phoenix\'s Flames).equipped&!prev_gcd(Phoenix\'s Flames)'},
	--actions.rop_phase+=/scorch,if=target.health.pct<=25&equipped.132454
	{'Scorch', 'target.health<=25&equipped(132454)'},
	--actions.rop_phase+=/fireball
	{'Fireball'}
}

local MainRotation = {
	--actions.single_target=pyroblast,if=buff.hot_streak.up&buff.hot_streak.remains<action.fireball.execute_time
	{'Pyroblast', 'player.buff(Hot Streak!)&player.buff(Hot Streak!).remains<action(Fireball).execute_time'},
	--actions.single_target+=/phoenixs_flames,if=charges_fractional>2.7&active_enemies>2
	{'Phoenix\'s Flames', 'artifact(Phoenix\'s Flames).equipped&{action(Phoenix\'s Flames).charges>2.7&target.area(8).enemies>2}'},
	--actions.single_target+=/flamestrike,if=talent.flame_patch.enabled&active_enemies>2&buff.hot_streak.react
	{'Flamestrike', 'talent(6,3)&target.area(10).enemies>2&player.buff(Hot Streak!)', 'target.ground'},
	--actions.single_target+=/pyroblast,if=buff.hot_streak.up&!prev_gcd.pyroblast
	{'Pyroblast', 'player.buff(Hot Streak!)&!prev_gcd(Pyroblast)'},
	--actions.single_target+=/pyroblast,if=buff.hot_streak.react&target.health.pct<=25&equipped.132454
	{'Pyroblast', 'player.buff(Hot Streak!)&target.health<=25&equipped(132454)'},
	--actions.single_target+=/pyroblast,if=buff.kaelthas_ultimate_ability.react
	{'Pyroblast', 'player.buff(Kael\'thas\'s Ultimate Ability)'},
	--actions.single_target+=/call_action_list,name=active_talents
	{Talents},
	--{'&Fire Blast', 'player.buff(Heating Up)&!prev_off_gcd(Fire Blast)&action(Fire Blast).charges>0&cooldown(Combustion).remains<action(Fire Blast).cooldown_to_max'},
	--actions.single_target+=/fire_blast,if=!talent.kindling.enabled&buff.heating_up.up&(!talent.rune_of_power.enabled||charges_fractional>1.4||cooldown.combustion.remains<40)&(3-charges_fractional)*(12*spell_haste)<cooldown.combustion.remains+3||target.time_to_die.remains<4
	{'&Fire Blast', '!talent(7,1)&player.buff(Heating Up)&player.casting(Fireball).left<98&!prev_off_gcd(Fire Blast)&{!talent(3,2)||action(Fire Blast).charges>1.4||cooldown(Combustion).remains<40}&{3-action(Fire Blast).charges}*{12*spell_haste}<=cooldown(Combustion).remains+3||target.time_to_die<4'},
	--actions.single_target+=/fire_blast,if=talent.kindling.enabled&buff.heating_up.up&(!talent.rune_of_power.enabled||charges_fractional>1.5||cooldown.combustion.remains<40)&(3-charges_fractional)*(18*spell_haste)<cooldown.combustion.remains+3||target.time_to_die.remains<4
  {'&Fire Blast', 'talent(7,1)&player.buff(Heating Up)&player.casting(Fireball).left<98&!prev_off_gcd(Fire Blast)&{!talent(3,2)||action(Fire Blast).charges>1.5||{cooldown(Combustion).remains<40}}&{3-action(Fire Blast).charges}*{18*spell_haste}<=cooldown(Combustion).remains+3||target.time_to_die<4'},
	--actions.single_target+=/phoenixs_flames,if=(buff.combustion.up||buff.rune_of_power.up||buff.incanters_flow.stack>3||talent.mirror_image.enabled)&artifact.phoenix_reborn.enabled&(4-charges_fractional)*13<cooldown.combustion.remains+5||target.time_to_die.remains<10
	{'Phoenix\'s Flames', '{player.buff(Combustion)||player.buff(Rune of Power)||player.buff(Incanter\'s Flow).stack>3||talent(3,1)}&{4-action(Phoenix\'s Flames).charges}*13<cooldown(Combustion).remains+5||target.time_to_die<10'},
	--actions.single_target+=/phoenixs_flames,if=(buff.combustion.up||buff.rune_of_power.up)&(4-charges_fractional)*30<cooldown.combustion.remains+5
	{'Phoenix\'s Flames', '{player.buff(Combustion)||player.buff(Rune of Power)}&{4-action(Phoenix\'s Flames).charges}*30<cooldown(Combustion).remains+5'},
	--actions.single_target+=/scorch,if=target.health.pct<=25&equipped.132454
	{'Scorch', 'target.health<=25&equipped(132454)'},
	{'Ice Floes', 'cooldown(61304).remains<0.2&xmoving=1&!prev_gcd(Ice Floes)&!player.buff(Ice Floes)'},
	--actions.single_target+=/fireball
	{'Fireball', 'xmoving=0||player.buff(Ice Floes)'},
	{'Ice Barrier', '!player.buff(Ice Barrier)&!player.buff(Combustion)&!player.buff(Rune of Power)'},
	--Scorch as a filler spell when moving.
	{'Scorch', 'xmoving=1&!player.buff(Ice Floes)'}
}

local xCombat = {
	--actions+=/rune_of_power,if=cooldown.combustion.remains>40&buff.combustion.down&(cooldown.flame_on.remains<5||cooldown.flame_on.remains>30)&!talent.kindling.enabled||target.time_to_die.remains<11||talent.kindling.enabled&(charges_fractional>1.8||time<40)&cooldown.combustion.remains>40
	{'Rune of Power', 'toggle(cooldowns)&xmoving=0&{cooldown(Combustion).remains>40||!toggle(xCombustion)}&{!player.buff(Combustion)&{cooldown(Flame On).remains<5||cooldown(Flame On).remains>30}&!talent(7,1)||target.time_to_die<11||talent(7,1)&{action(Rune of Power).charges>1.8||player.combat.time<40}&{cooldown(Combustion).remains>40||!toggle(xCombustion)}}'},
	--actions+=/call_action_list,name=combustion_phase,if=cooldown.combustion.remains<=action.rune_of_power.cast_time+(!talent.kindling.enabled*gcd)||buff.combustion.up
	{Combustion, 'toggle(xCombustion)&toggle(cooldowns)&xmoving=0&{cooldown(Combustion).remains<=action(Rune of Power).cast_time+gcd||player.buff(Combustion)}'},
	--actions+=/call_action_list,name=rop_phase,if=buff.rune_of_power.up&buff.combustion.down
	{RoP, 'xmoving=0&player.buff(Rune of Power)&!player.buff(Combustion)'},
	--actions+=/call_action_list,name=single_target
	{MainRotation}
}

local inCombat = {
	{Keybinds},
	{Interrupts, 'target.interruptAt(50)&toggle(interrupts)&target.infront&target.range<40'},
	{Cooldowns, 'toggle(cooldowns)'},
	--{Survival, 'player.health < 100'},
	{xCombat, 'target.range<40&target.infront'}
}

local outCombat = {
	{Keybinds},
	--{PreCombat}
}

NeP.CR:Add(63, 'Cthulhu Death Cult', inCombat, outCombat, ExeOnLoad, GUI)


--/dump NeP.Interface:Fetch("TOGGLE_STATES", "mastertoggle")
--/script NeP.Interface:toggleToggle("mastertoggle", true)
--/script NeP.Interface:toggleToggle("mastertoggle", false)
