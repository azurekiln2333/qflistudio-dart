import re
import sys
import pathlib

root = pathlib.Path('.')
chapter = sys.argv[1]
ids = set(sys.argv[2:])
path = root / 'curriculum' / 'chapters' / f'{chapter}.dart'
s = path.read_text(encoding='utf-8')
idx = [(m.start(), m.group(1)) for m in re.finditer(r"id: '(dart-lesson-\d+)'", s)]
for i, (pos, lid) in enumerate(idx):
    if lid in ids:
        end = idx[i + 1][0] if i + 1 < len(idx) else len(s)
        print('=' * 30, lid)
        print(s[pos:end].rstrip().rstrip(','))
        print()
