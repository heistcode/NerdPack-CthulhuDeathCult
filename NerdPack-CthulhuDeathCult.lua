-- luacheck: globals NeP
local CDC                  = (select(2, ...))
local GetTime              = GetTime
local UnitCastingInfo      = UnitCastingInfo
local UnitAura             = UnitAura
local GetSpellCooldown     = GetSpellCooldown
local IsUsableSpell        = IsUsableSpell
local CastSpellByName      = CastSpellByName
local UnitGUID             = UnitGUID
local UnitHealth           = UnitHealth
local UnitHealthMax        = UnitHealthMax
local IsSpellInRange       = IsSpellInRange
local SecureCmdOptionParse = SecureCmdOptionParse
local RunMacroText         = RunMacroText
local select               = select
local floor                = floor
local pairs                = pairs
local NeP                  = NeP

CDC.Name                   = "Cthulhu Death Cult"
CDC.Version                = 0.33

_G["BINDING_HEADER_CDC"]  = CDC.Name

do
	local LastCheck
	function CDC.SpamCheck()
		local time = GetTime()
		if LastCheck == nil or time - LastCheck > 0.5 then
			LastCheck = time
			return true
		else
			return false
		end
	end
end

do
	local MovementKeyDown = {}
	local Move = {
		W = { MoveForwardStart, MoveForwardStop },
		S = { MoveBackwardStart, MoveBackwardStop },
		A = { StrafeLeftStart, StrafeLeftStop },
		D = { StrafeRightStart, StrafeRightStop }
	}
	function CDC.IceFloesListener(_, event, _, sourceGUID, ...)
		if event == "SPELL_AURA_APPLIED" and sourceGUID == UnitGUID("player") and
				select(8, ...) == 108839 then
			for button in pairs(MovementKeyDown) do
				Move[button][1]()
			end
			NeP.Listener:Remove("CDC_IceFloesListener", "COMBAT_LOG_EVENT_UNFILTERED")
		end
	end

	function CDC.MovementCallback(button, down)
		local DoNotInterrupt = {
			["Fireball"]      = true,
			["Rune of Power"] = true,
			["Cinderstorm"]   = true,
			["Pyroblast"]     = true,
		}
		if down then
			MovementKeyDown[button] = true
			if DoNotInterrupt[UnitCastingInfo("player")] and not UnitAura("player", "Ice Floes") and
					GetSpellCooldown("Ice Floes") == 0 and IsUsableSpell("Ice Floes") then
				NeP.Listener:Add("CDC_IceFloesListener", "COMBAT_LOG_EVENT_UNFILTERED", CDC.IceFloesListener)
				if CDC.SpamCheck() then CastSpellByName("Ice Floes") end
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
end

function CDC.VehicleUICallback(button, down)
	if down and (SecureCmdOptionParse("[overridebar][vehicleui][possessbar,@vehicle,exists]")) then
		RunMacroText("/click ElvUI_Bar1Button"..button.."\n/click OverrideActionBarButton"..button)
	end
end

NeP.DSL:Register("bossttd", function(target)
	return NeP.DSL:Get("boss")(target) and NeP.DSL:Get("deathin")(target) or 8675309
end)

NeP.DSL:Register("relativehealth", function(target)
	return UnitHealth(target) / UnitHealthMax("player")
end)

NeP.DSL:Register("shaste", function()
	return floor((100 / (100 + NeP.DSL:Get("haste")("player"))) * 10 ^ 3) / 10 ^ 3
end)

NeP.DSL:Register("canfireball", function(target)
	return IsSpellInRange("Fireball", target) == 1
end)

CDC.GUI = {
	{
		type    = "checkbox",
		text    = "Use Potion",
		key     = "potion",
		default = false,
		desc    = "Use potion during heroism"
	},
	{
		type    = "checkbox",
		text    = "Use Gunpowder Charge",
		key     = "gunpowder",
		default = false,
		desc    = "Use gunpowdercharge during combustion"
	},
}

function CDC.ExeOnLoad()

	NeP.CustomKeybind:Add(CDC.Name, "W", CDC.MovementCallback)
	NeP.CustomKeybind:Add(CDC.Name, "A", CDC.MovementCallback)
	NeP.CustomKeybind:Add(CDC.Name, "S", CDC.MovementCallback)
	NeP.CustomKeybind:Add(CDC.Name, "D", CDC.MovementCallback)

	NeP.CustomKeybind:Add(CDC.Name, "Q")
	NeP.CustomKeybind:Add(CDC.Name, "SHIFT-Q")
	NeP.CustomKeybind:Add(CDC.Name, "1", CDC.VehicleUICallback)
	NeP.CustomKeybind:Add(CDC.Name, "2", CDC.VehicleUICallback)

	NeP.Interface:AddToggle({
		key  = "combustion",
		name = "Combustion",
		text = "ON/OFF using Combustion in rotation",
		icon = "Interface\\Icons\\Spell_fire_sealoffire",
	})
end

function CDC.ExeOnUnload()
	NeP.CustomKeybind:RemoveAll(CDC.Name)
end

