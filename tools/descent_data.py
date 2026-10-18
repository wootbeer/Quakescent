#!/usr/bin/env python3
"""
descent_data.py - readers for Descent's data files: HOG, PIG, HAM and
polygon models, plus small PNG and WAV writers.  qsconvert.py uses them.

These come from Doomscent's converter (tools/ddconvert.py in
https://github.com/wootbeer/Doomscent), with one addition: shareware 1.0-1.2
PIGs, which start straight with the bitmap directory, are recognised.

File formats follow the Descent 1 and Descent 2 source releases (PIGGY.C,
BM.C, INTERP.ASM), (c) 1993-1998 Parallax Software, used under its
non-commercial licence (see LICENSE in this folder).
"""

import struct
import zlib

# --------------------------------------------------------------------------
# Constants mirrored from the Descent 1 source (BM.H, PIGGY.C, ...).

MAX_TEXTURES = 800
MAX_SOUNDS = 250
VCLIP_MAXNUM = 70
MAX_EFFECTS = 60
MAX_WALL_ANIMS = 30
MAX_ROBOT_TYPES = 30
MAX_ROBOT_JOINTS = 600
MAX_WEAPON_TYPES = 30
MAX_POWERUP_TYPES = 29
MAX_GAUGE_BMS = 80
MAX_POLYGON_MODELS = 85
MAX_OBJ_BITMAPS = 210

BM_FLAG_TRANSPARENT = 1
BM_FLAG_SUPER_TRANSPARENT = 2
BM_FLAG_RLE = 8

DBM_FLAG_ABM = 64
DBM_FLAG_LARGE = 128

# The structures are byte packed; sizes verified against the 0xabcd marker
# at the end of robot_info.
SIZE_TMAP_INFO = 26
SIZE_VCLIP = 82
SIZE_ECLIP = 130
SIZE_WCLIP = 66
SIZE_ROBOT_INFO = 486
SIZE_JOINTPOS = 8
WEAPON_FMT = '<' + 'bbbb' + 'bhbh' + 'bhbb' + 'bbbb' + 'bbbb' + 'iiH' + 'iii' + '5i5i' + '7i' + 'H'
SIZE_WEAPON_INFO = struct.calcsize(WEAPON_FMT)  # 115
SIZE_POWERUP_INFO = 16
POLYMODEL_FMT = '<iiI10i' + '30i' * 3 + '10i10B' + '30i' * 2 + '6iiBHB'
SIZE_POLYMODEL = struct.calcsize(POLYMODEL_FMT)  # 734

# Gauges[] indices (GAUGES.C) and the names the mod looks them up by.
def fix(v):
    return v / 65536.0


class DescentError(Exception):
    pass


# --------------------------------------------------------------------------
# HOG

def read_hog(path):
    data = open(path, 'rb').read()
    if data[:3] != b'DHF':
        raise DescentError('%s is not a Descent HOG file' % path)
    files = {}
    p = 3
    while p + 17 <= len(data):
        name = data[p:p + 13].split(b'\0')[0].decode('latin-1').lower()
        size = struct.unpack_from('<i', data, p + 13)[0]
        files[name] = data[p + 17:p + 17 + size]
        p += 17 + size
    return files


# --------------------------------------------------------------------------
# PIG

class Bitmap:
    __slots__ = ('name', 'width', 'height', 'flags', 'offset')


class Sound:
    __slots__ = ('name', 'length', 'offset')


