/*  Quakescent - Quake plus Descent.
    Copyright (C) 2026 the Quakescent contributors.

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.  See LICENSE.
*/

// Quake's pickups as Descent's powerups (the README has the full list).
// They spin as Descent's powerup sprites when the asset pack has them.

// What a Quake item becomes: the name of its Descent powerup (which is
// also its sprite), or "" to leave it to Quake.  In Descent II mode about
// half of the weapons and ammo turn into the Descent II versions, and the
// biosuit and armours carry Descent II's equipment.
string(entity e) QS_ItemKind =
{
	local string c;
	local float alt, big;

	c = e.classname;
	alt = qs_game == 2 && (num_for_edict(e) & 1);
	big = e.spawnflags & (WEAPON_BIG2 | WEAPON_BIG);
	if (c == "item_health")
	{
		if (e.spawnflags & H_MEGA)
			return alt ? "shaker" : "life";
		return "shield";
	}
	if (c == "item_armor1")
		return alt ? "headlight" : "energy";
	if (c == "item_armor2")
		return alt ? "converter" : "energy";
	if (c == "item_armorInv")
		return alt ? "ammorack" : "energy";
	if (c == "item_cells")
		return "energy";
	if (c == "item_shells" || (c == "item_weapon" && (e.spawnflags & WEAPON_SHOTGUN)))
	{
		if (alt)
			return big ? "flash4" : "flash1";
		return big ? "conc4" : "conc1";
	}
	if (c == "item_spikes" || c == "item_weapon")
	{
		if (c == "item_weapon" && (e.spawnflags & WEAPON_ROCKET))
		{
			if (big)
				return alt ? "guided4" : "homing4";
			return alt ? "smine" : "prox";
		}
		return "vammo";
	}
	if (c == "item_rockets")
	{
		if (big)
			return alt ? "guided4" : "homing4";
		return alt ? "smine" : "prox";
	}
	if (c == "weapon_supershotgun")
		return alt ? "helix" : "spread";
	if (c == "weapon_nailgun")
		return alt ? "gauss" : "vulcan";
	if (c == "weapon_supernailgun")
		return alt ? "phoenix" : "plasma";
	if (c == "weapon_grenadelauncher")
		return "laser";
	if (c == "weapon_rocketlauncher")
		return alt ? "mercury4" : "smart";
	if (c == "weapon_lightning")
		return alt ? "omega" : "fusion";
	if (c == "item_artifact_super_damage")
		return "quad";
	if (c == "item_artifact_invulnerability")
		return "invuln";
	if (c == "item_artifact_invisibility")
		return "cloak";
	if (c == "item_artifact_envirosuit" && qs_game == 2)
		return "afterburner";
	if (c == "item_key1")
		return "keyb";
	if (c == "item_key2")
		return "keyy";
	return "";
};

// Precache the powerup sprites the pack has.
void() QS_PrecachePowerups =
{
	local float n, i;
	local string list;

	list = "life shield energy conc1 conc4 vammo homing1 homing4 prox spread vulcan plasma laser smart fusion quad invuln cloak keyb keyy mega gauss helix phoenix omega super converter ammorack afterburner headlight flash1 flash4 guided1 guided4 smine mercury1 mercury4 shaker";
	n = tokenize(list);
	for (i = 0; i < n; i++)
		if (QS_HavePowerup(argv(i)))
			precache_model(strzone(strcat("progs/qs/pw_", argv(i), ".spr32")));
};

// Called once an item has dropped to the floor: swap Quake's model for the
// Descent powerup, centred where the item was and floating a little.
void() QS_ItemLook =
{
	local string pw;
	local vector c;

	pw = QS_ItemKind(self);
	if (pw == "" || !QS_HavePowerup(pw))
		return;
	c = self.origin + (self.mins + self.maxs) * 0.5;
	setmodel(self, strcat("progs/qs/pw_", pw, ".spr32"));
	setsize(self, '-16 -16 -16', '16 16 16');
	setorigin(self, c + '0 0 4');
	self.scale = 0.5;
	if (pw == "life" || pw == "shield" || pw == "energy" || pw == "vammo")
		self.scale = 0.4;
	if (pw == "quad" || pw == "laser" || pw == "vulcan" || pw == "spread" || pw == "plasma" || pw == "fusion"
		|| pw == "gauss" || pw == "helix" || pw == "phoenix" || pw == "omega")
		self.scale = 0.55;
	self.effects = self.effects | EF_FULLBRIGHT;
};

