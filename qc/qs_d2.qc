/*  Quakescent - Quake plus Descent.
    Copyright (C) 2026 the Quakescent contributors.

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.  See LICENSE.
*/

// Descent II mode's equipment: the afterburner, headlight and energy to
// shield converter (the ammo rack just doubles the missile limits), and the
// guided missile.  Numbers from Descent II's controls and game code.

.float qs_convertfrac, qs_nextconvertsound;
.float qs_burning;

//--------------------------------------------------------------------------
// Afterburner: full forward thrust plus up to double for three seconds; it
// recharges over eight seconds from energy.  The thrust itself is in the
// shared physics (QS_ShipPhysics), so the client predicts it too.

// Before a movement command: what the physics may burn.
void() QS_AfterburnerPre =
{
	qs_burncharge = (self.qs_flags & QSF_AFTERBURNER) ? self.qs_burn : 0;
};

// After it: spend the charge if it burned.
void(float dt) QS_AfterburnerPost =
{
	local float burn;

	burn = (input_buttons & QSB_AFTERBURNER) && (self.qs_flags & QSF_AFTERBURNER) && self.qs_burn > 0;
	if (burn)
	{
		self.qs_burn = max(self.qs_burn - dt / 3, 0);
		if (!self.qs_burning)
		{
			QS_Sound(self, CHAN_AUTO, 247, 1, ATTN_NORM);
			self.qs_burning = TRUE;
		}
	}
	else
		self.qs_burning = FALSE;
};

// Every frame: recharge from energy when not burning.
void() QS_AfterburnerRecharge =
{
	local float up;

	if (!(self.qs_flags & QSF_AFTERBURNER) || self.qs_burning || self.qs_burn >= 1)
		return;
	up = min(qs_frametime / 8, 1 - self.qs_burn);
	up = min(up, max(self.qs_energy - 10, 0) / 10);
	if (up > 0)
	{
		self.qs_burn = self.qs_burn + up;
		self.qs_energy = self.qs_energy - up * 10;
	}
};

//--------------------------------------------------------------------------
// Headlight (impulse 14, H): the client draws the light.  It costs 3/8
// energy a second and goes off below 10.

void() QS_ToggleHeadlight =
{
	if (!(self.qs_flags & QSF_HEADLIGHT))
	{
		QS_Message(self, "No headlight in inventory!");
		return;
	}
	self.qs_flags = self.qs_flags ^ QSF_HEADLIGHT_ON;
	QS_Message(self, (self.qs_flags & QSF_HEADLIGHT_ON) ? "Headlight on" : "Headlight off");
};

void() QS_HeadlightFrame =
{
	if (!(self.qs_flags & QSF_HEADLIGHT_ON))
		return;
	self.qs_energy = max(0, self.qs_energy - qs_frametime * 3 / 8);
	if (self.qs_energy < 10)
		self.qs_flags = self.qs_flags - QSF_HEADLIGHT_ON;
};

//--------------------------------------------------------------------------
// Energy to shield converter (hold G): 20 energy a second for 10 shields,
// only from energy above 100.

void() QS_ConverterFrame =
{
	local float e, whole;

	if (!(self.qs_buttons & QSB_CONVERTER))
		return;
	if (!(self.qs_oldbuttons & QSB_CONVERTER))
	{
		if (!(self.qs_flags & QSF_CONVERTER))
			QS_Message(self, "No energy to shield converter!");
		else if (self.qs_energy <= QS_START_ENERGY)
			QS_Message(self, "Need more than 100 energy to convert!");
		else if (self.health >= QS_MAX_SHIELDS)
			QS_Message(self, "No transfer: shields already at max");
	}
	if (!(self.qs_flags & QSF_CONVERTER))
		return;
	e = min(qs_frametime * 20, self.qs_energy - QS_START_ENERGY);
	e = min(e, (QS_MAX_SHIELDS - self.health) * 2);
	if (e <= 0)
		return;
	self.qs_energy = self.qs_energy - e;
	self.qs_convertfrac = self.qs_convertfrac + e / 2;
	whole = floor(self.qs_convertfrac);
	if (whole > 0)
	{
		self.health = min(self.health + whole, QS_MAX_SHIELDS);
		self.qs_convertfrac = self.qs_convertfrac - whole;
	}
	if (time >= self.qs_nextconvertsound)
	{
		QS_Sound(self, CHAN_ITEM, 241, 1, ATTN_NORM);
		self.qs_nextconvertsound = time + 0.5;
	}
};

//--------------------------------------------------------------------------
// Guided missile: while it flies, the client steers it (at half rate, as in
// Descent II) and watches from it; the ship coasts.  Fired again, or once
// the player lets go, it homes like a homing missile.

void() QS_HomingThink;

void() QS_GuidedThink =
{
	local entity o;

	if (time >= self.qs_dietime)
	{
		QS_RemoveProjectile(self);
		return;
	}
	o = self.owner;
	if (o.qs_guidedmissile != self || o.health <= 0)
	{
		self.think = QS_HomingThink;
		self.nextthink = time;
		return;
	}
	self.nextthink = time + 0.05;
};

// In a movement command while flying a guided missile: the command's angles
// steer it, and the ship keeps its own.
void() QS_SteerGuided =
{
	local entity m;

	m = self.qs_guidedmissile;
	makevectors(input_angles);
	m.velocity = v_forward * m.qs_speed;
	m.angles = vectoangles(v_forward, v_up);
	input_angles = self.v_angle;
	input_movevalues = '0 0 0';
};

void() QS_D2Frame =
{
	if (self.qs_guidedmissile && (self.qs_guidedmissile.owner != self || !self.qs_guidedmissile.qs_speed))
		self.qs_guidedmissile = world;
	self.qs_guidednum = self.qs_guidedmissile ? num_for_edict(self.qs_guidedmissile) : 0;
	QS_AfterburnerRecharge();
	QS_HeadlightFrame();
	QS_ConverterFrame();
};