class Pig:
    def __init__(self, path):
        self.data = open(path, 'rb').read()
        self.gamedata = None
        start = struct.unpack_from('<i', self.data, 0)[0]
        if 0 < start < len(self.data) and not self._directory_at_start():
            self.data_start = start
            try:
                self.gamedata = GameData(self.data, 4)
            except (struct.error, DescentError) as e:
                print('warning: could not read game tables from PIG (%s); '
                      'models and some sprites will be skipped' % e)
        else:
            # Shareware / old PIGs have no embedded game data.
            self.data_start = 0
        self._read_directory()

    def _directory_at_start(self):
        """Shareware 1.0-1.2 PIGs start straight with the bitmap directory
        (bitmap count, sound count, then 8-character names) and have no
        game tables, so the first word is a count, not an offset."""
        d = self.data
        nbm, nsnd = struct.unpack_from('<ii', d, 0)
        if not (0 < nbm < 5000 and 0 <= nsnd < 1000):
            return False
        if 8 + nbm * 17 + nsnd * 20 > len(d):
            return False
        name = d[8:16].split(b'\0')[0]
        return len(name) > 0 and all(32 < c < 127 for c in name)

    def _read_directory(self):
        d = self.data
        q = self.data_start
        nbm, nsnd = struct.unpack_from('<ii', d, q)
        q += 8
        header_size = nbm * 17 + nsnd * 20
        base = self.data_start + 8 + header_size
        self.bitmaps = [None]           # bitmap index 0 is the "bogus" bitmap
        self.by_name = {}
        for _ in range(nbm):
            name, dflags, w, h, flags, avg, off = struct.unpack_from('<8sBBBBBi', d, q)
            q += 17
            b = Bitmap()
            b.name = name.split(b'\0')[0].decode('latin-1').lower()
            if dflags & DBM_FLAG_ABM:
                b.name += '#%d' % (dflags & 63)
            if dflags & DBM_FLAG_LARGE:
                w += 256
            b.width, b.height, b.flags, b.offset = w, h, flags, base + off
            self.bitmaps.append(b)
            self.by_name.setdefault(b.name, len(self.bitmaps) - 1)
        self.sounds = []
        for _ in range(nsnd):
            name, length, dlen, off = struct.unpack_from('<8siii', d, q)
            q += 20
            s = Sound()
            s.name = name.split(b'\0')[0].decode('latin-1').lower()
            s.length, s.offset = length, base + off
            self.sounds.append(s)

    def pixels(self, index):
        """Return (w, h, flags, bytes of palette indices)."""
        b = self.bitmaps[index]
        w, h = b.width, b.height
        d = self.data
        if not b.flags & BM_FLAG_RLE:
            return w, h, b.flags, d[b.offset:b.offset + w * h]
        p = b.offset + 4
        line_sizes = d[p:p + h]
        p += h
        out = bytearray()
        for y in range(h):
            row = bytearray()
            q = p
            end = p + line_sizes[y]
            while q < end:
                c = d[q]
                q += 1
                if (c & 0xE0) == 0xE0:
                    n = c & 0x1F
                    if n == 0:
                        break
                    row += bytes([d[q]]) * n
                    q += 1
                else:
                    row.append(c)
            row = row[:w]
            row += b'\0' * (w - len(row))
            out += row
            p = end
        return w, h, b.flags, bytes(out)

    def sound_pcm(self, s):
        return self.data[s.offset:s.offset + s.length]


