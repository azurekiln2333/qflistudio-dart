import re
import pathlib
import sys

root = pathlib.Path('curriculum/chapters')
want = set(sys.argv[1:])
for path in sorted(root.glob('*.dart')):
    s = path.read_text(encoding='utf-8')
    idx = [(m.start(), m.group(1)) for m in re.finditer(r"id: '(dart-lesson-\d+)'", s)]
    for i, (pos, lid) in enumerate(idx):
        if lid not in want:
            continue
        end = idx[i + 1][0] if i + 1 < len(idx) else len(s)
        block = s[pos:end]
        m = re.search(r'code:\n(.*?)\n    output:', block, re.S)
        o = re.search(r"output: '(.*?)',\n", block, re.S)
        title = re.search(r"title: '(.*?)',", block)
        print('=' * 20, lid, title.group(1) if title else '')
        print((m.group(1) if m else '<<no code>>').replace('"', '').replace('\\n', '\n'))
        print('--- expected output ---')
        print(o.group(1) if o else '?')
        print()