//==========================================================================
// Picking things up

float() QS_BoostAmount =
{
	// Descent's shield and energy boosts: 3 + 3 per level below Insane.
	return 3 + 3 * (5 - QS_Difficulty());
};

float(entity ship, float amount, float allowfull) QS_GiveShields =
{
	if (ship.health >= QS_MAX_SHIELDS && !allowfull)
	{
		QS_Message(ship, "Your shield is maxed out!");
		return FALSE;
	}
	ship.health = min(ship.health + amount, QS_MAX_SHIELDS);
	QS_Message(ship, strcat("Shield boosted to ", ftos(floor(ship.health)), "!"));
	return TRUE;
};

float(entity ship, float amount, float allowfull) QS_GiveEnergy =
{
	if (ship.qs_energy >= QS_MAX_ENERGY && !allowfull)
	{
		QS_Message(ship, "Your energy is maxed out!");
		return FALSE;
	}
	ship.qs_energy = min(ship.qs_energy + amount, QS_MAX_ENERGY);
	QS_Message(ship, strcat("Energy boosted to ", ftos(floor(ship.qs_energy)), "!"));
	return TRUE;
};

float(entity ship, float sw, float n) QS_GiveMissiles =
{
	local float have, maxn, got;
	local entity oself;

	have = QS_Missiles(ship, sw);
	maxn = QS_MissileMaxFor(ship, sw);
	if (have >= maxn)
	{
		QS_Message(ship, strcat("You can't carry any more ", QS_SecondaryName(sw), "s!"));
		return FALSE;
	}
	got = min(n, maxn - have);
	QS_SetMissiles(ship, sw, have + got);
	if (got == 1)
		QS_Message(ship, strcat(QS_SecondaryName(sw), "!"));
	else
		QS_Message(ship, strcat(ftos(got), " ", QS_SecondaryName(sw), "s!"));
	// Descent selects a better missile when you pick one up.
	if (sw > ship.qs_secondary || QS_Missiles(ship, ship.qs_secondary) <= 0)
	{
		if (sw != SW_PROXIMITY || QS_Missiles(ship, ship.qs_secondary) <= 0)
		{
			oself = self;
			self = ship;
			QS_SelectSecondary(sw, TRUE);
			self = oself;
		}
	}
	return TRUE;
};

float(entity ship, float units) QS_GiveVulcanAmmo =
{
	if (ship.qs_vulcan >= QS_VULCAN_MAX)
	{
		QS_Message(ship, "You can't carry any more vulcan ammo!");
		return FALSE;
	}
	ship.qs_vulcan = min(ship.qs_vulcan + units, QS_VULCAN_MAX);
	QS_Message(ship, "Vulcan ammo!");
	return TRUE;
};

float(entity ship, float pw) QS_GivePrimary =
{
	local entity oself;

	if (ship.qs_owned & (1 << pw))
	{
		// Already have it: the vulcan gives its ammo, the others energy.
		if (pw == PW_VULCAN || pw == PW_GAUSS)
			return QS_GiveVulcanAmmo(ship, 196);
		return QS_GiveEnergy(ship, QS_BoostAmount(), FALSE);
	}
	ship.qs_owned = ship.qs_owned | (1 << pw);
	QS_Message(ship, strcat(QS_PrimaryName(pw), "!"));
	if (pw == PW_OMEGA)
		ship.qs_omega = 1;
	if (pw == PW_VULCAN || pw == PW_GAUSS)
		ship.qs_vulcan = min(ship.qs_vulcan + 196, QS_VULCAN_MAX);
	// Descent switches to a newly found weapon if it's better.
	if (pw > ship.qs_primary)
	{
		oself = self;
		self = ship;
		QS_SelectPrimary(pw, TRUE);
		self = oself;
	}
	return TRUE;
};