class GameData:
    """The bitmaps.bin tables that registered PIGs carry (bm_read_all)."""

    def __init__(self, d, o):
        def i32():
            nonlocal o
            v = struct.unpack_from('<i', d, o)[0]
            o += 4
            return v

        i32()                                           # NumTextures
        o += MAX_TEXTURES * 2 + MAX_TEXTURES * SIZE_TMAP_INFO
        self.sound_map = list(d[o:o + MAX_SOUNDS])
        o += MAX_SOUNDS * 2                             # Sounds, AltSounds
        i32()                                           # Num_vclips
        self.vclips = []
        self.vclip_sounds = []
        for i in range(VCLIP_MAXNUM):
            play_time, nframes, frame_time, flags, snd = struct.unpack_from('<iiiih', d, o)
            frames = struct.unpack_from('<30H', d, o + 18)
            light = struct.unpack_from('<i', d, o + 78)[0]
            self.vclips.append((max(nframes, 0), fix(frame_time), frames[:max(nframes, 0)], fix(light)))
            self.vclip_sounds.append(snd)
            o += SIZE_VCLIP
        i32()
        o += MAX_EFFECTS * SIZE_ECLIP
        i32()
        o += MAX_WALL_ANIMS * SIZE_WCLIP
        i32()
        robots = o
        o += MAX_ROBOT_TYPES * SIZE_ROBOT_INFO
        if struct.unpack_from('<i', d, robots + SIZE_ROBOT_INFO - 4)[0] != 0xabcd:
            raise DescentError('robot table marker mismatch')
        i32()
        o += MAX_ROBOT_JOINTS * SIZE_JOINTPOS
        self.n_weapons = i32()
        self.weapons = [struct.unpack_from(WEAPON_FMT, d, o + i * SIZE_WEAPON_INFO)
                        for i in range(MAX_WEAPON_TYPES)]
        o += MAX_WEAPON_TYPES * SIZE_WEAPON_INFO
        i32()
        self.powerups = [struct.unpack_from('<iiii', d, o + i * SIZE_POWERUP_INFO)
                         for i in range(MAX_POWERUP_TYPES)]
        o += MAX_POWERUP_TYPES * SIZE_POWERUP_INFO
        n_models = i32()
        if not 0 < n_models <= 300:
            raise DescentError('bad polygon model count %d' % n_models)
        self.models = []
        for i in range(n_models):
            self.models.append(struct.unpack_from(POLYMODEL_FMT, d, o))
            o += SIZE_POLYMODEL
        self.model_data = []
        for m in self.models:
            self.model_data.append(d[o:o + m[1]])
            o += m[1]
        self.gauges = struct.unpack_from('<%dH' % MAX_GAUGE_BMS, d, o)
        o += MAX_GAUGE_BMS * 2
        o += MAX_POLYGON_MODELS * 4 * 2                 # Dying/Dead_modelnums
        self.obj_bitmaps = struct.unpack_from('<%dH' % MAX_OBJ_BITMAPS, d, o)
        o += MAX_OBJ_BITMAPS * 2
        self.obj_bitmap_ptrs = struct.unpack_from('<%dH' % MAX_OBJ_BITMAPS, d, o)
        o += MAX_OBJ_BITMAPS * 2
        ship = struct.unpack_from('<ii7i24i', d, o)
        o += 132
        self.ship = ship
        i32()                                           # Num_cockpits
        self.cockpits = struct.unpack_from('<4H', d, o)
        o += 8



# --------------------------------------------------------------------------
# Descent II: DESCENT2.HAM (game tables), *.PIG (bitmaps), DESCENT2.S22
# (sounds).  Layouts follow the Descent 2 source (PIGGY.C, BM.C).

BM_FLAG_RLE_BIG = 32

D2_SIZE_TMAP_INFO = 20
D2_SIZE_WCLIP = 126
D2_SIZE_ROBOT_INFO = 480
D2_WEAPON_FMT = '<bbhh' + 'bbh' + 'bbh' + 'bbh' + 'bbbb' + 'BBbbb' + 'iii' + 'H' + 'iii' + '5i5i' + '7i' + 'HH'
D2_SIZE_WEAPON_INFO = struct.calcsize(D2_WEAPON_FMT)   # 125
D2_SIZE_REACTOR = 200


