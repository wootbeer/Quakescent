/*  Quakescent - Quake plus Descent.
    Copyright (C) 2026 the Quakescent contributors.

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.  See LICENSE.
*/

// Quakescent's options (F7, or "qs_menu" in the console).  FTE's own menus
// are built into the engine, so the mod draws its own on top of the game,
// which is paused while it is open.

float qs_menu_open;
float qs_menu_sel;
float qs_menu_paused;

const float QS_MENU_ITEMS = 13;

void() QS_MenuClose;

string(float i) QS_MenuLabel =
{
	switch (i)
	{
	case 0: return "Cockpit";
	case 1: return "Mouse momentum";
	case 2: return "Turning";
	case 3: return "Auto-level";
	case 4: return "Bank into turns";
	case 5: return "Ship bob";
	case 6: return "Thrust";
	case 7: return "Weapon damage";
	case 8: return "Mouse speed";
	case 9: return "Invert mouse";
	case 10: return "Ship (next level)";
	case 11: return "Bind Descent-style keys";
	case 12: return "Done";
	}
	return "";
};

string(float on) QS_OnOff =
{
	return on ? "On" : "Off";
};

string(float i) QS_MenuValue =
{
	switch (i)
	{
	case 0: return QS_OnOff(cvar("qs_cockpit"));
	case 1: return QS_OnOff(cvar("qs_aimmomentum"));
	case 2: return cvar("qs_levelturn") ? "Level (Doom-style)" : "Ship's axes (Descent)";
	case 3: return QS_OnOff(cvar("qs_autolevel"));
	case 4: return QS_OnOff(cvar("qs_bankturns"));
	case 5: return QS_OnOff(cvar("qs_shipbob"));
	case 6: return strcat("x", ftos(cvar("qs_thrust")));
	case 7: return strcat("x", ftos(cvar("qs_damage")));
	case 8: return ftos(cvar("sensitivity"));
	case 9: return QS_OnOff(cvar("m_pitch") < 0);
	case 10: return cvar("qs_ship") ? "Pyro-GX" : "Quake marine";
	}
	return "";
};

void(string name) QS_Toggle =
{
	cvar_set(name, cvar(name) ? "0" : "1");
};

void(string name, float step, float lo, float hi, float dir) QS_Step =
{
	cvar_set(name, ftos(bound(lo, rint((cvar(name) + step * dir) / step) * step, hi)));
};

// Left/right (dir -1/+1) or Enter (dir 0) on an item.
void(float i, float dir) QS_MenuChange =
{
	switch (i)
	{
	case 0: QS_Toggle("qs_cockpit"); break;
	case 1: QS_Toggle("qs_aimmomentum"); break;
	case 2: QS_Toggle("qs_levelturn"); break;
	case 3: QS_Toggle("qs_autolevel"); break;
	case 4: QS_Toggle("qs_bankturns"); break;
	case 5: QS_Toggle("qs_shipbob"); break;
	case 6: QS_Step("qs_thrust", 0.25, 0.25, 4, dir ? dir : 1); break;
	case 7: QS_Step("qs_damage", 0.25, 0.25, 4, dir ? dir : 1); break;
	case 8: QS_Step("sensitivity", 0.5, 0.5, 30, dir ? dir : 1); break;
	case 9: cvar_set("m_pitch", ftos(-cvar("m_pitch"))); break;
	case 10: QS_Toggle("qs_ship"); break;
	case 11:
		if (dir == 0)
		{
			localcmd("exec qs_keys.cfg\n");
			QS_PushMessage("Descent-style keys bound");
		}
		break;
	case 12:
		if (dir == 0)
			QS_MenuClose();
		break;
	}
};

void() QS_MenuOpen =
{
	qs_menu_open = TRUE;
	// Pause a single-player game while the menu is up.
	qs_menu_paused = maxclients <= 1;
	if (qs_menu_paused)
		localcmd("pause\n");
};

void() QS_MenuClose =
{
	qs_menu_open = FALSE;
	if (qs_menu_paused)
		localcmd("pause\n");
	qs_menu_paused = FALSE;
	localcmd("cfg_save\n");
};

float(float evtype, float key) QS_MenuInput =
{
	if (!qs_menu_open)
		return FALSE;
	if (evtype == IE_KEYDOWN)
	{
		if (key == K_ESCAPE || key == K_F7 || key == K_MOUSE2)
			QS_MenuClose();
		else if (key == K_UPARROW || key == K_MWHEELUP)
			qs_menu_sel = (qs_menu_sel + QS_MENU_ITEMS - 1) % QS_MENU_ITEMS;
		else if (key == K_DOWNARROW || key == K_MWHEELDOWN)
			qs_menu_sel = (qs_menu_sel + 1) % QS_MENU_ITEMS;
		else if (key == K_LEFTARROW)
			QS_MenuChange(qs_menu_sel, -1);
		else if (key == K_RIGHTARROW)
			QS_MenuChange(qs_menu_sel, 1);
		else if (key == K_ENTER || key == K_KP_ENTER || key == K_MOUSE1)
			QS_MenuChange(qs_menu_sel, 0);
	}
	// Everything goes to the menu while it is open.
	return TRUE;
};

void(float w, float h) QS_DrawMenu =
{
	local float i, y, x0, x1, lh, cs;
	local vector col;

	if (!qs_menu_open)
		return;
	cs = max(8, floor(h / 60));          // character size
	lh = cs * 1.6;
	x0 = w / 2 - cs * 20;
	x1 = w / 2 + cs * 1;
	y = h / 2 - lh * (QS_MENU_ITEMS + 3) / 2;
	drawfill([x0 - cs * 2, y - cs * 2], [cs * 44, lh * (QS_MENU_ITEMS + 3) + cs * 3], '0 0 0', 0.8, 0);
	drawstring([w / 2 - cs * 9, y], "QUAKESCENT OPTIONS", [cs, cs], COL_ENERGY, 1, 0);
	y = y + lh * 2;
	for (i = 0; i < QS_MENU_ITEMS; i++)
	{
		col = (i == qs_menu_sel) ? COL_MESSAGE : '0.7 0.7 0.7';
		if (i == qs_menu_sel)
			drawstring([x0 - cs * 1.5, y], ">", [cs, cs], COL_MESSAGE, 1, 0);
		drawstring([x0, y], QS_MenuLabel(i), [cs, cs], col, 1, 0);
		drawstring([x1, y], QS_MenuValue(i), [cs, cs], col, 1, 0);
		y = y + lh;
	}
	drawstring([x0, y + cs * 0.5], "Up/down choose, left/right change, Esc closes", [cs * 0.7, cs * 0.7], '0.5 0.5 0.5', 1, 0);
};
