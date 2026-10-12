"""Summarize raw profile FrameTiming records without combining pipeline stages."""
import argparse
import json
import math
from pathlib import Path


def percentile(values, p):
    values = sorted(values)
    return values[max(0, math.ceil(len(values) * p) - 1)] if values else None


def frame_stats(frames, budget):
    build = [f['buildUs'] / 1000 for f in frames]
    raster = [f['rasterUs'] / 1000 for f in frames]
    over = sum(b > budget or r > budget for b, r in zip(build, raster))
    return {
        'frames': len(frames),
        'build_ms': {str(p): percentile(build, p) for p in (.5, .95, .99)},
        'raster_ms': {str(p): percentile(raster, p) for p in (.5, .95, .99)},
        'over_budget_count': over,
        'over_budget_percent': over * 100 / len(frames) if frames else None,
    }


def summarize(path, hz):
    data = json.loads(path.read_text(encoding='utf-8'))
    windows = data['windows']
    frames = data['frames']
    grouped = {}
    for window in windows:
        samples = [f for f in frames if window['startUs'] <= f['startUs'] < window['endUs']]
        grouped[window['name']] = {
            'duration_ms': (window['endUs'] - window['startUs']) / 1000,
            **frame_stats(samples, 1000 / hz),
        }
    routes = {}
    for route in ('detail', 'selection'):
        for direction in ('push', 'pop'):
            spans = [w for w in windows if w['name'].startswith(route + '-') and w['name'].endswith('.' + direction)]
            samples = [f for f in frames if any(w['startUs'] <= f['startUs'] < w['endUs'] for w in spans)]
            routes[route + '.' + direction] = {'cycles': len(spans), **frame_stats(samples, 1000 / hz)}
    latency = {}
    for kind in ('search', 'selection'):
        values = [r['latencyMs'] for r in data['results'] if r['kind'] == kind]
        latency[kind] = {'n': len(values), 'p50_ms': percentile(values, .5), 'p95_ms': percentile(values, .95), 'max_ms': max(values) if values else None}
    return {
        'source': str(path), 'variant': data['variant'], 'hz': hz,
        'budget_ms': 1000 / hz, 'windows': grouped, 'routes': routes,
        'latency': latency,
        'memory': [r for r in data['results'] if r['kind'] == 'memory'],
        'startup': [r for r in data['results'] if r['kind'] == 'startup'],
        'decode_probes': [r for r in data['results'] if r['kind'].startswith('decode-probe')],
        'observed_hz_at_callback': sorted({f.get('observedHzAtCallback', f.get('displayHz')) for f in frames if f.get('observedHzAtCallback', f.get('displayHz')) is not None}),
        'failures': [r for r in data['results'] if r['kind'] == 'failure'],
        'limitations': data['limitations'],
    }


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('input', type=Path)
    parser.add_argument('--hz', type=float, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    result = summarize(args.input, args.hz)
    args.output.write_text(json.dumps(result, indent=2, ensure_ascii=False), encoding='utf-8')
    print(json.dumps({k: result[k] for k in ('variant', 'latency', 'routes', 'failures')}, indent=2))
