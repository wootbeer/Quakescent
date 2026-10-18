/*  Quakescent - Quake plus Descent.
    Copyright (C) 2026 the Quakescent contributors.

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.  See LICENSE.
*/

// Descent's weapons on the Pyro-GX.
//
// Damage, speed, fire rate, energy use and lifetime are Descent 1's weapon
// table (its Weapon_info, by weapon id).  Speeds and splash radii are
// scaled to Quake units; damage is used as it is.

//==========================================================================
// The weapon table

float ws_energy;         // energy per shot
float ws_wait;           // seconds between shots
float ws_strength;       // damage
float ws_speed;          // Descent units per second
float ws_life;           // seconds
float ws_radius;         // splash radius, Descent units
float ws_blob;           // sprite radius for blob weapons
float ws_flash;          // muzzle flash size
float ws_impact;         // impact explosion size
float ws_flashvc;        // muzzle flash vclip
float ws_flashsnd;       // firing sound
float ws_robothitvc;     // explosion on hitting a monster
float ws_wallhitvc;      // explosion on hitting a wall

void(float energy, float wait, float strength, float speed, float life, float radius,
	float blob, float flash, float impact, float flashvc, float flashsnd,
	float robothit, float wallhit) QS_Fill =
{
	ws_energy = energy;
	ws_wait = wait;
	ws_strength = strength;
	ws_speed = speed;
	ws_life = life;
	ws_radius = radius;
	ws_blob = blob;
	ws_flash = flash;
	ws_impact = impact;
	ws_flashvc = flashvc;
	ws_flashsnd = flashsnd;
	ws_robothitvc = robothit;
	ws_wallhitvc = wallhit;
};

// Weapon ids are Descent's: 0-3 laser levels 1-4, 8 concussion, 9 flare,
// 11 vulcan, 12 spreadfire, 13 plasma, 14 fusion, 15 homing, 16 proximity
// bomb, 17 smart missile, 18 mega missile, 19 the smart missile's blobs;
// Descent II's 30-31 super laser levels 5-6, 32 gauss, 33 helix,
// 34 phoenix, 35 omega, 36 flash, 37 guided, 38 smart mine, 39 mercury,
// 40 earthshaker, 47 the smart mine's blobs, 54 the earthshaker's children.
void(float id) QS_WeaponStats1 =
{
	switch (id)
	{
	case 0:  QS_Fill(0.5, 0.25, 10, 120, 10, 0, 0, 1.0, 3, 11, 13, 59, 1); break;
	case 1:  QS_Fill(0.5, 0.25, 11, 125, 10, 0, 0, 1.25, 3, 15, 14, 21, 30); break;
	case 2:  QS_Fill(0.5, 0.20, 12, 130, 10, 0, 0, 1.5, 3, 14, 15, 23, 31); break;
	case 3:  QS_Fill(0.5, 0.20, 13, 135, 10, 0, 0, 2.0, 3, 12, 16, 22, 32); break;
	case 8:  QS_Fill(0, 0.5, 30, 90, 10, 30, 0, 5, 7, 11, 130, 5, 5); break;
	case 9:  QS_Fill(1, 1.15, 1, 120, 5, 0, 0, 0.5, 1, 11, 23, 59, -1); break;
	case 11: QS_Fill(0, 0.05, 4, 500, 3, 0, 0.5, 2, 2.5, 11, 115, 1, 1); break;
	case 12: QS_Fill(0.5, 0.2, 10, 120, 10, 0, 0.5, 2, 2.5, 14, 18, 23, 23); break;
	case 13: QS_Fill(0.5, 0.15, 11, 150, 10, 0, 1.3, 2, 3.5, 12, 25, 23, 32); break;
	case 14: QS_Fill(0, 1.0, 60, 150, 10, 0, 0, 6, 5, 15, 24, 65, 65); break;
	case 15: QS_Fill(0, 0.5, 40, 90, 20, 20, 0, 5, 7, 11, 130, 5, 5); break;
	case 16: QS_Fill(0, 0.2, 30, 0, 35, 40, 3, 5, 7, 11, 26, 5, 5); break;
	case 17: QS_Fill(0, 0.5, 25, 85, 3, 20, 0, 5, 7, 11, 130, 5, 5); break;
	case 18: QS_Fill(0, 0.5, 199, 85, 10, 80, 0, 5, 30, 11, 132, 63, 5); break;
	case 19: QS_Fill(0, 1.5, 35, 90, 12, 0, 1.5, 5, 7, 11, 12, 5, 5); break;
	default: QS_Fill(0, 1, 0, 100, 1, 0, 0, 1, 1, -1, -1, -1, -1); break;
	}
};

