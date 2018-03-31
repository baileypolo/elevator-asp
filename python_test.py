#!/usr/bin/env python3


import re


def parse(lines, re_atom= re.compile(r"(\b(?:holds|do)\(.*?\))(?:\.|\s|$)")):
    ans = []
    for line in lines:
        match = re_atom.findall(line)
        if match: ans.append(frozenset(match))
    return frozenset(ans)


def parse_sym(chars):
    sym = "".join(chars)
    try:
        return int(sym)
    except ValueError:
        pass
    return sym


def parse_atom(s):
    stack, sym = [[]], []
    for c in s:
        if "(" == c:
            assert sym
            stack.append([parse_sym(sym)])
            sym = []
        elif ")" == c:
            top = stack.pop()
            if sym:
                top.append(parse_sym(sym))
                sym = []
            stack[-1].append(tuple(top))
        elif "," == c:
            if sym:
                stack[-1].append(parse_sym(sym))
                sym = []
        else:
            sym.append(c)
    if sym: stack[-1].append(parse_sym(sym))
    assert 1 == len(stack)
    stack = stack.pop()
    assert 1 == len(stack)
    return stack.pop()


def sort_model(model, idxs= (-1, 0)):
    m = []
    for atom in model:
        sexp = parse_atom(atom)
        sexp = [sexp[idx] for idx in idxs]
        sexp.append(atom)
        m.append((sexp, atom))
    m.sort()
    return tuple(a[1] for a in m)


if '__main__' == __name__:
    import os
    import subprocess
    import sys

    arg = dict(zip(sys.argv[1::2], sys.argv[2::2]))
    arg.setdefault('--lvl', '1:35')
    arg.setdefault('--encoding', "elevator-04.lp")
    arg.setdefault('--instances', "instances")
    arg.setdefault('--timeout', "0")
    print(arg)

    lvl = arg['--lvl']
    if ":" in lvl:
        i, j = map(int, lvl.split(":"))
        i -= 1
    else:
        j = int(lvl)
        i = j - 1

    timeout = int(arg['--timeout']) or None
    for i in sorted(i for i in os.listdir(arg['--instances']) if i.endswith(".lp"))[i:j]:
        path = os.path.join(arg['--instances'], i)
        with open(path + ".sol", encoding= 'utf-8') as file: gold = parse([file.read()])
        try:
            out, err = subprocess.Popen(
                ('clingo', '--quiet=1', '--opt-mode=optN', arg['--encoding'], path)
                , stdout= subprocess.PIPE
                , universal_newlines= True).communicate(timeout= timeout)
        except subprocess.TimeoutExpired:
            print("timeout", path)
        test = parse(out.splitlines())
        if test.issuperset(gold):
            print("passed", path, out[out.rindex("CPU Time") + 15:-1])
        else:
            print("failed", path)
            print("expected:")
            for m in gold: print(*sort_model(m))
            print("got:")
            for m in test: print(*sort_model(m))
            sys.exit()
