/*  Quakescent - Quake plus Descent.
    Copyright (C) 2026 the Quakescent contributors.

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.  See LICENSE.
*/

// Quake's pickups as Descent's powerups.
//
//   health                  shields (megahealth +100)
//   armour, cells           energy
//   shells                  concussion missiles
//   nails                   vulcan ammo
//   rockets                 proximity bombs (small box), homing missiles (big)
//   super shotgun           spreadfire cannon
//   nailgun                 vulcan cannon
//   super nailgun           plasma cannon
//   grenade launcher        laser upgrade (a mega missile once the lasers
//                           are at level 4)
//   rocket launcher         smart missile
//   thunderbolt             fusion cannon
//   quad damage             quad lasers
//   pentagram               invulnerability
//   ring of shadows         cloak
//   silver / gold key       blue / yellow key
//
// They spin as Descent's powerup sprites when the asset pack has them.

// The powerup sprite for an item, or "" to keep Quake's model.
string(entity e) QS_PowerupFor =
{
	local string c;

	c = e.classname;
	if (c == "item_health")
		return (e.spawnflags & H_MEGA) ? "life" : "shield";
	if (c == "item_armor1" || c == "item_armor2" || c == "item_armorInv" || c == "item_cells")
		return "energy";
	if (c == "item_shells")
		return (e.spawnflags & WEAPON_BIG2) ? "conc4" : "conc1";
	if (c == "item_spikes")
		return "vammo";
	if (c == "item_rockets")
		return (e.spawnflags & WEAPON_BIG2) ? "homing4" : "prox";
	if (c == "item_weapon")
	{
		if (e.spawnflags & WEAPON_SHOTGUN)
			return (e.spawnflags & WEAPON_BIG) ? "conc4" : "conc1";
		if (e.spawnflags & WEAPON_ROCKET)
			return (e.spawnflags & WEAPON_BIG) ? "homing4" : "prox";
		return "vammo";
	}
	if (c == "weapon_supershotgun")
		return "spread";
	if (c == "weapon_nailgun")
		return "vulcan";
	if (c == "weapon_supernailgun")
		return "plasma";
	if (c == "weapon_grenadelauncher")
		return "laser";
	if (c == "weapon_rocketlauncher")
		return "smart";
	if (c == "weapon_lightning")
		return "fusion";
	if (c == "item_artifact_super_damage")
		return "quad";
	if (c == "item_artifact_invulnerability")
		return "invuln";
	if (c == "item_artifact_invisibility")
		return "cloak";
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

	list = "life shield energy conc1 conc4 vammo homing1 homing4 prox spread vulcan plasma laser smart fusion quad invuln cloak keyb keyy mega";
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

	if (!autocvar_qs_ship)
		return;
	pw = QS_PowerupFor(self);
	if (pw == "" || !QS_HavePowerup(pw))
		return;
	c = self.origin + (self.mins + self.maxs) * 0.5;
	setmodel(self, strcat("progs/qs/pw_", pw, ".spr32"));
	setsize(self, '-16 -16 -16', '16 16 16');
	setorigin(self, c + '0 0 4');
	self.scale = 0.5;
	if (pw == "life" || pw == "shield" || pw == "energy" || pw == "vammo")
		self.scale = 0.4;
	if (pw == "quad" || pw == "laser" || pw == "vulcan" || pw == "spread" || pw == "plasma" || pw == "fusion")
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
	maxn = QS_MissileMax(sw);
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
		if (pw == PW_VULCAN)
			return QS_GiveVulcanAmmo(ship, 196);
		return QS_GiveEnergy(ship, QS_BoostAmount(), FALSE);
	}
	ship.qs_owned = ship.qs_owned | (1 << pw);
	QS_Message(ship, strcat(QS_PrimaryName(pw), "!"));
	if (pw == PW_VULCAN)
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
	if (ship.qs_laser >= 3)
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
float() QS_ItemTouch =
{
	local string c;
	local float got, snd, respawn;

	if (other.health <= 0)
		return TRUE;
	c = self.classname;
	got = FALSE;
	snd = 83;
	respawn = 30;

	if (c == "item_health")
	{
		if (self.spawnflags & H_MEGA)
		{
			got = QS_GiveShields(other, 100, FALSE);
			snd = 82;
			respawn = 120;
		}
		else
		{
			got = QS_GiveShields(other, QS_BoostAmount(), FALSE);
			snd = 80;
			respawn = 20;
		}
	}
	else if (c == "item_armor1")
	{
		got = QS_GiveEnergy(other, 50, FALSE);
		snd = 81;
	}
	else if (c == "item_armor2")
	{
		got = QS_GiveEnergy(other, 75, FALSE);
		snd = 81;
	}
	else if (c == "item_armorInv")
	{
		got = QS_GiveEnergy(other, 100, FALSE);
		snd = 81;
	}
	else if (c == "item_cells")
	{
		got = QS_GiveEnergy(other, (self.spawnflags & WEAPON_BIG2) ? 50 : QS_BoostAmount(), FALSE);
		snd = 81;
	}
	else if (c == "item_shells" || (c == "item_weapon" && (self.spawnflags & WEAPON_SHOTGUN)))
		got = QS_GiveMissiles(other, SW_CONCUSSION, (self.spawnflags & (WEAPON_BIG2 | WEAPON_BIG)) ? 4 : 1);
	else if (c == "item_spikes" || (c == "item_weapon" && (self.spawnflags & WEAPON_SPIKES)))
		got = QS_GiveVulcanAmmo(other, (self.spawnflags & (WEAPON_BIG2 | WEAPON_BIG)) ? 98 : 49);
	else if (c == "item_rockets" || (c == "item_weapon" && (self.spawnflags & WEAPON_ROCKET)))
	{
		if (self.spawnflags & (WEAPON_BIG2 | WEAPON_BIG))
			got = QS_GiveMissiles(other, SW_HOMING, 4);
		else
			got = QS_GiveMissiles(other, SW_PROXIMITY, 4);
	}
	else if (c == "weapon_supershotgun")
		got = QS_GivePrimary(other, PW_SPREADFIRE);
	else if (c == "weapon_nailgun")
		got = QS_GivePrimary(other, PW_VULCAN);
	else if (c == "weapon_supernailgun")
		got = QS_GivePrimary(other, PW_PLASMA);
	else if (c == "weapon_lightning")
		got = QS_GivePrimary(other, PW_FUSION);
	else if (c == "weapon_grenadelauncher")
		got = QS_GiveLaserUpgrade(other);
	else if (c == "weapon_rocketlauncher")
		got = QS_GiveMissiles(other, SW_SMART, 1);
	else if (c == "item_artifact_super_damage")
	{
		if (other.qs_quad)
			got = QS_GiveEnergy(other, QS_BoostAmount(), FALSE);
		else
		{
			other.qs_quad = TRUE;
			QS_Message(other, "Quad lasers!");
			got = TRUE;
		}
		respawn = 60;
	}
	else if (c == "item_artifact_invulnerability")
	{
		other.items = other.items | IT_INVULNERABILITY;
		other.invincible_time = 1;
		other.invincible_finished = time + 30;
		QS_Message(other, "Invulnerability!");
		got = TRUE;
		snd = 162;
		respawn = 300;
	}
	else if (c == "item_artifact_invisibility")
	{
		other.items = other.items | IT_INVISIBILITY;
		other.invisible_time = 1;
		other.invisible_finished = time + 30;
		QS_Message(other, "Cloaking device on!");
		got = TRUE;
		snd = 160;
		respawn = 300;
	}
	else
		return FALSE;

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
		QS_SetMissiles(self, sw, QS_MissileMax(sw));
	self.items = self.items | IT_KEY1 | IT_KEY2;
	QS_Message(self, "Wowie zowie!");
};
