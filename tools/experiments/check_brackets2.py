import sys
sys.stdout.reconfigure(encoding='utf-8')

with open('lib/features/dpp/dpp_screen.dart', encoding='utf-8') as f:
    lines = f.readlines()

# Track bracket balance line by line
opens = 0
for i, line in enumerate(lines, 1):
    # Remove string literals (simple approach)
    s = line
    cleaned = []
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
            cleaned.append(s[j])
            j += 1
    
    cleaned_s = ''.join(cleaned)
    # Remove comments
    import re
    cleaned_s = re.sub(r'//.*', '', cleaned_s)
    cleaned_s = re.sub(r'/\*.*?\*/', '', cleaned_s, flags=re.DOTALL)
    
    net = cleaned_s.count('[') + cleaned_s.count('(') + cleaned_s.count('{') - \
          cleaned_s.count(']') - cleaned_s.count(')') - cleaned_s.count('}')
    
    if net != 0:
        print(f'Line {i}: net bracket change = {net:+d}: {line.rstrip()[:80]}')
    
    opens += net

print(f'\nTotal net change: {opens}')
if opens == 0:
    print('Brackets appear balanced')
else:
    print('Brackets are NOT balanced')
