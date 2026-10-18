/*  Quakescent - Quake plus Descent.
    Copyright (C) 2026 the Quakescent contributors.

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.  See LICENSE.
*/

// Descent's cheat codes, typed during play (the client spots them and sends
// "cmd qs_cheat N").  Quake's own cheats (god, noclip, give, impulse 9)
// still work alongside them.  Descent 1 takes no codes until
// gabbagabbahey; like Quake's, they need sv_cheats in multiplayer.

// Cheat numbers, shared with csqc/qs_cheats.qc.
enum
{
	CH_ENABLE, CH_WOWIE, CH_WOWIE2, CH_ALLKEYS, CH_INVUL, CH_CLOAK, CH_SHIELDS,
	CH_KILLREACTOR, CH_LEVELWARP, CH_RAPIDFIRE, CH_ROBOTSNOFIRE, CH_GHOST,
	CH_TURBO, CH_ACID,
	// Descent II's
	CH_LAMER, CH_ACCESSORY, CH_FULLMAP, CH_BOUNCY, CH_HOMING, CH_KILLROBOTS,
	CH_RABID, CH_GODZILLA
};

void(entity e, string what, float on) QS_CheatToggleMessage =
{
	QS_Message(e, strcat(what, on ? " ON!" : " OFF!"));
};

void(float n) QS_GiveAllPrimaries =
{
	local float i;

	for (i = 0; i < n; i++)
		self.qs_owned = self.qs_owned | (1 << i);
	self.qs_vulcan = QS_VULCAN_MAX;
	self.qs_energy = QS_MAX_ENERGY;
};

void(float n) QS_GiveAllSecondaries =
{
	local float i;

	for (i = 0; i < n; i++)
		QS_SetMissiles(self, i, QS_MissileMaxFor(self, i));
};

// Descent's mega-wowie powerup: every weapon, missiles, full shields and
// energy.
void() QS_MegaWowie =
{
	QS_GiveAllPrimaries(QS_NUM_PRIMARIES);
	QS_GiveAllSecondaries(QS_NUM_SECONDARIES);
	self.health = QS_MAX_SHIELDS;
	self.qs_laser = 3;
	self.qs_quad = TRUE;
	QS_Message(self, "Mega-wowie-zowie!");
};

// Kill every monster (Descent's kill_all_robots).  Returns how many died.
float() QS_KillMonsters =
{
	local entity e;
	local float n;

	n = 0;
	for (e = nextent(world); e; e = nextent(e))
		if ((e.flags & FL_MONSTER) && e.health > 0 && e.takedamage)
		{
			T_Damage(e, self, self, 50000);
			n = n + 1;
		}
	return n;
};

// Pick up everything lying around the level.
void() QS_CollectItems =
{
	local entity e, oself;

	oself = self;
	qs_quiet = TRUE;
	for (e = nextent(world); e; e = nextent(e))
		if ((e.flags & FL_ITEM) && e.solid == SOLID_TRIGGER && e.touch && e.model != "")
		{
			other = oself;
			self = e;
			self.touch();
			self = oself;
		}
	qs_quiet = FALSE;
};

// poboys: kill everything, take everything, and leave by the exit.
void() QS_KillReactor =
{
	local entity e, oself;

	QS_Message(self, "Reactor destroyed!");
	QS_KillMonsters();
	QS_CollectItems();
	e = find(world, classname, "trigger_changelevel");
	if (!e)
		return;
	oself = self;
	other = oself;
	self = e;
	self.touch();
	self = oself;
};

// farmerjoe's two digits: E<first>M<second>.
void(float num) QS_WarpToLevel =
{
	local string dest;

	dest = strcat("e", ftos(floor(num / 10)), "m", ftos(num % 10));
	if (!whichpack(strcat("maps/", dest, ".bsp")))
	{
		QS_Message(self, strcat("No level ", dest, "!"));
		return;
	}
	changelevel(dest);
};

