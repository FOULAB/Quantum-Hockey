import cwiid
import time
import uinput
from operator import itemgetter

wm = cwiid.Wiimote()
wm.led = 5

wm.rpt_mode = cwiid.RPT_IR

events = (
	uinput.BTN_SOUTH,
	uinput.ABS_X + (0, 1023, 5, 0),
	uinput.ABS_Y + (0, 767, 5, 0),
	uinput.ABS_RX + (0, 1023, 5, 0),
	uinput.ABS_RY + (0, 767, 5, 0)
	)

device = uinput.Device(events)

device.emit(uinput.ABS_X, 50)
time.sleep(0.25)
device.emit(uinput.ABS_X, 128)
time.sleep(0.25)


while 1 :
	ir = wm.state['ir_src']
	result = []

	for x in ir:
		if x is not None:
			result.append(x)
	#if result:
	#result = sorted(result, key=itemgetter('size'), reverse=True)

 	if result:
		lx = result[0].get("pos", "none")[0]
		ly = result[0].get("pos", "none")[1]
		device.emit(uinput.ABS_X, lx)
		device.emit(uinput.ABS_Y, ly)
		if len(result) > 1:
			rx = result[0].get("pos", "none")[0]
			ry = result[0].get("pos", "none")[1]
			device.emit(uinput.ABS_RX, rx)
			device.emit(uinput.ABS_RY, ry)
	time.sleep(0.01)
