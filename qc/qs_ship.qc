/*  Quakescent - Quake plus Descent.
    Copyright (C) 2026 the Quakescent contributors.

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.  See LICENSE.
*/

// The player as Descent's Pyro-GX: its movement (run per movement command
// through FTE's SV_RunClientCommand), spawning, dying, the state it keeps
// from level to level, and the stats the cockpit draws.
//
// Shields are the player's health (up to 200); energy, weapons and
// missiles are the fields below.  Quake's armour isn't used.


.float qs_ship;              // flying the Pyro-GX
.float qs_state;             // STAT_QS_STATE
.float qs_energy;
.float qs_laser;             // laser level 0-3 (Descent II: 4-5 are the super laser)
.float qs_quad;              // quad lasers
.float qs_owned;             // bit per primary weapon
.float qs_primary;
.float qs_secondary;
.float qs_vulcan;            // vulcan ammo, in Descent's units (x12.75 = rounds)
.float qs_conc, qs_homing, qs_prox, qs_smart, qs_mega;
.float qs_flash, qs_guided, qs_smine, qs_mercury, qs_shaker;      // Descent II's
.float qs_burn;              // Descent II: afterburner charge, 0-1
.float qs_omega;             // Descent II: omega cannon charge, 0-1
.float qs_guidednum;         // the guided missile being flown (entity number)
.entity qs_guidedmissile;
.float qs_flashed, qs_shaken;
.vector qs_omegagoal;
.float qs_omegatime;
.float qs_flags;             // QSF_*
.float qs_primready, qs_secready, qs_missilegun, qs_fusion;
.float qs_laserstat;         // qs_laser + 8 * qs_quad, for the cockpit
.float qs_impulse_pending;
.float qs_oldbuttons;
.float qs_buttons;           // input_buttons of the last movement command
.float qs_carryflags;        // QSF_* cheats brought from the last level

// Cheats only the server needs to know about (see qs_cheats.qc).
.float qs_cheats;
const float QSC_ENABLED = 1;
const float QSC_RAPIDFIRE = 2;
const float QSC_NOFIRE = 4;
const float QSC_GOD = 8;
const float QSC_BOUNCY = 16;         // Descent II: shots bounce
const float QSC_HOMING = 32;         // Descent II: shots home
const float QSC_GODZILLA = 64;       // Descent II: ramming kills
const float QSC_RABID = 128;         // Descent II: monsters fight each other
// ...and the QSF_* flags that carry over to the next level.
const float QS_CARRY_FLAGS = 448;    // QSF_GHOST | QSF_TURBO | QSF_ACID
// Descent II's equipment, kept from level to level (not the headlight's
// being on).
const float QS_EQUIP_FLAGS = 13824;  // QSF_AFTERBURNER | QSF_HEADLIGHT | QSF_CONVERTER | QSF_AMMORACK

const float QS_VULCAN_MAX = 784;
const float QS_VULCAN_SCALE = 12.75;     // rounds shown per unit

// Descent's Secondary_ammo_max; Descent II's ammo rack doubles it.
float(entity e, float sw) QS_MissileMaxFor =
{
	local float m;

	if (sw == SW_CONCUSSION || sw == SW_FLASH || sw == SW_GUIDED)
		m = 20;
	else if (sw == SW_HOMING || sw == SW_PROXIMITY || sw == SW_MERCURY || sw == SW_EARTHSHAKER)
		m = 10;
	else if (sw == SW_SMARTMINE)
		m = 15;
	else
		m = 5;
	if (sw == SW_EARTHSHAKER)
		m = 10;
	if (e.qs_flags & QSF_AMMORACK)
		m = m * 2;
	return m;
};

