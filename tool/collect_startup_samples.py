"""Collect isolated profile startup logs; never clears application data."""
import argparse
import json
import os
from pathlib import Path
import statistics
import subprocess
import time

parser = argparse.ArgumentParser()
parser.add_argument('--variant', required=True)
args = parser.parse_args()
adb = str(Path(os.environ['LOCALAPPDATA']) / 'Android/Sdk/platform-tools/adb.exe')
package = 'com.example.catalogo_legum_pro.integration'
activity = package + '/com.example.catalogo_legum_pro.MainActivity'

def run(*commands):
    return subprocess.check_output([adb, *commands], text=True, encoding='utf-8', errors='replace')

samples = []
excluded = []
for attempt in range(7):
    run('shell', 'am', 'force-stop', package)
    run('shell', 'am', 'start', '-W', '-n', activity)
    deadline = time.monotonic() + 50
    result = None
    while time.monotonic() < deadline:
        pid = run('shell', 'pidof', package).strip()
        logs = run('logcat', '-d', '--pid=' + pid, '-s', 'flutter')
        for line in logs.splitlines():
            if 'PERF_JSON: ' in line and 'production-startup' in line:
                result = json.loads(line.split('PERF_JSON: ', 1)[1])
        if result is not None and 'PERF_DONE: startup-' in logs:
            break
        time.sleep(.5)
    if result is None:
        raise RuntimeError('No startup result within deadline')
    if result['variant'] != args.variant or not result['profile']:
        raise RuntimeError('Unexpected build')
    (excluded if result['excludeFromStartupComparison'] else samples).append(result)
    print(json.dumps({'variant': args.variant, 'sample': len(samples), 'excluded': result['excludeFromStartupComparison'], 'mainToCatalogMs': result['dartMainToCatalogUsableMs']}), flush=True)
    if len(samples) == 5:
        break
    time.sleep(2)
if len(samples) != 5:
    raise RuntimeError('Insufficient valid samples')
output = {'samples': samples, 'excluded': excluded, 'medianMainToCatalogMs': statistics.median(s['dartMainToCatalogUsableMs'] for s in samples), 'medianBootstrapMs': statistics.median(s['realBootstrapMs'] for s in samples)}
Path('artifacts/performance/startup-' + args.variant + '.json').write_text(json.dumps(output, indent=2), encoding='utf-8')
print(json.dumps({k: v for k, v in output.items() if k.startswith('median')}), flush=True)