// Descent II's Weapon_info (DESCENT2.HAM).  Its versions of Descent 1's
// weapons differ a little (weaker lasers, for one).
void(float id) QS_WeaponStats2 =
{
	switch (id)
	{
	case 0:  QS_Fill(0.49, 0.25, 9, 120, 10, 0, 0, 1, 3, 11, 13, 59, 1); break;
	case 1:  QS_Fill(0.49, 0.25, 9.75, 125, 10, 0, 0, 1.1, 3, 15, 14, 21, 30); break;
	case 2:  QS_Fill(0.49, 0.25, 10.5, 130, 10, 0, 0, 1.15, 3, 14, 15, 23, 31); break;
	case 3:  QS_Fill(0.49, 0.25, 11.25, 135, 10, 0, 0, 1.2, 3, 12, 16, 22, 32); break;
	case 8:  QS_Fill(0, 0.5, 30, 90, 10, 30, 0, 5, 7, 11, 130, 5, 5); break;
	case 9:  QS_Fill(1, 1.15, 1, 120, 5, 0, 0, 0.5, 1, 11, 23, 59, -1); break;
	case 11: QS_Fill(0, 0.05, 4, 500, 3, 0, 0.5, 2, 2.5, 11, 115, 1, 1); break;
	case 12: QS_Fill(0.5, 0.2, 9, 130, 10, 0, 0.5, 2, 2.5, 14, 18, 23, 23); break;
	case 13: QS_Fill(0.5, 0.15, 11, 150, 10, 0, 1.3, 2, 3.5, 12, 25, 23, 32); break;
	case 14: QS_Fill(0.5, 1, 30, 150, 10, 0, 0, 6, 5, 15, 24, 65, 65); break;
	case 15: QS_Fill(0, 0.5, 40, 90, 10, 20, 0, 5, 7, 11, 130, 5, 5); break;
	case 16: QS_Fill(0, 0.2, 30, 0, 35, 40, 3, 5, 7, 11, 26, 5, 5); break;
	case 17: QS_Fill(0, 0.5, 25, 85, 3, 20, 0, 5, 7, 11, 130, 5, 5); break;
	case 18: QS_Fill(0, 1, 199, 85, 10, 80, 0, 5, 30, 11, 132, 63, 5); break;
	case 19: QS_Fill(0, 1.5, 35, 90, 12, 0, 1.5, 5, 7, 11, 12, 5, 5); break;
	case 30: QS_Fill(0.75, 0.25, 12, 135, 10, 0, 0, 1.25, 3, 85, 44, 59, 87); break;
	case 31: QS_Fill(0.75, 0.25, 12.5, 135, 10, 0, 0, 1.25, 3, 86, 45, 59, 88); break;
	case 32: QS_Fill(0, 0.15, 25, 700, 3, 10, 0.5, 2, 3.5, 11, 230, 95, 95); break;
	case 33: QS_Fill(0.75, 0.15, 11, 130, 10, 0, 0.5, 2, 2.5, 12, 37, 22, 22); break;
	case 34: QS_Fill(1, 0.12, 12, 140, 10, 0, 2.25, 2, 3.5, 11, 38, 23, 59); break;
	case 35: QS_Fill(0, 1, 7, 1000, 0.01, 0, 0.9, 1.25, 4, 86, 77, 105, 105); break;
	case 36: QS_Fill(0, 0.6, 9, 110, 30, 80, 0, 5, 7, 11, 130, 5, 5); break;
	case 37: QS_Fill(0, 0.3, 55, 60, 20, 40, 0, 5, 7, 11, 130, 5, 5); break;
	case 38: QS_Fill(0, 0.2, 30, 0, 120, 0, 3, 5, 7, 11, 26, 5, 5); break;
	case 39: QS_Fill(0, 0.75, 50, 400, 10, 30, 0, 5, 5, 11, 133, 106, 5); break;
	case 40: QS_Fill(0, 1.5, 220, 120, 10, 80, 0, 5, 50, 11, 250, 104, 5); break;
	case 47: QS_Fill(0, 1.5, 25, 90, 12, 0, 2, 5, 3, 11, 12, 5, 2); break;
	case 54: QS_Fill(0, 1, 100, 285, 10, 80, 0, 5, 30, 11, 132, 104, 5); break;
	default: QS_Fill(0, 1, 0, 100, 1, 0, 0, 1, 1, -1, -1, -1, -1); break;
	}
};

void(float id) QS_WeaponStats =
{
	local float diff;

	if (qs_game == 2)
		QS_WeaponStats2(id);
	else
		QS_WeaponStats1(id);
	// Descent makes energy weapons cheaper on Trainee and Rookie.
	diff = QS_Difficulty();
	if (diff < 2)
		ws_energy = ws_energy * (diff + 2) / 4;
};

// The big explosions' sound (Descent II's mega missile, earthshaker).
float(float id) QS_HitSound =
{
	if (qs_game == 2 && (id == 18 || id == 40 || id == 54))
		return 231;
	return 11;
};

float(float primary, float laser) QS_PrimaryWeaponId =
{
	switch (primary)
	{
	case PW_LASER: return min(laser, 3);
	case PW_VULCAN: return 11;
	case PW_SPREADFIRE: return 12;
	case PW_PLASMA: return 13;
	case PW_FUSION: return 14;
	case PW_SUPERLASER: return (laser >= 5) ? 31 : 30;
	case PW_GAUSS: return 32;
	case PW_HELIX: return 33;
	case PW_PHOENIX: return 34;
	case PW_OMEGA: return 35;
	}
	return 0;
};

float(float secondary) QS_SecondaryWeaponId =
{
	switch (secondary)
	{
	case SW_CONCUSSION: return 8;
	case SW_HOMING: return 15;
	case SW_PROXIMITY: return 16;
	case SW_SMART: return 17;
	case SW_MEGA: return 18;
	case SW_FLASH: return 36;
	case SW_GUIDED: return 37;
	case SW_SMARTMINE: return 38;
	case SW_MERCURY: return 39;
	case SW_EARTHSHAKER: return 40;
	}
	return 8;
};

string(float pw) QS_PrimaryName =
{
	switch (pw)
	{
	case PW_LASER: return "Laser cannon";
	case PW_VULCAN: return "Vulcan cannon";
	case PW_SPREADFIRE: return "Spreadfire cannon";
	case PW_PLASMA: return "Plasma cannon";
	case PW_FUSION: return "Fusion cannon";
	case PW_SUPERLASER: return "Super laser";
	case PW_GAUSS: return "Gauss cannon";
	case PW_HELIX: return "Helix cannon";
	case PW_PHOENIX: return "Phoenix cannon";
	case PW_OMEGA: return "Omega cannon";
	}
	return "";
};

string(float sw) QS_SecondaryName =
{
	switch (sw)
	{
	case SW_CONCUSSION: return "Concussion missile";
	case SW_HOMING: return "Homing missile";
	case SW_PROXIMITY: return "Proximity bomb";
	case SW_SMART: return "Smart missile";
	case SW_MEGA: return "Mega missile";
	case SW_FLASH: return "Flash missile";
	case SW_GUIDED: return "Guided missile";
	case SW_SMARTMINE: return "Smart mine";
	case SW_MERCURY: return "Mercury missile";
	case SW_EARTHSHAKER: return "Earthshaker missile";
	}
	return "";
};

//==========================================================================
// Effects

string qs_vclip_model[120];

// One of Descent's animations (vclips), played once.
void() QS_VclipThink =
{
	self.frame = self.frame + 1;
	if (self.frame >= self.cnt)
	{
		remove(self);
		return;
	}
	self.nextthink = time + self.wait;
};

// An animation size Descent units across (its radius, as Descent sizes
// them), with Quake's own effect when the pack doesn't have it.
void(vector org, float vc, float size) QS_Vclip =
{
	local entity e;

	if (!QS_HaveVclip(vc))
	{
		if (size >= 4)
		{
			WriteByte(MSG_BROADCAST, SVC_TEMPENTITY);
			WriteByte(MSG_BROADCAST, TE_EXPLOSION);
			WriteCoord(MSG_BROADCAST, org_x);
			WriteCoord(MSG_BROADCAST, org_y);
			WriteCoord(MSG_BROADCAST, org_z);
		}
		else if (size > 1)
		{
			WriteByte(MSG_BROADCAST, SVC_TEMPENTITY);
			WriteByte(MSG_BROADCAST, TE_SPIKE);
			WriteCoord(MSG_BROADCAST, org_x);
			WriteCoord(MSG_BROADCAST, org_y);
			WriteCoord(MSG_BROADCAST, org_z);
		}
		return;
	}
	e = spawn();
	e.classname = "qs_vclip";
	e.movetype = MOVETYPE_NONE;
	e.solid = SOLID_NOT;
	setmodel(e, qs_vclip_model[vc]);
	setorigin(e, org);
	e.scale = size * 2 * QS_SCALE / qs_vclip_size[vc];
	e.frame = 0;
	e.cnt = qs_vclip_frames[vc];
	e.wait = qs_vclip_time[vc];
	e.effects = EF_FULLBRIGHT;
	e.think = QS_VclipThink;
	e.nextthink = time + e.wait;
};