float(entity e, float sw) QS_Missiles =
{
	switch (sw)
	{
	case SW_CONCUSSION: return e.qs_conc;
	case SW_HOMING: return e.qs_homing;
	case SW_PROXIMITY: return e.qs_prox;
	case SW_SMART: return e.qs_smart;
	case SW_MEGA: return e.qs_mega;
	case SW_FLASH: return e.qs_flash;
	case SW_GUIDED: return e.qs_guided;
	case SW_SMARTMINE: return e.qs_smine;
	case SW_MERCURY: return e.qs_mercury;
	case SW_EARTHSHAKER: return e.qs_shaker;
	}
	return 0;
};

void(entity e, float sw, float n) QS_SetMissiles =
{
	n = bound(0, n, QS_MissileMaxFor(e, sw));
	switch (sw)
	{
	case SW_CONCUSSION: e.qs_conc = n; break;
	case SW_HOMING: e.qs_homing = n; break;
	case SW_PROXIMITY: e.qs_prox = n; break;
	case SW_SMART: e.qs_smart = n; break;
	case SW_MEGA: e.qs_mega = n; break;
	case SW_FLASH: e.qs_flash = n; break;
	case SW_GUIDED: e.qs_guided = n; break;
	case SW_SMARTMINE: e.qs_smine = n; break;
	case SW_MERCURY: e.qs_mercury = n; break;
	case SW_EARTHSHAKER: e.qs_shaker = n; break;
	}
};

// Descent's difficulty (0 Trainee - 4 Insane) for Quake's skill.
float() QS_Difficulty =
{
	return bound(0, cvar("skill") + 1, 4);
};

void(entity e, float ch, float num, float vol, float attn) QS_Sound =
{
	if (QS_HaveSound(num))
		sound(e, ch, QS_SoundName(num), vol, attn);
};

float qs_quiet;                  // no messages (the reactor cheat's sweep)

// A message on the player's message line (the cockpit draws prints there).
void(entity e, string msg) QS_Message =
{
	if (qs_quiet)
		return;
	sprint(e, strcat(msg, "\n"));
};

//==========================================================================
// Stats

void() QS_RegisterStats =
{
	clientstat(STAT_QS_STATE, EV_FLOAT, qs_state);
	clientstat(STAT_QS_ENERGY, EV_FLOAT, qs_energy);
	clientstat(STAT_QS_PRIMARY, EV_FLOAT, qs_primary);
	clientstat(STAT_QS_SECONDARY, EV_FLOAT, qs_secondary);
	clientstat(STAT_QS_LASER, EV_FLOAT, qs_laserstat);
	clientstat(STAT_QS_VULCAN, EV_FLOAT, qs_vulcan);
	clientstat(STAT_QS_MISSILES + SW_CONCUSSION, EV_FLOAT, qs_conc);
	clientstat(STAT_QS_MISSILES + SW_HOMING, EV_FLOAT, qs_homing);
	clientstat(STAT_QS_MISSILES + SW_PROXIMITY, EV_FLOAT, qs_prox);
	clientstat(STAT_QS_MISSILES + SW_SMART, EV_FLOAT, qs_smart);
	clientstat(STAT_QS_MISSILES + SW_MEGA, EV_FLOAT, qs_mega);
	clientstat(STAT_QS_MISSILES + SW_FLASH, EV_FLOAT, qs_flash);
	clientstat(STAT_QS_MISSILES + SW_GUIDED, EV_FLOAT, qs_guided);
	clientstat(STAT_QS_MISSILES + SW_SMARTMINE, EV_FLOAT, qs_smine);
	clientstat(STAT_QS_MISSILES + SW_MERCURY, EV_FLOAT, qs_mercury);
	clientstat(STAT_QS_MISSILES + SW_EARTHSHAKER, EV_FLOAT, qs_shaker);
	clientstat(STAT_QS_AFTERBURNER, EV_FLOAT, qs_burn);
	clientstat(STAT_QS_OMEGA, EV_FLOAT, qs_omega);
	clientstat(STAT_QS_GUIDED, EV_FLOAT, qs_guidednum);
	clientstat(STAT_QS_FLASHED, EV_FLOAT, qs_flashed);
	clientstat(STAT_QS_SHAKE, EV_FLOAT, qs_shaken);
	clientstat(STAT_QS_OMEGA_X, EV_FLOAT, qs_omegagoal_x);
	clientstat(STAT_QS_OMEGA_Y, EV_FLOAT, qs_omegagoal_y);
	clientstat(STAT_QS_OMEGA_Z, EV_FLOAT, qs_omegagoal_z);
	clientstat(STAT_QS_OMEGA_TIME, EV_FLOAT, qs_omegatime);
	clientstat(STAT_QS_OWNED, EV_FLOAT, qs_owned);
	clientstat(STAT_QS_FLAGS, EV_FLOAT, qs_flags);
	clientstat(STAT_QS_PRIMREADY, EV_FLOAT, qs_primready);
	clientstat(STAT_QS_SECREADY, EV_FLOAT, qs_secready);
	clientstat(STAT_QS_MISSILEGUN, EV_FLOAT, qs_missilegun);
	clientstat(STAT_QS_FUSION, EV_FLOAT, qs_fusion);
	clientstat(STAT_QS_ORIGIN_X, EV_FLOAT, origin_x);
	clientstat(STAT_QS_ORIGIN_Y, EV_FLOAT, origin_y);
	clientstat(STAT_QS_ORIGIN_Z, EV_FLOAT, origin_z);
	clientstat(STAT_QS_VEL_X, EV_FLOAT, velocity_x);
	clientstat(STAT_QS_VEL_Y, EV_FLOAT, velocity_y);
	clientstat(STAT_QS_VEL_Z, EV_FLOAT, velocity_z);
	clientstat(STAT_QS_HITS, EV_FLOAT, qs_hits);
	clientstat(STAT_QS_HITDAMAGE, EV_FLOAT, qs_hitdamage);
};

