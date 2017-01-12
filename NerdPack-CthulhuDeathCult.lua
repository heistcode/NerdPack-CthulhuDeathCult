-- luacheck: globals NeP
local CDC                  = (select(2, ...))
local UnitBuff             = UnitBuff
local UnitHealth           = UnitHealth
local UnitHealthMax        = UnitHealthMax
local IsSpellInRange       = IsSpellInRange
local SecureCmdOptionParse = SecureCmdOptionParse
local RunMacroText         = RunMacroText
local select               = select
local floor                = floor
local NeP                  = NeP

CDC.Name                   = "Cthulhu Death Cult"
CDC.Version                = 0.50

_G["BINDING_HEADER_CDC"]   = CDC.Name

function CDC.VehicleUICallback(button, down)
	if down and (SecureCmdOptionParse("[overridebar][vehicleui][possessbar,@vehicle,exists]")) then
		RunMacroText("/click ElvUI_Bar1Button" .. button .. "\n/click OverrideActionBarButton" .. button)
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

NeP.DSL:Register("spellsteal", function(target)
	if IsSpellInRange("Spellsteal", target) == 1 then
		for i = 1, 40 do
			if select(9, UnitBuff(target, i)) then
				return true
			end
		end
	end
end)

NeP.DSL:Register("mounted", function()
	return (SecureCmdOptionParse("[mounted]")) and true
end)

CDC.GUI = {
	{
		type    = "checkbox",
		text    = "Use Potion",
		key     = "potion",
		default = false,
		desc    = "Use potion during heroisam"
	},
	{
		type    = "checkbox",
		text    = "Use Gunpowder Charge",
		key     = "gunpowder",
		default = false,
		desc    = "Use gunpowdercharge during combustion"
	},
	{
		type    = "checkbox",
		text    = "Auto Ice Block",
		key     = "autoiceblock",
		default = true,
		desc    = "Use Ice Block automatically at 15% HP"
	},
	{
		type    = "checkbox",
		text    = "Auto Blazing Barrier",
		key     = "autoicebarrier",
		default = true,
		desc    = "Use Blazing Barrier automatically at 30% HP"
	},
	{
		type    = "checkbox",
		text    = "Auto Health Potion",
		key     = "autohppotion",
		default = true,
		desc    = "Use health potion automatically at 20% HP"
	},
}

function CDC.ExeOnLoad()

	NeP.CustomKeybind:Add(CDC.Name, "Q")
	NeP.CustomKeybind:Add(CDC.Name, "SHIFT-Q")
	NeP.CustomKeybind:Add(CDC.Name, "V")
	NeP.CustomKeybind:Add(CDC.Name, "F")

	NeP.CustomKeybind:Add(CDC.Name, "1", CDC.VehicleUICallback)
	NeP.CustomKeybind:Add(CDC.Name, "2", CDC.VehicleUICallback)
	NeP.CustomKeybind:Add(CDC.Name, "3", CDC.VehicleUICallback)
	NeP.CustomKeybind:Add(CDC.Name, "4", CDC.VehicleUICallback)

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

local castflamestrike = "customkeybind(1)"

local Keybinds = {
	{"%pause", "keybind(alt)"},
	{
		"/clearfocus [@focus,dead][@focus,noexists][mod:shift][@focus,noharm]\n" ..
				"/focus [@focus,noexists]\n/cast [@focus]Polymorph(Black Cat)",
		"customkeybind(v)"
	},
	{"Spellsteal", "customkeybind(f) & target.spellsteal"},
	{"%pause", "mounted & !customkeybind(4)"},
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
		"!Blazing Barrier",
		"UI(autoicebarrier) & player.health < 20 & !player.buff(Blazing Barrier) &" ..
				"!player.buff(Combustion) & !player.buff(Rune of Power)",
		"player"
	},
	{
		"!Ice Block",
		"{customkeybind(shift q) || {UI(autoiceblock) & player.combat & player.health < 15 &" ..
		 		"!player.buff(Ice Barrier) & spell(Ice Barrier).cooldown > 0 & !player.buff(Combustion) &" ..
				"!player.buff(Rune of Power)}} & !player.buff(Ice Block) & !player.debuff(Hypothermia)",
		"player"
	},
	{
		"#127834",
		"UI(autohppotion) & player.combat & player.health < 20 & !player.buff(Ice Barrier) &" ..
				"spell(Ice Barrier).cooldown > 0",
		"player"
	},
	{
		"Blazing Barrier",
		"{customkeybind(q) || {UI(autoicebarrier) & player.health < 30}} & !player.buff(Blazing Barrier)" ..
				"& !player.buff(Combustion) & !player.buff(Rune of Power)",
		"player"
	},

}

