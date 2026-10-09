a.int = 5
b.int = 3
s.str = "x"
if a > 1 and b < 4:
  print>>"both"
if a > 1 and b > 4:
  print>>"no1"
else:
  print>>"notboth"
if a is 1 or b is 3:
  print>>"one"
if a is 5 or b is 3:
  print>>"two"
if a and b > 2:
  print>>"short and"
if a and b > 4:
  print>>"no2"
if a is 9 or b is 3 and s == "x":
  print>>"prec1"
if a is 5 or b is 9 and s == "y":
  print>>"prec2"
if a is 9 or b is 9 and s == "x":
  print>>"no3"
if a or b is 3 and s is "x":
  print>>"mix"
if 1 is 1 and a is 5:
  print>>"fold"
if 1 is 2 and a is 5:
  print>>"no4"
c.int = 0
for i in range(30):
  if i > 5 and i < 10 or i is 20:
    c = c + 1
print>>c
