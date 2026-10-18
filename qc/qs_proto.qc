/*  Quakescent - Quake plus Descent.
    Copyright (C) 2026 the Quakescent contributors.

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.  See LICENSE.
*/

// Quakescent's server settings, and the functions id's code calls before
// they are defined.

var float autocvar_qs_thrust = 1;        // thrust multiplier (1 = Descent's)
var float autocvar_qs_shipbob = 1;       // Descent's gentle bob
var float autocvar_qs_damage = 1;        // weapon damage multiplier
var float autocvar_qs_damagetaken = 1;   // what hits the ship (1 = Quake's damage)
var float autocvar_qs_ship = 1;          // 0: play as Quake's marine instead
var float autocvar_qs_ickmode = 0;       // Ick Mode

void() QS_Precache;
void() QS_RegisterStats;
void() QS_ShipSpawn;
void() QS_SetChangeParms;
void() QS_SetNewParms;
void() QS_DecodeLevelParms;
void() QS_WeaponFrame;
float() QS_ItemTouch;
void() QS_BackpackTouch;
void() QS_ItemLook;
void() QS_GiveAll;
.float qs_ship;
.float qs_hits;               // times hit, and the last hit's damage, for
.float qs_hitdamage;          // the client's jolt
void() QS_StartFrame;
void(entity e) QS_IckKilled;
void(vector org, vector vel, float damage) QS_SpawnBlood;
