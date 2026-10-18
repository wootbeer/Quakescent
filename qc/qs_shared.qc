/*  Quakescent - Quake plus Descent.
    Copyright (C) 2026 the Quakescent contributors.

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.  See LICENSE.
*/

// && and || stop early, as in C.
#pragma flag enable logicops

// Constants and helpers shared by the server (progs.dat) and the client
// (csprogs.dat): the ship's physics, its orientation, and the stats and
// input bits the two sides use to talk.
//
// Descent's numbers come from its game data (the Pyro-GX's entry in
// bitmaps.tbl and the weapon table).  Distances are converted to Quake
// units with QS_SCALE.

// Quake units per Descent unit.  The Pyro-GX's radius of 4 Descent units
// makes it as wide as Quake's player hull.
const float QS_SCALE = 4;

// Descent runs its physics in steps of 1/64 second.
const float QS_PHYS_STEP = 0.015625;

// The Pyro-GX.
const float QS_SHIP_MASS = 4;
const float QS_SHIP_DRAG = 0.033;
const float QS_SHIP_MAX_THRUST = 7.8;
const float QS_SHIP_MAX_ROTTHRUST = 0.14;
const float QS_SHIP_WIGGLE = 0.5;
const float QS_ROLL_RATE = 0.125;            // revolutions per second
const float QS_TURNROLL_SCALE = 0.1538;

// The eye sits at the middle of Quake's player hull (-24 to +32).
const vector QS_VIEW_OFS = '0 0 4';

// Full thrust in input_movevalues.  The client scales the movement keys
// (or an analog stick) to this; the server divides it back out.
const float QS_MOVE_SCALE = 400;

const float QS_MAX_SHIELDS = 200;
const float QS_MAX_ENERGY = 200;
const float QS_START_ENERGY = 100;

// input_buttons bits.  Bit 0 is +attack (primary fire); the client sets
// the rest itself from its own commands.
const float QSB_PRIMARY = 1;
const float QSB_SECONDARY = 8;
const float QSB_FLARE = 16;
const float QSB_BOMB = 32;
const float QSB_REARVIEW = 64;
const float QSB_AFTERBURNER = 128;   // Descent II
const float QSB_CONVERTER = 256;     // Descent II: energy to shields

// Primary and secondary weapons (Descent's order).
enum
{
	PW_LASER, PW_VULCAN, PW_SPREADFIRE, PW_PLASMA, PW_FUSION,
	// Descent II's, each sharing a number key with its Descent 1 weapon
	PW_SUPERLASER, PW_GAUSS, PW_HELIX, PW_PHOENIX, PW_OMEGA, QS_NUM_PRIMARIES
};
enum
{
	SW_CONCUSSION, SW_HOMING, SW_PROXIMITY, SW_SMART, SW_MEGA,
	SW_FLASH, SW_GUIDED, SW_SMARTMINE, SW_MERCURY, SW_EARTHSHAKER, QS_NUM_SECONDARIES
};

// Stats the server sends for the cockpit (FTE leaves 32 and up to mods).
const float STAT_QS_STATE = 32;      // QS_STATE_*
const float STAT_QS_ENERGY = 33;
const float STAT_QS_PRIMARY = 34;    // selected primary
const float STAT_QS_SECONDARY = 35;  // selected secondary
const float STAT_QS_LASER = 36;      // laser level 0-5, +8 with quad lasers
const float STAT_QS_VULCAN = 37;     // vulcan rounds
const float STAT_QS_AFTERBURNER = 38;  // afterburner charge, 0-1
const float STAT_QS_OMEGA = 39;      // omega cannon charge, 0-1
const float STAT_QS_GUIDED = 40;     // entity number of the guided missile being flown
const float STAT_QS_FLASHED = 41;    // time a flash missile's flash started
const float STAT_QS_SHAKE = 42;      // time an earthshaker's quake started
const float STAT_QS_MISSILES = 60;   // 60-69: count of each secondary
const float STAT_QS_OWNED = 43;      // bit per primary weapon owned
const float STAT_QS_FLAGS = 44;      // QSF_*
const float STAT_QS_PRIMREADY = 45;  // time the primary can fire again
const float STAT_QS_SECREADY = 46;   // time the secondary can fire again
const float STAT_QS_MISSILEGUN = 47; // which missile gun fires next
const float STAT_QS_FUSION = 48;     // fusion charge, 0-4 seconds
// The ship's position and velocity after the last movement command the
// server ran, for the client's prediction.
const float STAT_QS_ORIGIN_X = 50;
const float STAT_QS_ORIGIN_Y = 51;
const float STAT_QS_ORIGIN_Z = 52;
const float STAT_QS_VEL_X = 53;
const float STAT_QS_VEL_Y = 54;
const float STAT_QS_VEL_Z = 55;
const float STAT_QS_HITS = 56;       // counts hits; the client jolts the ship
const float STAT_QS_HITDAMAGE = 57;

const float QS_STATE_SHIP = 1;       // flying (otherwise use the engine's view)
const float QS_STATE_DEAD = 2;

