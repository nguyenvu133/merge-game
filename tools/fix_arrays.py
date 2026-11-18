# make gen_data.py emit dynamic arrays ([]) instead of fixed ([..]!) so the
# const g_data struct accepts them
import io

p = 'gen_data.py'
s = io.open(p, encoding='utf-8').read()
for var in ['el_list', 'en_list', 'pt_list', 'sk_list', 'ef_list', 'tm_list', 'bo_list']:
    old = "'[' + ', '.join(%s) + ']!'" % var
    new = "'[' + ', '.join(%s) + ']'" % var
    assert old in s, 'not found: ' + old
    s = s.replace(old, new)
io.open(p, 'w', encoding='utf-8', newline='\n').write(s)
print('arrays -> dynamic')