void(vector org, float vc, float size, float snd) QS_Explosion =
{
	local entity s;

	QS_Vclip(org, vc, size);
	if (QS_HaveSound(snd))
	{
		// A short-lived entity to play the sound from.
		s = spawn();
		setorigin(s, org);
		QS_Sound(s, CHAN_AUTO, snd, 1, ATTN_NORM);
		s.think = SUB_Remove;
		s.nextthink = time + 0.1;
	}
};

// Descent's splash damage: full at the centre, falling off linearly to
// nothing at the edge.
void(entity inflictor, entity attacker, float damage, float radius, entity ignore) QS_RadiusDamage =
{
	local entity head;
	local vector org;
	local float dist, points;

	head = findradius(inflictor.origin, radius);
	while (head)
	{
		if (head != ignore && head.takedamage)
		{
			org = head.origin + (head.mins + head.maxs) * 0.5;
			dist = vlen(inflictor.origin - org);
			points = damage * (1 - dist / radius);
			if (head == attacker)
				points = points * 0.5;
			if (points > 0 && CanDamage(head, inflictor))
				T_Damage(head, inflictor, attacker, points);
		}
		head = head.chain;
	}
};

//==========================================================================
// Projectiles

.float qs_wid;           // weapon id
.float qs_dmg;
.float qs_splash;        // splash radius, Quake units
.float qs_robothitvc, qs_wallhitvc, qs_impactsize;
.entity qs_inner;        // the bright core drawn inside lasers
.float qs_speed;
.float qs_dietime;
.entity qs_target;
.float qs_bounces;
.float qs_blinded;       // a flash missile's victim: blind until then

void(entity e) QS_RemoveProjectile =
{
	if (e.owner.qs_guidedmissile == e)
		e.owner.qs_guidedmissile = world;
	if (e.qs_inner)
		remove(e.qs_inner);
	remove(e);
};

void() QS_ProjectileExpire =
{
	QS_RemoveProjectile(self);
};

void(float id, float n) QS_SmartRelease;

// Descent II's flash missile: monsters that see it lose track of their
// target for three seconds, and players looking at it are dazzled.
void() QS_FlashImpact =
{
	local entity head;
	local float range;

	range = self.qs_splash * 2;
	head = findradius(self.origin, range);
	while (head)
	{
		if (head.health > 0 && CanDamage(head, self))
		{
			if (head.flags & FL_MONSTER)
			{
				head.qs_blinded = time + 3;
				head.enemy = world;
				head.goalentity = world;
			}
			else if (head.qs_ship)
				head.qs_flashed = time;
		}
		head = head.chain;
	}
	// A brief white light.
	local entity l;
	l = spawn();
	setorigin(l, self.origin);
	l.pflags = PFLAGS_FULLDYNAMIC | PFLAGS_NOSHADOW;
	l.color = '1 1 1';
	l.light_lev = 600;
	l.think = SUB_Remove;
	l.nextthink = time + 0.3;
};

// The earthshaker shakes every ship within range.
void(vector org, float range) QS_Shake =
{
	local entity head;

	head = findradius(org, range);
	while (head)
	{
		if (head.qs_ship)
			head.qs_shaken = time;
		head = head.chain;
	}
};

// Shoot a switch, as in Descent: buttons that only react to being pressed
// fire when hit too.
void(entity hit, entity shooter) QS_ShootButton =
{
	local entity oself;

	if (hit.classname != "func_button" || hit.takedamage || !hit.use)
		return;
	oself = self;
	self = hit;
	activator = shooter;
	self.use();
	self = oself;
};

void() QS_ProjectileTouch =
{
	local float dmg, vc;

	if (other == self.owner)
		return;
	if (other.solid == SOLID_TRIGGER)
		return;
	if (pointcontents(self.origin) == CONTENT_SKY)
	{
		QS_RemoveProjectile(self);
		return;
	}
	// Phoenix fireballs (and the bouncy cheat's shots) bounce off walls
	// twice.
	if (self.qs_bounces > 0 && !other.takedamage)
	{
		self.qs_bounces = self.qs_bounces - 1;
		return;
	}
	dmg = self.qs_dmg * autocvar_qs_damage;
	if (other.takedamage)
	{
		if (other.flags & FL_MONSTER)
			SpawnBlood(self.origin, self.velocity * 0.2, min(dmg, 30));
		T_Damage(other, self, self.owner, dmg);
		vc = self.qs_robothitvc;
	}
	else
	{
		vc = self.qs_wallhitvc;
		QS_ShootButton(other, self.owner);
	}
	if (self.qs_splash)
		QS_RadiusDamage(self, self.owner, dmg, self.qs_splash, other);
	// Back off the surface a little so the explosion isn't half in the
	// wall.
	setorigin(self, self.origin - normalize(self.velocity) * 4);
	QS_Explosion(self.origin, vc, self.qs_impactsize, self.qs_splash ? QS_HitSound(self.qs_wid) : -1);
	if (self.qs_wid == 17)
		QS_SmartRelease(19, 6);
	else if (self.qs_wid == 36)
		QS_FlashImpact();
	else if (self.qs_wid == 40)
	{
		QS_Shake(self.origin, self.qs_splash * 6);
		QS_SmartRelease(54, 6);
	}
	else if (self.qs_wid == 54)
		QS_Shake(self.origin, self.qs_splash * 3);
	QS_RemoveProjectile(self);
};

// The nearest thing worth homing in on, in front of e and in sight.
entity(entity e, float mindot) QS_FindHomingTarget =
{
	local entity head, best;
	local float d, bestdist, dot;
	local vector dir, org;

	best = world;
	bestdist = 100000;
	head = findradius(e.origin, 2000);
	while (head)
	{
		if (head.takedamage && head.health > 0 && head != e.owner
			&& ((head.flags & FL_MONSTER) || (head.classname == "player" && deathmatch)))
		{
			org = head.origin + (head.mins + head.maxs) * 0.5;
			dir = org - e.origin;
			d = vlen(dir);
			dot = normalize(dir) * normalize(e.velocity);
			if (dot > mindot && d < bestdist)
			{
				traceline(e.origin, org, MOVE_NOMONSTERS, e);
				if (trace_fraction == 1)
				{
					best = head;
					bestdist = d;
				}
			}
		}
		head = head.chain;
	}
	return best;
};

