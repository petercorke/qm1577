import serial

ser = serial.Serial('/dev/tty.SLAB_USBtoUART', 38400, timeout=5)

x = ser.read(10)
print(x)