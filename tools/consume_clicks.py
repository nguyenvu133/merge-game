# Consume button clicks right after handling them — fixes the "trồng" bug where
# a single tap buys/upgrades many times (clicked stays true across throttled
# frames, so every poll re-fires the action).
import io

def consume(path):
    s = io.open(path, encoding='utf-8').read()
    lines = s.split('\n')
    out = []
    n = 0
    for i, ln in enumerate(lines):
        out.append(ln)
        st = ln.strip()
        # handler opening lines (exact form), excluding "&&" guards which are
        # not simple single-fire actions
        if st == 'if bt.clicked {':
            indent = ln[:len(ln) - len(ln.lstrip())]
            # only add the consume line when the NEXT line is not already it
            nxt = lines[i + 1].strip() if i + 1 < len(lines) else ''
            if nxt != 'bt.clicked = false':
                out.append(indent + '\tbt.clicked = false')
                n += 1
    io.open(path, 'w', encoding='utf-8', newline='\n').write('\n'.join(out))
    print(path, 'consumed', n, 'handlers')

consume('battle.v')
consume('map.v')
consume('settings.v')
