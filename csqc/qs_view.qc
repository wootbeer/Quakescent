/*  Quakescent - Quake plus Descent.
    Copyright (C) 2026 the Quakescent contributors.

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.  See LICENSE.
*/

// The client side of the Pyro-GX: it owns the ship's orientation (turned by
// the mouse a frame at a time, so the ship can loop and roll freely),
// predicts its position by replaying the movement commands the server
// hasn't run yet, and draws the view.

var float autocvar_qs_aimmomentum = 1;   // turns ease in and out like Descent's
var float autocvar_qs_levelturn = 1;     // near level, turn about the world's vertical
var float autocvar_qs_autolevel = 0;     // roll back to level when not banking
var float autocvar_qs_bankturns = 0;     // bank into turns
var float autocvar_qs_predict = 1;
var float autocvar_qs_debugview = 0;

float qs_state;                  // STAT_QS_STATE this frame
float qs_basis_init;
float qs_pending_yaw;            // mouse turn still to be made (degrees, + = right)
float qs_pending_pitch;          // (degrees, + = nose down)
vector qs_rotvel;                // revolutions per second: pitch, yaw, bank
float qs_turnroll;               // visual bank into turns, degrees
float qs_yawrate;                // smoothed turning rate, degrees per second
float qs_rearview;
float qs_rear_since;
float qs_hits_seen;
entity qs_pred;
vector qs_view_org;

// Keys the mod adds (see default.cfg).
float qs_key_bankl, qs_key_bankr, qs_key_fire2, qs_key_flare, qs_key_bomb;
float qs_key_left, qs_key_right, qs_key_lookup, qs_key_lookdown;
float qs_key_burn, qs_key_convert;   // Descent II's afterburner and converter

// Flying a guided missile: its own orientation, turned by the mouse at half
// rate; the ship's is put aside meanwhile.
float qs_guiding;
vector qs_ship_fwd, qs_ship_rgt, qs_ship_up;

void(entity hit) QS_MoveImpact = {};

void() QS_HudInit;
void(float w, float h) QS_DrawHud;
void(string msg) QS_PushMessage;
float qs_menu_open;
void() QS_MenuOpen;
void() QS_MenuClose;
float(float evtype, float key) QS_MenuInput;
void(float w, float h) QS_DrawMenu;
float(float key, float ch) QS_CheatKey;

void(float apilevel, string enginename, float engineversion) CSQC_Init =
{
	registercommand("+qs_bankleft");
	registercommand("-qs_bankleft");
	registercommand("+qs_bankright");
	registercommand("-qs_bankright");
	registercommand("+qs_fire2");
	registercommand("-qs_fire2");
	registercommand("+qs_flare");
	registercommand("-qs_flare");
	registercommand("+qs_bomb");
	registercommand("-qs_bomb");
	registercommand("+qs_rearview");
	registercommand("-qs_rearview");
	registercommand("+qs_left");
	registercommand("-qs_left");
	registercommand("+qs_right");
	registercommand("-qs_right");
	registercommand("+qs_lookup");
	registercommand("-qs_lookup");
	registercommand("+qs_lookdown");
	registercommand("-qs_lookdown");
	registercommand("qs_levelship");
	registercommand("+qs_afterburner");
	registercommand("-qs_afterburner");
	registercommand("+qs_convert");
	registercommand("-qs_convert");
	registercommand("qs_menu");
	QS_LoadAssets();
	QS_HudInit();
	// Configs saved before the options menu existed don't bind it.
	if (getkeybind(K_F7) == "")
		localcmd("bind f7 qs_menu\n");
	// ...nor Descent II's equipment.
	if (getkeybind(K_LSHIFT) == "")
		localcmd("bind shift +qs_afterburner\n");
	if (getkeybind(104) == "")
		localcmd("bind h \"impulse 14\"\n");
	if (getkeybind(103) == "")
		localcmd("bind g +qs_convert\n");
};

void(float down) QS_RearViewKey =
{
	// Descent's check_rear_view(): a tap toggles the rear view, holding the
	// key keeps it only while held.
	if (down)
	{
		qs_rearview = !qs_rearview;
		qs_rear_since = time;
	}
	else if (qs_rearview && time - qs_rear_since > 0.25)
		qs_rearview = FALSE;
};

