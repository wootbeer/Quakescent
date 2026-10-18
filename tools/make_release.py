#!/usr/bin/env python3
"""Assemble the end-user release zip.

    python tools/make_release.py [--exe path/to/qsconvert.exe] [--fteqcc PATH] [-o dist]

The zip is ready to play from once the player adds their game files: the
launchers, the built mod (quakescent/), the converter, README, licences and
empty id1/ and data/ folders.  The mod's source (GPL) goes in src/.  It
never contains game data or FTEQW.
"""
import argparse
import os
import subprocess
import sys
import zipfile

root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--exe', help='standalone qsconvert.exe to include')
    ap.add_argument('--fteqcc', help='fteqcc to build with (default: see build.py)')
    ap.add_argument('-o', '--outdir', default=os.path.join(root, 'dist'))
    args = ap.parse_args()

    version = open(os.path.join(root, 'VERSION')).read().strip()
    os.makedirs(args.outdir, exist_ok=True)
    game = os.path.join(args.outdir, 'quakescent')
    cmd = [sys.executable, os.path.join(root, 'tools', 'build.py'), '--out', game]
    if args.fteqcc:
        cmd += ['--fteqcc', args.fteqcc]
    subprocess.check_call(cmd)

    name = 'Quakescent-%s' % version
    out = os.path.join(args.outdir, name + '.zip')
    files = {
        'Quakescent.bat': 'Quakescent.bat',
        'quakescent.sh': 'quakescent.sh',
        'README.md': 'README.md',
        'LICENSE': 'LICENSE',
        'CHANGELOG.md': 'CHANGELOG.md',
        'id1/README.txt': 'id1/README.txt',
        'data/README.txt': 'data/README.txt',
        'quakescent/README.txt': 'quakescent/README.txt',
        'tools/launcher.ps1': 'tools/launcher.ps1',
        'tools/qsconvert.py': 'tools/qsconvert.py',
        'tools/descent_data.py': 'tools/descent_data.py',
        'tools/LICENSE': 'tools/LICENSE',
        'tools/ickface.png': 'tools/ickface.png',
    }
    with zipfile.ZipFile(out, 'w', zipfile.ZIP_DEFLATED) as z:
        for arc, rel in files.items():
            info = zipfile.ZipInfo.from_file(os.path.join(root, rel), name + '/' + arc)
            if arc.endswith('.sh'):
                info.external_attr = 0o100755 << 16
            with open(os.path.join(root, rel), 'rb') as f:
                z.writestr(info, f.read(), zipfile.ZIP_DEFLATED)
        for f in ('progs.dat', 'csprogs.dat'):
            z.write(os.path.join(game, f), name + '/quakescent/' + f)
        for d, _, fs in os.walk(os.path.join(root, 'mod')):
            for f in fs:
                rel = os.path.relpath(os.path.join(d, f), os.path.join(root, 'mod'))
                z.write(os.path.join(d, f), name + '/quakescent/' + rel.replace(os.sep, '/'))
        for top in ('qc', 'csqc', 'mod'):
            for d, _, fs in os.walk(os.path.join(root, top)):
                for f in sorted(fs):
                    rel = os.path.relpath(os.path.join(d, f), root).replace(os.sep, '/')
                    z.write(os.path.join(d, f), '%s/src/%s' % (name, rel))
        z.write(os.path.join(root, 'tools', 'build.py'), name + '/src/tools/build.py')
        if args.exe:
            z.write(args.exe, name + '/tools/qsconvert.exe')
    print('wrote', out)


if __name__ == '__main__':
    main()
