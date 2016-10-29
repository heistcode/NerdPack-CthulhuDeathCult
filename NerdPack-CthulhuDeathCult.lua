-- luacheck: globals NeP

local GetTime                 = GetTime
local UnitCastingInfo         = UnitCastingInfo
local UnitAura                = UnitAura
local GetSpellCooldown        = GetSpellCooldown
local IsUsableSpell           = IsUsableSpell
local CastSpellByName         = CastSpellByName
local UnitGUID                = UnitGUID
local IsMouseButtonDown       = IsMouseButtonDown
local CreateFrame             = CreateFrame
local SetOverrideBindingClick = SetOverrideBindingClick
local select                  = select
local pairs                   = pairs
local NeP                     = NeP

local MovementKeyDown, KeyboardKeyDown, CreatedKeybinds, LastCheck = {}, {}, {}

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
	["Pyroblast"]     = true,
}

local CreateKeybind = function(key, callback)
	CreatedKeybinds[key] = CreateFrame("BUTTON", "CDCKeybind"..key)
	SetOverrideBindingClick(CreatedKeybinds[key], true, key, CreatedKeybinds[key]:GetName())
	CreatedKeybinds[key]:SetScript("OnClick", function(_, _, down) callback(key, down) end)
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
		for button in pairs(MovementKeyDown) do
			Move[button][1]()
		end
		NeP.Listener:Remove("CDC_IceFloesListener", "COMBAT_LOG_EVENT_UNFILTERED")
	end
end

local MovementCallback = function(button, down)
	if down then
		MovementKeyDown[button] = true
		if DoNotInterrupt[UnitCastingInfo("player")] and not UnitAura("player", "Ice Floes") and GetSpellCooldown("Ice Floes") == 0 and IsUsableSpell("Ice Floes") then
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

local KeyboardCallback = function(button, down)
	if down then
		KeyboardKeyDown[button] = true
	else
		KeyboardKeyDown[button] = nil
	end
end

NeP.DSL:Register("mouse3", function() return IsMouseButtonDown(3) end)

NeP.DSL:Register("customkeybind", function(_, key)
	key = key:upper()
	return KeyboardKeyDown[key] or false
end)

NeP.DSL:Register("boss_time_to_die", function(target)
	return NeP.DSL:Get("boss")(target) and NeP.DSL:Get("deathin")(target) or 8675309
end)

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
	CreateKeybind("W", MovementCallback)
	CreateKeybind("A", MovementCallback)
	CreateKeybind("S", MovementCallback)
	CreateKeybind("D", MovementCallback)

	CreateKeybind("Q", KeyboardCallback)

	NeP.Interface:AddToggle({
		key  = "xCombustion",
		name = "Combustion",
		text = "ON/OFF using Combustion in rotation",
		icon = "Interface\\Icons\\Spell_fire_sealoffire",
	})
end

--[[local cancast = "{xmoving = 0 || player.buff(Ice Floes) || prev_gcd(Ice Floes) || cooldown(Ice Floes).remains = 0}"

local castFireball = {
	{"Ice Floes", "cooldown(61304).remains < 0.5 & xmoving = 1 & !prev_gcd(Ice Floes) & !player.buff(Ice Floes)"},
	{"Fireball"}
}

local Main = {
	{"Pyroblast", "player.buff(Hot Streak!) & !lastcast(Pyroblast) & {lastgcd(Fireball) || player.casting(Fireball) || !"..cancast.."}"},
	{"&Fire Blast", "player.buff(Heating Up) & !lastcast(Fire Blast)"},
	{"Scorch", "target.health<=25&equipped(132454)"},
	{castFireball, cancast},
	{"Ice Barrier", "!player.buff(Ice Barrier)&!player.buff(Combustion)&!player.buff(Rune of Power)"},
	{"Scorch", "xmoving=1&!player.buff(Ice Floes)"}
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
	{"%pause", "keybind(alt)"}
}--]]

local cancast = "{xmoving = 0 || player.buff(Ice Floes) || prev_gcd(Ice Floes) || cooldown(Ice Floes).remains = 0}"

local cannotcast = "!"..cancast

local castFireball = {
	{"Ice Floes", "cooldown(61304).remains < 0.5 & xmoving = 1 & !prev_gcd(Ice Floes) & !player.buff(Ice Floes)"},
	{"Fireball"}
}

local castPyroblast = {
	{"Ice Floes", "cooldown(61304).remains < 0.5 & xmoving = 1 & !prev_gcd(Ice Floes) & !player.buff(Ice Floes)"},
	{"Pyroblast"}
}

local Keybinds = {
	{"%pause", "keybind(alt)"}
}


local Interrupts = {
	{"Counterspell"},
	{"Arcane Torrent", "target.range <= 8 & spell(Counterspell).cooldown > gcd & !prev_gcd(Counterspell)"},
}

local Survival = {
	{"Ice Barrier", "!player.buff(Ice Barrier) & !player.buff(Combustion) & !player.buff(Rune of Power)"},
}

local Talents = {
	{"Flame On", "talent(4,2) & {action(Fire Blast).charges < 0.2 & {cooldown(Combustion).remains > 65 || target.boss_time_to_die < cooldown(Combustion).remains}}"},
	{"Blast Wave", "talent(4,1) & {!player.buff(Combustion) || {player.buff(Combustion) & action(Fire Blast).charges < 1 & action(Phoenix's Flames).charges < 1}}"},
	{"Meteor", "talent(7,3) & {cooldown(Combustion).remains > 30 || {cooldown(Combustion).remains > target.boss_time_to_die} || player.buff(Rune of Power)}"},
	{"Cinderstorm", "talent(7,2) & {cooldown(Combustion).remains < action(Cinderstorm).cast_time & {player.buff(Rune of Power) || !talent(3,2)} || cooldown(Combustion).remains > 10 * spell_haste & !player.buff(Combustion)}"},
	{"Dragon's Breath", "equipped(132863)"},
	{"Living Bomb", "talent(6,1) & target.area(10).enemies > 1 & !player.buff(Combustion)"}
}

