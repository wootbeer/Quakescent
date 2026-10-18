/*  Quakescent - Quake plus Descent.
    Copyright (C) 2026 the Quakescent contributors.

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.  See LICENSE.
*/

// The omega cannon's lightning, as Descent II draws it: every frame a new
// arc of small blobs (its weapon animation, each showing a random frame and
// lasting that one frame) from the gun to where the bolt strikes, bowed out
// along a random direction that is re-randomised every fourth blob.  Each
// blob lights the walls.  The server says where it strikes and when it
// last fired; the arc starts at the gun of the ship as the client sees it.

entity qs_omegablob;
string qs_omegamodel;
float qs_omegaframes;
float qs_omegascale;

vector() QS_RandomVector =
{
	return normalize([QS_CRandom(), QS_CRandom(), QS_CRandom()] + '0.001 0 0');
};

void() QS_OmegaInit =
{
	if (!QS_HaveVclip(103))
		return;
	qs_omegamodel = "progs/qs/vc103.spr32";
	precache_model(qs_omegamodel);
	qs_omegaframes = qs_vclip_frames[103];
	// blob_size 0.9: Descent draws the blob 1.8 units across.
	qs_omegascale = 0.9 * 2 * QS_SCALE / qs_vclip_size[103];
	qs_omegablob = spawn();
	setmodel(qs_omegablob, qs_omegamodel);
};

void(vector p, float lit) QS_OmegaBlob =
{
	setorigin(qs_omegablob, p);
	qs_omegablob.frame = floor(random() * qs_omegaframes);
	qs_omegablob.scale = qs_omegascale;
	// The frames are grey discs with white streaks; added on, they glow.
	qs_omegablob.effects = EF_FULLBRIGHT | EF_ADDITIVE;
	addentity(qs_omegablob);
	if (lit)
		dynamiclight_add(p, 110, '0.6 0.75 1', 0, "", PFLAGS_NOSHADOW);
};

// Distances in Descent units, as create_omega_blobs() has them.
const float OMEGA_MIN_BLOBS = 3;
const float OMEGA_MIN_DIST = 3;
const float OMEGA_DESIRED_DIST = 5;
const float OMEGA_MAX_BLOBS = 16;

void() QS_DrawOmega =
{
	local vector start, goal, dir, delta, pos, pv, g, eye;
	local float dist, n, spacing, i, perturb, half;

	if (!qs_omegablob || qs_guiding)
		return;
	if (time - getstatf(STAT_QS_OMEGA_TIME) > 0.08 || getstatf(STAT_QS_PRIMARY) != PW_OMEGA)
		return;
	goal = [getstatf(STAT_QS_OMEGA_X), getstatf(STAT_QS_OMEGA_Y), getstatf(STAT_QS_OMEGA_Z)];
	g = qs_gun[1];
	eye = qs_view_org;
	start = eye + (qs_rgt * g_x + qs_up * g_y + qs_fwd * g_z) * QS_SCALE;

	dir = goal - start;
	dist = vlen(dir) / QS_SCALE;
	if (dist < 0.01)
		return;
	dir = normalize(dir);
	if (dist < OMEGA_MIN_BLOBS * OMEGA_MIN_DIST)
	{
		spacing = OMEGA_MIN_DIST;
		n = max(floor(dist / spacing), 1);
	}
	else
	{
		spacing = OMEGA_DESIRED_DIST;
		n = floor(dist / spacing);
		if (n > OMEGA_MAX_BLOBS)
		{
			n = OMEGA_MAX_BLOBS;
			spacing = dist / n;
		}
		else if (n < OMEGA_MIN_BLOBS)
		{
			n = OMEGA_MIN_BLOBS;
			spacing = dist / n;
		}
	}
	delta = dir * spacing * QS_SCALE;

	// Close by, a straight line; further, start half way out and bow out
	// toward the middle.
	pos = start;
	half = dist >= OMEGA_MIN_DIST * 4;
	if (half)
		pos = pos + delta * 0.5;

	// A random direction, favouring not going up in the ship's view.
	pv = QS_RandomVector() - qs_up * 0.5;

	for (i = 0; i < n; i++)
	{
		if (i == n - 1)
			pos = pos + delta * (15 / 32);
		if ((i % 4) == 3)
			pv = pv + QS_RandomVector() * 0.25;
		perturb = 0;
		if (half)
		{
			if (i < floor(n / 2))
				perturb = i + 0.25;
			else if (n - 1 - i < floor(n / 2))
				perturb = n - 1 - i;
		}
		g = pos + pv * (perturb * QS_SCALE);
		// Not right in front of the eye: Descent II's dashboard hides the
		// first few, and this close they would fill the screen.
		if (vlen(g - eye) > 8 * QS_SCALE)
			QS_OmegaBlob(g, (i % 4) == 1 || i == n - 1);
		pos = pos + delta;
	}
};