class Pig2(Pig):
    def __init__(self, path, sound_path=None):
        self.data = open(path, 'rb').read()
        self.gamedata = None
        if self.data[:4] != b'PPIG':
            raise DescentError('%s is not a Descent II PIG file' % path)
        nbm = struct.unpack_from('<i', self.data, 8)[0]
        q = 12
        base = q + nbm * 18
        self.bitmaps = [None]
        self.by_name = {}
        for _ in range(nbm):
            name, dflags, w, h, whx, flags, avg, off = struct.unpack_from('<8sBBBBBBi', self.data, q)
            q += 18
            b = Bitmap()
            b.name = name.split(b'\0')[0].decode('latin-1').lower()
            if dflags & DBM_FLAG_ABM:
                b.name += '#%d' % (dflags & 63)
            b.width = w + ((whx & 0x0f) << 8)
            b.height = h + ((whx & 0xf0) << 4)
            b.flags, b.offset = flags, base + off
            self.bitmaps.append(b)
            self.by_name.setdefault(b.name, len(self.bitmaps) - 1)
        self.sounds = []
        self.sound_data = b''
        if sound_path:
            d = open(sound_path, 'rb').read()
            if d[:4] != b'DSND':
                raise DescentError('%s is not a Descent II sound file' % sound_path)
            self.sound_data = d
            n = struct.unpack_from('<i', d, 8)[0]
            q = 12
            base = q + n * 20
            for _ in range(n):
                name, length, dlen, off = struct.unpack_from('<8siii', d, q)
                q += 20
                snd = Sound()
                snd.name = name.split(b'\0')[0].decode('latin-1').lower()
                snd.length, snd.offset = length, base + off
                self.sounds.append(snd)

    def pixels(self, index):
        b = self.bitmaps[index]
        if not b.flags & BM_FLAG_RLE_BIG:
            return Pig.pixels(self, index)
        # Big RLE: 16-bit row sizes (cockpits and other wide bitmaps).
        w, h, d = b.width, b.height, self.data
        p = b.offset + 4
        sizes = struct.unpack_from('<%dH' % h, d, p)
        p += h * 2
        out = bytearray()
        for y in range(h):
            row = bytearray()
            q, end = p, p + sizes[y]
            while q < end:
                c = d[q]
                q += 1
                if (c & 0xE0) == 0xE0:
                    n = c & 0x1F
                    if n == 0:
                        break
                    row += bytes([d[q]]) * n
                    q += 1
                else:
                    row.append(c)
            row = row[:w]
            row += b'\0' * (w - len(row))
            out += row
            p = end
        return w, h, b.flags, bytes(out)

    def sound_pcm(self, s):
        return self.sound_data[s.offset:s.offset + s.length]


class GameData2:
    """DESCENT2.HAM (bm_read_all), with the fields GameData has.  Weapon
    tuples are rearranged into Descent 1's layout (see WEAPON_FMT) so the
    rest of the converter can treat both games alike."""

    def __init__(self, d):
        if d[:4] != b'HAM!':
            raise DescentError('not a Descent II HAM file')
        o = 4
        version = struct.unpack_from('<i', d, o)[0]
        o += 4
        if version < 3:
            o += 4                                      # sound offset

        def i32():
            nonlocal o
            v = struct.unpack_from('<i', d, o)[0]
            o += 4
            return v

        n = i32()                                       # textures
        o += n * 2 + n * D2_SIZE_TMAP_INFO
        n = i32()
        self.sound_map = list(d[o:o + n])
        o += n * 2
        n = i32()
        self.vclips = []
        self.vclip_sounds = []
        for i in range(n):
            play_time, nframes, frame_time, flags, snd = struct.unpack_from('<iiiih', d, o)
            frames = struct.unpack_from('<30H', d, o + 18)
            light = struct.unpack_from('<i', d, o + 78)[0]
            self.vclips.append((max(nframes, 0), fix(frame_time), frames[:max(nframes, 0)], fix(light)))
            self.vclip_sounds.append(snd)
            o += SIZE_VCLIP
        self.vclips += [(0, 0, (), 0)] * max(0, 120 - n)
        self.vclip_sounds += [-1] * max(0, 120 - n)
        n = i32()
        o += n * SIZE_ECLIP
        n = i32()
        o += n * D2_SIZE_WCLIP
        n = i32()
        if n and struct.unpack_from('<i', d, o + D2_SIZE_ROBOT_INFO - 4)[0] != 0xabcd:
            raise DescentError('robot table marker mismatch')
        o += n * D2_SIZE_ROBOT_INFO
        n = i32()
        o += n * SIZE_JOINTPOS
        self.n_weapons = i32()
        self.weapons = []
        self.weapons2 = []
        for i in range(self.n_weapons):
            w = struct.unpack_from(D2_WEAPON_FMT, d, o)
            o += D2_SIZE_WEAPON_INFO
            self.weapons2.append(w)
            # -> D1 order: render, model, inner, persistent, flash vclip,
            # flash sound, robot hit vclip/sound, wall hit vclip/sound,
            # fire count, ammo usage, weapon vclip, destroyable, matter,
            # bounce, homing, 3 x pad, energy, fire wait, bitmap, blob,
            # flash, impact sizes, strength[5], speed[5], 7 fixes, picture.
            self.weapons.append((w[0], w[2], w[3], w[1], w[4], w[6], w[5], w[9], w[7], w[12],
                                 w[8], w[10], w[11], w[13], w[14], w[15], w[16], 0, 0, 0,
                                 w[22], w[23], w[25], w[26], w[27], w[28]) + w[29:46] + (w[46],))
        n = i32()
        self.powerups = [struct.unpack_from('<iiii', d, o + i * SIZE_POWERUP_INFO) for i in range(n)]
        o += n * SIZE_POWERUP_INFO
        n = i32()
        self.models = []
        for i in range(n):
            self.models.append(struct.unpack_from(POLYMODEL_FMT, d, o))
            o += SIZE_POLYMODEL
        self.model_data = []
        for m in self.models:
            self.model_data.append(d[o:o + m[1]])
            o += m[1]
        o += n * 4 * 2                                  # Dying/Dead_modelnums
        n = i32()
        self.gauges = struct.unpack_from('<%dH' % n, d, o)
        self.gauges_hires = struct.unpack_from('<%dH' % n, d, o + n * 2)
        o += n * 4
        n = i32()
        self.obj_bitmaps = struct.unpack_from('<%dH' % n, d, o)
        self.obj_bitmap_ptrs = struct.unpack_from('<%dH' % n, d, o + n * 2)
        o += n * 4
        self.ship = struct.unpack_from('<ii7i24i', d, o)
        o += 132
        n = i32()
        self.cockpits = struct.unpack_from('<%dH' % n, d, o)
        o += n * 2
        i32()                                           # First_multi_bitmap_num
        n = i32()
        o += n * D2_SIZE_REACTOR
        i32()                                           # Marker_model_num
        self.trailing = len(d) - o                      # (extra data, unused)

