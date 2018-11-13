import cwiid
import time
import uinput
from operator import itemgetter

print("Please turn wiimote on now")
wm = cwiid.Wiimote()
wm.led = 5
wm.rpt_mode = cwiid.RPT_IR

print("Connected! Launch the game!")

events = (
	uinput.BTN_SOUTH,
	uinput.ABS_X + (0, 1023, 5, 0),
	uinput.ABS_Y + (0, 767, 5, 0),
	uinput.ABS_RX + (0, 1023, 5, 0),
	uinput.ABS_RY + (0, 767, 5, 0)
	)

device = uinput.Device(events)



while 1 :
	ir = wm.state['ir_src']
	result = []

	for x in ir:
		if x is not None:
			result.append(x)

 	if result:
		lx = result[0].get("pos", "none")[0]
		ly = result[0].get("pos", "none")[1]
		device.emit(uinput.ABS_X, lx)
		device.emit(uinput.ABS_Y, ly)
		if len(result) > 1:
			rx = result[1].get("pos", "none")[0]
			ry = result[1].get("pos", "none")[1]
			device.emit(uinput.ABS_RX, rx)
			device.emit(uinput.ABS_RY, ry)