// Homing missiles turn toward their target; Descent's turn the velocity
// toward it a step at a time at full speed.
void() QS_HomingThink =
{
	local vector dir, org;

	if (time >= self.qs_dietime)
	{
		QS_RemoveProjectile(self);
		return;
	}
	if (!self.qs_target || self.qs_target.health <= 0)
		self.qs_target = QS_FindHomingTarget(self, 0.5);
	if (self.qs_target)
	{
		org = self.qs_target.origin + (self.qs_target.mins + self.qs_target.maxs) * 0.5;
		dir = normalize(org - self.origin);
		self.velocity = normalize(normalize(self.velocity) + dir * 0.25) * self.qs_speed;
		self.angles = vectoangles(self.velocity);
	}
	self.nextthink = time + 0.05;
};

// Proximity bombs drift to a stop and wait for something to come close.
void() QS_ProximityThink =
{
	local entity head;

	if (time >= self.qs_dietime)
	{
		QS_Explosion(self.origin, self.qs_wallhitvc, self.qs_impactsize, 11);
		if (self.qs_splash)
			QS_RadiusDamage(self, self.owner, self.qs_dmg * autocvar_qs_damage, self.qs_splash, world);
		if (self.qs_wid == 38)
			QS_SmartRelease(47, 6);
		QS_RemoveProjectile(self);
		return;
	}
	self.velocity = self.velocity * 0.9;
	// Armed after a moment, so it doesn't go off in the player's face.
	if (time > self.ltime)
	{
		head = findradius(self.origin, 4 * QS_SCALE * 4);
		while (head)
		{
			if (head.takedamage && head.health > 0 && head != self.owner
				&& ((head.flags & FL_MONSTER) || (head.classname == "player" && deathmatch)))
			{
				self.qs_dietime = time;
				break;
			}
			head = head.chain;
		}
	}
	self.nextthink = time + 0.1;
};

void() QS_FlareTouch =
{
	if (other == self.owner || other.solid == SOLID_TRIGGER)
		return;
	if (other.takedamage)
	{
		T_Damage(other, self, self.owner, self.qs_dmg);
		QS_RemoveProjectile(self);
		return;
	}
	// Flares stick to walls and keep burning.
	self.velocity = '0 0 0';
	self.movetype = MOVETYPE_NONE;
	self.touch = SUB_Null;
};

// Descent's weapons light up the walls around them as they fly (their
// lightcast): a coloured realtime light that moves with the bolt.
void(entity p, float id) QS_ProjectileLight =
{
	local vector c;
	local float r;

	r = 150;
	if (id == 0) c = '1 0.25 0.2';              // laser 1: red
	else if (id == 1) c = '0.9 0.3 1';          // laser 2: purple
	else if (id == 2) c = '0.3 0.5 1';          // laser 3: blue
	else if (id == 3) c = '0.3 1 0.3';          // laser 4: green
	else if (id == 12) c = '0.4 0.6 1';         // spreadfire
	else if (id == 13 || id == 19) c = '0.5 1 0.4';  // plasma, smart blobs
	else if (id == 14) { c = '0.8 0.5 1'; r = 220; } // fusion
	else if (id == 9) { c = '1 0.8 0.5'; r = 300; }  // flare
	else if (id == 30 || id == 31) c = '0.4 1 0.25';   // super laser: green
	else if (id == 33) c = '0.25 1 1';          // helix
	else if (id == 34) { c = '1 0.5 0.15'; r = 200; } // phoenix
	else if (id == 47) c = '1 0.4 0.4';         // smart mine blobs
	else if (id == 8 || id == 15 || id == 17 || id == 18 || (id >= 36 && id <= 40) || id == 54)
	{ c = '1 0.6 0.3'; r = 120; }               // missiles
	else
		return;
	// Each light is a realtime light, a whole extra lighting pass; rapid
	// fire would put dozens in the air and stall the game.  Light only
	// the first few.
	local entity e;
	local float n;
	n = 0;
	for (e = find(world, classname, "qs_weapon"); e; e = find(e, classname, "qs_weapon"))
		if (e.light_lev > 0)
			if (++n >= 6)
				return;
	p.pflags = PFLAGS_FULLDYNAMIC | PFLAGS_NOSHADOW;
	p.color = c;
	p.light_lev = r;
};

entity(float id, vector org, vector dir, float mult) QS_SpawnProjectile =
{
	local entity p, in;
	local string mdl, inner;

	QS_WeaponStats(id);
	p = spawn();
	p.classname = "qs_weapon";
	p.owner = self;
	p.qs_wid = id;
	p.qs_dmg = ws_strength * mult;
	p.qs_splash = ws_radius * QS_SCALE;
	p.qs_robothitvc = ws_robothitvc;
	p.qs_wallhitvc = ws_wallhitvc;
	p.qs_impactsize = ws_impact;
	p.qs_speed = ws_speed * QS_SCALE;
	p.movetype = MOVETYPE_FLYMISSILE;
	p.solid = SOLID_BBOX;
	p.velocity = dir * p.qs_speed;
	p.angles = vectoangles(dir);
	p.touch = QS_ProjectileTouch;
	p.qs_dietime = time + ws_life;
	p.think = QS_ProjectileExpire;
	p.nextthink = p.qs_dietime;
	p.effects = EF_FULLBRIGHT;

	mdl = "";
	inner = "";
	if (id <= 3)
	{
		mdl = strcat("laser", ftos(id + 1));
		inner = strcat(mdl, "_in");
	}
	else if (id == 8) mdl = "concussion";
	else if (id == 9) mdl = "flare";
	else if (id == 14) { mdl = "fusion"; inner = "fusion_in"; }
	else if (id == 15) mdl = "homing";
	else if (id == 17) mdl = "smart";
	else if (id == 18) mdl = "mega";
	else if (id == 30) { mdl = "laser5"; inner = "laser5_in"; }
	else if (id == 31) { mdl = "laser6"; inner = "laser6_in"; }
	else if (id == 36) mdl = "flash";
	else if (id == 37) mdl = "guided";
	else if (id == 39) mdl = "mercury";
	else if (id == 40) mdl = "shaker";
	else if (id == 54) mdl = "shakerkid";
	// Descent II's blobs and mines are animations.
	local float vc;
	vc = -1;
	if (id == 33) vc = 98;
	else if (id == 34) vc = 68;
	else if (id == 38) vc = 80;
	else if (id == 47) vc = 92;

	if (mdl != "" && QS_HaveModel(mdl))
	{
		setmodel(p, strcat("progs/qs/", mdl, ".md3"));
		if (inner != "" && QS_HaveModel(inner))
		{
			in = spawn();
			in.classname = "qs_weapon_inner";
			setmodel(in, strcat("progs/qs/", inner, ".md3"));
			in.effects = EF_FULLBRIGHT;
			setattachment(in, p, "");
			p.qs_inner = in;
		}
	}
	else if (vc >= 0 && QS_HaveVclip(vc))
	{
		setmodel(p, qs_vclip_model[vc]);
		p.scale = max(ws_blob, 1) * 2 * QS_SCALE / qs_vclip_size[vc];
	}
	else if (id <= 3 || id == 14 || id == 30 || id == 31)
		setmodel(p, "progs/w_spike.mdl");
	else if (id == 11 || id == 32)
		setmodel(p, "progs/spike.mdl");
	else if (id == 12 || id == 13 || id == 19 || id == 16 || id == 33 || id == 34 || id == 38 || id == 47)
	{
		if (id == 12 && QS_HaveModel("sprdblob"))
			setmodel(p, "progs/qs/sprdblob.spr32");
		else if ((id == 13 || id == 19) && QS_HaveModel("plasblob"))
			setmodel(p, "progs/qs/plasblob.spr32");
		else if (id == 16 && QS_HaveVclip(53))
			setmodel(p, qs_vclip_model[53]);
		else
			setmodel(p, "progs/s_light.spr");
		if (ws_blob > 0 && id != 16)
			p.scale = ws_blob * 2 * QS_SCALE / 64;
	}
	else if (id == 9)
		setmodel(p, "progs/s_light.spr");
	else
		setmodel(p, "progs/missile.mdl");
	setsize(p, '0 0 0', '0 0 0');
	setorigin(p, org);

	if (id == 15 || id == 19 || id == 47 || id == 54)
	{
		p.think = QS_HomingThink;
		p.nextthink = time + 0.05;
	}
	else if (id == 34)
	{
		p.movetype = MOVETYPE_BOUNCEMISSILE;
		p.qs_bounces = 2;
	}
	else if (id == 37)
	{
		p.think = QS_GuidedThink;
		p.nextthink = time;
	}
	else if (id == 16 || id == 38)
	{
		p.movetype = MOVETYPE_FLY;
		p.touch = SUB_Null;
		p.solid = SOLID_NOT;
		p.ltime = time + 1;
		p.think = QS_ProximityThink;
		p.nextthink = time + 0.1;
	}
	else if (id == 9)
	{
		p.touch = QS_FlareTouch;
	}
	if (id == 11 || id == 32)
		p.effects = 0;
	if ((self.qs_cheats & QSC_BOUNCY) && p.movetype == MOVETYPE_FLYMISSILE)
	{
		p.movetype = MOVETYPE_BOUNCEMISSILE;
		p.qs_bounces = 2;
	}
	if ((self.qs_cheats & QSC_HOMING) && p.think == QS_ProjectileExpire && id != 9)
	{
		p.think = QS_HomingThink;
		p.nextthink = time + 0.05;
	}
	QS_ProjectileLight(p, id);
	return p;
};