void() QS_UpdateStats =
{
	self.qs_laserstat = self.qs_laser + (self.qs_quad ? 8 : 0);
	// The super laser comes with laser levels 5 and 6.
	if (self.qs_laser >= 4)
		self.qs_owned = self.qs_owned | (1 << PW_SUPERLASER);
	else
		self.qs_owned = self.qs_owned - (self.qs_owned & (1 << PW_SUPERLASER));
	self.qs_flags = self.qs_flags - (self.qs_flags & (QSF_INVULNERABLE | QSF_CLOAKED | QSF_KEY_BLUE | QSF_KEY_YELLOW));
	if (self.invincible_finished > time)
		self.qs_flags = self.qs_flags | QSF_INVULNERABLE;
	if (self.invisible_finished > time)
		self.qs_flags = self.qs_flags | QSF_CLOAKED;
	if (self.items & IT_KEY1)
		self.qs_flags = self.qs_flags | QSF_KEY_BLUE;
	if (self.items & IT_KEY2)
		self.qs_flags = self.qs_flags | QSF_KEY_YELLOW;
};

//==========================================================================
// Movement

// Something the ship flew into.  Buttons and the like react to being
// touched by the player.
void(entity hit) QS_MoveImpact =
{
	local entity oself;

	// Descent II's godzilla cheat: ramming a monster destroys it.
	if ((self.qs_cheats & QSC_GODZILLA) && (hit.flags & FL_MONSTER) && hit.health > 0)
		T_Damage(hit, self, self, 50000);
	if (hit == world || !hit.touch || hit.solid == SOLID_TRIGGER)
		return;
	oself = self;
	other = oself;
	self = hit;
	self.touch();
	self = oself;
};

// Quake's water and lava damage look at waterlevel, which the engine's own
// player physics would have set.  The ship counts as in it or not.
void() QS_WaterCheck =
{
	local float c;

	c = pointcontents(self.origin);
	self.watertype = c;
	if (c <= CONTENT_WATER)
		self.waterlevel = 1;
	else
		self.waterlevel = 0;
	// The ship carries its own air.
	self.air_finished = time + 12;
};

