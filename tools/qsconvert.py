#!/usr/bin/env python3
"""
qsconvert.py - build qs_descent_assets.pk3 from your own Descent 1 data files.

Quakescent does not ship any Descent data.  This tool reads DESCENT.HOG and
DESCENT.PIG (registered 1.4/1.5, or the 1.0-1.2 shareware), or with
--descent2 Descent II's DESCENT2.HOG, DESCENT2.HAM, GROUPA.PIG and
DESCENT2.S22, and writes a resource archive for FTEQW holding the cockpit and gauges, powerup and
effect sprites, weapon and ship models, sounds and fonts the mod uses.

Usage:
    python qsconvert.py <descent dir or DESCENT.PIG> [-o qs_descent_assets.pk3]
    python qsconvert.py --descent2 <descent ii dir> [-o qs_descent_assets.pk3]

Only the Python 3 standard library is needed.  The Descent file readers are
in descent_data.py (shared with Doomscent's converter).

What it writes (all paths inside the pk3):
    gfx/qs/*.png          cockpit, gauges, reticle, weapon pictures, fonts
    progs/qs/vcNN.spr32   Descent's animations (vclips), one frame each
    progs/qs/pw_*.spr32   powerups, as self-animating sprite groups
    progs/qs/*.md3        weapon and ship models, with their textures
    sound/qs/NN.wav       sounds, by Descent sound number
    qs/assets.txt         what was converted, for the mod to read

File formats follow the Descent 1 source release, (c) 1993-1998 Parallax
Software, used under its non-commercial licence (see LICENSE in this folder).
"""

import argparse
import math
import os
import re
import struct
import sys
import zipfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import descent_data as dd                                   # noqa: E402

# Quake units per Descent unit (QS_SCALE in the mod): the Pyro-GX's radius
# of 4 Descent units makes it as wide as Quake's player hull.
WORLD_SCALE = 4.0

# Gauges[] index -> picture name (GAUGES.C order).
GAUGE_NAMES = {}
for _i in range(10):
    GAUGE_NAMES[_i] = 'shld%d' % _i          # shield ring, 0 = full
    GAUGE_NAMES[10 + _i] = 'invu%d' % _i     # invulnerable ring
GAUGE_NAMES.update({
    21: 'enrgl', 22: 'enrgr', 23: 'numer',
    24: 'keyb', 25: 'keyy', 26: 'keyr', 27: 'keyb0', 28: 'keyy0', 29: 'keyr0',
    30: 'sbkb', 31: 'sbky', 32: 'sbkr', 33: 'sbkb0', 34: 'sbky0', 35: 'sbkr0',
    36: 'sbenergy', 37: 'lives', 38: 'ship',
    46: 'rcrs0', 47: 'rcrs1', 48: 'rpri0', 49: 'rpri1', 50: 'rpri2',
    51: 'rsec0', 52: 'rsec1', 53: 'rsec2', 54: 'rsec3', 55: 'rsec4',
    56: 'homon', 57: 'homof',
})

# Weapon_info ids whose cockpit picture the HUD shows.
WEAPON_PICTURES = {0: 'wlaser', 11: 'wvulcan', 12: 'wspread', 13: 'wplasma', 14: 'wfusion',
                   8: 'wconc', 15: 'whoming', 16: 'wprox', 17: 'wsmart', 18: 'wmega'}

# Descent II's additions.
D2_GAUGE_NAMES = {20: 'aftrbrn'}
D2_WEAPON_PICTURES = {30: 'wsuper', 32: 'wgauss', 33: 'whelix', 34: 'wphoenix', 35: 'womega',
                      36: 'wflash', 37: 'wguided', 38: 'wsmine', 39: 'wmercury', 40: 'wshaker'}
D2_WEAPON_MODELS = {30: 'laser5', 31: 'laser6', 36: 'flash', 37: 'guided', 39: 'mercury',
                    40: 'shaker', 54: 'shakerkid'}
# Powerup name -> its index in Descent II's powerup table (POWERUP.H).
D2_POWERUPS = {'life': 0, 'energy': 1, 'shield': 2, 'laser': 3, 'keyb': 4, 'keyr': 5, 'keyy': 6,
               'conc1': 10, 'conc4': 11, 'quad': 12, 'vulcan': 13, 'spread': 14, 'plasma': 15,
               'fusion': 16, 'prox': 17, 'homing1': 18, 'homing4': 19, 'smart': 20, 'mega': 21,
               'vammo': 22, 'cloak': 23, 'invuln': 25, 'gauss': 28, 'helix': 29, 'phoenix': 30,
               'omega': 31, 'super': 32, 'fullmap': 33, 'converter': 34, 'ammorack': 35,
               'afterburner': 36, 'headlight': 37, 'flash1': 38, 'flash4': 39, 'guided1': 40,
               'guided4': 41, 'smine': 42, 'mercury1': 43, 'mercury4': 44, 'shaker': 45}