float(string cmd) CSQC_ConsoleCommand =
{
	local string c;

	tokenize(cmd);
	c = argv(0);
	switch (c)
	{
	case "+qs_bankleft": qs_key_bankl = 1; break;
	case "-qs_bankleft": qs_key_bankl = 0; break;
	case "+qs_bankright": qs_key_bankr = 1; break;
	case "-qs_bankright": qs_key_bankr = 0; break;
	case "+qs_fire2": qs_key_fire2 = 1; break;
	case "-qs_fire2": qs_key_fire2 = 0; break;
	case "+qs_flare": qs_key_flare = 1; break;
	case "-qs_flare": qs_key_flare = 0; break;
	case "+qs_bomb": qs_key_bomb = 1; break;
	case "-qs_bomb": qs_key_bomb = 0; break;
	case "+qs_rearview": QS_RearViewKey(TRUE); break;
	case "-qs_rearview": QS_RearViewKey(FALSE); break;
	case "+qs_left": qs_key_left = 1; break;
	case "-qs_left": qs_key_left = 0; break;
	case "+qs_right": qs_key_right = 1; break;
	case "-qs_right": qs_key_right = 0; break;
	case "+qs_lookup": qs_key_lookup = 1; break;
	case "-qs_lookup": qs_key_lookup = 0; break;
	case "+qs_lookdown": qs_key_lookdown = 1; break;
	case "-qs_lookdown": qs_key_lookdown = 0; break;
	case "+qs_afterburner": qs_key_burn = 1; break;
	case "-qs_afterburner": qs_key_burn = 0; break;
	case "+qs_convert": qs_key_convert = 1; break;
	case "-qs_convert": qs_key_convert = 0; break;
	case "qs_menu":
		if (qs_menu_open)
			QS_MenuClose();
		else
			QS_MenuOpen();
		break;
	case "qs_levelship":
		if (qs_basis_init)
			QS_LevelShip(180);
		break;
	default:
		return FALSE;
	}
	return TRUE;
};

// The mouse turns the ship itself rather than Quake's view angles.
float(float evtype, float scanx, float chary, float devid) CSQC_InputEvent =
{
	if (qs_menu_open)
		return QS_MenuInput(evtype, scanx);
	if (evtype == IE_KEYDOWN && qs_state == QS_STATE_SHIP && QS_CheatKey(scanx, chary))
		return TRUE;
	if (evtype == IE_MOUSEDELTA && qs_state == QS_STATE_SHIP && qs_basis_init)
	{
		qs_pending_yaw = qs_pending_yaw + scanx * cvar("sensitivity") * cvar("m_yaw");
		qs_pending_pitch = qs_pending_pitch + chary * cvar("sensitivity") * cvar("m_pitch");
		return TRUE;
	}
	return FALSE;
};

// The server turned us (spawning, teleporters): start from there.
float(vector ang, float isdelta) CSQC_Parse_SetAngles =
{
	if (isdelta)
		ang = ang + QS_BasisToAngles();
	QS_AnglesToBasis(ang);
	qs_basis_init = TRUE;
	qs_pending_yaw = qs_pending_pitch = 0;
	qs_rotvel = '0 0 0';
	return FALSE;
};

// Start or stop flying a guided missile.
void() QS_GuidedCheck =
{
	local float g;

	g = getstatf(STAT_QS_GUIDED) != 0;
	if (g == qs_guiding)
		return;
	if (g)
	{
		// The missile starts off the way the ship faces.
		qs_ship_fwd = qs_fwd;
		qs_ship_rgt = qs_rgt;
		qs_ship_up = qs_up;
	}
	else
	{
		qs_fwd = qs_ship_fwd;
		qs_rgt = qs_ship_rgt;
		qs_up = qs_ship_up;
	}
	qs_guiding = g;
	qs_pending_yaw = qs_pending_pitch = 0;
	qs_rotvel = '0 0 0';
};

