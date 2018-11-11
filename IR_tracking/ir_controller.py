import cwiid
import time
import uinput
from operator import itemgetter

print("Please wiimote on now...")
wm = cwiid.Wiimote()
wm.led = 5
wm.rpt_mode = cwiid.RPT_IR

print("Connected!")
time.sleep(0.5)

xmin = 0
xmax = 1023
ymin = 0
ymax = 767

raw_input("Press Enter to start calibration")
print("Place a single controller on the BOTTOM LEFT corner of the table.")
for x in range(6):
    print(5-x)
    time.sleep(1)
xmin = wm.state['ir_src'][0].get("pos", "none")[0]
ymin = wm.state['ir_src'][0].get("pos", "none")[1]

print("Place the controller on the TOP RIGHT corner of the table.")
for x in range(6):
    print(5-x)
    time.sleep(1)
xmax = wm.state['ir_src'][0].get("pos", "none")[0]
ymax = wm.state['ir_src'][0].get("pos", "none")[1]

print("Done! X: " + xmin + '-' + xmax + ', Y: ' + ymin + '-' + ymax)

events = (
	uinput.BTN_SOUTH,
	uinput.ABS_X + (xmin, xmax, 5, 0),
	uinput.ABS_Y + (ymin, ymax, 5, 0),
	uinput.ABS_RX + (xmin, xmax, 5, 0),
	uinput.ABS_RY + (ymin, ymax, 5, 0)
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
			rx = result[1].get("pos", "none")[0]
			ry = result[1].get("pos", "none")[1]
			device.emit(uinput.ABS_RX, rx)
			device.emit(uinput.ABS_RY, ry)
	time.sleep(0.01)
