from pathlib import Path
p = Path('lib/features/home/home_screen.dart')
lines = p.read_text().splitlines()
start = next(i for i,l in enumerate(lines) if '...subjects.map((subject) {' in l)
end = next(i for i,l in enumerate(lines[start:], start) if l.strip() == '}),')
paren = 0
for idx,line in enumerate(lines[start:end+1], start):
    paren += line.count('(') - line.count(')')
    if paren != 0:
        print(idx+1, paren, line)
