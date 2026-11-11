x.int = 5
s.str = "b"
if x < 3:
  print>>"lt3"
elif x <= 5:
  print>>"le5"
elif x >= 5:
  print>>"no"
else:
  print>>"no"
if x >= 6:
  print>>"no"
elif x != 5:
  print>>"no"
elif s != "b":
  print>>"no"
else :
  print>>"else"
if x is 1:
  print>>"no"
elif x is 5 :
  print>>"five"
  if s == "a":
    print>>"no"
  elif s == "b":
    print>>"inner b"
print>>"after"
c.int = 0
for i in range(20):
  if i <= 3:
    c = c + 1
  elif i >= 17:
    c = c + 100
  elif i % 2 == 0:
    c = c + 10000
print>>c
if 3 <= 3 and 4 >= 5:
  print>>"no"
elif 2 != 3:
  print>>"fold"
loops(4):
  if x <= 4:
    x = x + 1
  elif x >= 7:
    x = x - 3
  else:
    x = x * 2
print>>x