# Weapon_info id -> model name.  The inner model (the bright core of the
# lasers and the fusion bolt) is written as <name>_in.
WEAPON_MODELS = {0: 'laser1', 1: 'laser2', 2: 'laser3', 3: 'laser4', 14: 'fusion',
                 8: 'concussion', 15: 'homing', 17: 'smart', 18: 'mega', 9: 'flare'}

# Powerup name -> vclip number (the $POWERUP table).
POWERUP_VCLIPS = {'life': 36, 'energy': 18, 'shield': 19, 'laser': 20,
                  'keyb': 24, 'keyr': 26, 'keyy': 25, 'conc1': 34, 'conc4': 35,
                  'quad': 51, 'vulcan': 37, 'spread': 38, 'plasma': 39, 'fusion': 40,
                  'prox': 41, 'homing1': 42, 'homing4': 43, 'smart': 44, 'mega': 45,
                  'vammo': 46, 'cloak': 47, 'invuln': 49}

FONTS = {'font3-1.fnt': 'small', 'font2-1.fnt': 'medium', 'font1-1.fnt': 'big'}


class Tables:
    """What the converter needs from Descent's game tables, from either the
    binary tables registered PIGs carry or the shareware's bitmaps.tbl."""

    def __init__(self):
        self.gauges = {}             # gauge index -> bitmap index
        self.vclips = {}             # vclip number -> (frame time, [bitmap index])
        self.sounds = {}             # sound number -> PIG sound index
        self.weapon_pictures = {}    # weapon id -> bitmap index
        self.weapon_hires = {}       # weapon id -> Descent II's 640x480 picture
        self.weapon_models = {}      # weapon id -> (model, inner model or None)
        self.ship_model = None
        self.cockpit = [0, 0, 0]     # cockpit, rear view, status bar
        self.hires = {}              # low-res bitmap index -> Descent II's 640x480 one
        self.gun_points = []         # Pyro-GX gun points, Descent units


class Model:
    """Interpreter data plus the bitmap index of each of its textures."""

    def __init__(self, data, textures, colors15=False):
        self.data = data
        self.textures = textures
        self.colors15 = colors15     # POF colours are still 15-bit RGB


def tables_from_gamedata(gd):
    t = Tables()
    for gi in range(len(gd.gauges)):
        if gd.gauges[gi]:
            t.gauges[gi] = gd.gauges[gi]
    for vc, (nframes, ftime, frames, light) in enumerate(gd.vclips):
        frames = [f for f in frames if f]
        if frames:
            t.vclips[vc] = (ftime, frames)
    for num, idx in enumerate(gd.sound_map):
        if idx != 255:
            t.sounds[num] = idx

    def model(mnum):
        if mnum < 0 or mnum >= len(gd.models):
            return None
        m = gd.models[mnum]
        n_textures, first_texture = m[-3], m[-2]
        tex = [gd.obj_bitmaps[gd.obj_bitmap_ptrs[first_texture + i]] for i in range(n_textures)]
        return Model(gd.model_data[mnum], tex)

    for wi in range(min(gd.n_weapons, len(gd.weapons))):
        w = gd.weapons[wi]
        if w[43]:
            t.weapon_pictures[wi] = w[43]
        if w[0] == 2 and w[1] >= 0:            # render_type polymodel
            t.weapon_models[wi] = (model(w[1]), model(w[2]) if w[2] >= 0 else None)
    t.ship_model = model(gd.ship[0])
    t.cockpit = list(gd.cockpits[:3])
    if hasattr(gd, 'gauges_hires'):
        # Descent II: the high-resolution cockpit, gauges and pictures.
        for k in range(3):
            if len(gd.cockpits) > k + 3:
                t.hires[gd.cockpits[k]] = gd.cockpits[k + 3]
        for gi in range(len(gd.gauges)):
            if gd.gauges[gi] and gd.gauges_hires[gi]:
                t.hires[gd.gauges[gi]] = gd.gauges_hires[gi]
        # Per weapon: robot weapons pair some low-resolution pictures
        # with other weapons' high-resolution ones (21 has the proximity
        # bomb's with the homing missile's).
        for wi in range(len(gd.weapons2)):
            if gd.weapons[wi][43] and gd.weapons2[wi][47]:
                t.weapon_hires[wi] = gd.weapons2[wi][47]
    # player_ship: model_num, expl_vclip_num, mass, drag, max_thrust,
    # reverse_thrust, brakes, wiggle, max_rotthrust, then 8 gun points.
    gp = gd.ship[9:33]
    t.gun_points = [tuple(dd.fix(gp[i * 3 + k]) for k in range(3)) for i in range(8)]
    return t