void() QS_ShipCommand =
{
	// While the server is turning the ship (spawning, teleporters), its
	// angles win over the client's until the client has taken them.
	if (self.fixangle)
	{
		input_angles = [-self.angles_x * 3, self.angles_y, self.angles_z];
		// Send the angle itself, not a change from the client's view: the
		// ship's view isn't the engine's.
		self.fixangle = 3;
	}
	if (!self.qs_guidedmissile)
	{
		self.v_angle = input_angles;
		self.angles = [-input_angles_x / 3, input_angles_y, input_angles_z];
	}
	self.flags = self.flags - (self.flags & FL_ONGROUND);

	// Teleporters freeze the player for a moment.
	if (time < self.pausetime)
		self.velocity = '0 0 0';

	// Flying a guided missile: its steering takes the angles, and the
	// ship coasts.
	if (self.qs_guidedmissile)
		QS_SteerGuided();
	QS_AfterburnerPre();
	qs_move_isserver = TRUE;
	QS_ShipPhysics(self, autocvar_qs_thrust, autocvar_qs_shipbob, self.qs_flags);
	qs_move_isserver = FALSE;
	QS_AfterburnerPost(input_timelength);

	if (!(self.qs_flags & QSF_GHOST))
		touchtriggers();
	QS_WaterCheck();
};

void() SV_RunClientCommand =
{
	self.qs_buttons = input_buttons;
	self.button0 = input_buttons & 1;
	self.button2 = (input_buttons & 2) ? 1 : 0;
	if (input_impulse)
		self.impulse = input_impulse;

	if (self.qs_ship && self.deadflag == DEAD_NO && self.movetype != MOVETYPE_NOCLIP
		&& self.movetype != MOVETYPE_NONE)
	{
		self.qs_state = QS_STATE_SHIP;
		QS_ShipCommand();
		return;
	}
	if (self.qs_ship && self.deadflag != DEAD_NO)
		self.qs_state = QS_STATE_DEAD;
	else
		self.qs_state = 0;
	runstandardplayerphysics(self);
};

//==========================================================================
// Spawning, dying, and what carries over between levels

void(entity attacker, float damage) QS_ShipPain =
{
	QS_Sound(self, CHAN_VOICE, 71, 1, ATTN_NORM);
};

void(vector org, float vc, float size, float snd) QS_Explosion;
void() DropBackpack;

void() QS_ShipDie =
{
	self.qs_state = QS_STATE_DEAD;
	self.qs_fusion = 0;
	QS_Explosion(self.origin + QS_VIEW_OFS, 58, 8, 31);
	// Fall and drift like Quake's player; the ship model goes.
	self.modelindex = 0;
	self.weaponmodel = "";
	self.view_ofs = QS_VIEW_OFS;
	self.deadflag = DEAD_DEAD;
	self.solid = SOLID_NOT;
	self.flags = self.flags - (self.flags & FL_ONGROUND);
	self.movetype = MOVETYPE_TOSS;
	self.angles_x = 0;
	self.angles_z = 0;
	DropBackpack();
};

void() QS_ShipSpawn =
{
	self.qs_ship = TRUE;
	self.qs_state = QS_STATE_SHIP;
	self.max_health = QS_MAX_SHIELDS;
	self.armorvalue = 0;
	self.armortype = 0;
	self.view_ofs = QS_VIEW_OFS;
	self.th_pain = QS_ShipPain;
	self.th_die = QS_ShipDie;
	self.weaponmodel = "";
	self.velocity = '0 0 0';
	self.qs_fusion = 0;
	self.qs_primready = self.qs_secready = time;
	self.qs_flags = self.qs_carryflags;
	if (self.qs_cheats & QSC_GOD)
		self.flags = self.flags | FL_GODMODE;
	if (self.qs_cheats & QSC_NOFIRE)
		self.flags = self.flags | FL_NOTARGET;
	if (QS_HaveModel("pyro"))
		setmodel(self, "progs/qs/pyro.md3");
	setsize(self, VEC_HULL_MIN, VEC_HULL_MAX);
	// Spawn points are on the floor; hover a little above it.
	tracebox(self.origin, self.mins, self.maxs, self.origin + '0 0 12', MOVE_NORMAL, self);
	setorigin(self, trace_endpos);
	self.qs_owned = self.qs_owned | (1 << PW_LASER);
	QS_UpdateStats();
};

