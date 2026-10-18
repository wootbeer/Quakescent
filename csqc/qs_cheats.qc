/*  Quakescent - Quake plus Descent.
    Copyright (C) 2026 the Quakescent contributors.

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.  See LICENSE.
*/

// Spotting Descent's cheat codes as they are typed during play; the server
// (qc/qs_cheats.qc) does the rest.  Descent II's codes come with Descent II
// mode.  Like Doomscent, keys three letters into a code don't reach their
// bindings, so typing a code doesn't fly the ship about much.

// The cheat numbers must match qc/qs_cheats.qc.
const float CH_ENABLE = 0;
const float CH_WOWIE = 1;
const float CH_WOWIE2 = 2;
const float CH_ALLKEYS = 3;
const float CH_INVUL = 4;
const float CH_CLOAK = 5;
const float CH_SHIELDS = 6;
const float CH_KILLREACTOR = 7;
const float CH_LEVELWARP = 8;
const float CH_RAPIDFIRE = 9;
const float CH_ROBOTSNOFIRE = 10;
const float CH_GHOST = 11;
const float CH_TURBO = 12;
const float CH_ACID = 13;

const float QS_NUM_CODES = 14;

string qs_typed;                 // the last few letters typed (zoned)
float qs_warping;
string qs_warpdigits;            // (zoned)

void(string s) QS_SetTyped =
{
	if (qs_typed)
		strunzone(qs_typed);
	qs_typed = strzone(s);
};

void(string s) QS_SetWarpDigits =
{
	if (qs_warpdigits)
		strunzone(qs_warpdigits);
	qs_warpdigits = strzone(s);
};

string(float i) QS_CheatCode =
{
	switch (i)
	{
	case 0: return "gabbagabbahey";
	case 1: return "scourge";
	case 2: return "bigred";
	case 3: return "mitzi";
	case 4: return "racerx";
	case 5: return "guile";
	case 6: return "twilight";
	case 7: return "poboys";
	case 8: return "farmerjoe";
	case 9: return "porgys";
	case 10: return "ahimsa";
	// Doomscent's extras, for both games.
	case 11: return "astral";
	case 12: return "buggin";
	case 13: return "bittersweet";
	}
	return "";
};

float(float i) QS_CheatFor =
{
	return i;                        // Descent 1's codes are in cheat order
};

// How many of the code's first letters were just typed.
float(string code) QS_PrefixTyped =
{
	local float len, tl;

	tl = strlen(qs_typed);
	for (len = min(strlen(code) - 1, tl); len > 0; len--)
		if (substring(qs_typed, tl - len, len) == substring(code, 0, len))
			return len;
	return 0;
};

// A key press during play.  Returns TRUE to keep it from its binding.
float(float key, float ch) QS_CheatKey =
{
	local float i, matched, tl, cl;
	local string code;

	if (ch >= 65 && ch <= 90)
		ch = ch + 32;

	// farmerjoe asks for a level: two digits, E<first>M<second>.
	if (qs_warping)
	{
		if (ch >= 48 && ch <= 57)
		{
			QS_SetWarpDigits(strcat(qs_warpdigits, chr2str(ch)));
			if (strlen(qs_warpdigits) == 2)
			{
				qs_warping = FALSE;
				localcmd(strcat("cmd qs_warp ", qs_warpdigits, "\n"));
			}
			return TRUE;
		}
		qs_warping = FALSE;
		return FALSE;
	}

	if (ch < 97 || ch > 122)
		return FALSE;
	code = strcat(qs_typed, chr2str(ch));
	tl = strlen(code);
	if (tl > 15)
		code = substring(code, tl - 15, 15);
	QS_SetTyped(code);
	tl = strlen(qs_typed);

	matched = 0;
	for (i = 0; i < QS_NUM_CODES; i++)
	{
		code = QS_CheatCode(i);
		cl = strlen(code);
		if (tl >= cl && substring(qs_typed, tl - cl, cl) == code)
		{
			QS_SetTyped("");
			localcmd(strcat("cmd qs_cheat ", ftos(QS_CheatFor(i)), "\n"));
			if (QS_CheatFor(i) == CH_LEVELWARP)
			{
				qs_warping = TRUE;
				QS_SetWarpDigits("");
			}
			return TRUE;
		}
		matched = max(matched, QS_PrefixTyped(code));
	}
	if (matched >= 3)
		return TRUE;
	// In single player the chat key is never needed, so it can start a
	// code (twilight).
	if (matched >= 1 && maxclients <= 1 && substring(getkeybind(key), 0, 11) == "messagemode")
		return TRUE;
	return FALSE;
};
