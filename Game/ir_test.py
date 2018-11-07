import cwiid
import time
from operator import itemgetter

wm = cwiid.Wiimote()
wm.led = 5

wm.rpt_mode = cwiid.RPT_IR

while 1 :
  ir = wm.state['ir_src']
  #ir = sorted(ir, key=lambda k: k['size'])
  result = []

  for x in ir:
    if x is not None:
      result.append(x)
  if result:
    result = sorted(result, key=itemgetter('size'), reverse=True)
  print(result)
  time.sleep(0.2)