float(entity ship) QS_GiveLaserUpgrade =
{
	local entity oself;

	// Descent II's super laser is laser levels 5 and 6.
	if (qs_game == 2 && ship.qs_laser >= 3 && ship.qs_laser < 5)
	{
		ship.qs_laser = ship.qs_laser + 1;
		QS_Message(ship, strcat("Super boost to laser level ", ftos(ship.qs_laser + 1), "!"));
		if (ship.qs_primary == PW_LASER)
		{
			ship.qs_owned = ship.qs_owned | (1 << PW_SUPERLASER);
			oself = self;
			self = ship;
			QS_SelectPrimary(PW_SUPERLASER, TRUE);
			self = oself;
		}
		return TRUE;
	}
	if (ship.qs_laser >= ((qs_game == 2) ? 5 : 3))
	{
		if (QS_GiveMissiles(ship, SW_MEGA, 1))
			return TRUE;
		return QS_GiveEnergy(ship, QS_BoostAmount(), FALSE);
	}
	ship.qs_laser = ship.qs_laser + 1;
	QS_Message(ship, strcat("Laser cannon boosted to level ", ftos(ship.qs_laser + 1), "!"));
	return TRUE;
};

// The item has been taken: hide it, respawn it later in deathmatch, and
// fire its targets as Quake's items do.
void(float respawn) QS_ItemTaken =
{
	self.model = string_null;
	self.solid = SOLID_NOT;
	if (deathmatch && deathmatch != 2 && respawn > 0)
	{
		self.nextthink = time + respawn;
		self.think = SUB_regen;
	}
	activator = other;
	SUB_UseTargets();
};

// Touch function for every item when the toucher is a ship.  Returns FALSE
// for items it leaves to Quake (keys, the biosuit, sigils).
// Descent II's equipment: give it once.
float(entity ship, float flag, string name) QS_GiveEquipment =
{
	if (ship.qs_flags & flag)
	{
		QS_Message(ship, strcat("You already have the ", name, "!"));
		return QS_GiveEnergy(ship, QS_BoostAmount(), FALSE);
	}
	ship.qs_flags = ship.qs_flags | flag;
	ship.qs_carryflags = ship.qs_carryflags | flag;
	QS_Message(ship, strcat(name, "!"));
	if (flag == QSF_AFTERBURNER)
		ship.qs_burn = 1;
	return TRUE;
};

