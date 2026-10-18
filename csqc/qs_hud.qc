/*  Quakescent - Quake plus Descent.
    Copyright (C) 2026 the Quakescent contributors.

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.  See LICENSE.
*/

// Descent's cockpit.  Everything is laid out in Descent's 320x200 cockpit
// coordinates and stretched to the screen, as Descent's own ports do.
// Without the asset pack a plain text readout stands in.

var float autocvar_qs_cockpit = 1;       // 0: full-screen readouts instead

float qs_sx, qs_sy;              // 320x200 -> screen

// Descent's gauge colours, brightened a little for modern displays.
const vector COL_ENERGY = '0.88 0.63 0.19';
const vector COL_SHIELD = '0.56 0.56 1';
const vector COL_WEAPON = '0.13 0.75 0.13';
const vector COL_AMMO = '0.82 0.13 0.13';
const vector COL_MESSAGE = '0.13 0.88 0.13';

string qs_fontpic[3];

void() QS_HudInit =
{
	local float n, i;

	qs_fontpic[QS_FONT_SMALL] = "gfx/qs/font_small";
	qs_fontpic[QS_FONT_MEDIUM] = "gfx/qs/font_medium";
	qs_fontpic[QS_FONT_BIG] = "gfx/qs/font_big";
	for (i = 0; i < 3; i++)
		if (qs_font_have[i])
			precache_pic(qs_fontpic[i]);
	n = tokenize(qs_pics);
	if (qs_assets_loaded)
	{
		// qs_pics is "|a|b|c|": precache each.
		n = tokenizebyseparator(qs_pics, "|");
		for (i = 0; i < n; i++)
			if (argv(i) != "")
				precache_pic(strcat("gfx/qs/", argv(i)));
	}
};

//==========================================================================
// Drawing helpers, in 320x200 space

void(string name, float x, float y) QS_Pic =
{
	local string p;
	local vector sz;

	if (!QS_HavePic(name))
		return;
	p = strcat("gfx/qs/", name);
	sz = drawgetimagesize(p);
	drawpic([x * qs_sx, y * qs_sy], p, [sz_x * qs_sx, sz_y * qs_sy], '1 1 1', 1, 0);
};

// Part of a picture: from pixel column l to r (of its own width).
void(string name, float x, float y, float l, float r) QS_PicCols =
{
	local string p;
	local vector sz;

	if (!QS_HavePic(name))
		return;
	p = strcat("gfx/qs/", name);
	sz = drawgetimagesize(p);
	l = bound(0, l, sz_x);
	r = bound(l, r, sz_x);
	if (r <= l)
		return;
	drawsubpic([(x + l) * qs_sx, y * qs_sy], [(r - l) * qs_sx, sz_y * qs_sy], p,
		[l / sz_x, 0], [(r - l) / sz_x, 1], '1 1 1', 1, 0);
};

float(string s, float font) QS_TextWidth =
{
	local float i, n, w, c;

	if (!qs_font_have[font])
		return strlen(s) * 4;
	n = strlen(s);
	w = 0;
	for (i = 0; i < n; i++)
	{
		c = str2chr(s, i);
		if (c >= 0 && c < 256)
			w = w + qs_fontw[font * 256 + c];
	}
	return w;
};

// Text in one of Descent's proportional fonts (the engine's font if the
// pack has none).
void(string s, float x, float y, float font, vector rgb, float scale) QS_Text =
{
	local float i, n, c, w, cw, ch;
	local vector gsize;

	if (!qs_font_have[font])
	{
		drawstring([x * qs_sx, y * qs_sy], s, [4 * qs_sx * scale, 5 * qs_sy * scale], rgb, 1, 0);
		return;
	}
	if (qs_font_colored[font])
		rgb = '1 1 1';
	cw = qs_font_cellw[font];
	ch = qs_font_cellh[font];
	gsize = [cw * 16, ch * 16];
	n = strlen(s);
	for (i = 0; i < n; i++)
	{
		c = str2chr(s, i);
		if (c < 0 || c > 255)
			continue;
		w = qs_fontw[font * 256 + c];
		if (w <= 0)
			continue;
		if (c != 32)
			drawsubpic([x * qs_sx, y * qs_sy], [w * qs_sx * scale, ch * qs_sy * scale], qs_fontpic[font],
				[(c & 15) * cw / gsize_x, floor(c / 16) * ch / gsize_y], [w / gsize_x, ch / gsize_y], rgb, 1, 0);
		x = x + w * scale;
	}
};

void(string s, float right, float y, float font, vector rgb, float scale) QS_TextRight =
{
	QS_Text(s, right - QS_TextWidth(s, font) * scale, y, font, rgb, scale);
};

void(string s, float y, float font, vector rgb, float scale) QS_TextCenter =
{
	QS_Text(s, 160 - QS_TextWidth(s, font) * scale / 2, y, font, rgb, scale);
};

string(float n, float digits) QS_Pad =
{
	local string s;

	s = ftos(floor(n));
	while (strlen(s) < digits)
		s = strcat("0", s);
	return s;
};