# --------------------------------------------------------------------------
# PNG / WAV writers

def png(width, height, rgba, offsets=None):
    def chunk(tag, payload):
        c = struct.pack('>I', len(payload)) + tag + payload
        return c + struct.pack('>I', zlib.crc32(tag + payload) & 0xffffffff)

    raw = bytearray()
    stride = width * 4
    for y in range(height):
        raw.append(0)
        raw += rgba[y * stride:(y + 1) * stride]
    out = b'\x89PNG\r\n\x1a\n'
    out += chunk(b'IHDR', struct.pack('>IIBBBBB', width, height, 8, 6, 0, 0, 0))
    if offsets is not None:
        # grAb: ZDoom's sprite/graphic offset chunk.
        out += chunk(b'grAb', struct.pack('>ii', offsets[0], offsets[1]))
    out += chunk(b'IDAT', zlib.compress(bytes(raw), 9))
    out += chunk(b'IEND', b'')
    return out


def read_png(data):
    """Minimal PNG reader (8-bit, non-interlaced) -> (width, height, RGBA)."""
    if data[:8] != b'\x89PNG\r\n\x1a\n':
        raise ValueError('not a PNG file')
    o = 8
    idat = b''
    plte = trns = None
    while o < len(data):
        n, tag = struct.unpack_from('>I4s', data, o)
        body = data[o + 8:o + 8 + n]
        o += 12 + n
        if tag == b'IHDR':
            w, h, depth, ctype, _, _, interlace = struct.unpack('>IIBBBBB', body)
        elif tag == b'PLTE':
            plte = body
        elif tag == b'tRNS':
            trns = body
        elif tag == b'IDAT':
            idat += body
        elif tag == b'IEND':
            break
    if depth != 8 or interlace:
        raise ValueError('only 8-bit, non-interlaced PNGs are supported')
    bpp = {0: 1, 2: 3, 3: 1, 4: 2, 6: 4}[ctype]
    raw = zlib.decompress(idat)
    stride = w * bpp
    prev = bytearray(stride)
    rgba = bytearray(w * h * 4)
    p = 0
    for y in range(h):
        ft = raw[p]
        line = bytearray(raw[p + 1:p + 1 + stride])
        p += 1 + stride
        for i in range(stride):
            a = line[i - bpp] if i >= bpp else 0
            b = prev[i]
            if ft == 1:
                line[i] = (line[i] + a) & 255
            elif ft == 2:
                line[i] = (line[i] + b) & 255
            elif ft == 3:
                line[i] = (line[i] + ((a + b) >> 1)) & 255
            elif ft == 4:
                c = prev[i - bpp] if i >= bpp else 0
                pa, pb, pc = abs(b - c), abs(a - c), abs(a + b - 2 * c)
                line[i] = (line[i] + (a if pa <= pb and pa <= pc else b if pb <= pc else c)) & 255
        prev = line
        for x in range(w):
            q = (y * w + x) * 4
            v = line[x * bpp:x * bpp + bpp]
            if ctype == 6:
                rgba[q:q + 4] = v
            elif ctype == 2:
                rgba[q:q + 4] = bytes(v) + b'\xff'
            elif ctype == 0:
                rgba[q:q + 4] = bytes((v[0], v[0], v[0], 255))
            elif ctype == 4:
                rgba[q:q + 4] = bytes((v[0], v[0], v[0], v[1]))
            else:
                k = v[0]
                al = trns[k] if trns and k < len(trns) else 255
                rgba[q:q + 4] = plte[k * 3:k * 3 + 3] + bytes((al,))
    return w, h, rgba


