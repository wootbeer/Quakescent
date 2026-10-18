# Quakescent

Quake plus Descent: fly the Pyro-GX through Quake's levels with Descent's
six-degrees-of-freedom flight, cockpit and weapons. A sister project of
[Doomscent](https://github.com/wootbeer/Doomscent).

Quakescent is a mod for an unmodified [FTEQW](https://www.fteqw.org/), the
Quake engine. Quake's monsters, maps and music stay as they are. The player
becomes Descent's ship:

- **Full 6DOF flight.** Thrust, slide and bank, loop and fly upside down,
  with Descent's own ship physics (thrust 7.8, mass 4, drag 0.033, the
  rotational drag behind banking and the gentle bob).
- **Descent's cockpit.** Energy and shield gauges, the shield ring, key
  lights, weapon boxes and the reticle, laid out as in Descent, plus the
  rear view and Descent's message line for all game messages.
- **Descent's weapons.** Lasers (levels 1-4, plus quad lasers), vulcan,
  spreadfire, plasma and fusion (hold fire to charge); concussion, homing
  and smart missiles, proximity bombs and the mega missile; flares. Damage,
  speed, fire rate and energy use come from Descent's weapon table, and the
  lasers, missiles and fusion bolt use Descent's own 3D models.
- **Descent's powerups.** Quake's pickups become Descent's spinning
  powerups (see below).
- **Shootable switches.** Buttons you'd have to press in Quake also fire
  when you shoot them, as in Descent.

## Install and play (Windows)

1. Download the latest `Quakescent-x.y.z.zip` from
   [Releases](https://github.com/wootbeer/Quakescent/releases) and unzip it
   anywhere, e.g. `C:\Games\Quakescent`.
2. Copy your game files in:
   - Quake's `PAK0.PAK`, and `PAK1.PAK` for the full game, into `id1`
     (they're in the `id1` folder of your Quake). For the 2021 re-release
     (Steam, GOG) copy `rerelease\id1\pak0.pak` instead, which holds the
     whole game. The shareware `PAK0.PAK` works too (episode 1).
   - `DESCENT.HOG` and `DESCENT.PIG` from Descent 1 into `data`. The
     registered game (1.4/1.5) and the 1.0-1.2 shareware both work.
3. Double-click `Quakescent.bat`.

On the first run the launcher:

- offers to download FTEQW (2026-07-13) into an `fte` folder (or set the
  `FTEQW` environment variable to an existing `fteqw64.exe`);
- converts your Descent files into `quakescent\qs_descent_assets.pk3`
  (cockpit, gauges, sprites, models, sounds, fonts).

Then pick New Game from Quake's menu, or pass a map:
`Quakescent.bat +map e1m1 +skill 2`.

**No game data is included**, and the generated `qs_descent_assets.pk3`
contains Descent's data, so don't share it. Quake and Descent are sold on
GOG and Steam.

Windows SmartScreen or antivirus may be wary of `tools\qsconvert.exe`,
since it isn't code-signed. It is built from `tools/qsconvert.py` by this
repository's GitHub Actions; with Python 3 installed you can delete the exe
and the launcher will run the script instead.

## Linux

Put your files in `id1/` and `data/` as above and run `./quakescent.sh`.
It needs Python 3, and downloads FTEQW into `fte/` on the first run (or set
`FTEQW=/path/to/fteqw64`).

## Running from source

Clone the repository, put your files in `id1/` and `data/`, and run
`Quakescent.bat` or `./quakescent.sh`. With Python 3 installed, the
launcher rebuilds the mod whenever something in `qc/`, `csqc/` or `mod/`
changes, downloading FTE's QuakeC compiler (fteqcc) into `tools/` the
first time. By hand:

```
python tools/build.py                 # qc/ + csqc/ -> quakescent/
python tools/qsconvert.py data -o quakescent/qs_descent_assets.pk3
fteqw64 -basedir . -game quakescent +map e1m1
```

To make a release, set `VERSION` and add a `CHANGELOG.md` entry, then either
push a tag `v<VERSION>` or run the Release workflow from the Actions tab with
"publish" ticked. It builds `qsconvert.exe` and the zip and publishes them.

## Controls

| Action | Key |
|---|---|
| Thrust forward / back | W / S |
| Slide left / right | A / D |
| Slide up / down | Space / C (or Ctrl) |
| Pitch and turn | Mouse (arrow keys also turn and pitch) |
| Bank left / right | Q / E |
| Fire primary / secondary | Left / right mouse button |
| Select primary weapon | 1-5 (laser, vulcan, spreadfire, plasma, fusion) |
| Select secondary weapon | 6-0 (concussion, homing, proximity, smart, mega) |
| Cycle secondary / primary | Middle mouse button or wheel down / wheel up |
| Fire flare | F |
| Drop proximity bomb | B |
| Rear view (tap to toggle, hold to peek) | V |
| Level the ship | Z |

Settings (type them in the console, `~`):

| Setting | Default | |
|---|---|---|
| `qs_cockpit` | 1 | Descent's cockpit; 0 for full-screen readouts |
| `qs_aimmomentum` | 1 | turns ease in and out like Descent's |
| `qs_levelturn` | 1 | near level flight, turn about the world's vertical (0: always about the ship's own axes, like Descent) |
| `qs_autolevel` | 0 | roll back to level when not banking |
| `qs_bankturns` | 0 | bank into turns |
| `qs_thrust` | 1 | thrust multiplier |
| `qs_damage` | 1 | weapon damage multiplier |
| `qs_shipbob` | 1 | the ship's gentle bob |
| `qs_ship` | 1 | 0 plays as Quake's marine (from the next map) |

Mouse speed is FTE's `sensitivity`.

## How Quake's items map to Descent

| Quake | Quakescent |
|---|---|
| Health (small, normal) / megahealth | Shield boost / +100 shields |
| Green / yellow / red armour | Energy +50 / +75 / +100 |
| Cells (small / large) | Energy boost / +50 energy |
| Shells (small / large) | Concussion missile / 4-pack |
| Nails | Vulcan ammo |
| Rockets (small / large) | Proximity bomb pack / 4 homing missiles |
| Super shotgun | Spreadfire cannon |
| Nailgun | Vulcan cannon |
| Super nailgun | Plasma cannon |
| Thunderbolt | Fusion cannon |
| Grenade launcher | Laser upgrade (a mega missile once the lasers are at level 4) |
| Rocket launcher | Smart missile |
| Quad damage | Quad lasers |
| Pentagram of protection | Invulnerability |
| Ring of shadows | Cloak |
| Silver / gold key | Blue / yellow key (still open Quake's doors) |
| Backpack | Its ammo as vulcan ammo, homing missiles and energy |

The biosuit and the runes stay as they are. Impulse 255 gives everything
(outside deathmatch).

## Licence

Quakescent's QuakeC (`qc/`, `csqc/`) is free software under the GNU GPL
version 2 or later ([LICENSE](LICENSE)). It is built on id Software's GPL
QuakeC (v1.01, from id-Software/Quake-Tools) and FTEQW's QuakeC
definitions.

The asset converter (`tools/qsconvert.py`, `tools/descent_data.py`) is a
separate program under a non-commercial licence
([tools/LICENSE](tools/LICENSE)), because its handling of Descent's file
formats derives from the Descent source releases, which Parallax Software
licensed for non-commercial use only. It shares its reader with Doomscent.

FTEQW is a separate program under the GPL, downloaded by the launcher and
not modified. Quake is (c) id Software; Descent is (c) Parallax Software /
Interplay. Quake is a trademark of id Software and Descent of Interplay;
Quakescent is not affiliated with or endorsed by either.