// A fresh ship, at the start of a game or after dying.
void() QS_NewShip =
{
	self.health = 100;
	self.qs_energy = QS_START_ENERGY;
	self.qs_laser = 0;
	self.qs_quad = FALSE;
	self.qs_owned = 1 << PW_LASER;
	self.qs_primary = PW_LASER;
	self.qs_secondary = SW_CONCUSSION;
	self.qs_vulcan = 0;
	self.qs_conc = 3;
	self.qs_homing = self.qs_prox = self.qs_smart = self.qs_mega = 0;
	self.qs_flash = self.qs_guided = self.qs_smine = self.qs_mercury = self.qs_shaker = 0;
	self.qs_carryflags = self.qs_carryflags - (self.qs_carryflags & QS_EQUIP_FLAGS);
	self.qs_burn = 0;
};

void() QS_SetChangeParms =
{
	// Descent tops shields and energy up to 100 for the next level.
	parm2 = bound(100, self.health, QS_MAX_SHIELDS);
	parm10 = max(self.qs_energy, 100);
	parm11 = self.qs_owned;
	parm12 = self.qs_laser + (self.qs_quad ? 8 : 0);
	parm13 = self.qs_vulcan;
	parm14 = self.qs_conc;
	parm15 = self.qs_homing;
	parm16 = self.qs_prox;
	parm17 = self.qs_smart;
	parm18 = self.qs_mega;
	parm19 = self.qs_primary + self.qs_secondary * 16;
	parm20 = 1;                      // the parms hold a ship
	parm21 = self.qs_cheats | (self.qs_flags & QS_CARRY_FLAGS);
	parm22 = self.qs_flash;
	parm23 = self.qs_guided;
	parm24 = self.qs_smine;
	parm25 = self.qs_mercury;
	parm26 = self.qs_shaker;
	parm27 = self.qs_flags & QS_EQUIP_FLAGS;
	parm28 = self.qs_burn;
};

void() QS_SetNewParms =
{
	parm2 = 100;
	parm10 = QS_START_ENERGY;
	parm11 = 1 << PW_LASER;
	parm12 = 0;
	parm13 = 0;
	parm14 = 3;
	parm15 = parm16 = parm17 = parm18 = 0;
	parm19 = PW_LASER + SW_CONCUSSION * 16;
	parm20 = 1;
	parm21 = parm22 = parm23 = parm24 = parm25 = parm26 = parm27 = parm28 = 0;
};

void() QS_DecodeLevelParms =
{
	if (!parm20)
	{
		// Parms from before the ship existed (a new game).
		QS_NewShip();
		return;
	}
	self.qs_energy = parm10;
	self.qs_owned = parm11 | (1 << PW_LASER);
	self.qs_laser = parm12 & 7;
	self.qs_quad = (parm12 & 8) ? TRUE : FALSE;
	self.qs_flash = parm22;
	self.qs_guided = parm23;
	self.qs_smine = parm24;
	self.qs_mercury = parm25;
	self.qs_shaker = parm26;
	self.qs_burn = parm28;
	self.qs_vulcan = parm13;
	self.qs_conc = parm14;
	self.qs_homing = parm15;
	self.qs_prox = parm16;
	self.qs_smart = parm17;
	self.qs_mega = parm18;
	self.qs_cheats = parm21 & 255;
	self.qs_carryflags = (parm21 & QS_CARRY_FLAGS) | (parm27 & QS_EQUIP_FLAGS);
	self.qs_primary = parm19 & 15;
	self.qs_secondary = floor(parm19 / 16) & 15;
	if (!(self.qs_owned & (1 << self.qs_primary)))
		self.qs_primary = PW_LASER;
};