local Talents = {
	{
		"Flame On",
		"talent(4,2) & {spell(Fire Blast).charges < 0.5 & {spell(Combustion).cooldown > 60 ||" ..
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
		"customkeybind(2)"
		--"talent(6,1) & toggle(aoe) & !player.buff(Combustion) & player.area(40).enemies > 1"
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
	{
		"Fireball",
		"equipped(139326) & !player.buff(Combustion) & player.buff(Maddening Whispers).count > 7 &" ..
		 		"!moving"
	},
	{
		"Scorch",
		"equipped(139326) & !player.buff(Combustion) & player.buff(Maddening Whispers).count > 7 &" ..
				"moving"
	},
	{"Rune of Power", "!player.buff(Combustion)"},
	{"&Combustion", "player.casting(Rune of Power) & player.casting.percent > 80"},
	{"Blood Fury"},
	{"Berserking"},
	--{"Flamestrike", castflamestrike .. "& player.buff(Hot Streak!)", "cursor.ground"},
	{"/cast [@cursor] Flamestrike", castflamestrike .. "& player.buff(Hot Streak!)"},
	{"&Pyroblast", "!" .. castflamestrike .. "& player.buff(Hot Streak!) & player.buff(Combustion)"},
	{
		"Phoenix's Flames",
		"spell(Phoenix's Flames).charges > 2.7 & player.buff(Combustion) & !player.buff(Hot Streak!)"
	},
	{
		"&Fire Blast",
		"player.buff(Heating Up) & !player.lastcast(Fire Blast) & player.buff(Combustion)"
	},
	{"Phoenix's Flames"},
	{"Scorch", "player.buff(Combustion).duration > spell(Scorch).casttime"},
}

local MainRotation = {
	--{"Flamestrike", castflamestrike .. "& player.buff(Hot Streak!)", "cursor.ground"},
	{"/cast [@cursor] Flamestrike", castflamestrike .. "& player.buff(Hot Streak!)"},
	{
		"&Pyroblast",
		"!" .. castflamestrike .. "& player.buff(Hot Streak!) & player.buff(Hot Streak!).duration <" ..
				"spell(Fireball).casttime"
	},
	{
		"&Pyroblast",
		"!" .. castflamestrike .. "& player.buff(Hot Streak!) & {lastgcd(Fireball) ||" ..
				"player.casting(Fireball) || player.casting(Pyroblast) || moving}"
	},
	{
		"&Pyroblast",
		"!" .. castflamestrike .. "& player.buff(Hot Streak!) & target.health <= 25 & equipped(132454)"
	},
	{Talents},
	{
		"Pyroblast",
		"!customkeybind(1) & !customkeybind(2) &" ..
				"target.relativehealth > 10 &" ..
				"!player.casting(Pyroblast) & !player.buff(Hot Streak!) &" ..
				"player.buff(Kael'thas's Ultimate Ability).duration > spell(Pyroblast).casttime + gcd" ..
				"& !lastgcd(Pyroblast) & !moving"
	},
	{
		"Phoenix's Flames",
		"!player.buff(Hot Streak!) & spell(Phoenix's Flames).charges > 2.7 & spell(Combustion).cooldown > 0"
	},
	{
		"&Fire Blast",
		"!talent(7,1) & player.buff(Heating Up) & {player.casting(Fireball) ||" ..
				"player.casting(Pyroblast) || moving} & !lastcast(Fire Blast) & {!talent(3,2) ||" ..
				"spell(Fire Blast).charges > 1.4 || {toggle(combustion) & toggle(cooldowns) &" ..
				"spell(Combustion).cooldown < 40}} & {{3 - spell(Fire Blast).charges} * {12 * shaste} <=" ..
				"spell(Combustion).cooldown + 3 || target.bossttd < 4 || !toggle(combustion) ||" ..
				"!toggle(cooldowns)}"
	},
	{
		"&Fire Blast",
		"talent(7,1) & player.buff(Heating Up) & {player.casting(Fireball) ||" ..
				"player.casting(Pyroblast) || moving} & !lastcast(Fire Blast) & {!talent(3,2) ||" ..
				"spell(Fire Blast).charges > 1.5 || {toggle(combustion) & toggle(cooldowns) &"..
				"spell(Combustion).cooldown < 40}} & {{3 - spell(Fire Blast).charges} * {18 * shaste} <=" ..
				"spell(Combustion).cooldown + 3 || target.bossttd < 4 || !toggle(combustion) ||" ..
				"!toggle(cooldowns)}"
	},
	{
		"&Fire Blast",
		"spell(Combustion).cooldown > 60 & spell(Combustion).cooldown < 65 &" ..
				"spell(Flame On).cooldown = 0"
	},
	{
		"Phoenix's Flames",
		"!player.buff(Hot Streak!) & {player.buff(Combustion) || player.buff(Rune of Power)} &" ..
				"{4 - spell(Phoenix's Flames).charges} * 13 < spell(Combustion).cooldown + 5 ||" ..
				"target.bossttd < 10"
	},
	{
		"Phoenix's Flames",
		"!player.buff(Hot Streak!) & {player.buff(Combustion) || player.buff(Rune of Power)} &" ..
				"{4 - spell(Phoenix's Flames).charges} * 30 < spell(Combustion).cooldown + 5"
	},
	{"Scorch", "target.health <= 25 & equipped(132454)"},
	{"Fireball", "!moving"},
	{
		"Blazing Barrier",
		"!player.buff(Blazing Barrier) & !player.buff(Combustion) & !player.buff(Rune of Power)"
	},
	{"Scorch"}
}

local Combat = {
	{
		"Rune of Power",
		"{{boss1.exists & target.relativehealth > 5 || target.relativehealth > 1} || target.boss} &" ..
				"toggle(cooldowns) & !moving & !player.buff(Combustion) & {spell(Combustion).cooldown > 90" ..
				"|| {toggle(combustion) & spell(Combustion).cooldown > 17 & spell(Rune of Power).charges" ..
				"> 1.75} || {!toggle(combustion) & spell(Rune of Power).charges > 1.9}}"
	},
	{
		"#139326",
		"equipped(139326) & !player.buff(Combustion) & {{{boss1.exists & target.relativehealth > 5 ||" ..
				"target.relativehealth > 1} || target.boss || customkeybind(3)} &" ..
				"{!player.buff(Rune of Power) & spell(Rune of Power).cooldown = 0} & toggle(combustion) &" ..
				"toggle(cooldowns) & !moving & spell(Combustion).cooldown <= 7}"
	},
	{
		CombustionRotation,
		"player.buff(Combustion) || {{{boss1.exists & target.relativehealth > 5 ||" ..
				"target.relativehealth > 1} || target.boss || customkeybind(3)} &" ..
				"{player.casting(Rune of Power) || {!player.buff(Rune of Power) &" ..
				"spell(Rune of Power).cooldown = 0}} & toggle(combustion) & toggle(cooldowns) &" ..
				"{player.casting(Rune of Power) || !moving || player.buff(Maddening Whispers)} &" ..
				"spell(Combustion).cooldown <= spell(Rune of Power).casttime}"
	},
	{MainRotation}
}

local IC = {
	{"/equip Felo'melorn", "!equipped(128820)"},
	--{"&Ice Floes", "player.debuff(Sapped Soul)"}, todo: Change to something else
	{Keybinds},
	{Interrupts, "target.interruptAt(50) & toggle(interrupts) & target.canfireball & target.infront"},
	{Survival},
	{Combat, "target.canfireball & target.infront"}
}

local OOC = {
	{Keybinds},
	{Survival},
	{
		"#139326",
		"customkeybind(1) & equipped(139326) & spell(Combustion).cooldown <= 7 & toggle(combustion) &" ..
		"toggle(cooldowns)"
	},
	{"Fireball", "customkeybind(1) & !moving"},
	{IC, "customkeybind(2) || customkeybind(4)"},
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