//==========================================================================
// The message line: prints and centerprints, up to three lines, three
// seconds each.

string qs_msg[3];
float qs_msgtime[3];

void(string line) QS_PushLine =
{
	local float i;

	if (line == "")
		return;
	for (i = 0; i < 2; i++)
	{
		if (qs_msg[i])
			strunzone(qs_msg[i]);
		qs_msg[i] = qs_msg[i + 1] ? strzone(qs_msg[i + 1]) : "";
		qs_msgtime[i] = qs_msgtime[i + 1];
	}
	if (qs_msg[2])
		strunzone(qs_msg[2]);
	qs_msg[2] = strzone(line);
	qs_msgtime[2] = time;
};

void(string msg) QS_PushMessage =
{
	local float n, i;

	// Strip Quake's coloured-text marker and split into lines.
	if (str2chr(msg, 0) == 1 || str2chr(msg, 0) == 2)
		msg = substring(msg, 1, -1);
	n = tokenizebyseparator(msg, "\n");
	for (i = 0; i < n; i++)
		QS_PushLine(strtrim(argv(i)));
};

void() QS_DrawMessages =
{
	local float i, y;

	y = 4;
	for (i = 0; i < 3; i++)
	{
		if (!qs_msg[i] || qs_msg[i] == "" || time - qs_msgtime[i] > 3 || qs_msgtime[i] > time)
			continue;
		QS_TextCenter(qs_msg[i], y, QS_FONT_SMALL, COL_MESSAGE, 1);
		y = y + 7;
	}
};

//==========================================================================

string(float pw) QS_PrimaryShort =
{
	if (pw == PW_LASER) return "LASER";
	if (pw == PW_VULCAN) return "VULCAN";
	if (pw == PW_SPREADFIRE) return "SPREAD";
	if (pw == PW_PLASMA) return "PLASMA";
	return "FUSION";
};

string(float sw) QS_SecondaryShort =
{
	if (sw == SW_CONCUSSION) return "CONCSN";
	if (sw == SW_HOMING) return "HOMING";
	if (sw == SW_PROXIMITY) return "PROXIM";
	if (sw == SW_SMART) return "SMART";
	return "MEGA";
};

string(float pw) QS_PrimaryPic =
{
	if (pw == PW_LASER) return "wlaser";
	if (pw == PW_VULCAN) return "wvulcan";
	if (pw == PW_SPREADFIRE) return "wspread";
	if (pw == PW_PLASMA) return "wplasma";
	return "wfusion";
};

string(float sw) QS_SecondaryPic =
{
	if (sw == SW_CONCUSSION) return "wconc";
	if (sw == SW_HOMING) return "whoming";
	if (sw == SW_PROXIMITY) return "wprox";
	if (sw == SW_SMART) return "wsmart";
	return "wmega";
};

float() QS_Shields =
{
	return max(0, getstatf(STAT_HEALTH));
};

void() QS_DrawWeaponBoxes =
{
	local float pw, sw, laser;

	pw = getstatf(STAT_QS_PRIMARY);
	sw = getstatf(STAT_QS_SECONDARY);
	laser = getstatf(STAT_QS_LASER);

	QS_Pic(QS_PrimaryPic(pw), 64, 154);
	QS_Text(QS_PrimaryShort(pw), 87, 157, QS_FONT_SMALL, COL_WEAPON, 1);
	if (pw == PW_LASER)
	{
		QS_Text(strcat("LVL: ", ftos((laser & 3) + 1)), 87, 163, QS_FONT_SMALL, COL_WEAPON, 1);
		if (laser & 4)
			QS_Text("QUAD", 87, 169, QS_FONT_SMALL, COL_WEAPON, 1);
	}
	else if (pw == PW_VULCAN)
		QS_Text(QS_Pad(getstatf(STAT_QS_VULCAN) * 12.75, 5), 93, 171, QS_FONT_SMALL, COL_AMMO, 1);

	QS_Pic(QS_SecondaryPic(sw), 234, 154);
	QS_Text(QS_SecondaryShort(sw), 207, 157, QS_FONT_SMALL, COL_WEAPON, 1);
	QS_Text(QS_Pad(getstatf(STAT_QS_MISSILES + sw), 3), 213, 171, QS_FONT_SMALL, COL_AMMO, 1);
};

