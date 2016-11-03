-- luacheck: globals NeP
local CDC                     = select(2, ...)
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

CDC.Name                      = "Cthulhu Death Cult"
CDC.Version                   = 0.1

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

NeP.DSL:Register("boss_time_to_die", function(target)
	return NeP.DSL:Get("boss")(target) and NeP.DSL:Get("deathin")(target) or 8675309
end)

NeP.DSL:Register("invehicle", function()
	return (SecureCmdOptionParse("[overridebar][vehicleui][possessbar,@vehicle,exists]true")) == "true"
end)

local GUI = {
}

local ExeOnLoad = function()

	NeP.CustomKeybind:Add(CDC.Name, "W", MovementCallback)
	NeP.CustomKeybind:Add(CDC.Name, "A", MovementCallback)
	NeP.CustomKeybind:Add(CDC.Name, "S", MovementCallback)
	NeP.CustomKeybind:Add(CDC.Name, "D", MovementCallback)

	NeP.CustomKeybind:Add(CDC.Name, "Q")
	NeP.CustomKeybind:Add(CDC.Name, "1")

	NeP.Interface:AddToggle({
		key  = "xCombustion",
		name = "Combustion",
		text = "ON/OFF using Combustion in rotation",
		icon = "Interface\\Icons\\Spell_fire_sealoffire",
	})
end

local ExeOnUnload = function()
	NeP.CustomKeybind:RemoveAll(CDC.Name)
end

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
	{"&Combustion", "player.buff(Rune of Power) || {player.casting(Rune of Power) & player.casting.percent > 80}"},
	{"Blood Fury"},
	{"Berserking"},
	{"&Pyroblast", "player.buff(Hot Streak!) & player.buff(Combustion)"},
	{"Phoenix's Flames", "action(Phoenix's Flames).charges>2.7 & player.buff(Combustion) & !player.buff(Hot Streak!)"},
	{"&Fire Blast", "player.buff(Heating Up) & !player.lastcast(Fire Blast) & player.buff(Combustion)"},
	{"Phoenix's Flames", "artifact(Phoenix's Flames).equipped"},
	{"Scorch", "player.buff(Combustion).remains > action(Scorch).cast_time"},
}

local MainRotation = {
	{"Pyroblast", "player.buff(Hot Streak!) & player.buff(Hot Streak!).remains < action(Fireball).execute_time"},
	{"Phoenix's Flames", "action(Phoenix's Flames).charges > 2.7"},
	{"Flamestrike", "talent(6,3) & target.area(10).enemies > 2 & player.buff(Hot Streak!)", "target.ground"},
	{"&Pyroblast", "player.buff(Hot Streak!) & {lastgcd(Fireball) || player.casting(Fireball) || player.casting(Pyroblast) ||"..cannotcast.."}"},
	{"Pyroblast", "player.buff(Hot Streak!) & target.health <= 25 & equipped(132454)"},
	{castPyroblast, "!player.casting(Pyroblast) & !player.buff(Hot Streak!) & player.buff(Kael'thas's Ultimate Ability) & player.buff(Kael'thas's Ultimate Ability).remains > action(Pyroblast).execute_time + gcd & "..cancast},
	{"Phoenix's Flames", "!player.buff(Hot Streak!) & action(Phoenix's Flames).charges > 2.7"},
	{Talents},
	{"&Fire Blast", "!talent(7,1) & player.buff(Heating Up) & {player.casting(Fireball) || player.casting(Pyroblast) || ".. cannotcast .."} & !prev_off_gcd(Fire Blast) & {!talent(3,2) || action(Fire Blast).charges > 1.4 || cooldown(Combustion).remains < 40} & {3 - action(Fire Blast).charges} * {12 * spell_haste} <= cooldown(Combustion).remains + 3 || target.boss_time_to_die < 4"},
	{"&Fire Blast", "talent(7,1) & player.buff(Heating Up) & {player.casting(Fireball) || player.casting(Pyroblast) || ".. cannotcast .."} & !prev_off_gcd(Fire Blast) & {!talent(3,2) || action(Fire Blast).charges > 1.5 || {cooldown(Combustion).remains < 40}} & {3 - action(Fire Blast).charges} * {18 * spell_haste} <= cooldown(Combustion).remains + 3 || target.boss_time_to_die < 4"},
	{"Phoenix's Flames", "!player.buff(Hot Streak!) & {player.buff(Combustion) || player.buff(Rune of Power) || player.buff(Incanter's Flow).stack > 3 || talent(3,1)} & {4 - action(Phoenix's Flames).charges} * 13 < cooldown(Combustion).remains + 5 || target.boss_time_to_die < 10"},
	{"Phoenix's Flames", "!player.buff(Hot Streak!) & {player.buff(Combustion) || player.buff(Rune of Power)} & {4 - action(Phoenix's Flames).charges} * 30 < cooldown(Combustion).remains + 5"},
	{"Scorch", "target.health <= 25 & equipped(132454)"},
	{castFireball, cancast},
	{"Ice Barrier", "!player.buff(Ice Barrier) & !player.buff(Combustion) & !player.buff(Rune of Power)"},
	{"Scorch", "xmoving=1 & !player.buff(Ice Floes)"}
}

local xCombat = {
	{"Rune of Power", "toggle(cooldowns) & xmoving = 0 & {cooldown(Combustion).remains > 40 || !toggle(xCombustion)} & {!player.buff(Combustion) & {cooldown(Flame On).remains < 5 || cooldown(Flame On).remains > 30} & !talent(7,1) || target.boss_time_to_die < 11 || talent(7,1) & {action(Rune of Power).charges > 1.8 || player.combat.time < 40} & {cooldown(Combustion).remains > 40 || !toggle(xCombustion)}}"},
	{Combustion, "toggle(xCombustion) & toggle(cooldowns) & {xmoving = 0 || player.buff(Combustion)} & {cooldown(Combustion).remains <= action(Rune of Power).cast_time || player.buff(Combustion)}"},
	{MainRotation}
}

local inCombat = {
	{Keybinds},
	{"&/click ElvUI_Bar1Button1\n/click OverrideActionBarButton1", "invehicle & customkeybind(1)"},
	{Interrupts, "target.interruptAt(50) & toggle(interrupts) & target.infront & target.range < 40"},
	{Survival, "customkeybind(q)"},
	{xCombat, "target.range < 40 & target.infront"}
}

local outCombat = {
	{Keybinds},
	{Survival, "customkeybind(q)"},
	{"&/click ElvUI_Bar1Button1\n/click OverrideActionBarButton1", "invehicle & customkeybind(1)"},
	{"&/stopcasting", "!invehicle & !customkeybind(1) & player.casting(Fireball)"},
	{"Fireball", "!invehicle & customkeybind(1)"}
}

CDC.CR = {
	name = CDC.Name,
	ic = inCombat,
	ooc = outCombat,
	load = ExeOnLoad,
	unload = ExeOnUnload,
	gui = GUI,
}

NeP.CR:Add(63, CDC.CR)


--/dump NeP.Interface:Fetch("TOGGLE_STATES", "mastertoggle")
--/script NeP.Interface:toggleToggle("mastertoggle", true)
--/script NeP.Interface:toggleToggle("mastertoggle", false)
