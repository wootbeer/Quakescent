/*  Quakescent - Quake plus Descent.
    Copyright (C) 2026 the Quakescent contributors.

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.  See LICENSE.
*/

// Ick Mode (qs_ickmode, as in Doomscent): every monster wears the same face
// (data/ickface.png, or the one in tools/, made into progs/qs/ickface.spr32
// by the converter) scaled to the monster's size, bleeds green, and warps
// out when it dies instead of leaving a corpse.  It can be switched on and
// off during play.

.entity qs_face;
float qs_ick_next;
float qs_greenblood;             // particle effect number, once looked up

// The face follows its monster about.  (It can't be attached to it: the
// monster's own model is hidden, and that would hide the face too.)
void() QS_IckFaceThink =
{
	local entity m;

	m = self.owner;
	if (!m || m.qs_face != self)
	{
		remove(self);
		return;
	}
	setorigin(self, m.origin + [0, 0, (m.mins_z + m.maxs_z) * 0.5]);
	self.nextthink = time;
};

void(entity m) QS_IckAttach =
{
	local entity f;
	local float h;

	f = spawn();
	f.classname = "qs_ickface";
	f.owner = m;
	setmodel(f, "progs/qs/ickface.spr32");
	h = max(m.maxs_z - m.mins_z, 24);
	f.scale = h / 64 * 1.1;
	f.effects = EF_FULLBRIGHT;       // like Quake's own sprites
	f.think = QS_IckFaceThink;
	m.qs_face = f;
	f.nextthink = time;
	setorigin(f, m.origin + [0, 0, (m.mins_z + m.maxs_z) * 0.5]);
	// The monster's own model goes; it still moves, fights and is hit
	// as before.
	m.effects = m.effects | EF_NODRAW;
};

void(entity m) QS_IckDetach =
{
	remove(m.qs_face);
	m.qs_face = world;
	m.effects = m.effects - (m.effects & EF_NODRAW);
};

// Run every frame from StartFrame: put faces on (or take them off) as the
// setting changes and monsters appear.
void() QS_StartFrame =
{
	local entity e;
	local float on;

	if (time < qs_ick_next)
		return;
	qs_ick_next = time + 0.25;
	on = autocvar_qs_ickmode && QS_HaveModel("ickface");
	for (e = nextent(world); e; e = nextent(e))
	{
		if (!(e.flags & FL_MONSTER) || e.health <= 0)
			continue;
		if (on && !e.qs_face)
			QS_IckAttach(e);
		else if (!on && e.qs_face)
			QS_IckDetach(e);
	}
};

// From Killed: an Ick monster beams out (Descent's warp-in effect) and its
// body stays hidden.
void(entity m) QS_IckKilled =
{
	local vector mid;

	if (!m.qs_face)
		return;
	mid = m.origin + (m.mins + m.maxs) * 0.5;
	QS_Explosion(mid, 61, max(m.maxs_z - m.mins_z, 24) / QS_SCALE * 0.6, 92);
	remove(m.qs_face);
	m.qs_face = world;
	m.effects = m.effects | EF_NODRAW;
	m.solid = SOLID_NOT;
};

// Quake's blood (SpawnBlood calls this): green in Ick Mode.
void(vector org, vector vel, float damage) QS_SpawnBlood =
{
	if (autocvar_qs_ickmode)
	{
		if (!qs_greenblood)
			qs_greenblood = particleeffectnum("qs.greenblood");
		if (qs_greenblood)
		{
			pointparticles(qs_greenblood, org, vel * 0.1, damage * 2);
			return;
		}
	}
	particle(org, vel * 0.1, 73, damage * 2);
};