// Mouse, turn keys and banking, once per video frame.
void(float dt) QS_UpdateOrientation =
{
	local float yawin, pitchin, bankin, keep, roll;

	qs_pending_yaw = qs_pending_yaw + (qs_key_right - qs_key_left) * cvar("cl_yawspeed") * dt;
	qs_pending_pitch = qs_pending_pitch + (qs_key_lookdown - qs_key_lookup) * cvar("cl_pitchspeed") * dt;
	if (autocvar_qs_aimmomentum)
	{
		// Descent's mouse fed rotational thrust, so turns eased in and out:
		// pay the turn out at Descent's rotational drag.  The total turn is
		// unchanged.
		keep = pow(1 - QS_SHIP_DRAG * 5 / 2, dt / QS_PHYS_STEP);
		yawin = qs_pending_yaw * (1 - keep);
		pitchin = qs_pending_pitch * (1 - keep);
	}
	else
	{
		yawin = qs_pending_yaw;
		pitchin = qs_pending_pitch;
	}
	qs_pending_yaw = qs_pending_yaw - yawin;
	qs_pending_pitch = qs_pending_pitch - pitchin;
	// Descent II steers guided missiles at half rate.
	if (qs_guiding)
	{
		yawin = yawin / 2;
		pitchin = pitchin / 2;
	}

	// Near level flight turn about the world's vertical, so the horizon
	// stays put; rolled over, about the ship's own axes like Descent.
	roll = QS_CurrentRoll();
	if (autocvar_qs_levelturn && fabs(roll) < 45 && fabs(qs_fwd_z) < 0.98)
	{
		QS_Rotate(-pitchin, 0, 0);
		QS_RotateWorldZ(yawin);
	}
	else
		QS_Rotate(-pitchin, yawin, 0);

	// Getting hit knocks the ship around a little; Descent's rotational
	// drag settles it.
	if (getstatf(STAT_QS_HITS) != qs_hits_seen)
	{
		local float k;
		qs_hits_seen = getstatf(STAT_QS_HITS);
		k = min(getstatf(STAT_QS_HITDAMAGE), 40) / 400;
		qs_rotvel = qs_rotvel + [QS_CRandom() * k, QS_CRandom() * k, QS_CRandom() * k];
	}

	// Banking uses Descent's rotational thrust and drag.
	bankin = qs_key_bankr - qs_key_bankl;
	qs_rotvel = QS_SimulateDrag(qs_rotvel, [0, 0, bankin * QS_SHIP_MAX_ROTTHRUST / QS_SHIP_MASS],
		QS_SHIP_DRAG * 5 / 2, dt);
	QS_Rotate(qs_rotvel_x * 360 * dt, qs_rotvel_y * 360 * dt, qs_rotvel_z * 360 * dt);
	if (!bankin && autocvar_qs_autolevel)
		QS_LevelShip(QS_ROLL_RATE * 360 * dt);

	// The bank-into-turns effect follows the (smoothed) turn rate.
	if (dt > 0)
		qs_yawrate = qs_yawrate + (yawin / dt - qs_yawrate) * min(1, dt * 6);
	if (autocvar_qs_bankturns)
		qs_turnroll = qs_turnroll + bound(-QS_ROLL_RATE * 360 * dt,
			bound(-25, qs_yawrate * QS_TURNROLL_SCALE, 25) - qs_turnroll, QS_ROLL_RATE * 360 * dt);
	else
		qs_turnroll = 0;
};

void() CSQC_Input_Frame =
{
	local float fm, sm, um, b;

	if (qs_state != QS_STATE_SHIP || !qs_basis_init)
		return;
	input_angles = QS_BasisToAngles();
	// Scale the movement keys (or a stick) to the server's full thrust.
	fm = input_movevalues_x / max(cvar("cl_forwardspeed"), 1);
	sm = input_movevalues_y / max(cvar("cl_sidespeed"), 1);
	um = input_movevalues_z / max(cvar("cl_upspeed"), 1);
	input_movevalues = [bound(-1, fm, 1), bound(-1, sm, 1), bound(-1, um, 1)] * QS_MOVE_SCALE;
	b = input_buttons & QSB_PRIMARY;
	if (qs_key_fire2)
		b = b | QSB_SECONDARY;
	if (qs_key_flare)
		b = b | QSB_FLARE;
	if (qs_key_bomb)
		b = b | QSB_BOMB;
	if (qs_rearview)
		b = b | QSB_REARVIEW;
	if (qs_key_burn)
		b = b | QSB_AFTERBURNER;
	if (qs_key_convert)
		b = b | QSB_CONVERTER;
	input_buttons = b;
	// Steering a guided missile, the ship coasts.
	if (qs_guiding)
		input_movevalues = '0 0 0';
};

// Where the ship is now: the server's last word on it plus the movement
// commands it hasn't run yet, replayed with the same code it uses.
vector() QS_PredictOrigin =
{
	local vector o;
	local float i;

	o = [getstatf(STAT_QS_ORIGIN_X), getstatf(STAT_QS_ORIGIN_Y), getstatf(STAT_QS_ORIGIN_Z)];
	if (!autocvar_qs_predict)
		return o;
	if (!qs_pred)
	{
		qs_pred = spawn();
		qs_pred.solid = SOLID_NOT;
	}
	setsize(qs_pred, '-16 -16 -24', '16 16 32');
	setorigin(qs_pred, o);
	qs_pred.velocity = [getstatf(STAT_QS_VEL_X), getstatf(STAT_QS_VEL_Y), getstatf(STAT_QS_VEL_Z)];
	for (i = servercommandframe + 1; i <= clientcommandframe; i++)
	{
		if (!getinputstate(i))
			continue;
		QS_ShipPhysics(qs_pred, cvar("qs_thrust") ? cvar("qs_thrust") : 1, cvar("qs_shipbob"),
			getstatf(STAT_QS_FLAGS));
	}
	return qs_pred.origin;
};