local cancast =
	"{{!moving || player.buff(Ice Floes) || lastgcd(Ice Floes) || spell(Ice Floes).cooldown = 0}" ..
			"& target.canfireball & target.infront}"

local CastFireball = {
	{
		"&Ice Floes",
		"spell(61304).cooldown < 0.1 & moving & !lastgcd(Ice Floes) & !player.buff(Ice Floes)"
	},
	{"Fireball"}
}

local CastPyroblast = {
	{
		"&Ice Floes",
		"spell(61304).cooldown < 0.1 & moving & !lastgcd(Ice Floes) & !player.buff(Ice Floes)"
	},
	{"Pyroblast"}
}

local Keybinds = {
	{"%pause", "keybind(alt)"}
}


local Interrupts = {
	{"Counterspell"},
	{
		"Arcane Torrent",
		"target.range <= 8 & spell(Counterspell).cooldown > gcd & !lastgcd(Counterspell)"
	},
}

local Survival = {
	{
		"!Ice Barrier",
		"player.health < 20 & !player.buff(Ice Barrier) & !player.buff(Combustion) &" ..
				"!player.buff(Rune of Power)"
	},
	{
		"!Ice Block",
		"{customkeybind(shift q) || {player.combat & player.health < 15 & !player.buff(Ice Barrier) &" ..
				"spell(Ice Barrier).cooldown > 0 & !player.buff(Combustion) & !player.buff(Rune of Power)}}" ..
				"& !player.buff(Ice Block) & !player.debuff(Hypothermia)"
	},
	{"#127834", "player.health < 20 & !player.buff(Ice Barrier) & spell(Ice Barrier).cooldown > 0"},
	{
		"Ice Barrier",
		"{customkeybind(q) || player.health < 30} & !player.buff(Ice Barrier) &" ..
				"!player.buff(Combustion) & !player.buff(Rune of Power)"
	},

}

local Talents = {
	{
		"Flame On",
		"talent(4,2) & {spell(Fire Blast).charges < 0.2 & {spell(Combustion).cooldown > 65 ||" ..
				"target.bossttd < spell(Combustion).cooldown}}"
	},
	{
		"Blast Wave",
		"talent(4,1) & toggle(aoe) & {!player.buff(Combustion) || {player.buff(Combustion) &" ..
				"spell(Fire Blast).charges < 1 & spell(Phoenix's Flames).charges < 1}}"
	},
	{
		"Meteor",
		"talent(7,3) & toggle(aoe) & {spell(Combustion).cooldown > 30 || {spell(Combustion).cooldown" ..
				"> target.bossttd} || player.buff(Rune of Power)}"
	},
	{
		"Cinderstorm",
		"talent(7,2) & toggle(aoe) & {spell(Combustion).cooldown < spell(Cinderstorm).casttime &" ..
				"{player.buff(Rune of Power) || !talent(3,2)} || spell(Combustion).cooldown > 10 * shaste" ..
				"& !player.buff(Combustion)}"
	},
	{"Dragon's Breath", "equipped(132863)"},
	{
		"Living Bomb",
		"talent(6,1) & {player.area(40).enemies > 1 & toggle(aoe)} & !player.buff(Combustion)"
	}
}

local CombustionRotation = {
	{Talents},
	{"#139326", "equipped(139326) & !player.buff(Combustion)"},
	{"#127843", "UI(potion) & hashero & boss1.exists"},
	{
		"#132510",
		"UI(gunpowder) & {target.relativehealth > 5 || target.boss} & !{UI(potion) & boss1.exists} &" ..
				"player.buff(Combustion) & player.buff(Rune of Power) &" ..
				"player.buff(Pyretic Incantation).count = 5"
	},
	{"Rune of Power", "!player.buff(Combustion)"},
	{
		"&Combustion",
		"player.buff(Rune of Power) || {player.casting(Rune of Power) & player.casting.percent > 80}"
	},
	{"Blood Fury"},
	{"Berserking"},
	{"&Pyroblast", "player.buff(Hot Streak!) & player.buff(Combustion)"},
	{
		"Phoenix's Flames",
		"spell(Phoenix's Flames).charges>2.7 & player.buff(Combustion) & !player.buff(Hot Streak!)"
	},
	{
		"&Fire Blast",
		"player.buff(Heating Up) & !player.lastcast(Fire Blast) & player.buff(Combustion)"
	},
	{"Phoenix's Flames"},
	{"Scorch", "player.buff(Combustion).duration > spell(Scorch).casttime"},
}

