import io

p = 'gen_data.py'
s = io.open(p, encoding='utf-8').read()

old = "m = load('monsters.json')"
new = "m = load('monsters.json')\nen = load('enemies.json')  # enemies live in their OWN file, separate from elements"
assert old in s, 'load line not found'
s = s.replace(old, new)

old2 = "els, ens = m['elements'], m['enemies']"
new2 = "els, ens = m['elements'], en['enemies']"
assert old2 in s, 'els/ens line not found'
s = s.replace(old2, new2)

io.open(p, 'w', encoding='utf-8', newline='\n').write(s)
print('gen_data.py now reads enemies.json')
