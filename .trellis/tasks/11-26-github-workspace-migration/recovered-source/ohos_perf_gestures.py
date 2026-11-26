import datetime
import json
import pathlib
import subprocess
import sys

hdc = r'D:\ProgramFiles\Huawei\OpenHarmony\Sdk\23\toolchains\hdc.exe'
prefix = [hdc, '-t', '192.168.68.207:46551', 'shell', 'uitest', 'uiInput']
records = []


def action(label, *args):
    started = datetime.datetime.now().isoformat()
    result = subprocess.run(prefix + list(map(str, args)), capture_output=True, text=True)
    output = result.stdout + result.stderr
    if result.returncode or '[Fail]' in output or 'Error Code:' in output:
        raise RuntimeError(label + ': ' + output)
    records.append({'action': label, 'started': started,
                    'finished': datetime.datetime.now().isoformat(),
                    'output': output.strip()})


for label, x in [('examples', 890), ('tutorials', 636)]:
    action(label, 'click', x, 2600)
    for index in range(6):
        y0, y1 = (2100, 750) if index % 2 == 0 else (750, 2100)
        action(f'{label}_scroll_{index}', 'swipe', 1180, y0, 1180, y1, 1400)

output_path = pathlib.Path(sys.argv[1])
output_path.write_text(json.dumps(records, ensure_ascii=False, indent=2), encoding='utf-8')
print('Captured', len(records), 'page/scroll operations')