// The smart missile (and Descent II's smart mine and earthshaker) bursts
// into children that home in on whatever is nearby.
void(float id, float n) QS_SmartRelease =
{
	local float i;
	local vector dir;
	local entity oself, b;

	oself = self;
	self = self.owner;              // the children belong to the player
	for (i = 0; i < n; i++)
	{
		dir = normalize([QS_CRandom(), QS_CRandom(), QS_CRandom()]);
		b = QS_SpawnProjectile(id, oself.origin, dir, 1);
		b.qs_target = QS_FindHomingTarget(b, -1);
	}
	self = oself;
};

// The ship's orientation, from its view angles.
void() QS_ShipVectors =
{
	makevectors(self.v_angle);
};

// Spawn a weapon at one of the Pyro-GX's gun points (Descent's
// Laser_player_fire_spread()).
entity(float id, float gun, float spreadr, float spreadu, float makesound, float mult) QS_FireFromGun =
{
	local vector center, ofs, start, dir, g;
	local entity p;

	QS_ShipVectors();
	center = self.origin + QS_VIEW_OFS;
	g = qs_gun[gun];
	ofs = (v_right * g_x + v_up * g_y + v_forward * g_z) * QS_SCALE;
	start = center + ofs;
	// Don't fire through a wall the gun is poking into.
	traceline(center, start + normalize(ofs) * 2, MOVE_NOMONSTERS, self);
	if (trace_fraction < 1)
		start = center;
	dir = normalize(v_forward + v_right * spreadr + v_up * spreadu);
	p = QS_SpawnProjectile(id, start, dir, mult);
	// Things fired backwards (bombs) start with the ship's own motion.
	if (id == 16 || id == 38)
		p.velocity = self.velocity * 0.5 - v_forward * 16;
	if (makesound)
	{
		QS_Sound(self, CHAN_WEAPON, ws_flashsnd, 1, ATTN_NORM);
		QS_Vclip(start + v_forward * 2, ws_flashvc, ws_flash * 0.5);
	}
	return p;
};

//==========================================================================
// Firing

.float qs_nextprimary, qs_lastprimary, qs_nextsecondary, qs_nextflare;
.float qs_lastweaponframe;
float qs_frametime;          // since this player's last weapon frame
.float qs_spreadtoggle, qs_fusioncharging, qs_fusionsound;
.float qs_helix;             // the helix cannon's line turns each shot

float(float pw) QS_HavePrimaryAmmo =
{
	if (pw == PW_VULCAN || pw == PW_GAUSS)
		return self.qs_vulcan > 0;
	if (pw == PW_OMEGA)
		return self.qs_omega > 0 || self.qs_energy > 0;
	QS_WeaponStats(QS_PrimaryWeaponId(pw, self.qs_laser));
	if (pw == PW_FUSION)
		return self.qs_energy >= 2;
	return self.qs_energy >= ws_energy;
};

void(float pw, float quiet) QS_SelectPrimary;

// Out of ammo: the best weapon that has some (Descent's auto-select order,
// best first).
void() QS_AutoSelectPrimary =
{
	local float i, pw;

	for (i = 0; i < QS_NUM_PRIMARIES; i++)
	{
		// Best first: Descent II's omega, fusion, phoenix, plasma, helix,
		// spreadfire, gauss, vulcan, super laser, laser.
		switch (i)
		{
		case 0: pw = PW_OMEGA; break;
		case 1: pw = PW_FUSION; break;
		case 2: pw = PW_PHOENIX; break;
		case 3: pw = PW_PLASMA; break;
		case 4: pw = PW_HELIX; break;
		case 5: pw = PW_SPREADFIRE; break;
		case 6: pw = PW_GAUSS; break;
		case 7: pw = PW_VULCAN; break;
		case 8: pw = PW_SUPERLASER; break;
		default: pw = PW_LASER; break;
		}
		if ((self.qs_owned & (1 << pw)) && QS_HavePrimaryAmmo(pw))
		{
			QS_SelectPrimary(pw, TRUE);
			return;
		}
	}
	QS_SelectPrimary(PW_LASER, TRUE);
};

