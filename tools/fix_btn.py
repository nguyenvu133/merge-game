import io

p = 'battle.v'
s = io.open(p, encoding='utf-8').read()
n = s.replace("'ui/button0.png'", "'ui/button1.png'")
io.open(p, 'w', encoding='utf-8', newline='\n').write(n)
print('button0->button1:', s.count("'ui/button0.png'"), '->', n.count("'ui/button1.png'"))
