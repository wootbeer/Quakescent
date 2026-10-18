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
// bomb, 17 smart missile, 18 mega missile, 19 the smart missile's blobs.
void(float id) QS_WeaponStats =
{
	local float diff;

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
	// Descent makes energy weapons cheaper on Trainee and Rookie.
	diff = QS_Difficulty();
	if (diff < 2)
		ws_energy = ws_energy * (diff + 2) / 4;
};

float(float primary, float laser) QS_PrimaryWeaponId =
{
	if (primary == PW_LASER)
		return laser;
	if (primary == PW_VULCAN)
		return 11;
	if (primary == PW_SPREADFIRE)
		return 12;
	if (primary == PW_PLASMA)
		return 13;
	return 14;
};

float(float secondary) QS_SecondaryWeaponId =
{
	if (secondary == SW_CONCUSSION)
		return 8;
	if (secondary == SW_HOMING)
		return 15;
	if (secondary == SW_PROXIMITY)
		return 16;
	if (secondary == SW_SMART)
		return 17;
	return 18;
};

string(float pw) QS_PrimaryName =
{
	if (pw == PW_LASER)
		return "Laser cannon";
	if (pw == PW_VULCAN)
		return "Vulcan cannon";
	if (pw == PW_SPREADFIRE)
		return "Spreadfire cannon";
	if (pw == PW_PLASMA)
		return "Plasma cannon";
	return "Fusion cannon";
};

string(float sw) QS_SecondaryName =
{
	if (sw == SW_CONCUSSION)
		return "Concussion missile";
	if (sw == SW_HOMING)
		return "Homing missile";
	if (sw == SW_PROXIMITY)
		return "Proximity bomb";
	if (sw == SW_SMART)
		return "Smart missile";
	return "Mega missile";
};

//==========================================================================
// Effects

string qs_vclip_model[100];

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

void(entity e) QS_RemoveProjectile =
{
	if (e.qs_inner)
		remove(e.qs_inner);
	remove(e);
};

void() QS_ProjectileExpire =
{
	QS_RemoveProjectile(self);
};

void() QS_SmartRelease;

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
	dmg = self.qs_dmg * autocvar_qs_damage;
	if (other.takedamage)
	{
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
	QS_Explosion(self.origin, vc, self.qs_impactsize, self.qs_splash ? 11 : -1);
	if (self.qs_wid == 17)
		QS_SmartRelease();
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
		QS_RadiusDamage(self, self.owner, self.qs_dmg * autocvar_qs_damage, self.qs_splash, world);
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
	else if (id <= 3 || id == 14)
		setmodel(p, "progs/w_spike.mdl");
	else if (id == 11)
		setmodel(p, "progs/spike.mdl");
	else if (id == 12 || id == 13 || id == 19 || id == 16)
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

	if (id == 15 || id == 19)
	{
		p.think = QS_HomingThink;
		p.nextthink = time + 0.05;
	}
	else if (id == 16)
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
		p.effects = p.effects | EF_DIMLIGHT;
	}
	if (id == 11)
		p.effects = 0;
	return p;
};

