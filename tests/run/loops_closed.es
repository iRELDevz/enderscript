c.int = 5
d.int = 2
loops(7):
  c = 3 + c
loops(0):
  c = c + 100
loops((-3)):
  c = c - 100
loops(10):
  c = c - 4
loops(4):
  c = c + d
loops(1000000):
  c = c + 2147483647
print>>c