const float QSF_INVULNERABLE = 1;
const float QSF_CLOAKED = 2;
const float QSF_KEY_BLUE = 4;        // Quake's silver key
const float QSF_KEY_YELLOW = 8;      // Quake's gold key
const float QSF_HOMING_LOCK = 16;    // a homing missile is after us
const float QSF_REARVIEW = 32;
// Cheats the client needs to know about: its prediction must fly the same
// way, and acid wobbles its view.
const float QSF_GHOST = 64;          // fly through walls
const float QSF_TURBO = 128;         // everything at double speed
const float QSF_ACID = 256;
// Descent II's equipment.
const float QSF_AFTERBURNER = 512;   // has the afterburner
const float QSF_HEADLIGHT = 1024;    // has the headlight
const float QSF_HEADLIGHT_ON = 2048;
const float QSF_CONVERTER = 4096;    // has the energy to shield converter
const float QSF_AMMORACK = 8192;     // has the ammo rack (double missiles)

// Descent's do_physics_sim(): in each 1/64 second step the acceleration is
// added and then drag takes its share.  A leftover part step is applied
// pro rata.
vector(vector v, vector accel, float drag, float dt) QS_SimulateDrag =
{
	local float steps, count, k;

	steps = dt / QS_PHYS_STEP;
	count = floor(steps);
	k = steps - count;
	while (count > 0)
	{
		v = v + accel;
		v = v * (1 - drag);
		count = count - 1;
	}
	v = v + accel * k;
	v = v * (1 - k * drag);
	return v;
};

// The ship's thrust for one movement command: v_forward/v_right/v_up must
// hold its orientation.  fm, sm and um are -1..1.
vector(float fm, float sm, float um, float thrustscale, float t) QS_ShipAccel =
{
	local vector accel;

	accel = (v_forward * fm + v_right * sm + v_up * um)
		* (QS_SHIP_MAX_THRUST / QS_SHIP_MASS * QS_SCALE * thrustscale);
	return accel;
};

// The ship's gentle bob (Descent's PF_WIGGLE): Descent added it to the
// velocity every frame at about 30 fps, so here it is an acceleration sized
// to match, independent of frame rate.
vector(float t) QS_ShipWiggle =
{
	return v_up * (QS_SHIP_WIGGLE * 30 * QS_PHYS_STEP * sin(t * 2 * M_PI) * QS_SCALE);
};

float() QS_CRandom =
{
	return 2 * (random() - 0.5);
};

//==========================================================================
// Orientation
//
// The ship's orientation is an orthonormal basis, so it can loop and fly
// upside down.  It is converted to Quake view angles only to send and draw.

vector qs_fwd, qs_rgt, qs_up;

// Rotate the basis about its own axes (degrees): pitch up, yaw right,
// bank right.
void(float pitchup, float yawright, float bankright) QS_Rotate =
{
	local float c, s;
	local vector t;

	if (yawright)
	{
		c = cos(yawright * M_PI / 180);
		s = sin(yawright * M_PI / 180);
		t = qs_fwd * c + qs_rgt * s;
		qs_rgt = qs_rgt * c - qs_fwd * s;
		qs_fwd = t;
	}
	if (pitchup)
	{
		c = cos(pitchup * M_PI / 180);
		s = sin(pitchup * M_PI / 180);
		t = qs_fwd * c + qs_up * s;
		qs_up = qs_up * c - qs_fwd * s;
		qs_fwd = t;
	}
	if (bankright)
	{
		c = cos(bankright * M_PI / 180);
		s = sin(bankright * M_PI / 180);
		t = qs_up * c + qs_rgt * s;
		qs_rgt = qs_rgt * c - qs_up * s;
		qs_up = t;
	}
	// Keep it orthonormal.
	qs_fwd = normalize(qs_fwd);
	qs_rgt = normalize(crossproduct(qs_fwd, qs_up));
	qs_up = crossproduct(qs_rgt, qs_fwd);
};

// Turn about the world's vertical axis (degrees, + = right).
void(float yawright) QS_RotateWorldZ =
{
	local float c, s;

	if (!yawright)
		return;
	c = cos(-yawright * M_PI / 180);
	s = sin(-yawright * M_PI / 180);
	qs_fwd = [qs_fwd_x * c - qs_fwd_y * s, qs_fwd_x * s + qs_fwd_y * c, qs_fwd_z];
	qs_rgt = [qs_rgt_x * c - qs_rgt_y * s, qs_rgt_x * s + qs_rgt_y * c, qs_rgt_z];
	qs_up = [qs_up_x * c - qs_up_y * s, qs_up_x * s + qs_up_y * c, qs_up_z];
	qs_fwd = normalize(qs_fwd);
	qs_rgt = normalize(crossproduct(qs_fwd, qs_up));
	qs_up = crossproduct(qs_rgt, qs_fwd);
};

