#!/usr/bin/env python3
"""
build.py - compile Quakescent's QuakeC and assemble the mod folder.

    python tools/build.py [--fteqcc PATH] [--out quakescent]

Compiles qc/progs.src (progs.dat, the server side) and csqc/csprogs.src
(csprogs.dat, the cockpit and the client side of the ship) with FTE's QuakeC
compiler, and copies mod/ next to them, in quakescent/ (the game directory FTEQW
loads with -game quakescent; the launchers run this when the source has
changed).

fteqcc is looked for in --fteqcc, the FTEQCC environment variable, tools/,
and the PATH; if it isn't found the official build is downloaded into
tools/ (Windows and Linux x86_64).
"""

import argparse
import io
import os
import platform
import shutil
import stat
import subprocess
import sys
import urllib.request
import zipfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FTEQCC_VERSION = '2026-07-13'
FTEQCC_URL = 'https://fastdl.idtech.space/bin/fteqcc-%s-%s.zip'


def fteqcc_names():
    if os.name == 'nt':
        return ['fteqcc64.exe', 'fteqcc.exe']
    return ['fteqcc64', 'fteqcc', 'fteqcc.bin']


def find_fteqcc(explicit):
    if explicit:
        return explicit
    if os.environ.get('FTEQCC'):
        return os.environ['FTEQCC']
    for name in fteqcc_names():
        p = os.path.join(ROOT, 'tools', name)
        if os.path.exists(p):
            return p
        p = shutil.which(name)
        if p:
            return p
    return download_fteqcc()


def download_fteqcc():
    machine = platform.machine().lower()
    if os.name == 'nt':
        target = 'win-x86_64'
    elif sys.platform.startswith('linux') and machine in ('x86_64', 'amd64'):
        target = 'linux-x86_64'
    else:
        sys.exit('error: fteqcc not found; install it (https://www.fteqcc.org/) and pass --fteqcc')
    url = FTEQCC_URL % (target, FTEQCC_VERSION)
    print('downloading %s' % url)
    data = urllib.request.urlopen(url).read()
    with zipfile.ZipFile(io.BytesIO(data)) as z:
        for info in z.infolist():
            base = os.path.basename(info.filename)
            if base.lower().startswith('fteqcc') and not base.endswith(('.txt', '.db')):
                dest = os.path.join(ROOT, 'tools', base)
                with open(dest, 'wb') as f:
                    f.write(z.read(info))
                os.chmod(dest, os.stat(dest).st_mode | stat.S_IEXEC)
                if base in fteqcc_names():
                    return dest
    sys.exit('error: no fteqcc in %s' % url)


def compile_progs(fteqcc, srcdir, srcfile, out):
    # The .src files name ../build/quakescent/...; compile there, then move
    # the result if another output folder was asked for.
    r = subprocess.run([fteqcc, '-srcfile', srcfile], cwd=os.path.join(ROOT, srcdir),
                       stdout=subprocess.PIPE, stderr=subprocess.STDOUT, universal_newlines=True)
    errors = [ln for ln in r.stdout.splitlines() if ' error' in ln.lower() or 'werror' in ln.lower()]
    if r.returncode != 0 or errors:
        print(r.stdout)
        sys.exit('error: compiling %s/%s failed' % (srcdir, srcfile))
    print('compiled %s' % out)
    return os.path.join(ROOT, 'build', 'quakescent', out)


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    ap.add_argument('--fteqcc')
    ap.add_argument('--out', default=os.path.join(ROOT, 'quakescent'))
    args = ap.parse_args(argv)

    fteqcc = find_fteqcc(args.fteqcc)
    os.makedirs(os.path.join(ROOT, 'build', 'quakescent'), exist_ok=True)
    progs = compile_progs(fteqcc, 'qc', 'progs.src', 'progs.dat')
    csprogs = compile_progs(fteqcc, 'csqc', 'csprogs.src', 'csprogs.dat')

    out = os.path.abspath(args.out)
    os.makedirs(out, exist_ok=True)
    for p in (progs, csprogs):
        if os.path.dirname(p) != out:
            shutil.copy2(p, out)
    shutil.copytree(os.path.join(ROOT, 'mod'), out, dirs_exist_ok=True)
    # Line-number files are only for debugging.
    for f in ('progs.lno', 'csprogs.lno'):
        p = os.path.join(ROOT, 'build', 'quakescent', f)
        if os.path.exists(p):
            os.remove(p)
    print('mod folder: %s' % os.path.relpath(out, ROOT))


if __name__ == '__main__':
    main()
