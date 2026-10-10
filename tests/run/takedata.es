loops(adv,
start.adv
3(
print>>adv.takedata
)
2(
print>>"b"{adv.takedata}
break
)
4(
print>>"c"{adv.takedata}
break.adv
)
5(
print>>"never"
)
stop.adv
)
print>>"after "{adv.takedata}
a.int = adv.takedata
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
