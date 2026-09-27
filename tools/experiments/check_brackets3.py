import sys
sys.stdout.reconfigure(encoding='utf-8')

with open('lib/features/dpp/dpp_screen.dart', encoding='utf-8') as f:
    lines = f.readlines()

import re

def clean_line(s):
    # Remove string literals
    result = []
    j = 0
    while j < len(s):
        if s[j] == "'":
            j += 1
            while j < len(s) and s[j] != "'":
                if s[j] == '\\':
                    j += 1
                j += 1
            if j < len(s):
                j += 1
        elif s[j] == '"':
            j += 1
            while j < len(s) and s[j] != '"':
                if s[j] == '\\':
                    j += 1
                j += 1
            if j < len(s):
                j += 1
        elif s[j] == '`':
            j += 1
            while j < len(s) and s[j] != '`':
                j += 1
            if j < len(s):
                j += 1
        else:
            result.append(s[j])
            j += 1
    s = ''.join(result)
    # Remove comments
    s = re.sub(r'//.*', '', s)
    s = re.sub(r'/\*.*?\*/', '', s, flags=re.DOTALL)
    return s

depth = 0
for i, line in enumerate(lines, 1):
    cleaned = clean_line(line)
    net = cleaned.count('[') + cleaned.count('(') + cleaned.count('{') - \
          cleaned.count(']') + cleaned.count(')') + cleaned.count('}')
    
    # Show when depth changes
    if net != 0:
        print(f'Line {i}: depth {depth} -> {depth+net:+d} | {line.rstrip()[:80]}')
    depth += net

print(f'\nFinal depth: {depth}')
if depth == 0:
    print('Brackets appear balanced')
else:
    print('Brackets are NOT balanced')