void(float cheat) QS_DoCheat =
{
	local float n;

	// Descent 1 takes no codes until gabbagabbahey; Descent II needs none.
	if (qs_game != 2 && cheat != CH_ENABLE && !(self.qs_cheats & QSC_ENABLED))
		return;
	QS_Sound(self, CHAN_VOICE, 200, 1, ATTN_NORM);
	switch (cheat)
	{
	case CH_ENABLE:
		if (!(self.qs_cheats & QSC_ENABLED))
			QS_Message(self, "Cheats are enabled!");
		self.qs_cheats = self.qs_cheats | QSC_ENABLED;
		break;
	case CH_WOWIE:
		if (qs_game == 2)
		{
			// Descent II's: everything, and the super laser at level 6.
			QS_GiveAllPrimaries(QS_NUM_PRIMARIES);
			QS_GiveAllSecondaries(QS_NUM_SECONDARIES);
			self.qs_laser = 5;
			self.qs_omega = 1;
		}
		else
		{
			// Descent 1's: laser, vulcan and spreadfire, the first three
			// missiles, and quad lasers at level 4.
			QS_GiveAllPrimaries(3);
			QS_GiveAllSecondaries(3);
			self.qs_laser = 3;
		}
		self.qs_quad = TRUE;
		QS_Message(self, "Wowie zowie!");
		break;
	case CH_WOWIE2:
		QS_GiveAllPrimaries(QS_NUM_PRIMARIES);
		QS_GiveAllSecondaries(QS_NUM_SECONDARIES);
		self.qs_laser = 3;
		self.qs_quad = TRUE;
		QS_Message(self, "Super wowie zowie!");
		break;
	case CH_ALLKEYS:
		self.items = self.items | IT_KEY1 | IT_KEY2;
		QS_Message(self, "All keys!");
		break;
	case CH_INVUL:
		self.qs_cheats = self.qs_cheats ^ QSC_GOD;
		self.flags = self.flags - (self.flags & FL_GODMODE);
		if (self.qs_cheats & QSC_GOD)
			self.flags = self.flags | FL_GODMODE;
		QS_CheatToggleMessage(self, "Invulnerability", self.qs_cheats & QSC_GOD);
		break;
	case CH_CLOAK:
		if (self.invisible_finished > time)
		{
			self.invisible_finished = 0;
			self.items = self.items - (self.items & IT_INVISIBILITY);
			QS_CheatToggleMessage(self, "Cloak", FALSE);
		}
		else
		{
			self.items = self.items | IT_INVISIBILITY;
			self.invisible_time = 1;
			self.invisible_finished = time + 30;
			QS_CheatToggleMessage(self, "Cloak", TRUE);
		}
		break;
	case CH_SHIELDS:
		self.health = QS_MAX_SHIELDS;
		QS_Message(self, "Full shields!");
		break;
	case CH_KILLREACTOR:
		QS_KillReactor();
		break;
	case CH_LEVELWARP:
		// The client asks for the level number and sends qs_warp.
		QS_Message(self, "Warp to which level?");
		break;
	case CH_RAPIDFIRE:
		self.qs_cheats = self.qs_cheats ^ QSC_RAPIDFIRE;
		QS_CheatToggleMessage(self, "Rapid fire", self.qs_cheats & QSC_RAPIDFIRE);
		// Descent 1's hands out everything too.
		if ((self.qs_cheats & QSC_RAPIDFIRE) && qs_game != 2)
			QS_MegaWowie();
		break;
	case CH_ROBOTSNOFIRE:
		self.qs_cheats = self.qs_cheats ^ QSC_NOFIRE;
		self.flags = self.flags - (self.flags & FL_NOTARGET);
		if (self.qs_cheats & QSC_NOFIRE)
			self.flags = self.flags | FL_NOTARGET;
		QS_CheatToggleMessage(self, "Robot firing", !(self.qs_cheats & QSC_NOFIRE));
		break;
	case CH_GHOST:
		self.qs_flags = self.qs_flags ^ QSF_GHOST;
		QS_CheatToggleMessage(self, "Ghosty mode", self.qs_flags & QSF_GHOST);
		break;
	case CH_TURBO:
		self.qs_flags = self.qs_flags ^ QSF_TURBO;
		QS_CheatToggleMessage(self, "Turbo mode", self.qs_flags & QSF_TURBO);
		break;
	case CH_ACID:
		self.qs_flags = self.qs_flags ^ QSF_ACID;
		break;
	case CH_LAMER:
		// Descent II's answer to its old Descent 1 codes: a cheater gets
		// nothing.
		self.health = 1;
		self.qs_energy = 1;
		QS_Message(self, "Take that...cheater!");
		break;
	case CH_ACCESSORY:
		self.qs_flags = self.qs_flags | QSF_HEADLIGHT | QSF_CONVERTER | QSF_AFTERBURNER | QSF_AMMORACK;
		self.qs_carryflags = self.qs_carryflags | QSF_HEADLIGHT | QSF_CONVERTER | QSF_AFTERBURNER | QSF_AMMORACK;
		self.qs_burn = 1;
		QS_Message(self, "Accessories!!");
		break;
	case CH_FULLMAP:
		// Quake has no automap to fill in.
		QS_Message(self, "Full map! (Quake has no map to show)");
		break;
	case CH_BOUNCY:
		self.qs_cheats = self.qs_cheats ^ QSC_BOUNCY;
		QS_CheatToggleMessage(self, "Bouncing weapons", self.qs_cheats & QSC_BOUNCY);
		break;
	case CH_HOMING:
		self.qs_cheats = self.qs_cheats ^ QSC_HOMING;
		QS_CheatToggleMessage(self, "Homing weapons", self.qs_cheats & QSC_HOMING);
		break;
	case CH_KILLROBOTS:
		n = QS_KillMonsters();
		QS_Message(self, strcat(ftos(n), " monsters toasted!"));
		break;
	case CH_RABID:
		self.qs_cheats = self.qs_cheats ^ QSC_RABID;
		QS_Message(self, (self.qs_cheats & QSC_RABID) ? "Rabid monsters!" : "Kill the player!");
		break;
	case CH_GODZILLA:
		self.qs_cheats = self.qs_cheats ^ QSC_GODZILLA;
		QS_Message(self, (self.qs_cheats & QSC_GODZILLA) ? "Oh no, there goes Tokyo!" : "What's with all these funny little houses?");
		break;
	}
};

