import sys
import serial
import signal


should_exit = False


def signal_handler(sig, frame):
    global should_exit
    should_exit = True


def main():
    signal.signal(signal.SIGINT, signal_handler)

    global dev
    dev = serial.Serial("/dev/ttyUSB0", 3000000)

    while not should_exit:
        x = int.from_bytes(dev.read(1))
        sys.stdout.write(chr(x))
        sys.stdout.flush()
    
    dev.close()

main()