/*  Quakescent - Quake plus Descent.
    Copyright (C) 2026 the Quakescent contributors.

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.  See LICENSE.
*/

// What the Descent asset pack (qs_descent_assets.pk3, made by
// tools/qsconvert.py from the player's own Descent files) holds.  The
// converter lists it in qs/assets.txt; without the pack the mod falls back
// to Quake's own models, sounds and status bar.

float qs_assets_loaded;
var float qs_game = 1;               // 2 in Descent II mode (a Descent II pack)
hashtable qs_picsize;            // picture name -> size in the 320x200 layout
float qs_have_sound[256];
float qs_vclip_frames[120];
float qs_vclip_time[120];        // seconds per frame
float qs_vclip_size[120];        // largest side of the first frame, pixels
vector qs_gun[8];                // Pyro-GX gun points, Descent units
float qs_have_guns;
string qs_models;                // "|laser1|pyro|..."
string qs_powerups;              // "|energy|shield|..."
string qs_pics;                  // "|cockpit|shld0|..."
float qs_font_cellw[3];          // QS_FONT_*
float qs_font_cellh[3];
float qs_font_colored[3];
float qs_font_have[3];
float qs_fontw[768];             // character widths, 256 per font

const float QS_FONT_SMALL = 0;
const float QS_FONT_MEDIUM = 1;
const float QS_FONT_BIG = 2;

float(string name) QS_FontIndex =
{
	if (name == "small")
		return QS_FONT_SMALL;
	if (name == "medium")
		return QS_FONT_MEDIUM;
	if (name == "big")
		return QS_FONT_BIG;
	return -1;
};

void() QS_DefaultGuns =
{
	// The Pyro-GX's gun points (x right, y up, z forward): lasers, quad
	// lasers, missiles, then the centre guns above and below.
	qs_gun[0] = '2.23 -0.91 0.55';
	qs_gun[1] = '-2.25 -0.91 0.53';
	qs_gun[2] = '3.39 -1.81 2.26';
	qs_gun[3] = '-3.41 -1.80 2.26';
	qs_gun[4] = '2.33 0 -1.39';
	qs_gun[5] = '-2.39 0 -1.39';
	qs_gun[6] = '0.02 -1.34 2.82';
	qs_gun[7] = '-0.02 -1.34 -2.91';
};

void() QS_LoadAssets =
{
	local float fh, n, i, f, start, num;
	local string line, w, models, powerups, pics;

	QS_DefaultGuns();
	fh = fopen("qs/assets.txt", FILE_READ);
	if (fh < 0)
		return;
	qs_assets_loaded = TRUE;
	qs_picsize = hash_createtab(128, EV_VECTOR);
	models = "|";
	powerups = "|";
	pics = "|";
	while (1)
	{
		line = fgets(fh);
		if not (line)
			break;
		n = tokenize(line);
		if (n < 2)
			continue;
		w = argv(0);
		if (w == "sound")
		{
			num = stof(argv(1));
			if (num >= 0 && num < 256)
				qs_have_sound[num] = TRUE;
		}
		else if (w == "vclip" && n >= 6)
		{
			num = stof(argv(1));
			if (num >= 0 && num < 120)
			{
				qs_vclip_frames[num] = stof(argv(2));
				qs_vclip_time[num] = stof(argv(3));
				qs_vclip_size[num] = max(stof(argv(4)), stof(argv(5)));
			}
		}
		else if (w == "model" || w == "blob")
			models = strcat(models, argv(1), "|");
		else if (w == "powerup")
			powerups = strcat(powerups, argv(1), "|");
		else if (w == "pic")
		{
			pics = strcat(pics, argv(1), "|");
			if (n >= 4)
				hash_add(qs_picsize, argv(1), [stof(argv(2)), stof(argv(3))], EV_VECTOR | HASH_REPLACE);
		}
		else if (w == "game")
			qs_game = stof(argv(1));
		else if (w == "gun" && n >= 5)
		{
			num = stof(argv(1));
			if (num >= 0 && num < 8)
			{
				qs_gun[num] = [stof(argv(2)), stof(argv(3)), stof(argv(4))];
				qs_have_guns = TRUE;
			}
		}
		else if (w == "font" && n >= 5)
		{
			f = QS_FontIndex(argv(1));
			if (f >= 0)
			{
				qs_font_have[f] = TRUE;
				qs_font_cellw[f] = stof(argv(2));
				qs_font_cellh[f] = stof(argv(3));
				qs_font_colored[f] = stof(argv(4));
			}
		}
		else if (w == "fontw" && n >= 3)
		{
			f = QS_FontIndex(argv(1));
			start = stof(argv(2));
			if (f >= 0)
				for (i = 3; i < n && start + i - 3 < 256; i++)
					qs_fontw[f * 256 + start + i - 3] = stof(argv(i));
		}
	}
	fclose(fh);
	qs_models = strzone(models);
	qs_powerups = strzone(powerups);
	qs_pics = strzone(pics);
};

float(string name) QS_HaveModel =
{
	return qs_assets_loaded && strstrofs(qs_models, strcat("|", name, "|")) >= 0;
};

float(string name) QS_HavePowerup =
{
	return qs_assets_loaded && strstrofs(qs_powerups, strcat("|", name, "|")) >= 0;
};

float(string name) QS_HavePic =
{
	return qs_assets_loaded && strstrofs(qs_pics, strcat("|", name, "|")) >= 0;
};

float(float vc) QS_HaveVclip =
{
	if (vc < 0 || vc >= 120)
		return FALSE;
	return qs_vclip_frames[vc] > 0;
};

float(float num) QS_HaveSound =
{
	if (num < 0 || num >= 256)
		return FALSE;
	return qs_have_sound[num];
};

string(float num) QS_SoundName =
{
	return strcat("qs/", ftos(num), ".wav");
};

// A HUD picture's size in the 320x200 cockpit layout.
vector(string name) QS_PicSize =
{
	return hash_get(qs_picsize, name, '0 0 0', EV_VECTOR);
};
