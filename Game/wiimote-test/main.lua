--Wiimote support
local sp = require("serial-port")

assert(sp.open("/dev/ttyAMA0"), "Port opened failed");
assert(sp.setBaud(sp.B115200), "set baud failed");

while true do
   print("listening");
  local r = sp.read();
  if #r > 0 then
    print(r);
  end
end