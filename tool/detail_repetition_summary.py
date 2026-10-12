"""Retain both repetitions and describe all samples without selecting a run."""
import json
from pathlib import Path
import statistics

report = {}
for variant in ('baseline', 'candidate'):
    runs = [json.loads(Path('artifacts/performance/regression-' + variant + '20-run' + str(i) + '.json').read_text(encoding='utf-8')) for i in (1, 2)]
    report[variant] = {}
    for label in ('normal', 'reduced-motion'):
        for kind, field in (('detail-usable', 'openPostFrameMs'), ('detail-return-usable', 'returnPostFrameMs')):
            samples = [[r[field] for r in run['results'] if r['kind'] == kind and r['label'] == label] for run in runs]
            values = samples[0] + samples[1]
            report[variant][label + '.' + kind] = {'perRunSamplesMs': samples, 'n': len(values), 'pooledMedianMs': statistics.median(values), 'maxMs': max(values)}
for key in report['baseline']:
    before = report['baseline'][key]['pooledMedianMs']
    after = report['candidate'][key]['pooledMedianMs']
    report['candidate'][key]['pooledMedianChangePercent'] = (after / before - 1) * 100
Path('artifacts/performance/detail-f20-repetitions.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
print(json.dumps({v: {k: {x: y for x, y in s.items() if x != 'perRunSamplesMs'} for k, s in d.items()} for v, d in report.items()}, indent=2))