// Bank relative to the world, in degrees (+ = rolled right).
float() QS_CurrentRoll =
{
	local vector flatright, flatup;

	flatright = crossproduct(qs_fwd, '0 0 1');
	if (vlen(flatright) < 0.001)
		return 0;
	flatright = normalize(flatright);
	flatup = crossproduct(flatright, qs_fwd);
	return atan2(qs_up * flatright, qs_up * flatup) * 180 / M_PI;
};

// Roll back toward level by at most maxdeg.
void(float maxdeg) QS_LevelShip =
{
	local float roll;

	roll = QS_CurrentRoll();
	roll = -roll;
	if (roll > maxdeg)
		roll = maxdeg;
	if (roll < -maxdeg)
		roll = -maxdeg;
	if (roll)
		QS_Rotate(0, 0, roll);
};

void(vector ang) QS_AnglesToBasis =
{
	makevectors(ang);
	qs_fwd = v_forward;
	qs_rgt = v_right;
	qs_up = v_up;
};

// The basis as Quake view angles (pitch down positive, as v_angle), so
// that makevectors() of the result gives the basis back.
vector() QS_BasisToAngles =
{
	local float pitch, yaw, roll, h;

	h = sqrt(qs_fwd_x * qs_fwd_x + qs_fwd_y * qs_fwd_y);
	pitch = atan2(-qs_fwd_z, h) * 180 / M_PI;
	if (h > 0.0001)
	{
		yaw = atan2(qs_fwd_y, qs_fwd_x) * 180 / M_PI;
		roll = atan2(-qs_rgt_z, qs_up_z) * 180 / M_PI;
	}
	else
	{
		// Straight up or down: no roll, the heading comes from the up
		// vector.
		roll = 0;
		if (qs_fwd_z < 0)
			yaw = atan2(qs_up_y, qs_up_x) * 180 / M_PI;
		else
			yaw = atan2(-qs_up_y, -qs_up_x) * 180 / M_PI;
	}
	return [pitch, yaw, roll];
};

//==========================================================================
// Movement
//
// One movement command for a ship: the server runs it for real, the client
// replays the commands the server hasn't acknowledged yet to predict where
// the ship is.  Both must do exactly the same.

float qs_move_isserver;
float qs_burncharge;             // the afterburner's charge for this command

// Something the ship flew into: let it react (buttons, doors' touch).
void(entity hit) QS_MoveImpact;

void(entity ship, float dt, float ghost) QS_FlyMove =
{
	local float bump, timeleft;
	local vector end;

	if (ghost)
	{
		setorigin(ship, ship.origin + ship.velocity * dt);
		return;
	}
	timeleft = dt;
	for (bump = 0; bump < 4; bump++)
	{
		if (ship.velocity == '0 0 0')
			break;
		end = ship.origin + ship.velocity * timeleft;
		tracebox(ship.origin, ship.mins, ship.maxs, end, MOVE_NORMAL, ship);
		if (trace_allsolid)
		{
			// Stuck (spawned inside something): let it move anyway so it
			// can get out.
			setorigin(ship, end);
			break;
		}
		if (trace_fraction > 0)
			setorigin(ship, trace_endpos);
		if (trace_fraction == 1)
			break;
		if (qs_move_isserver)
			QS_MoveImpact(trace_ent);
		timeleft = timeleft * (1 - trace_fraction);
		// Slide along what we hit, as Descent's ship does.
		ship.velocity = ship.velocity - trace_plane_normal * (ship.velocity * trace_plane_normal);
		// And keep a hair off it, so the next trace doesn't start inside.
		ship.velocity = ship.velocity + trace_plane_normal * 0.5;
	}
};

// Run one movement command (the input_* globals) for ship.  flags are its
// QSF_* (the ghost and turbo cheats change how it flies).
void(entity ship, float thrustscale, float wiggle, float flags) QS_ShipPhysics =
{
	local float dt, fm, sm, um;
	local vector accel;

	dt = input_timelength;
	if (dt <= 0)
		return;
	if (dt > 0.1)
		dt = 0.1;
	// Descent's turbo cheat doubles the game's clock.
	if (flags & QSF_TURBO)
		dt = dt * 2;

	makevectors(input_angles);
	fm = bound(-1, input_movevalues_x / QS_MOVE_SCALE, 1);
	// Descent II's afterburner: full forward thrust plus up to double
	// again, while it has charge.
	if ((input_buttons & QSB_AFTERBURNER) && (flags & QSF_AFTERBURNER) && qs_burncharge > 0)
		fm = 1 + min(0.5, qs_burncharge) * 2;
	sm = bound(-1, input_movevalues_y / QS_MOVE_SCALE, 1);
	um = bound(-1, input_movevalues_z / QS_MOVE_SCALE, 1);
	accel = QS_ShipAccel(fm, sm, um, thrustscale, 0);
	if (wiggle)
		accel = accel + QS_ShipWiggle(input_servertime);
	ship.velocity = QS_SimulateDrag(ship.velocity, accel, QS_SHIP_DRAG, dt);
	QS_FlyMove(ship, dt, flags & QSF_GHOST);
};