// Descent II's headlight, and the earthshaker's quake.
void() QS_ViewEffects =
{
	local float flags, t;
	local vector a;

	flags = getstatf(STAT_QS_FLAGS);
	if (flags & QSF_HEADLIGHT_ON)
		dynamiclight_add(qs_view_org + qs_fwd * 96, 450, '1 0.97 0.88', 0, "", PFLAGS_NOSHADOW);
	t = time - getstatf(STAT_QS_SHAKE);
	if (getstatf(STAT_QS_SHAKE) && t >= 0 && t < 2)
	{
		a = getproperty(VF_ANGLES);
		a = a + [QS_CRandom(), QS_CRandom(), QS_CRandom()] * (2 - t) * 2;
		setproperty(VF_ANGLES, a);
	}
};

// The basis turned for the rear view: half a turn about the ship's up.
vector() QS_ViewAngles =
{
	local vector ang, f, r;

	if (qs_rearview)
	{
		f = qs_fwd;
		r = qs_rgt;
		qs_fwd = -f;
		qs_rgt = -r;
		ang = QS_BasisToAngles();
		qs_fwd = f;
		qs_rgt = r;
	}
	else
		ang = QS_BasisToAngles();
	ang_z = ang_z + qs_turnroll;
	return ang;
};

void(float vwidth, float vheight, float notmenu) CSQC_UpdateView =
{
	local float ship;

	qs_state = getstatf(STAT_QS_STATE);
	ship = qs_state == QS_STATE_SHIP;
	if (!ship)
	{
		qs_basis_init = FALSE;
		qs_rearview = FALSE;
	}

	clearscene();
	setproperty(VF_DRAWCROSSHAIR, !ship && qs_state != QS_STATE_DEAD);
	setproperty(VF_DRAWENGINESBAR, !qs_state);
	if (ship)
	{
		if (!qs_basis_init)
		{
			qs_hits_seen = getstatf(STAT_QS_HITS);
			// First frame as a ship: start from the view the engine had.
			QS_AnglesToBasis(getproperty(VF_ANGLES));
			qs_basis_init = TRUE;
			qs_rotvel = '0 0 0';
		}
		QS_GuidedCheck();
		QS_UpdateOrientation(frametime);
		qs_view_org = QS_PredictOrigin() + QS_VIEW_OFS;
		if (qs_guiding && (float)getentity(getstatf(STAT_QS_GUIDED), GE_ACTIVE))
			qs_view_org = getentity(getstatf(STAT_QS_GUIDED), GE_ORIGIN);
		setproperty(VF_ORIGIN, qs_view_org);
		setproperty(VF_ANGLES, QS_ViewAngles());
		QS_ViewEffects();
		if (getstatf(STAT_QS_FLAGS) & QSF_ACID)
		{
			// Descent's acid cheat wobbled the level; here the view wobbles.
			local vector a;
			a = QS_ViewAngles();
			a_x = a_x + sin(time * 2.3) * 4;
			a_z = a_z + sin(time * 1.7) * 8;
			setproperty(VF_ANGLES, a);
			setproperty(VF_AFOV, cvar("fov") + sin(time * 1.3) * 15);
		}
		addentities(MASK_ENGINE);
	}
	else
		addentities(MASK_ENGINE | MASK_VIEWMODEL);
	renderscene();
	if (qs_state)
		QS_DrawHud(vwidth, vheight);
	QS_DrawMenu(vwidth, vheight);
	if (autocvar_qs_debugview)
		drawstring('8 40', strcat(vtos(getproperty(VF_ORIGIN)), " ", vtos(getproperty(VF_ANGLES)),
			" ", ftos(servercommandframe), "/", ftos(clientcommandframe)), '8 8', '1 1 1', 1, 0);
};

// Descent shows every message on its message line.
void(string printmsg, float printlvl) CSQC_Parse_Print =
{
	print(printmsg);
	QS_PushMessage(printmsg);
};

float(string msg) CSQC_Parse_CenterPrint =
{
	if (!qs_state)
		return FALSE;
	QS_PushMessage(msg);
	return TRUE;
};