void(float pw, float id, float mult) QS_FirePrimaryOnce =
{
	local float m;

	if (pw == PW_LASER)
	{
		m = self.qs_quad ? 0.75 : 1;
		QS_FireFromGun(id, 0, 0, 0, TRUE, m);
		QS_FireFromGun(id, 1, 0, 0, FALSE, m);
		if (self.qs_quad)
		{
			QS_FireFromGun(id, 2, 0, 0, FALSE, m);
			QS_FireFromGun(id, 3, 0, 0, FALSE, m);
		}
	}
	else if (pw == PW_VULCAN)
		QS_FireFromGun(id, 6, QS_CRandom() / 16, QS_CRandom() / 16, TRUE, 1);
	else if (pw == PW_SPREADFIRE)
	{
		if (self.qs_spreadtoggle)
		{
			QS_FireFromGun(id, 6, 1 / 16, 0, FALSE, 1);
			QS_FireFromGun(id, 6, -1 / 16, 0, FALSE, 1);
		}
		else
		{
			QS_FireFromGun(id, 6, 0, 1 / 16, FALSE, 1);
			QS_FireFromGun(id, 6, 0, -1 / 16, FALSE, 1);
		}
		QS_FireFromGun(id, 6, 0, 0, TRUE, 1);
		self.qs_spreadtoggle = !self.qs_spreadtoggle;
	}
	else if (pw == PW_PLASMA)
	{
		QS_FireFromGun(id, 0, 0, 0, TRUE, 1);
		QS_FireFromGun(id, 1, 0, 0, FALSE, 1);
	}
	else if (pw == PW_FUSION)
	{
		QS_FireFromGun(id, 0, 0, 0, TRUE, mult);
		QS_FireFromGun(id, 1, 0, 0, FALSE, mult);
		// Recoil.
		self.velocity = self.velocity - v_forward * (128 / QS_SHIP_MASS * QS_SCALE);
	}
	else if (pw == PW_SUPERLASER)
	{
		m = self.qs_quad ? 0.75 : 1;
		QS_FireFromGun(id, 0, 0, 0, TRUE, m);
		QS_FireFromGun(id, 1, 0, 0, FALSE, m);
		if (self.qs_quad)
		{
			QS_FireFromGun(id, 2, 0, 0, FALSE, m);
			QS_FireFromGun(id, 3, 0, 0, FALSE, m);
		}
	}
	else if (pw == PW_GAUSS)
		QS_FireFromGun(id, 6, QS_CRandom() / 64, QS_CRandom() / 64, TRUE, 1);
	else if (pw == PW_HELIX)
	{
		// Five blobs in a line that turns 22.5 degrees each shot.
		local float r, u, a;
		a = self.qs_helix * 22.5 * M_PI / 180;
		r = cos(a) / 16;
		u = sin(a) / 16;
		QS_FireFromGun(id, 6, 0, 0, TRUE, 1);
		QS_FireFromGun(id, 6, r, u, FALSE, 1);
		QS_FireFromGun(id, 6, -r, -u, FALSE, 1);
		QS_FireFromGun(id, 6, r * 2, u * 2, FALSE, 1);
		QS_FireFromGun(id, 6, -r * 2, -u * 2, FALSE, 1);
		self.qs_helix = (self.qs_helix + 1) % 8;
	}
	else if (pw == PW_PHOENIX)
	{
		QS_FireFromGun(id, 0, 0, 0, TRUE, 1);
		QS_FireFromGun(id, 1, 0, 0, FALSE, 1);
	}
};

//--------------------------------------------------------------------------
// Descent II's omega cannon: lightning that locks onto the nearest enemy in
// front.  It runs on its own charge (a second of fire), which refills over
// four seconds from energy while the trigger is up.

.float qs_lastomega, qs_omegadamage, qs_omegasound, qs_omegaimpact;

void() QS_OmegaRecharge =
{
	local float dc, cost, diff;

	if (!(self.qs_owned & (1 << PW_OMEGA)))
	{
		self.qs_omega = 1;
		return;
	}
	if (self.qs_omega >= 1 || time - self.qs_lastomega < 0.06 || self.qs_energy <= 0)
		return;
	dc = min(qs_frametime / 4, 1 - self.qs_omega);
	self.qs_omega = self.qs_omega + dc;
	cost = dc * 190 / 17;
	diff = QS_Difficulty();
	if (diff < 2)
		cost = cost * (diff + 2) / 4;
	self.qs_energy = max(0, self.qs_energy - cost);
};

void(float held) QS_HandleOmega =
{
	local entity head, best;
	local vector start, goal, to, g;
	local float d, dp, bestdot, range, dmg;

	if (!held)
		return;
	if (!(self.qs_omega >= 1 / 8 || (self.qs_omega > 0 && self.qs_energy <= 0)))
	{
		if (self.qs_omega <= 0 && self.qs_energy <= 0)
			QS_AutoSelectPrimary();
		return;
	}
	self.qs_omega = max(self.qs_omega - qs_frametime, 0);
	self.qs_lastomega = time;
	self.qs_primready = time;
	QS_WeaponStats(35);

	QS_ShipVectors();
	g = qs_gun[1];
	start = self.origin + QS_VIEW_OFS + (v_right * g_x + v_up * g_y + v_forward * g_z) * QS_SCALE;
	range = 80 * QS_SCALE;
	// The nearest enemy in the omega's narrow cone.
	best = world;
	bestdot = 15 / 16;
	head = findradius(self.origin, range);
	while (head)
	{
		if (head.takedamage && head.health > 0 && head != self
			&& ((head.flags & FL_MONSTER) || (head.classname == "player" && deathmatch)))
		{
			to = head.origin + (head.mins + head.maxs) * 0.5 - start;
			d = vlen(to);
			dp = normalize(to) * v_forward;
			if (d > 1 && dp > bestdot)
			{
				traceline(start, start + to, MOVE_NOMONSTERS, self);
				if (trace_fraction == 1)
				{
					bestdot = dp;
					best = head;
				}
			}
		}
		head = head.chain;
	}
	if (best)
	{
		goal = best.origin + (best.mins + best.maxs) * 0.5;
		// OMEGA_DAMAGE_SCALE (32) x frame time x strength.
		self.qs_omegadamage = self.qs_omegadamage + 32 * qs_frametime * ws_strength * autocvar_qs_damage;
		dmg = floor(self.qs_omegadamage);
		if (dmg > 0)
		{
			self.qs_omegadamage = self.qs_omegadamage - dmg;
			T_Damage(best, self, self, dmg);
		}
	}
	else
	{
		// Nothing to lock onto: crackle straight ahead to a wall.
		traceline(start, start + normalize(v_forward + [QS_CRandom(), QS_CRandom(), QS_CRandom()] / 16) * range,
			MOVE_NORMAL, self);
		goal = trace_endpos;
	}
	// The client draws the lightning, a new arc every frame.
	self.qs_omegagoal = goal;
	self.qs_omegatime = time;
	if (time >= self.qs_omegaimpact)
	{
		self.qs_omegaimpact = time + 0.25;
		QS_Vclip(goal, best ? ws_robothitvc : ws_wallhitvc, ws_impact / 2);
	}
	if (time >= self.qs_omegasound)
	{
		self.qs_omegasound = time + 0.12;
		QS_Sound(self, CHAN_WEAPON, ws_flashsnd, 1, ATTN_NORM);
	}
};