local Combustion = {
	{"Rune of Power", "!player.buff(Combustion)"},
	{Talents},
	{"Combustion", "player.buff(Rune of Power) || player.casting(Rune of Power).percent > 90"},
	{"Blood Fury"},
	{"Berserking"},
	{"Pyroblast", "player.buff(Hot Streak!)"},
	{"&Fire Blast", "player.buff(Heating Up) & !prev_off_gcd(Fire Blast) & player.buff(Combustion)"},
	{"Phoenix's Flames", "artifact(Phoenix's Flames).equipped"},
	{"Scorch", "player.buff(Combustion).remains > action(Scorch).cast_time"},
	{"Scorch", "target.health<=25 & equipped(132454)"}
}

local MainRotation = {
	{"Pyroblast", "player.buff(Hot Streak!) & player.buff(Hot Streak!).remains < action(Fireball).execute_time"},
	{"Phoenix's Flames", "action(Phoenix's Flames).charges > 2.7"},
	{"Flamestrike", "talent(6,3) & target.area(10).enemies > 2 & player.buff(Hot Streak!)", "target.ground"},
	{"Pyroblast", "player.buff(Hot Streak!) & {lastgcd(Fireball) || player.casting(Fireball) || player.casting(Pyroblast) ||"..cannotcast.."}"},
	{"Pyroblast", "player.buff(Hot Streak!) & target.health <= 25 & equipped(132454)"},
	{castPyroblast, "!player.casting(Pyroblast) & !player.buff(Hot Streak!) & player.buff(Kael'thas's Ultimate Ability) & player.buff(Kael'thas's Ultimate Ability).remains < action(Pyroblast).execute_time & "..cancast},
	{"Phoenix's Flames", "action(Phoenix's Flames).charges > 2.7"},
	{Talents},
	{"&Fire Blast", "!talent(7,1) & player.buff(Heating Up) & player.casting(Fireball).left < 98 & !prev_off_gcd(Fire Blast) & {!talent(3,2) || action(Fire Blast).charges > 1.4 || cooldown(Combustion).remains < 40} & {3 - action(Fire Blast).charges} * {12 * spell_haste} <= cooldown(Combustion).remains + 3 || target.boss_time_to_die < 4"},
  {"&Fire Blast", "talent(7,1) & player.buff(Heating Up) & player.casting(Fireball).left < 98 & !prev_off_gcd(Fire Blast) & {!talent(3,2) || action(Fire Blast).charges > 1.5 || {cooldown(Combustion).remains < 40}} & {3 - action(Fire Blast).charges} * {18 * spell_haste} <= cooldown(Combustion).remains + 3 || target.boss_time_to_die < 4"},
	{"Phoenix's Flames", "{player.buff(Combustion) || player.buff(Rune of Power) || player.buff(Incanter's Flow).stack > 3 || talent(3,1)} & {4 - action(Phoenix's Flames).charges} * 13 < cooldown(Combustion).remains + 5 || target.boss_time_to_die < 10"},
	{"Phoenix's Flames", "{player.buff(Combustion) || player.buff(Rune of Power)} & {4 - action(Phoenix's Flames).charges} * 30 < cooldown(Combustion).remains + 5"},
	{"Scorch", "target.health <= 25 & equipped(132454)"},
	{castFireball, cancast},
	{"Ice Barrier", "!player.buff(Ice Barrier) & !player.buff(Combustion) & !player.buff(Rune of Power)"},
	{"Scorch", "xmoving=1 & !player.buff(Ice Floes)"}
}

local xCombat = {
	{"Rune of Power", "toggle(cooldowns) & xmoving = 0 & {cooldown(Combustion).remains > 40 || !toggle(xCombustion)} & {!player.buff(Combustion) & {cooldown(Flame On).remains < 5 || cooldown(Flame On).remains > 30} & !talent(7,1) || target.boss_time_to_die < 11 || talent(7,1) & {action(Rune of Power).charges > 1.8 || player.combat.time < 40} & {cooldown(Combustion).remains > 40 || !toggle(xCombustion)}}"},
	{Combustion, "toggle(xCombustion) & toggle(cooldowns) & {xmoving = 0 || player.buff(Combustion)} & {cooldown(Combustion).remains <= action(Rune of Power).cast_time + gcd || player.buff(Combustion)}"},
	--{xmoving = 0 || player.buff(Combustion)} TODO: nested || doesn't seem to work here. --/dump NeP.DSL:Get('xmoving')()
	--{MainRotation}
}

local inCombat = {
	{Keybinds},
	{Interrupts, "target.interruptAt(50) & toggle(interrupts) & target.infront & target.range < 40"},
	{Survival, "customkeybind(q)"},
	{xCombat, "target.range < 40 & target.infront"}
}

local outCombat = {
	{Keybinds},
	{Survival, "customkeybind(q)"},
}

NeP.CR:Add(63, "Cthulhu Death Cult", inCombat, outCombat, ExeOnLoad, GUI)


--/dump NeP.Interface:Fetch("TOGGLE_STATES", "mastertoggle")
--/script NeP.Interface:toggleToggle("mastertoggle", true)
--/script NeP.Interface:toggleToggle("mastertoggle", false)