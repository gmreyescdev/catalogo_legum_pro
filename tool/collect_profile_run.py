"""Launch an isolated benchmark and copy its completed private JSON."""
import argparse
import json
import os
from pathlib import Path
import subprocess
import time

parser = argparse.ArgumentParser()
parser.add_argument('--variant', required=True)
parser.add_argument('--hz', type=int, choices=[60, 120], required=True)
parser.add_argument('--regression', action='store_true')
args = parser.parse_args()
artifact_variant = ('regression-' if args.regression else '') + args.variant
adb = str(Path(os.environ['LOCALAPPDATA']) / 'Android/Sdk/platform-tools/adb.exe')
package = 'com.example.catalogo_legum_pro.integration'

def run(*commands):
    return subprocess.check_output([adb, *commands], text=True, encoding='utf-8', errors='replace')

run('shell', 'am', 'force-stop', package)
run('shell', 'am', 'start', '-n', package + '/com.example.catalogo_legum_pro.MainActivity', '--ei', 'PERF_DISPLAY_HZ', str(args.hz))
deadline = time.monotonic() + 480
environment = []
next_state = 0
last_progress = ''
while time.monotonic() < deadline:
    try:
        pid = run('shell', 'pidof', package).strip()
    except subprocess.CalledProcessError:
        time.sleep(.5)
        continue
    logs = run('logcat', '-d', '--pid=' + pid, '-s', 'flutter')
    lines = [line for line in logs.splitlines() if 'PERF_JSON:' in line]
    if lines and lines[-1] != last_progress:
        last_progress = lines[-1]
        print(last_progress, flush=True)
    if time.monotonic() >= next_state:
        display = run('shell', 'dumpsys', 'display')
        thermal = run('shell', 'dumpsys', 'thermalservice')
        environment.append({'elapsedSeconds': 480 - (deadline - time.monotonic()), 'display': display, 'thermal': thermal})
        next_state = time.monotonic() + 30
    if 'PERF_DONE:' in logs and 'PERF_INTERNAL_SAVED:' in logs:
        saved = [line.split('PERF_INTERNAL_SAVED: ', 1)[1].strip() for line in logs.splitlines() if 'PERF_INTERNAL_SAVED: ' in line][-1]
        private_path = ('files/' if args.regression else 'app_flutter/performance-fixture-v1/') + saved.rsplit('/', 1)[-1]
        raw = subprocess.check_output([adb, 'exec-out', 'run-as', package, 'cat', private_path])
        data = json.loads(raw)
        if data['variant'] != args.variant:
            raise RuntimeError('Wrong variant')
        Path('artifacts/performance/' + artifact_variant + '-raw.json').write_bytes(raw)
        Path('artifacts/performance/' + artifact_variant + '-log.txt').write_text(logs, encoding='utf-8')
        Path('artifacts/performance/' + artifact_variant + '-environment.json').write_text(json.dumps(environment, indent=2), encoding='utf-8')
        print(json.dumps({'completed': args.variant, 'frames': len(data.get('frames', [])), 'failures': [r for r in data['results'] if r['kind'] == 'failure']}), flush=True)
        break
    time.sleep(5)
else:
    raise RuntimeError('Benchmark did not finish')
