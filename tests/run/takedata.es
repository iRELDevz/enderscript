loops(ins,
start.ins
3(
print>>ins.takedata
)
2(
print>>"b"{ins.takedata}
break
)
4(
print>>"c"{ins.takedata}
break.ins
)
5(
print>>"never"
)
stop.ins
)
print>>"after "{ins.takedata}
a.int = ins.takedata
print>>a
k.int = 0
loops(g,
start.g
1(
for k in range(10):
  if k is 3:
    break.g
)
2(
print>>"never"
)
stop.g
)
print>>"k "{k}
loops(o,
start.o
2(
loops(o,
start.o
o.takedata + 3(
show>>o.takedata
)
stop.o
)
print>>""
)
stop.o
)
