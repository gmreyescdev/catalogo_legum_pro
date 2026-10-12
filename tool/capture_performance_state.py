"""Read only the completed isolated harness records through the Dart VM service.

Fallback for Android builds that deny ADB access to app external storage.
Run after PERF_DONE; inspection overhead must not overlap measured windows.
"""
import argparse
import concurrent.futures
import json
import urllib.parse
import urllib.request
from pathlib import Path


parser = argparse.ArgumentParser()
parser.add_argument('--service-url', required=True)
parser.add_argument('--variant', required=True)
parser.add_argument('--output', type=Path, required=True)
args = parser.parse_args()


def rpc(method, **params):
    url = args.service_url.rstrip('/') + '/' + method + '?' + urllib.parse.urlencode(params)
    with urllib.request.urlopen(url, timeout=30) as response:
        data = json.load(response)
    if 'error' in data:
        raise RuntimeError(str(data['error']))
    return data['result']


isolate = rpc('getVM')['isolates'][0]['id']
state_class = next(c for c in rpc('getClassList', isolateId=isolate)['classes']
                   if c.get('name') == '_PerformanceAppState')


def state_field(name):
    instance = rpc('getInstances', isolateId=isolate, objectId=state_class['id'], limit=1)['instances'][0]
    state = rpc('getObject', isolateId=isolate, objectId=instance['id'])
    return next(f['value'] for f in state['fields'] if f['decl']['name'] == name)


def decode(ref):
    kind = ref.get('kind')
    if kind == 'Null':
        return None
    if kind in ('Int', 'Double', 'Bool'):
        return json.loads(ref['valueAsString'])
    if kind == 'String' and not ref.get('valueAsStringIsTruncated'):
        return ref['valueAsString']
    obj = rpc('getObject', isolateId=isolate, objectId=ref['id'])
    if obj.get('kind') == 'Map':
        entries = obj.get('entries', obj.get('associations', []))
        return {decode(e['key']): decode(e['value']) for e in entries}
    if obj.get('kind') == 'List':
        return [decode(e) for e in obj['elements']]
    if obj.get('kind') == 'String':
        return obj['valueAsString']
    raise RuntimeError('Unexpected harness record kind: ' + str(obj.get('kind')))


data = {'variant': args.variant, 'retrieval': 'VM service after PERF_DONE; no evaluation or app mutation'}
with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
    for name in ('results', 'windows', 'frames'):
        count = state_field(name)['length']
        records = []
        for offset in range(0, count, 100):
            ref = state_field(name)  # Refresh temporary object IDs before each page.
            chunk = rpc('getObject', isolateId=isolate, objectId=ref['id'], offset=offset, count=min(100, count-offset))
            records.extend(pool.map(decode, chunk['elements']))
        data[name] = records
        print(name, len(records), flush=True)
data['limitations'] = [
    'In-memory repository; SQL/bootstrap/native process startup not measured',
    'Harness calls route widgets, not gesture hit-testing; admin/reduced motion require separate validation',
    'Input latency ends at post-frame, not physical display presentation',
    'Stress scroll is a subset of 100 products; background interruption during fixture preparation',
    'Observed Hz at timing callback is not a per-frame VSYNC trace',
    'RSS is not PSS; VM inspection occurred only after all measured windows ended',
]
args.output.write_text(json.dumps(data), encoding='utf-8')