// Touch function for every item when the toucher is a ship.  Returns FALSE
// for items it leaves to Quake (keys, the biosuit in Descent 1, sigils).
float() QS_ItemTouch =
{
	local string k, c;
	local float got, snd, respawn;

	if (other.health <= 0)
		return TRUE;
	k = QS_ItemKind(self);
	c = self.classname;
	if (k == "" || k == "keyb" || k == "keyy")
		return FALSE;
	got = FALSE;
	snd = 83;
	respawn = 30;

	switch (k)
	{
	case "life":
		got = QS_GiveShields(other, 100, FALSE);
		snd = 82;
		respawn = 120;
		break;
	case "shaker":
		// Descent II: a megahealth also brings an earthshaker.
		got = QS_GiveShields(other, 100, TRUE);
		got = QS_GiveMissiles(other, SW_EARTHSHAKER, 1) || got;
		snd = 82;
		respawn = 120;
		break;
	case "shield":
		got = QS_GiveShields(other, QS_BoostAmount(), FALSE);
		snd = 80;
		respawn = 20;
		break;
	case "energy":
		if (c == "item_armor1")
			got = QS_GiveEnergy(other, 50, FALSE);
		else if (c == "item_armor2")
			got = QS_GiveEnergy(other, 75, FALSE);
		else if (c == "item_armorInv")
			got = QS_GiveEnergy(other, 100, FALSE);
		else
			got = QS_GiveEnergy(other, (self.spawnflags & WEAPON_BIG2) ? 50 : QS_BoostAmount(), FALSE);
		snd = 81;
		break;
	case "headlight":
		got = QS_GiveEquipment(other, QSF_HEADLIGHT, "Headlight");
		break;
	case "converter":
		got = QS_GiveEquipment(other, QSF_CONVERTER, "Energy to shield converter");
		break;
	case "ammorack":
		got = QS_GiveEquipment(other, QSF_AMMORACK, "Ammo rack");
		break;
	case "afterburner":
		got = QS_GiveEquipment(other, QSF_AFTERBURNER, "Afterburner");
		break;
	case "conc1": got = QS_GiveMissiles(other, SW_CONCUSSION, 1); break;
	case "conc4": got = QS_GiveMissiles(other, SW_CONCUSSION, 4); break;
	case "flash1": got = QS_GiveMissiles(other, SW_FLASH, 1); break;
	case "flash4": got = QS_GiveMissiles(other, SW_FLASH, 4); break;
	case "homing4": got = QS_GiveMissiles(other, SW_HOMING, 4); break;
	case "guided4": got = QS_GiveMissiles(other, SW_GUIDED, 4); break;
	case "prox": got = QS_GiveMissiles(other, SW_PROXIMITY, 4); break;
	case "smine": got = QS_GiveMissiles(other, SW_SMARTMINE, 4); break;
	case "smart": got = QS_GiveMissiles(other, SW_SMART, 1); break;
	case "mercury4": got = QS_GiveMissiles(other, SW_MERCURY, 4); break;
	case "vammo":
		got = QS_GiveVulcanAmmo(other, (self.spawnflags & (WEAPON_BIG2 | WEAPON_BIG)) ? 98 : 49);
		break;
	case "spread": got = QS_GivePrimary(other, PW_SPREADFIRE); break;
	case "helix": got = QS_GivePrimary(other, PW_HELIX); break;
	case "vulcan": got = QS_GivePrimary(other, PW_VULCAN); break;
	case "gauss": got = QS_GivePrimary(other, PW_GAUSS); break;
	case "plasma": got = QS_GivePrimary(other, PW_PLASMA); break;
	case "phoenix": got = QS_GivePrimary(other, PW_PHOENIX); break;
	case "fusion": got = QS_GivePrimary(other, PW_FUSION); break;
	case "omega": got = QS_GivePrimary(other, PW_OMEGA); break;
	case "laser": got = QS_GiveLaserUpgrade(other); break;
	case "quad":
		if (other.qs_quad)
			got = QS_GiveEnergy(other, QS_BoostAmount(), FALSE);
		else
		{
			other.qs_quad = TRUE;
			QS_Message(other, "Quad lasers!");
			got = TRUE;
		}
		respawn = 60;
		break;
	case "invuln":
		other.items = other.items | IT_INVULNERABILITY;
		other.invincible_time = 1;
		other.invincible_finished = time + 30;
		QS_Message(other, "Invulnerability!");
		got = TRUE;
		snd = 162;
		respawn = 300;
		break;
	case "cloak":
		other.items = other.items | IT_INVISIBILITY;
		other.invisible_time = 1;
		other.invisible_finished = time + 30;
		QS_Message(other, "Cloaking device on!");
		got = TRUE;
		snd = 160;
		respawn = 300;
		break;
	default:
		return FALSE;
	}

	if (got)
	{
		QS_Sound(other, CHAN_ITEM, snd, 1, ATTN_NORM);
		stuffcmd(other, "bf\n");
		QS_ItemTaken(respawn);
	}
	return TRUE;
};

// A backpack (what a dead monster drops): its Quake ammo as Descent's.
void() QS_BackpackTouch =
{
	local float got;

	got = FALSE;
	if (self.ammo_shells || self.ammo_nails)
		got = QS_GiveVulcanAmmo(other, self.ammo_shells * 2 + self.ammo_nails) || got;
	if (self.ammo_rockets >= 5)
		got = QS_GiveMissiles(other, SW_HOMING, 1) || got;
	if (self.ammo_cells)
		got = QS_GiveEnergy(other, self.ammo_cells * 2, FALSE) || got;
	if (!got)
		return;
	QS_Sound(other, CHAN_ITEM, 83, 1, ATTN_NORM);
	stuffcmd(other, "bf\n");
	remove(self);
};

// Impulse 255 (the old "all weapons" cheat, outside deathmatch).
void() QS_GiveAll =
{
	local float sw;

	self.qs_owned = (1 << QS_NUM_PRIMARIES) - 1;
	self.qs_laser = 3;
	self.qs_quad = TRUE;
	self.qs_vulcan = QS_VULCAN_MAX;
	self.qs_energy = QS_MAX_ENERGY;
	for (sw = 0; sw < QS_NUM_SECONDARIES; sw++)
		QS_SetMissiles(self, sw, QS_MissileMaxFor(self, sw));
	self.items = self.items | IT_KEY1 | IT_KEY2;
	QS_Message(self, "Wowie zowie!");
};
