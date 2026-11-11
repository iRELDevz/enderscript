a.str = "b"
x.int = 0
if a == "b" :
  print>>"if"
else :
  print>>"else"
if a == "c":
  print>>"no"
else:
  print>>"yes"
  if x is 0:
    x = 5
  else:
    x = 9
print>>x
for i in range(6):
  if i % 2 == 0:
    x = x + 1
  else:
    x = x * 2
print>>x
loops(3):
  if x > 100:
    if x > 1000:
      print>>"big"
    else:
      print>>"mid"
  else:
    x = x * 10
print>>x
