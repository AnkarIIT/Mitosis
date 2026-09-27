from pathlib import Path
p = Path('lib/features/home/home_screen.dart')
lines = p.read_text().splitlines()
start = next(i for i,l in enumerate(lines) if '...subjects.map((subject) {' in l)
end = next(i for i,l in enumerate(lines[start:], start) if l.strip()=='}),')
text = '\n'.join(lines[start:end+1])
stack=[]
for li, line in enumerate(text.splitlines(), start=start+1):
    for ci, ch in enumerate(line, start=1):
        if ch == '(':
            stack.append((li, ci, line))
        elif ch == ')':
            if stack:
                stack.pop()
            else:
                print('Unmatched ) at', li, ci, line)
if stack:
    print('Unmatched ( count', len(stack))
    for item in stack[-10:]:
        print(item)