// The smart missile bursts into blobs that home in on whatever is nearby.
void() QS_SmartRelease =
{
	local float i;
	local vector dir;
	local entity oself, b;

	oself = self;
	self = self.owner;              // the blobs belong to the player
	for (i = 0; i < 6; i++)
	{
		dir = normalize([QS_CRandom(), QS_CRandom(), QS_CRandom()]);
		b = QS_SpawnProjectile(19, oself.origin, dir, 1);
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
	if (id == 16)
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

float(float pw) QS_HavePrimaryAmmo =
{
	if (pw == PW_VULCAN)
		return self.qs_vulcan > 0;
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
	if ((self.qs_owned & (1 << PW_FUSION)) && QS_HavePrimaryAmmo(PW_FUSION))
		QS_SelectPrimary(PW_FUSION, TRUE);
	else if ((self.qs_owned & (1 << PW_PLASMA)) && QS_HavePrimaryAmmo(PW_PLASMA))
		QS_SelectPrimary(PW_PLASMA, TRUE);
	else if ((self.qs_owned & (1 << PW_SPREADFIRE)) && QS_HavePrimaryAmmo(PW_SPREADFIRE))
		QS_SelectPrimary(PW_SPREADFIRE, TRUE);
	else if ((self.qs_owned & (1 << PW_VULCAN)) && QS_HavePrimaryAmmo(PW_VULCAN))
		QS_SelectPrimary(PW_VULCAN, TRUE);
	else
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
		if (pw == PW_VULCAN)
		{
			if (self.qs_vulcan <= 0)
			{
				QS_AutoSelectPrimary();
				break;
			}
			self.qs_vulcan = self.qs_vulcan - 1;
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
		self.qs_nextprimary = self.qs_nextprimary + ws_wait;
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
		self.qs_nextprimary = time + ws_wait;
		self.qs_primready = self.qs_nextprimary;
		QS_FirePrimaryOnce(PW_FUSION, 14, mult);
	}
};

void(float sw, float quiet) QS_SelectSecondary;

void() QS_AutoSelectSecondary =
{
	local float sw;

	for (sw = SW_MEGA; sw >= SW_CONCUSSION; sw--)
		if (QS_Missiles(self, sw) > 0 && sw != SW_PROXIMITY)
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
	self.qs_nextsecondary = time + ws_wait;
	self.qs_secready = self.qs_nextsecondary;

	if (sw == SW_CONCUSSION || sw == SW_HOMING)
	{
		QS_FireFromGun(id, 4 + (self.qs_missilegun & 1), 0, 0, TRUE, 1);
		self.qs_missilegun = self.qs_missilegun + 1;
	}
	else
		QS_FireFromGun(id, 7, 0, 0, TRUE, 1);
	if (sw == SW_MEGA)
		self.velocity = self.velocity - v_forward * (128 / QS_SHIP_MASS * QS_SCALE);
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
	self.qs_nextflare = time + ws_wait;
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

void() QS_ImpulseCommands =
{
	local float imp;

	imp = self.impulse;
	self.impulse = 0;
	if (imp >= 1 && imp <= 5)
		QS_SelectPrimary(imp - 1, FALSE);
	else if (imp >= 6 && imp <= 10)
		QS_SelectSecondary(imp - 6, FALSE);
	else if (imp == 12)
		QS_CyclePrimary();
	else if (imp == 13)
		QS_CycleSecondary();
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
	if (self.qs_primary == PW_FUSION)
		QS_HandleFusion(buttons & QSB_PRIMARY);
	else if (buttons & QSB_PRIMARY)
		QS_FirePrimaryHeld();
	if (buttons & QSB_SECONDARY)
		QS_FireSecondary(self.qs_secondary);
	if (buttons & QSB_FLARE)
		QS_FireFlare();
	if ((buttons & QSB_BOMB) && !(self.qs_oldbuttons & QSB_BOMB))
		QS_FireSecondary(SW_PROXIMITY);
	if (buttons & QSB_REARVIEW)
		self.qs_flags = self.qs_flags | QSF_REARVIEW;
	else
		self.qs_flags = self.qs_flags - (self.qs_flags & QSF_REARVIEW);
	self.qs_oldbuttons = buttons;

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
	for (i = 0; i < 100; i++)
		if (QS_HaveVclip(i))
		{
			qs_vclip_model[i] = strzone(strcat("progs/qs/vc", ftos(i), ".spr32"));
			precache_model(qs_vclip_model[i]);
		}
	n = tokenize("laser1 laser1_in laser2 laser2_in laser3 laser3_in laser4 laser4_in concussion flare fusion fusion_in homing smart mega pyro");
	for (i = 0; i < n; i++)
		if (QS_HaveModel(argv(i)))
			precache_model(strzone(strcat("progs/qs/", argv(i), ".md3")));
	if (QS_HaveModel("sprdblob"))
		precache_model("progs/qs/sprdblob.spr32");
	if (QS_HaveModel("plasblob"))
		precache_model("progs/qs/plasblob.spr32");
	QS_PrecachePowerups();
	// Quake's stand-ins when the asset pack is missing.
	precache_model("progs/w_spike.mdl");
	precache_model("progs/spike.mdl");
	precache_model("progs/missile.mdl");
	precache_model("progs/s_light.spr");
};
