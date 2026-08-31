import sys
sys.stdout.reconfigure(encoding='utf-8')
with open('lib/features/dpp/dpp_screen.dart', encoding='utf-8') as f:
    content = f.read()

def remove_strings(s):
    result = []
    i = 0
    while i < len(s):
        if s[i] == "'":
            result.append("'")
            i += 1
            while i < len(s) and s[i] != "'":
                if s[i] == '\\':
                    i += 1
                result.append(s[i])
                i += 1
            if i < len(s):
                result.append(s[i])
                i += 1
        elif s[i] == '"':
            result.append('"')
            i += 1
            while i < len(s) and s[i] != '"':
                if s[i] == '\\':
                    i += 1
                result.append(s[i])
                i += 1
            if i < len(s):
                result.append(s[i])
                i += 1
        elif s[i] == '`':
            result.append('`')
            i += 1
            while i < len(s) and s[i] != '`':
                result.append(s[i])
                i += 1
            if i < len(s):
                result.append(s[i])
                i += 1
        else:
            result.append(s[i])
            i += 1
    return ''.join(result)

import re
no_strings = remove_strings(content)
no_strings = re.sub(r'//.*', '', no_strings)
no_strings = re.sub(r'/\*.*?\*/', '', no_strings, flags=re.DOTALL)

stack = []
for i, ch in enumerate(no_strings):
    if ch == '[':
        stack.append(('[', i))
    elif ch == ']':
        if not stack or stack[-1][0] != '[':
            line = content[:i].count('\n') + 1
            print(f'Unmatched ] at line {line}')
            break
        stack.pop()
    elif ch == '(':
        stack.append(('(', i))
    elif ch == ')':
        if not stack or stack[-1][0] != '(':
            line = content[:i].count('\n') + 1
            print(f'Unmatched ) at line {line}')
            break
        stack.pop()
    elif ch == '{':
        stack.append(('{', i))
    elif ch == '}':
        if not stack or stack[-1][0] != '{':
            line = content[:i].count('\n') + 1
            print(f'Unmatched }} at line {line}')
            break
        stack.pop()

if stack:
    for bracket, pos in stack:
        line = content[:pos].count('\n') + 1
        print(f'Unclosed {bracket} at line {line}')
else:
    print('All brackets balanced')
