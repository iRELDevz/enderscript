c.int = 0
n.int = 3
x.int = 0
loops(a,
  start.a
  4(
    c = c + 1
    if c is 2:
      print>>"two"
    elif c > 3:
      print>>"big"
    for x in range(2):
      c = c + 10
  )
  n * 2(
    loops(b,
    start.b
    2(
    c = c + 100
    )
    stop.b
    )
  )
  0(
    print>>"never"
  )
  stop.a
)
print>>c
loops(2):
  loops(z,
    start.z
    1(
      print>>"inner"
    )
    stop.z
  )
