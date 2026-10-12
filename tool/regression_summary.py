"""Summarize complementary regression markers separately from frame budgets."""
import argparse
import json
from pathlib import Path
import statistics

parser = argparse.ArgumentParser()
parser.add_argument('--fixture', type=int, choices=[20, 100], default=100)
args = parser.parse_args()
suffix = '20' if args.fixture == 20 else ''
output = {}
for variant in ('baseline', 'candidate'):
    raw = json.loads(Path('artifacts/performance/regression-' + variant + suffix + '-raw.json').read_text(encoding='utf-8'))
    results = raw['results']
    summary = {'detail': {}, 'traversals': [r for r in results if r['kind'] == 'full-F' + str(args.fixture) + '-traversal'], 'adminCycles': len([r for r in results if r['kind'] == 'admin-cycle']), 'failures': [r for r in results if r['kind'] == 'failure'], 'functional': [r for r in results if r['kind'] == 'functional-summary']}
    for label in ('normal', 'reduced-motion'):
        for kind, field in (('detail-usable', 'openPostFrameMs'), ('detail-return-usable', 'returnPostFrameMs')):
            values = [r[field] for r in results if r['kind'] == kind and r['label'] == label]
            summary['detail'][label + '.' + kind] = {'n': len(values), 'medianMs': statistics.median(values) if values else None, 'maxMs': max(values) if values else None}
    output[variant] = summary
for key in output['baseline']['detail']:
    before = output['baseline']['detail'][key]['medianMs']
    after = output['candidate']['detail'][key]['medianMs']
    if before and after:
        output['candidate']['detail'][key]['medianChangePercent'] = (after / before - 1) * 100
Path('artifacts/performance/regression' + suffix + '-summary.json').write_text(json.dumps(output, indent=2, ensure_ascii=False), encoding='utf-8')
print(json.dumps(output, indent=2, ensure_ascii=True))
