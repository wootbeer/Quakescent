#!/bin/sh
# Quakescent launcher for Linux.
# Needs Python 3.  Put Quake's pak0.pak (and pak1.pak) in ./id1/ and
# DESCENT.HOG / DESCENT.PIG in ./data/.  FTEQW is downloaded into ./fte/ on
# the first run unless FTEQW=/path/to/fteqw64 is set.  Arguments go to FTEQW
# (e.g. ./quakescent.sh +map e1m1 +skill 2).
set -e
ROOT=$(cd "$(dirname "$0")" && pwd)
FTE_VERSION=2026-07-13
FTE_URL="https://fastdl.idtech.space/bin/fteqw-linux-x86_64-$FTE_VERSION.zip"
fail() { echo "$*" >&2; exit 1; }

# FTEQW
FTE=${FTEQW:-"$ROOT/fte/fteqw64"}
if [ ! -x "$FTE" ]; then
	echo "FTEQW was not found in $ROOT/fte/; downloading FTEQW $FTE_VERSION from fteqw.org..."
	python3 - "$FTE_URL" "$ROOT/fte" <<'EOF'
import io, os, stat, sys, urllib.request, zipfile
url, dest = sys.argv[1:3]
z = zipfile.ZipFile(io.BytesIO(urllib.request.urlopen(url).read()))
os.makedirs(dest, exist_ok=True)
for info in z.infolist():
    name = os.path.basename(info.filename)
    if not name or info.is_dir():
        continue
    path = os.path.join(dest, name)
    with open(path, 'wb') as f:
        f.write(z.read(info))
    if '.' not in name or name.endswith('.so'):
        os.chmod(path, os.stat(path).st_mode | stat.S_IEXEC)
EOF
	[ -x "$FTE" ] || fail "fteqw64 wasn't in the download; get FTEQW from https://www.fteqw.org/ and set FTEQW."
fi

# From a source checkout, rebuild the mod when its source has changed.
if [ -d "$ROOT/qc" ]; then
	if [ ! -f "$ROOT/quakescent/progs.dat" ] || \
	   [ -n "$(find "$ROOT/qc" "$ROOT/csqc" "$ROOT/mod" -newer "$ROOT/quakescent/progs.dat" -type f | head -n 1)" ]; then
		python3 "$ROOT/tools/build.py"
	fi
fi
[ -f "$ROOT/quakescent/progs.dat" ] || fail "quakescent/progs.dat is missing; re-download the release."

# Quake's paks: FTE wants them lower case.
for f in "$ROOT"/id1/*.[Pp][Aa][Kk]; do
	[ -e "$f" ] || continue
	lower=$(basename "$f" | tr 'A-Z' 'a-z')
	[ "$(basename "$f")" = "$lower" ] || [ -e "$ROOT/id1/$lower" ] || ln -s "$(basename "$f")" "$ROOT/id1/$lower"
done
[ -f "$ROOT/id1/pak0.pak" ] || fail "Copy pak0.pak (and pak1.pak) from your Quake's id1 folder into $ROOT/id1/ (for the 2021 re-release: rerelease/id1/pak0.pak)."

# Descent's data.
ASSETS="$ROOT/quakescent/qs_descent_assets.pk3"
if [ ! -f "$ASSETS" ] || [ "$ROOT/tools/qsconvert.py" -nt "$ASSETS" ]; then
	has() { ls "$ROOT/data" 2>/dev/null | grep -qix "$1"; }
	if ! has descent.hog || ! has descent.pig; then
		fail "Copy DESCENT.HOG and DESCENT.PIG from your copy of Descent 1 into $ROOT/data/ and run this again."
	fi
	echo "Converting your Descent data..."
	python3 "$ROOT/tools/qsconvert.py" "$ROOT/data" -o "$ASSETS"
fi

# Answer FTE's first-run question about its online package source with
# "no" (it can be switched on from the Updates menu).
if [ ! -f "$ROOT/installed.lst" ]; then
	printf 'version 2\nsource "https://fte.triptohell.info/downloadables.php?game=Q1" "disabled"\n' > "$ROOT/installed.lst"
fi

exec "$FTE" -basedir "$ROOT" -nohome -game quakescent "$@"