def decode_tbl(data):
    """bitmaps.bin as the shareware ships it: bitmaps.tbl, each byte XORed
    with 0xE9 and rotated right two bits."""
    out = bytearray()
    for c in data:
        v = c ^ 0xE9
        out.append(((v << 2) | (v >> 6)) & 0xFF)
    text = out.decode('latin-1')
    # Line ends come out as 0x8F.
    return text.replace('\x8f', '\n').replace('\r', '')


def read_pof(data):
    """A .pof polygon model file: the interpreter data (IDTA chunk) and its
    texture names (TXTR chunk)."""
    if data[:4] != b'PSPO':
        raise dd.DescentError('not a POF file')
    p = 6                       # 'PSPO', then a 16-bit version
    idta = None
    names = []
    while p + 8 <= len(data):
        cid = data[p:p + 4]
        clen = struct.unpack_from('<i', data, p + 4)[0]
        body = data[p + 8:p + 8 + clen]
        if cid == b'IDTA':
            idta = body
        elif cid == b'TXTR':
            n = struct.unpack_from('<h', body, 0)[0]
            q = 2
            for _ in range(n):
                e = body.index(b'\0', q)
                names.append(body[q:e].decode('latin-1').lower())
                q = e + 1
        p += 8 + clen
    if idta is None:
        raise dd.DescentError('POF file has no model data')
    return idta, names


def tables_from_tbl(text, hog, pig):
    """Parse the parts of bitmaps.tbl the converter uses (BM.C)."""
    t = Tables()
    lines = [ln.strip() for ln in text.split('\n')]

    def bitmap(name):
        base = os.path.splitext(name.lower())[0]
        return pig.by_name.get(base)

    def abm_frames(name):
        base = os.path.splitext(name.lower())[0]
        frames = []
        k = 0
        while (base + '#%d' % k) in pig.by_name:
            frames.append(pig.by_name[base + '#%d' % k])
            k += 1
        return frames

    def kv(line):
        return dict(re.findall(r'(\w+)=("[^"]*"|\S+)', line))

    def pof_model(name):
        d = hog.get(name.lower())
        if d is None:
            return None
        idta, names = read_pof(d)
        tex = []
        for n in names:
            base = os.path.splitext(n)[0]
            # An animated texture is named by its first frame.
            tex.append(pig.by_name.get(base) or pig.by_name.get(base + '#0') or 0)
        return Model(idta, tex, colors15=True)

    section = None
    gauge = 0
    weapon = 0
    i = 0
    while i < len(lines):
        line = lines[i]
        i += 1
        if line.startswith('@'):            # registered-only entry
            line = line[1:]
        if not line or line.startswith(';'):
            continue
        word = line.split()[0]
        if word.startswith('$'):
            section = word
            rest = line[len(word):].strip()
            if section == '$VCLIP':
                a = kv(rest)
                num = int(a['clip_num'])
                # The bitmap is on the next line.
                name = lines[i].lstrip('@').split()[0] if i < len(lines) else ''
                i += 1
                frames = abm_frames(name)
                if frames:
                    t.vclips[num] = (float(a.get('time', 1)) / len(frames), frames)
            elif section == '$SOUND':
                parts = rest.split()
                if len(parts) >= 2:
                    idx = next((k for k, s in enumerate(pig.sounds)
                                if s.name == os.path.splitext(parts[1].lower())[0]), None)
                    if idx is not None:
                        t.sounds[int(parts[0])] = idx
            elif section in ('$WEAPON', '$WEAPON_UNUSED'):
                a = kv(rest)
                if section == '$WEAPON':
                    if 'picture' in a and bitmap(a['picture']):
                        t.weapon_pictures[weapon] = bitmap(a['picture'])
                    if 'weapon_pof' in a:
                        try:
                            outer = pof_model(a['weapon_pof'])
                            inner = pof_model(a['weapon_pof_inner']) if 'weapon_pof_inner' in a else None
                            if outer:
                                t.weapon_models[weapon] = (outer, inner)
                        except (dd.DescentError, struct.error, ValueError) as e:
                            print('warning: model for weapon %d skipped: %s' % (weapon, e))
                weapon += 1
            elif section == '$PLAYER_SHIP':
                a = kv(rest)
                if 'model' in a:
                    try:
                        t.ship_model = pof_model(a['model'])
                    except (dd.DescentError, struct.error, ValueError) as e:
                        print('warning: ship model skipped: %s' % e)
            elif section == '$GAUGES':
                gauge = gauge_line(t, rest, gauge, bitmap, abm_frames)
            continue
        if section == '$COCKPIT':
            k = t.cockpit.index(0) if 0 in t.cockpit else None
            if k is not None:
                t.cockpit[k] = bitmap(word) or 0
        elif section == '$GAUGES':
            gauge = gauge_line(t, line, gauge, bitmap, abm_frames)
    t.gun_points = []            # the POF's GUNS chunk is not read; the mod has defaults
    return t