local MainRotation = {
	{
		"Pyroblast",
		"player.buff(Hot Streak!) & player.buff(Hot Streak!).duration < spell(Fireball).casttime"
	},
	{"Phoenix's Flames", "spell(Phoenix's Flames).charges > 2.7"},
	{
		"Flamestrike",
		"talent(6,3) & target.area(10).enemies > 2 & player.buff(Hot Streak!)",
		"target.ground"
	},
	{
		"&Pyroblast",
		"player.buff(Hot Streak!) & {lastgcd(Fireball) || player.casting(Fireball) ||" ..
				"player.casting(Pyroblast) || !" .. cancast .. "}"
	},
	{Talents},
	{"Pyroblast", "player.buff(Hot Streak!) & target.health <= 25 & equipped(132454)"},
	{
		CastPyroblast,
		"target.relativehealth > 1 & !player.casting(Pyroblast) & !player.buff(Hot Streak!) &" ..
				"player.buff(Kael'thas's Ultimate Ability).duration > spell(Pyroblast).casttime + gcd" ..
				"&" .. cancast
	},
	{"Phoenix's Flames", "!player.buff(Hot Streak!) & spell(Phoenix's Flames).charges > 2.7"},
	{
		"&Fire Blast",
		"!talent(7,1) & player.buff(Heating Up) & {player.casting(Fireball) ||" ..
				"player.casting(Pyroblast) || !".. cancast .."} & !lastcast(Fire Blast) &" ..
				"{!talent(3,2) || spell(Fire Blast).charges > 1.4 || spell(Combustion).cooldown < 40} &" ..
				"{3 - spell(Fire Blast).charges} * {12 * shaste} <= spell(Combustion).cooldown + 3" ..
				"|| target.bossttd < 4"
	},
	{
		"&Fire Blast",
		"talent(7,1) & player.buff(Heating Up) & {player.casting(Fireball) ||" ..
				"player.casting(Pyroblast) || !" ..	cancast .. "} & !lastcast(Fire Blast) &" ..
				"{!talent(3,2) || spell(Fire Blast).charges > 1.5 || {spell(Combustion).cooldown < 40}}" ..
				"& {3 - spell(Fire Blast).charges} * {18 * shaste} <= spell(Combustion).cooldown +" ..
				"3 || target.bossttd < 4"
	},
	{
		"Phoenix's Flames",
		"!player.buff(Hot Streak!) & {player.buff(Combustion) || {player.buff(Rune of Power) &" ..
				"player.buff(Pyretic Incantation).count > 3} || player.buff(Incanter's Flow).count > 3 ||" ..
				"talent(3,1)} & {4 - spell(Phoenix's Flames).charges} * 13 < spell(Combustion).cooldown" ..
				"+ 5 || target.bossttd < 10"
	},
	{
		"Phoenix's Flames",
		"!player.buff(Hot Streak!) & {player.buff(Combustion) || {player.buff(Rune of Power) &" ..
				"player.buff(Pyretic Incantation).count > 3}} & {4 - spell(Phoenix's Flames).charges} * 30" ..
				"< spell(Combustion).cooldown + 5"
	},
	{"Scorch", "target.health <= 25 & equipped(132454)"},
	{CastFireball, cancast},
	{
		"Ice Barrier",
		"!player.buff(Ice Barrier) & !player.buff(Combustion) & !player.buff(Rune of Power)"
	},
	{"Scorch", "moving & !player.buff(Ice Floes)"}
}

local Combat = {
	{"!Slow Fall", "player.debuff(Sapped Soul)", "player"},
	{
		"Rune of Power",
		"{target.relativehealth > 1 || target.boss} & toggle(cooldowns) & !moving &" ..
				"{spell(Combustion).cooldown > 40 || !toggle(combustion)} & {!player.buff(Combustion) &" ..
				"{spell(Flame On).cooldown < 5 || spell(Flame On).cooldown > 30} & !talent(7,1) ||" ..
				"target.bossttd < 11 || talent(7,1) & {spell(Rune of Power).charges > 1.8 ||" ..
				"player.combat.time < 40} & {spell(Combustion).cooldown > 40 || !toggle(combustion)}}"
	},
	{
		CombustionRotation,
		"player.buff(Combustion) || {{target.relativehealth > 1 || target.boss} &" ..
				"toggle(combustion) & toggle(cooldowns) & {!moving || player.buff(Combustion)} &" ..
				"{spell(Combustion).cooldown <= spell(Rune of Power).casttime || player.buff(Combustion)}}"
	},
	{MainRotation}
}

local IC = {
	{"/equip Felo'melorn", "!equipped(128820)"},
	{Keybinds},
	{Interrupts, "target.interruptAt(50) & toggle(interrupts) & target.canfireball & target.infront"},
	{Survival},
	{Combat, "target.canfireball & target.infront"}
}

local OOC = {
	{Keybinds},
	{Survival},
	{
		"&/stopcasting",
		"!customkeybind(1) & !customkeybind(2) & player.casting(Fireball) & player.casting.percent < 80"
	},
	{CastFireball, "customkeybind(1) &".. cancast},
	{IC, "customkeybind(2)"},
}

CDC.CR = {
	name = CDC.Name,
	ic = IC,
	ooc = OOC,
	load = CDC.ExeOnLoad,
	unload = CDC.ExeOnUnload,
	gui = CDC.GUI,
}

NeP.CR:Add(63, CDC.CR)


--/dump NeP.Interface:Fetch("TOGGLE_STATES", "mastertoggle")
--/script NeP.Interface:toggleToggle("mastertoggle", true)
--/script NeP.Interface:toggleToggle("mastertoggle", false)