.float qs_rabidnext;

// Rapid fire: a shot every 1/25 second; turbo doubles the guns' speed.
float(float wait) QS_FireWait =
{
	if (self.qs_cheats & QSC_RAPIDFIRE)
		wait = 1 / 25;
	if (self.qs_flags & QSF_TURBO)
		wait = wait / 2;
	return wait;
};

void() FoundTarget;

// Descent II's rabid robots: monsters go for the nearest other monster.
void() QS_RabidFrame =
{
	local entity e, head, best, oself;
	local float d, bestd;

	if (time < self.qs_rabidnext)
		return;
	self.qs_rabidnext = time + 1;
	oself = self;
	for (e = nextent(world); e; e = nextent(e))
	{
		if (!(e.flags & FL_MONSTER) || e.health <= 0)
			continue;
		if (e.enemy && !e.enemy.qs_ship && e.enemy.health > 0)
			continue;
		best = world;
		bestd = 600;
		head = findradius(e.origin, 600);
		while (head)
		{
			if (head != e && (head.flags & FL_MONSTER) && head.health > 0)
			{
				d = vlen(head.origin - e.origin);
				traceline(e.origin + e.view_ofs, head.origin, MOVE_NOMONSTERS, e);
				if (d < bestd && trace_fraction == 1)
				{
					best = head;
					bestd = d;
				}
			}
			head = head.chain;
		}
		if (best)
		{
			self = e;
			self.enemy = best;
			FoundTarget();
			self = oself;
		}
	}
};

// With robot firing off, monsters forget the player.
void() QS_CheatFrame =
{
	local entity e;

	if (self.qs_cheats & QSC_RABID)
		QS_RabidFrame();
	if (!(self.qs_cheats & QSC_NOFIRE))
		return;
	for (e = nextent(world); e; e = nextent(e))
		if ((e.flags & FL_MONSTER) && e.enemy == self)
		{
			e.enemy = world;
			e.goalentity = world;
		}
};

void(string cmd) SV_ParseClientCommand =
{
	local float n;

	n = tokenize(cmd);
	if (argv(0) == "qs_cheat" || argv(0) == "qs_warp")
	{
		if (!self.qs_ship || self.health <= 0)
			return;
		if ((deathmatch || coop) && !cvar("sv_cheats"))
			return;
		if (argv(0) == "qs_cheat")
			QS_DoCheat(stof(argv(1)));
		else if (self.qs_cheats & QSC_ENABLED)
			QS_WarpToLevel(stof(argv(1)));
		return;
	}
	clientcommand(self, cmd);
};