def gauge_line(t, line, gauge, bitmap, abm_frames):
    """One bitmap in the $GAUGES list: a .bbm takes one gauge slot, an .abm
    one per frame."""
    if not line:
        return gauge
    name = line.split()[0]
    if '=' in name:
        return gauge
    if name.lower().endswith('.abm'):
        for f in abm_frames(name):
            t.gauges[gauge] = f
            gauge += 1
    else:
        b = bitmap(name)
        if b:
            t.gauges[gauge] = b
        gauge += 1
    return gauge


# --------------------------------------------------------------------------
# Output formats

def spr32(frames, group_interval=None):
    """An FTE/DarkPlaces 32-bit sprite (SPR version 32).  frames is a list
    of (w, h, rgba).  With group_interval the frames form one self-animating
    group; otherwise each is its own frame for the mod to step through."""
    maxw = max(f[0] for f in frames)
    maxh = max(f[1] for f in frames)
    radius = math.sqrt((maxw / 2.0) ** 2 + (maxh / 2.0) ** 2)
    nframes = 1 if group_interval else len(frames)
    out = bytearray(b'IDSP')
    # version, type (2 = SPR_VP_PARALLEL), radius, maxwidth, maxheight,
    # numframes, beamlength, synctype (1 = random)
    out += struct.pack('<iifiiifi', 32, 2, radius, maxw, maxh, nframes, 0.0, 1)

    def frame(w, h, rgba):
        return struct.pack('<iiii', -(w // 2), h // 2, w, h) + bytes(rgba)

    if group_interval:
        out += struct.pack('<ii', 1, len(frames))
        # FTE takes each frame's own duration (and adds them up itself).
        for k in range(len(frames)):
            out += struct.pack('<f', group_interval)
        for w, h, rgba in frames:
            out += frame(w, h, rgba)
    else:
        for w, h, rgba in frames:
            out += struct.pack('<i', 0) + frame(w, h, rgba)
    return bytes(out)


# Animations whose fine detail matters (the omega's lightning streaks):
# enlarged with hard pixel edges, so the engine's texture smoothing keeps
# them crisp as Descent's pixel-for-pixel drawing did.  vclip -> factor.
SHARP_VCLIPS = {103: 4}


def upscale(w, h, rgba, k):
    out = bytearray(w * k * h * k * 4)
    for y in range(h * k):
        row = (y // k) * w
        for x in range(w * k):
            s = (row + x // k) * 4
            d = (y * w * k + x) * 4
            out[d:d + 4] = rgba[s:s + 4]
    return w * k, h * k, bytes(out)


def md3_normal(n):
    x, y, z = n
    if x == 0 and y == 0:
        return 0 if z > 0 else 128
    lng = int(math.degrees(math.acos(max(-1.0, min(1.0, z)))) * 255 / 360) & 255
    lat = int(math.degrees(math.atan2(y, x)) * 255 / 360) & 255
    return (lat << 8) | lng


def md3(name, surfaces):
    """A one-frame MD3.  surfaces: list of (shader path, verts, uvs, tris)
    with verts in Quake units and tris as vertex index triples."""
    allv = [v for s in surfaces for v in s[1]] or [(0, 0, 0)]
    mins = [min(v[k] for v in allv) for k in range(3)]
    maxs = [max(v[k] for v in allv) for k in range(3)]
    radius = max(math.sqrt(sum(c * c for c in v)) for v in allv)

    def name64(s):
        return s.encode('latin-1')[:63].ljust(64, b'\0')

    header_size = 108
    frame = struct.pack('<3f3f3ff16s', *mins, *maxs, 0, 0, 0, radius, b'frame0')
    surf_blobs = []
    for shader, verts, uvs, tris in surfaces:
        # Smooth-ish normals: average of the faces touching each vertex.
        normals = [[0.0, 0.0, 0.0] for _ in verts]
        for a, b, c in tris:
            u = [verts[b][k] - verts[a][k] for k in range(3)]
            v = [verts[c][k] - verts[a][k] for k in range(3)]
            n = (u[1] * v[2] - u[2] * v[1], u[2] * v[0] - u[0] * v[2], u[0] * v[1] - u[1] * v[0])
            for i in (a, b, c):
                for k in range(3):
                    normals[i][k] += n[k]
        tri_data = b''.join(struct.pack('<3i', *t) for t in tris)
        shader_data = name64(shader) + struct.pack('<i', 0)
        st_data = b''.join(struct.pack('<2f', u, v) for u, v in uvs)
        xyz = bytearray()
        for v, n in zip(verts, normals):
            ln = math.sqrt(sum(c * c for c in n)) or 1.0
            xyz += struct.pack('<3hH', *[int(round(c * 64)) for c in v],
                               md3_normal(tuple(c / ln for c in n)))
        surf_header = 108
        ofs_tris = surf_header
        ofs_shaders = ofs_tris + len(tri_data)
        ofs_st = ofs_shaders + len(shader_data)
        ofs_xyz = ofs_st + len(st_data)
        ofs_end = ofs_xyz + len(xyz)
        blob = (b'IDP3' + name64('surf%d' % len(surf_blobs)) +
                struct.pack('<iiiiiiiiii', 0, 1, 1, len(verts), len(tris),
                            ofs_tris, ofs_shaders, ofs_st, ofs_xyz, ofs_end) +
                tri_data + shader_data + st_data + bytes(xyz))
        surf_blobs.append(blob)
    ofs_frames = header_size
    ofs_tags = ofs_frames + len(frame)
    ofs_surfs = ofs_tags
    ofs_end = ofs_surfs + sum(len(b) for b in surf_blobs)
    head = (b'IDP3' + struct.pack('<i', 15) + name64(name) +
            struct.pack('<iiiiiiiii', 0, 1, 0, len(surf_blobs), 0,
                        ofs_frames, ofs_tags, ofs_surfs, ofs_end))
    return head + frame + b''.join(surf_blobs)


# --------------------------------------------------------------------------

class QSConverter:
    def __init__(self, hog_path, pig_path, out, ham_path=None, sound_path=None):
        self.hog = dd.read_hog(hog_path)
        self.d2 = ham_path is not None
        if self.d2:
            self.pig = dd.Pig2(pig_path, sound_path)
            palname = 'groupa.256'
        else:
            self.pig = dd.Pig(pig_path)
            palname = 'palette.256'
        pal = self.hog.get(palname)
        if pal is None:
            raise dd.DescentError('%s missing from HOG' % palname)
        self.palette = [(min(255, pal[i * 3] * 255 // 63),
                         min(255, pal[i * 3 + 1] * 255 // 63),
                         min(255, pal[i * 3 + 2] * 255 // 63)) for i in range(256)]
        if self.d2:
            with open(ham_path, 'rb') as f:
                self.gd2 = dd.GameData2(f.read())
            self.tables = tables_from_gamedata(self.gd2)
            self.source = 'descent2'
        elif self.pig.gamedata:
            self.tables = tables_from_gamedata(self.pig.gamedata)
            self.source = 'registered'
        elif 'bitmaps.bin' in self.hog:
            self.tables = tables_from_tbl(decode_tbl(self.hog['bitmaps.bin']), self.hog, self.pig)
            self.source = 'shareware'
        else:
            raise dd.DescentError('no game tables found (neither in the PIG nor bitmaps.bin in the HOG)')
        self.zip = zipfile.ZipFile(out, 'w', zipfile.ZIP_DEFLATED)
        self.info = ['# Quakescent asset pack, generated by qsconvert.py from %s Descent data.' % self.source,
                     '# Contains data from your own copy of Descent; do not redistribute.',
                     'source %s' % self.source,
                     'game %d' % (2 if self.d2 else 1)]
        self.report = []

    def rgba(self, index, transparent=False):
        w, h, flags, px = self.pig.pixels(index)
        out = bytearray(w * h * 4)
        transparent = transparent or flags & (dd.BM_FLAG_TRANSPARENT | dd.BM_FLAG_SUPER_TRANSPARENT)
        for i, c in enumerate(px):
            if transparent and c >= 254:
                continue
            r, g, b = self.palette[c]
            out[i * 4:i * 4 + 4] = bytes((r, g, b, 255))
        return w, h, out

    def pic(self, name, index, transparent=False, hi=None):
        """A HUD picture.  Its size is given in the 320x200 cockpit layout;
        Descent II's 640x480 versions are used where there are some, at
        half by 1/2.4 of their size."""
        hi = hi or self.tables.hires.get(index)
        if hi:
            w, h, data = self.rgba(hi, transparent)
            sw, sh = w / 2.0, h / 2.4
        else:
            w, h, data = self.rgba(index, transparent)
            sw, sh = w, h
        self.zip.writestr('gfx/qs/%s.png' % name, dd.png(w, h, data))
        self.info.append('pic %s %g %g' % (name, sw, sh))

    # -- HUD -------------------------------------------------------------

    def convert_hud(self):
        t = self.tables
        for k, name in enumerate(('cockpit', 'rearview', 'status')):
            if t.cockpit[k]:
                self.pic(name, t.cockpit[k], True)
        n = 0
        gauges = dict(GAUGE_NAMES)
        pictures = dict(WEAPON_PICTURES)
        if self.d2:
            gauges.update(D2_GAUGE_NAMES)
            pictures.update(D2_WEAPON_PICTURES)
        for gi, name in gauges.items():
            if gi in t.gauges:
                self.pic(name, t.gauges[gi])
                n += 1
        for wi, name in pictures.items():
            if wi in t.weapon_pictures:
                self.pic(name, t.weapon_pictures[wi], hi=t.weapon_hires.get(wi))
                n += 1
        self.report.append('%d HUD pictures' % n)

    def convert_fonts(self):
        """Descent's fonts as 16x16 character grids (gfx/qs/font_*.png) plus
        each character's width in assets.txt, for proportional text."""
        for hogname, fname in FONTS.items():
            d = self.hog.get(hogname)
            if d is None or d[:4] != b'PSFN':
                continue
            datasize = struct.unpack_from('<i', d, 4)[0]
            f = 8
            w, h, flags, baseline, minc, maxc, bytewidth, data_ofs, _, widths_ofs, kern_ofs = \
                struct.unpack_from('<hhhhBBhIIII', d, f)
            nchars = maxc - minc + 1
            color = flags & 1
            prop = flags & 2
            palette = None
            if color:
                pal = d[8 + datasize:8 + datasize + 768]
                palette = [(pal[i * 3] * 255 // 63, pal[i * 3 + 1] * 255 // 63, pal[i * 3 + 2] * 255 // 63)
                           for i in range(256)]
            widths = (struct.unpack_from('<%dh' % nchars, d, f + widths_ofs) if prop else [w] * nchars)
            cell_w = max(max(widths), 1)
            cell_h = h
            gw, gh = cell_w * 16, cell_h * 16
            grid = bytearray(gw * gh * 4)
            char_w = [0] * 256
            ptr = f + (data_ofs if prop else 28)
            for i in range(nchars):
                cw = widths[i]
                code = minc + i
                bw = (cw + 7) // 8 if prop else bytewidth
                for y in range(h):
                    for x in range(cw):
                        if color:
                            c = d[ptr + y * cw + x]
                            if c == 255:
                                continue
                            px = bytes(palette[c] + (255,))
                        else:
                            if not d[ptr + y * bw + x // 8] & (0x80 >> (x % 8)):
                                continue
                            px = b'\xff\xff\xff\xff'
                        gx = (code % 16) * cell_w + x
                        gy = (code // 16) * cell_h + y
                        grid[(gy * gw + gx) * 4:(gy * gw + gx) * 4 + 4] = px
                ptr += (cw * h) if color else (bw * h)
                if 0 <= code < 256:
                    char_w[code] = cw
            # Lower case falls back to upper case where Descent has none.
            for code in range(ord('a'), ord('z') + 1):
                if char_w[code] == 0 and char_w[code - 32]:
                    char_w[code] = char_w[code - 32]
                    for y in range(cell_h):
                        sy = (code - 32) // 16 * cell_h + y
                        dy = code // 16 * cell_h + y
                        s0 = (sy * gw + (code - 32) % 16 * cell_w) * 4
                        d0 = (dy * gw + code % 16 * cell_w) * 4
                        grid[d0:d0 + cell_w * 4] = grid[s0:s0 + cell_w * 4]
            if char_w[32] == 0:
                char_w[32] = max(2, cell_w // 2)
            self.zip.writestr('gfx/qs/font_%s.png' % fname, dd.png(gw, gh, grid))
            self.info.append('font %s %d %d %d' % (fname, cell_w, cell_h, 1 if color else 0))
            for start in range(0, 256, 32):
                self.info.append('fontw %s %d %s' % (fname, start,
                                                     ' '.join(str(c) for c in char_w[start:start + 32])))
            self.report.append('font %s' % fname)

    # -- sprites ---------------------------------------------------------

    def frames(self, vc):
        ftime, frames = self.tables.vclips[vc]
        return ftime, [self.rgba(f) for f in frames]

    def convert_sprites(self):
        n = 0
        for vc in sorted(self.tables.vclips):
            ftime, frames = self.frames(vc)
            if self.d2 and vc in SHARP_VCLIPS:
                frames = [upscale(*f, SHARP_VCLIPS[vc]) for f in frames]
            self.zip.writestr('progs/qs/vc%d.spr32' % vc, spr32(frames))
            self.info.append('vclip %d %d %.4f %d %d' % (vc, len(frames), ftime,
                                                          frames[0][0], frames[0][1]))
            n += 1
        p = 0
        if self.d2:
            powerups = dict((name, self.gd2.powerups[i][0]) for name, i in D2_POWERUPS.items()
                            if i < len(self.gd2.powerups))
        else:
            powerups = POWERUP_VCLIPS
        for name, vc in powerups.items():
            if vc not in self.tables.vclips:
                continue
            ftime, frames = self.frames(vc)
            self.zip.writestr('progs/qs/pw_%s.spr32' % name, spr32(frames, ftime))
            self.info.append('powerup %s %d %d' % (name, frames[0][0], frames[0][1]))
            p += 1
        # Weapon blobs drawn as plain sprites.
        for bname in ('sprdblob', 'plasblob#0', 'blob01#0'):
            idx = self.pig.by_name.get(bname)
            if idx:
                w, h, data = self.rgba(idx)
                nm = bname.split('#')[0]
                self.zip.writestr('progs/qs/%s.spr32' % nm, spr32([(w, h, data)]))
                self.info.append('blob %s %d %d' % (nm, w, h))
        self.report.append('%d animations, %d powerups' % (n, p))

    # -- sounds ----------------------------------------------------------

    def convert_sounds(self):
        n = 0
        for num, idx in sorted(self.tables.sounds.items()):
            if idx < len(self.pig.sounds):
                s = self.pig.sounds[idx]
                self.zip.writestr('sound/qs/%d.wav' % num, dd.wav(self.pig.sound_pcm(s), 22050 if self.d2 else 11025))
                self.info.append('sound %d' % num)
                n += 1
        self.report.append('%d sounds' % n)

    # -- models ----------------------------------------------------------

    def write_model(self, model, name):
        faces, colors = dd.interp_faces(model.data)
        base = 'progs/qs/%s' % name
        if colors:
            strip = bytearray()
            for c in colors:
                if c < 256 and not model.colors15:
                    r, g, b = self.palette[c]
                else:
                    r, g, b = (((c >> 10) & 31) * 255 // 31, ((c >> 5) & 31) * 255 // 31,
                               (c & 31) * 255 // 31)
                strip += bytes((r, g, b, 255))
            self.zip.writestr(base + '_c.png', dd.png(len(colors), 1, strip))
        for i, bm in enumerate(model.textures):
            if any(f[0] == 't' and f[1] == i for f in faces):
                # Textures the data lacks (registered-only bitmaps in the
                # shareware) become plain grey.
                w, h, rgba = self.rgba(bm) if bm else (1, 1, b'\x80\x80\x80\xff')
                self.zip.writestr('%s_t%d.png' % (base, i), dd.png(w, h, rgba))
        surfaces = {}
        for kind, mat, verts, uvs in faces:
            shader = (base + '_c') if kind == 'c' else ('%s_t%d' % (base, mat))
            sv, suv, stris = surfaces.setdefault(shader, ([], [], []))
            first = len(sv)
            for k, (x, y, z) in enumerate(verts):
                # Descent: x right, y up, z forward.  Quake: x forward,
                # y left, z up.
                sv.append((z * WORLD_SCALE, -x * WORLD_SCALE, y * WORLD_SCALE))
                if kind == 'c':
                    suv.append(((mat + 0.5) / len(colors), 0.5))
                else:
                    suv.append(uvs[k])
            for k in range(1, len(verts) - 1):
                stris.append((first, first + k, first + k + 1))
        surf_list = [(sh, sv, suv, st) for sh, (sv, suv, st) in surfaces.items() if st]
        if not surf_list:
            raise dd.DescentError('model %s has no faces' % name)
        self.zip.writestr(base + '.md3', md3(name, surf_list))
        self.info.append('model %s' % name)

    def convert_models(self):
        done = 0
        models = dict(WEAPON_MODELS)
        if self.d2:
            models.update(D2_WEAPON_MODELS)
        for wi, name in models.items():
            pair = self.tables.weapon_models.get(wi)
            if not pair or not pair[0]:
                continue
            try:
                self.write_model(pair[0], name)
                done += 1
                if pair[1]:
                    self.write_model(pair[1], name + '_in')
            except (struct.error, KeyError, IndexError, dd.DescentError) as e:
                print('warning: model for weapon %d skipped: %s' % (wi, e))
        if self.tables.ship_model:
            try:
                self.write_model(self.tables.ship_model, 'pyro')
                done += 1
            except (struct.error, KeyError, IndexError, dd.DescentError) as e:
                print('warning: ship model skipped: %s' % e)
        for k, g in enumerate(self.tables.gun_points):
            self.info.append('gun %d %.3f %.3f %.3f' % ((k,) + g))
        self.report.append('%d models' % done)

    # -- Ick Mode --------------------------------------------------------

    def convert_ickface(self, path):
        """Ick Mode's monster face: data/ickface.png if there is one, else
        tools/ickface.png, else a built-in cartoon face."""
        face = None
        used = 'built-in'
        if path:
            try:
                with open(path, 'rb') as f:
                    face = dd.fit_image(*dd.read_png(f.read()), target_h=64)
                used = os.path.basename(path)
            except (OSError, ValueError, KeyError) as e:
                print('warning: %s: %s; using the built-in face' % (path, e))
        if face is None:
            face = dd.default_face()
        self.zip.writestr('progs/qs/ickface.spr32', spr32([face]))
        self.info.append('blob ickface %d %d' % (face[0], face[1]))
        self.report.append('Ick Mode face (%s)' % used)

    def finish(self):
        self.zip.writestr('qs/assets.txt', '\n'.join(self.info) + '\n')
        self.zip.close()


def find_file(directory, name):
    for f in os.listdir(directory):
        if f.lower() == name.lower():
            return os.path.join(directory, f)
    return None


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    ap.add_argument('source', help='Descent directory, or path to DESCENT.PIG')
    ap.add_argument('--hog', help='path to DESCENT.HOG (default: next to the PIG)')
    ap.add_argument('--descent2', action='store_true',
                    help='convert Descent II (DESCENT2.HOG, DESCENT2.HAM, GROUPA.PIG, DESCENT2.S22)')
    ap.add_argument('-o', '--output', default='qs_descent_assets.pk3')
    args = ap.parse_args(argv)

    ham = sounds = None
    if args.descent2:
        d = args.source if os.path.isdir(args.source) else os.path.dirname(os.path.abspath(args.source))
        hog = args.hog or find_file(d, 'descent2.hog')
        ham = find_file(d, 'descent2.ham')
        pig = find_file(d, 'groupa.pig')
        sounds = find_file(d, 'descent2.s22') or find_file(d, 'descent2.s11')
        for f, name in ((hog, 'DESCENT2.HOG'), (ham, 'DESCENT2.HAM'), (pig, 'GROUPA.PIG'),
                        (sounds, 'DESCENT2.S22')):
            if not f:
                sys.exit('error: %s not found in %s' % (name, d))
    elif os.path.isdir(args.source):
        pig = find_file(args.source, 'descent.pig')
        hog = args.hog or find_file(args.source, 'descent.hog')
    else:
        pig = args.source
        hog = args.hog or find_file(os.path.dirname(os.path.abspath(pig)) or '.', 'descent.hog')
    if not pig or not os.path.exists(pig):
        sys.exit('error: DESCENT.PIG not found')
    if not hog or not os.path.exists(hog):
        sys.exit('error: DESCENT.HOG not found (pass --hog)')

    tmp = args.output + '.tmp'
    try:
        c = QSConverter(hog, pig, tmp, ham, sounds)
        c.convert_hud()
        c.convert_fonts()
        c.convert_sprites()
        c.convert_sounds()
        c.convert_models()
        here = os.path.dirname(os.path.abspath(sys.executable if getattr(sys, 'frozen', False) else __file__))
        face = find_file(os.path.dirname(os.path.abspath(pig)), 'ickface.png')
        if not face and os.path.exists(os.path.join(here, 'ickface.png')):
            face = os.path.join(here, 'ickface.png')
        c.convert_ickface(face)
        c.finish()
    except dd.DescentError as e:
        if os.path.exists(tmp):
            os.remove(tmp)
        sys.exit('error: %s' % e)
    os.replace(tmp, args.output)
    print('wrote %s from %s Descent data (%s)' % (args.output, c.source, ', '.join(c.report)))


if __name__ == '__main__':
    main()