def fit_image(w, h, rgba, target_h):
    """Crop to the opaque area and box-filter down to target_h pixels tall."""
    xs = [x for x in range(w) if any(rgba[(y * w + x) * 4 + 3] > 16 for y in range(0, h, max(1, h // 128)))]
    ys = [y for y in range(h) if any(rgba[(y * w + x) * 4 + 3] > 16 for x in range(0, w, max(1, w // 128)))]
    if not xs or not ys:
        raise ValueError('the image is fully transparent')
    x0, x1, y0, y1 = xs[0], xs[-1] + 1, ys[0], ys[-1] + 1
    k = (y1 - y0) / float(target_h)
    nw = max(1, int(round((x1 - x0) / k)))
    out = bytearray(nw * target_h * 4)
    for ty in range(target_h):
        sy0, sy1 = y0 + int(ty * k), max(y0 + int(ty * k) + 1, y0 + int((ty + 1) * k))
        for tx in range(nw):
            sx0, sx1 = x0 + int(tx * k), max(x0 + int(tx * k) + 1, x0 + int((tx + 1) * k))
            r = g = b = a = n = 0
            for sy in range(sy0, min(sy1, h)):
                for sx in range(sx0, min(sx1, w)):
                    q = (sy * w + sx) * 4
                    al = rgba[q + 3]
                    r += rgba[q] * al
                    g += rgba[q + 1] * al
                    b += rgba[q + 2] * al
                    a += al
                    n += 1
            q = (ty * nw + tx) * 4
            if a and a >= n * 64:   # mostly opaque: keep, with hard edges
                out[q:q + 4] = bytes((r // a, g // a, b // a, 255))
    return nw, target_h, out


def default_face(size=64):
    """A simple cartoon face for Ick Mode when data/ickface.png is absent."""
    out = bytearray(size * size * 4)
    c = size / 2.0

    def put(x, y, col):
        q = (y * size + x) * 4
        out[q:q + 4] = bytes(col) + b'\xff'

    for y in range(size):
        for x in range(size):
            u, v = (x + 0.5 - c) / (c * 0.86), (y + 0.5 - c * 1.04) / (c * 0.96)
            if u * u + v * v > 1:
                continue
            shade = 1.0 - 0.25 * max(0.0, u)
            put(x, y, [int(ch * shade) for ch in (120, 200, 90)])
            if v < -0.35:                                   # beanie
                put(x, y, [int(ch * shade) for ch in (60, 40, 90)])
            for ex in (-0.38, 0.38):                        # eyes
                du, dv = u - ex, v + 0.05
                if du * du + dv * dv < 0.045:
                    put(x, y, (240, 240, 240))
                if (du - 0.04) ** 2 + (dv - 0.03) ** 2 < 0.012:
                    put(x, y, (20, 20, 20))
            for ex in (-0.38, 0.38):                        # black-framed glasses
                du, dv = abs(u - ex), abs(v + 0.05)
                if du < 0.28 and dv < 0.26 and (du > 0.21 or dv > 0.19):
                    put(x, y, (15, 15, 15))
            if abs(u) < 0.12 and abs(v + 0.1) < 0.04:       # bridge
                put(x, y, (15, 15, 15))
            if abs(u) > 0.64 and abs(v + 0.1) < 0.04:       # arms
                put(x, y, (15, 15, 15))
            du, dv = u / 0.28, (v - 0.5) / 0.2              # open mouth
            if du * du + dv * dv < 1:
                put(x, y, (90, 20, 30))
    return size, size, out


def wav(pcm, rate=11025):
    hdr = b'RIFF' + struct.pack('<I', 36 + len(pcm)) + b'WAVE'
    hdr += b'fmt ' + struct.pack('<IHHIIHH', 16, 1, 1, rate, rate, 1, 8)
    hdr += b'data' + struct.pack('<I', len(pcm))
    return hdr + pcm


# --------------------------------------------------------------------------

def interp_faces(data):
    """Walk Descent's polygon model interpreter data (INTERP.ASM).  Returns
    (faces, colors): faces are (kind, material, [(x, y, z)], uvs or None),
    kind 'c' for a flat colour (material indexes colors) or 't' for a
    textured face (material is the model's texture number)."""
    points = {}
    faces = []          # (material, [(x,y,z)], [(u,v)])
    colors = []

    def walk(p, ofs):
        while True:
            op = struct.unpack_from('<H', data, p)[0]
            if op == 0:
                return
            if op == 1:
                n = struct.unpack_from('<H', data, p + 2)[0]
                for i in range(n):
                    v = struct.unpack_from('<3i', data, p + 4 + i * 12)
                    points[i] = tuple(fix(v[k]) + ofs[k] for k in range(3))
                p += 4 + n * 12
            elif op == 7:
                n, start = struct.unpack_from('<HH', data, p + 2)
                for i in range(n):
                    v = struct.unpack_from('<3i', data, p + 8 + i * 12)
                    points[start + i] = tuple(fix(v[k]) + ofs[k] for k in range(3))
                p += 8 + n * 12
            elif op == 2:
                n = struct.unpack_from('<H', data, p + 2)[0]
                color = struct.unpack_from('<H', data, p + 28)[0]
                idx = struct.unpack_from('<%dH' % n, data, p + 30)
                if color not in colors:
                    colors.append(color)
                faces.append(('c', colors.index(color), [points[i] for i in idx], None))
                p += 30 + ((n & ~1) + 1) * 2
            elif op == 3:
                n = struct.unpack_from('<H', data, p + 2)[0]
                bm = struct.unpack_from('<H', data, p + 28)[0]
                idx = struct.unpack_from('<%dH' % n, data, p + 30)
                uvp = p + 30 + ((n & ~1) + 1) * 2
                uvs = [struct.unpack_from('<3i', data, uvp + i * 12)[:2] for i in range(n)]
                faces.append(('t', bm, [points[i] for i in idx], [(fix(u), fix(v)) for u, v in uvs]))
                p = uvp + n * 12
            elif op == 4:
                front, back = struct.unpack_from('<HH', data, p + 28)
                walk(p + front, ofs)
                walk(p + back, ofs)
                p += 32
            elif op == 5:
                p += 36
            elif op == 6:
                pos = struct.unpack_from('<3i', data, p + 4)
                sub = struct.unpack_from('<H', data, p + 16)[0]
                walk(p + sub, tuple(ofs[k] + fix(pos[k]) for k in range(3)))
                p += 20
            elif op == 8:
                p += 4
            else:
                raise DescentError('unknown model opcode %d' % op)

    walk(0, (0.0, 0.0, 0.0))
    return faces, colors