// Descent's do_laser_firing_player(): fire as often as the fire wait
// allows while the trigger is held.
void() QS_FirePrimaryHeld =
{
	local float pw, id, guard;

	pw = self.qs_primary;
	id = QS_PrimaryWeaponId(pw, self.qs_laser);
	if (self.qs_lastprimary + 0.1 < time)
		self.qs_nextprimary = max(self.qs_nextprimary, time);
	self.qs_lastprimary = time;
	guard = 0;
	while (self.qs_nextprimary <= time && guard < 4)
	{
		guard = guard + 1;
		QS_WeaponStats(id);
		if (pw == PW_VULCAN || pw == PW_GAUSS)
		{
			if (self.qs_vulcan <= 0)
			{
				QS_AutoSelectPrimary();
				break;
			}
			// The gauss uses vulcan ammo twice as fast.
			self.qs_vulcan = max(0, self.qs_vulcan - ((pw == PW_GAUSS) ? 2 : 1));
		}
		else
		{
			if (self.qs_energy < ws_energy)
			{
				QS_AutoSelectPrimary();
				break;
			}
			self.qs_energy = self.qs_energy - ws_energy;
		}
		self.qs_nextprimary = self.qs_nextprimary + QS_FireWait(ws_wait);
		QS_FirePrimaryOnce(pw, id, 1);
	}
	self.qs_primready = self.qs_nextprimary;
};

// The fusion cannon charges while the trigger is held and fires on
// release; held too long, it starts to hurt.
void(float held) QS_HandleFusion =
{
	local float mult;

	if (held && time >= self.qs_nextprimary)
	{
		if (!self.qs_fusioncharging)
		{
			if (self.qs_energy < 2)
			{
				QS_AutoSelectPrimary();
				return;
			}
			self.qs_energy = self.qs_energy - 2;
			self.qs_fusioncharging = TRUE;
			self.qs_fusion = 0;
		}
		self.qs_fusion = self.qs_fusion + qs_frametime;
		self.qs_energy = max(0, self.qs_energy - qs_frametime);
		if (time >= self.qs_fusionsound)
		{
			self.qs_fusionsound = time + 0.125 + random() * 0.125;
			if (self.qs_fusion > 2)
			{
				QS_Sound(self, CHAN_WEAPON, 11, 1, ATTN_NORM);
				T_Damage(self, self, self, floor(random() * 3));
			}
			else
				QS_Sound(self, CHAN_WEAPON, 34, 1, ATTN_NORM);
		}
		if (self.qs_energy <= 0)
			held = FALSE;
	}
	if (!held && self.qs_fusioncharging)
	{
		mult = min(1 + self.qs_fusion / 2, 4);
		self.qs_fusioncharging = FALSE;
		self.qs_fusion = 0;
		QS_WeaponStats(14);
		self.qs_nextprimary = time + QS_FireWait(ws_wait);
		self.qs_primready = self.qs_nextprimary;
		QS_FirePrimaryOnce(PW_FUSION, 14, mult);
	}
};

void(float sw, float quiet) QS_SelectSecondary;

void() QS_AutoSelectSecondary =
{
	local float sw;

	for (sw = QS_NUM_SECONDARIES - 1; sw >= 0; sw--)
		if (QS_Missiles(self, sw) > 0 && sw != SW_PROXIMITY && sw != SW_SMARTMINE)
		{
			QS_SelectSecondary(sw, TRUE);
			return;
		}
};

void(float sw) QS_FireSecondary =
{
	local float id;

	if (time < self.qs_nextsecondary)
		return;
	if (QS_Missiles(self, sw) <= 0)
	{
		if (sw == self.qs_secondary)
			QS_AutoSelectSecondary();
		return;
	}
	id = QS_SecondaryWeaponId(sw);
	QS_WeaponStats(id);
	QS_SetMissiles(self, sw, QS_Missiles(self, sw) - 1);
	self.qs_nextsecondary = time + QS_FireWait(ws_wait);
	self.qs_secready = self.qs_nextsecondary;

	local entity m;
	if (sw == SW_CONCUSSION || sw == SW_HOMING || sw == SW_FLASH || sw == SW_GUIDED || sw == SW_MERCURY)
	{
		m = QS_FireFromGun(id, 4 + (self.qs_missilegun & 1), 0, 0, TRUE, 1);
		self.qs_missilegun = self.qs_missilegun + 1;
	}
	else
		m = QS_FireFromGun(id, 7, 0, 0, TRUE, 1);
	if (sw == SW_MEGA || sw == SW_EARTHSHAKER)
		self.velocity = self.velocity - v_forward * (128 / QS_SHIP_MASS * QS_SCALE);
	if (sw == SW_GUIDED)
	{
		// A new guided missile takes over from the last one, which then
		// homes on its own.  The player flies it from its own view.
		self.qs_guidedmissile = m;
		self.qs_guidednum = num_for_edict(m);
	}
	if (QS_Missiles(self, sw) <= 0 && sw == self.qs_secondary)
		QS_AutoSelectSecondary();
};

void() QS_FireFlare =
{
	if (time < self.qs_nextflare)
		return;
	QS_WeaponStats(9);
	if (self.qs_energy < ws_energy)
		return;
	self.qs_nextflare = time + QS_FireWait(ws_wait);
	self.qs_energy = self.qs_energy - ws_energy;
	QS_FireFromGun(9, 6, 0, 0, TRUE, 1);
};

//==========================================================================
// Selecting weapons

void(float pw, float quiet) QS_SelectPrimary =
{
	if (!(self.qs_owned & (1 << pw)))
	{
		if (!quiet)
		{
			QS_Message(self, strcat("You don't have the ", QS_PrimaryName(pw), "!"));
			QS_Sound(self, CHAN_ITEM, 156, 1, ATTN_NORM);
		}
		return;
	}
	if (pw == self.qs_primary)
		return;
	self.qs_primary = pw;
	self.qs_fusioncharging = FALSE;
	self.qs_fusion = 0;
	// A short pause while it changes over.
	self.qs_nextprimary = max(self.qs_nextprimary, time + 0.25);
	self.qs_primready = self.qs_nextprimary;
	if (!quiet)
	{
		QS_Message(self, strcat(QS_PrimaryName(pw), " selected!"));
		QS_Sound(self, CHAN_ITEM, 155, 1, ATTN_NORM);
	}
};

