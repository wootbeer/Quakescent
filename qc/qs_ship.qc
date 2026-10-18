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

var float autocvar_qs_thrust = 1;        // thrust multiplier (1 = Descent's)
var float autocvar_qs_shipbob = 1;       // Descent's gentle bob
var float autocvar_qs_damage = 1;        // weapon damage multiplier
var float autocvar_qs_ship = 1;          // 0: play as Quake's marine instead

.float qs_ship;              // flying the Pyro-GX
.float qs_state;             // STAT_QS_STATE
.float qs_energy;
.float qs_laser;             // laser level 0-3
.float qs_quad;              // quad lasers
.float qs_owned;             // bit per primary weapon
.float qs_primary;
.float qs_secondary;
.float qs_vulcan;            // vulcan ammo, in Descent's units (x12.75 = rounds)
.float qs_conc, qs_homing, qs_prox, qs_smart, qs_mega;
.float qs_flags;             // QSF_*
.float qs_primready, qs_secready, qs_missilegun, qs_fusion;
.float qs_laserstat;         // qs_laser + 4 * qs_quad, for the cockpit
.float qs_impulse_pending;
.float qs_oldbuttons;
.float qs_buttons;           // input_buttons of the last movement command

const float QS_VULCAN_MAX = 784;
const float QS_VULCAN_SCALE = 12.75;     // rounds shown per unit

// Descent's Secondary_ammo_max.
float(float sw) QS_MissileMax =
{
	if (sw == SW_CONCUSSION)
		return 20;
	if (sw == SW_HOMING || sw == SW_PROXIMITY)
		return 10;
	return 5;
};

float(entity e, float sw) QS_Missiles =
{
	if (sw == SW_CONCUSSION)
		return e.qs_conc;
	if (sw == SW_HOMING)
		return e.qs_homing;
	if (sw == SW_PROXIMITY)
		return e.qs_prox;
	if (sw == SW_SMART)
		return e.qs_smart;
	return e.qs_mega;
};

void(entity e, float sw, float n) QS_SetMissiles =
{
	n = bound(0, n, QS_MissileMax(sw));
	if (sw == SW_CONCUSSION)
		e.qs_conc = n;
	else if (sw == SW_HOMING)
		e.qs_homing = n;
	else if (sw == SW_PROXIMITY)
		e.qs_prox = n;
	else if (sw == SW_SMART)
		e.qs_smart = n;
	else
		e.qs_mega = n;
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

// A message on the player's message line (the cockpit draws prints there).
void(entity e, string msg) QS_Message =
{
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
};

void() QS_UpdateStats =
{
	self.qs_laserstat = self.qs_laser + (self.qs_quad ? 4 : 0);
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
	self.v_angle = input_angles;
	self.angles = [-input_angles_x / 3, input_angles_y, input_angles_z];
	self.flags = self.flags - (self.flags & FL_ONGROUND);

	// Teleporters freeze the player for a moment.
	if (time < self.pausetime)
		self.velocity = '0 0 0';

	qs_move_isserver = TRUE;
	QS_ShipPhysics(self, autocvar_qs_thrust, autocvar_qs_shipbob);
	qs_move_isserver = FALSE;

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
	if (!autocvar_qs_ship)
	{
		self.qs_ship = FALSE;
		return;
	}
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
	self.qs_flags = 0;
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
};

void() QS_SetChangeParms =
{
	// Descent tops shields and energy up to 100 for the next level.
	parm2 = bound(100, self.health, QS_MAX_SHIELDS);
	parm10 = max(self.qs_energy, 100);
	parm11 = self.qs_owned;
	parm12 = self.qs_laser + (self.qs_quad ? 4 : 0);
	parm13 = self.qs_vulcan;
	parm14 = self.qs_conc;
	parm15 = self.qs_homing;
	parm16 = self.qs_prox;
	parm17 = self.qs_smart;
	parm18 = self.qs_mega;
	parm19 = self.qs_primary + self.qs_secondary * 16;
	parm20 = 1;                      // the parms hold a ship
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
	self.qs_laser = parm12 & 3;
	self.qs_quad = (parm12 & 4) ? TRUE : FALSE;
	self.qs_vulcan = parm13;
	self.qs_conc = parm14;
	self.qs_homing = parm15;
	self.qs_prox = parm16;
	self.qs_smart = parm17;
	self.qs_mega = parm18;
	self.qs_primary = parm19 & 15;
	self.qs_secondary = floor(parm19 / 16) & 15;
	if (!(self.qs_owned & (1 << self.qs_primary)))
		self.qs_primary = PW_LASER;
};