void() QS_DrawCockpit =
{
	local float energy, shields, flags, bm, notenergy;

	energy = floor(getstatf(STAT_QS_ENERGY));
	shields = floor(QS_Shields());
	flags = getstatf(STAT_QS_FLAGS);

	QS_Pic("cockpit", 0, 0);

	// Energy bars empty from the outside in.
	notenergy = 61 - min(energy, 100) * 61 / 100;
	QS_PicCols("enrgl", 70, 131, notenergy, 64);
	QS_PicCols("enrgr", 190, 131, 0, 64 - notenergy);

	QS_Pic("numer", 154, 130);
	QS_TextRight(ftos(energy), 170, 131.5, QS_FONT_SMALL, COL_ENERGY, 1);
	QS_TextRight(ftos(shields), 170, 144.5, QS_FONT_SMALL, COL_SHIELD, 1);

	// Shield ring and ship.
	if (flags & QSF_INVULNERABLE)
		QS_Pic(strcat("invu", ftos(floor(time * 10) % 10)), 146, 155);
	else
	{
		bm = shields >= 100 ? 9 : floor(shields / 10);
		QS_Pic(strcat("shld", ftos(9 - bm)), 146, 155);
	}
	QS_Pic("ship", 151, 160);

	// Keys: Quake's silver key lights the blue one, gold the yellow.
	QS_Pic((flags & QSF_KEY_BLUE) ? "keyb" : "keyb0", 45, 152);
	QS_Pic((flags & QSF_KEY_YELLOW) ? "keyy" : "keyy0", 44, 162);
	QS_Pic("keyr0", 43, 172);

	QS_Pic(((flags & QSF_HOMING_LOCK) && (floor(time * 8) & 1)) ? "homon" : "homof", 7, 171);

	QS_DrawWeaponBoxes();
};

// Without the cockpit: Descent's full-screen readouts.
void() QS_DrawMinimal =
{
	local float pw, sw, laser;
	local string p;

	pw = getstatf(STAT_QS_PRIMARY);
	sw = getstatf(STAT_QS_SECONDARY);
	laser = getstatf(STAT_QS_LASER);
	QS_Text(strcat("SHIELD: ", ftos(floor(QS_Shields()))), 4, 178, QS_FONT_SMALL, COL_SHIELD, 1.3);
	QS_Text(strcat("ENERGY: ", ftos(floor(getstatf(STAT_QS_ENERGY)))), 4, 186, QS_FONT_SMALL, COL_ENERGY, 1.3);
	p = QS_PrimaryShort(pw);
	if (pw == PW_LASER)
	{
		p = strcat(p, " LVL ", ftos((laser & 3) + 1));
		if (laser & 4)
			p = strcat(p, " QUAD");
	}
	else if (pw == PW_VULCAN)
		p = strcat(p, ": ", ftos(floor(getstatf(STAT_QS_VULCAN) * 12.75)));
	QS_TextRight(p, 316, 178, QS_FONT_SMALL, COL_WEAPON, 1.3);
	QS_TextRight(strcat(QS_SecondaryShort(sw), ": ", ftos(getstatf(STAT_QS_MISSILES + sw))),
		316, 186, QS_FONT_SMALL, COL_WEAPON, 1.3);
};

// Descent's reticle: the cross, plus markers for whether the primary and
// secondary are ready to fire.
void() QS_DrawReticle =
{
	local float pw, sw, laser, primready, secready, pbm, sbm, now;

	now = getstatf(STAT_QS_PRIMREADY);
	pw = getstatf(STAT_QS_PRIMARY);
	sw = getstatf(STAT_QS_SECONDARY);
	laser = getstatf(STAT_QS_LASER);
	primready = time >= getstatf(STAT_QS_PRIMREADY) - 0.05;
	secready = time >= getstatf(STAT_QS_SECREADY) - 0.05 && getstatf(STAT_QS_MISSILES + sw) > 0;

	pbm = primready ? 1 : 0;
	if (pbm && pw == PW_LASER && (laser & 4))
		pbm = 2;
	sbm = secready ? 1 : 0;
	if (sw != SW_CONCUSSION && sw != SW_HOMING)
		sbm = sbm + 3;
	else if (sbm && !(getstatf(STAT_QS_MISSILEGUN) & 1))
		sbm = sbm + 1;

	if (!QS_HavePic("rcrs0"))
	{
		drawfill([160 * qs_sx - 1, 100 * qs_sy - 4], '2 9', COL_WEAPON, 0.8, 0);
		drawfill([160 * qs_sx - 4, 100 * qs_sy - 1], '9 2', COL_WEAPON, 0.8, 0);
		return;
	}
	QS_Pic(strcat("rcrs", ftos((pbm || sbm) ? 1 : 0)), 160 - 4, 100 - 2);
	QS_Pic(strcat("rpri", ftos(pbm)), 160 - 15, 100 + 6);
	QS_Pic(strcat("rsec", ftos(sbm)), 160 - 12, 100 + 1);
};

void(float w, float h) QS_DrawHud =
{
	local float flags;

	qs_sx = w / 320;
	qs_sy = h / 200;
	flags = getstatf(STAT_QS_FLAGS);

	if (qs_state == QS_STATE_SHIP)
	{
		if (qs_rearview)
		{
			if (autocvar_qs_cockpit && QS_HavePic("rearview"))
				QS_Pic("rearview", 0, 0);
			else
				QS_TextCenter("REAR VIEW", 186, QS_FONT_SMALL, COL_MESSAGE, 1);
		}
		else
		{
			if (autocvar_qs_cockpit && QS_HavePic("cockpit"))
				QS_DrawCockpit();
			else
				QS_DrawMinimal();
			QS_DrawReticle();
		}
	}
	QS_DrawMessages();
};