void(float sw, float quiet) QS_SelectSecondary =
{
	if (QS_Missiles(self, sw) <= 0)
	{
		if (!quiet)
		{
			QS_Message(self, strcat("You have no ", QS_SecondaryName(sw), "s!"));
			QS_Sound(self, CHAN_ITEM, 156, 1, ATTN_NORM);
		}
		return;
	}
	if (sw == self.qs_secondary)
		return;
	self.qs_secondary = sw;
	if (!quiet)
	{
		QS_Message(self, strcat(QS_SecondaryName(sw), " selected!"));
		QS_Sound(self, CHAN_ITEM, 155, 1, ATTN_NORM);
	}
};

void() QS_CycleSecondary =
{
	local float i, sw;

	for (i = 1; i <= QS_NUM_SECONDARIES; i++)
	{
		sw = (self.qs_secondary + i) % QS_NUM_SECONDARIES;
		if (QS_Missiles(self, sw) > 0)
		{
			QS_SelectSecondary(sw, FALSE);
			return;
		}
	}
};

void() QS_CyclePrimary =
{
	local float i, pw;

	for (i = 1; i <= QS_NUM_PRIMARIES; i++)
	{
		pw = (self.qs_primary + i) % QS_NUM_PRIMARIES;
		if (self.qs_owned & (1 << pw))
		{
			QS_SelectPrimary(pw, FALSE);
			return;
		}
	}
};

// Number keys 1-5 pick Descent 1's weapon, or with that already selected,
// its Descent II counterpart (and back), as in Descent II.
void(float base) QS_PrimaryKey =
{
	local float other, havebase, haveother, pick;

	other = base + 5;
	havebase = self.qs_owned & (1 << base);
	haveother = self.qs_owned & (1 << other);
	pick = base;
	if (self.qs_primary == base && haveother)
		pick = other;
	else if (self.qs_primary == other && havebase)
		pick = base;
	else if (self.qs_primary == other || (!havebase && haveother))
		pick = other;
	QS_SelectPrimary(pick, FALSE);
};

void(float base) QS_SecondaryKey =
{
	local float other, havebase, haveother, pick;

	other = base + 5;
	havebase = QS_Missiles(self, base) > 0;
	haveother = QS_Missiles(self, other) > 0;
	pick = base;
	if (self.qs_secondary == base && haveother)
		pick = other;
	else if (self.qs_secondary == other && havebase)
		pick = base;
	else if (self.qs_secondary == other || (!havebase && haveother))
		pick = other;
	QS_SelectSecondary(pick, FALSE);
};

void() QS_ImpulseCommands =
{
	local float imp;

	imp = self.impulse;
	self.impulse = 0;
	if (imp >= 1 && imp <= 5)
		QS_PrimaryKey(imp - 1);
	else if (imp >= 6 && imp <= 10)
		QS_SecondaryKey(imp - 6);
	else if (imp == 12)
		QS_CyclePrimary();
	else if (imp == 13)
		QS_CycleSecondary();
	else if (imp == 14)
		QS_ToggleHeadlight();
	else if (imp == 255 && (cvar("sv_cheats") || !deathmatch))
		QS_GiveAll();
};

// Called every frame from PlayerPostThink in place of W_WeaponFrame.
void() QS_WeaponFrame =
{
	local float buttons;

	qs_frametime = bound(0, time - self.qs_lastweaponframe, 0.1);
	self.qs_lastweaponframe = time;

	if (self.impulse)
		QS_ImpulseCommands();

	// Stale timers (from a saved game, say) would block firing.
	if (self.qs_nextprimary > time + 5)
		self.qs_nextprimary = self.qs_primready = time;
	if (self.qs_nextsecondary > time + 5)
		self.qs_nextsecondary = self.qs_secready = time;

	buttons = self.qs_buttons;
	QS_OmegaRecharge();
	if (self.qs_primary == PW_FUSION)
		QS_HandleFusion(buttons & QSB_PRIMARY);
	else if (self.qs_primary == PW_OMEGA)
		QS_HandleOmega(buttons & QSB_PRIMARY);
	else if (buttons & QSB_PRIMARY)
		QS_FirePrimaryHeld();
	if (buttons & QSB_SECONDARY)
		QS_FireSecondary(self.qs_secondary);
	if (buttons & QSB_FLARE)
		QS_FireFlare();
	if ((buttons & QSB_BOMB) && !(self.qs_oldbuttons & QSB_BOMB))
	{
		// Descent's drop-bomb key: proximity bombs, or Descent II's smart
		// mines when those are selected or the only ones left.
		if (QS_Missiles(self, SW_SMARTMINE) > 0
			&& (self.qs_secondary == SW_SMARTMINE || QS_Missiles(self, SW_PROXIMITY) <= 0))
			QS_FireSecondary(SW_SMARTMINE);
		else
			QS_FireSecondary(SW_PROXIMITY);
	}
	QS_D2Frame();
	if (buttons & QSB_REARVIEW)
		self.qs_flags = self.qs_flags | QSF_REARVIEW;
	else
		self.qs_flags = self.qs_flags - (self.qs_flags & QSF_REARVIEW);
	self.qs_oldbuttons = buttons;

	QS_CheatFrame();
	QS_UpdateStats();
};

//==========================================================================

void() QS_PrecachePowerups;

void() QS_Precache =
{
	local float i, n;

	for (i = 0; i < 256; i++)
		if (qs_have_sound[i])
			precache_sound(strzone(QS_SoundName(i)));
	for (i = 0; i < 120; i++)
		if (QS_HaveVclip(i))
		{
			qs_vclip_model[i] = strzone(strcat("progs/qs/vc", ftos(i), ".spr32"));
			precache_model(qs_vclip_model[i]);
		}
	n = tokenize("laser1 laser1_in laser2 laser2_in laser3 laser3_in laser4 laser4_in concussion flare fusion fusion_in homing smart mega pyro laser5 laser5_in laser6 laser6_in flash guided mercury shaker shakerkid");
	for (i = 0; i < n; i++)
		if (QS_HaveModel(argv(i)))
			precache_model(strzone(strcat("progs/qs/", argv(i), ".md3")));
	if (QS_HaveModel("sprdblob"))
		precache_model("progs/qs/sprdblob.spr32");
	if (QS_HaveModel("plasblob"))
		precache_model("progs/qs/plasblob.spr32");
	if (QS_HaveModel("ickface"))
		precache_model("progs/qs/ickface.spr32");
	QS_PrecachePowerups();
	// Quake's stand-ins when the asset pack is missing.
	precache_model("progs/w_spike.mdl");
	precache_model("progs/spike.mdl");
	precache_model("progs/missile.mdl");
	precache_model("progs/s_light.spr");
};
