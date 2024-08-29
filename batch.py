#!/usr/bin/env -S python3 -u

import serial # type: ignore
import time
import statistics
from typing import List
from typing import Optional

# Get line of text and convert to list of integers
def get_line(seri : serial.Serial) -> Optional[List[int]]:
    t = time.time()
    res = seri.readline()
    if len(res) > 2 and hex(res[-1]) == "0xa":
        t = time.time() - t
        f = list(map(int, res.decode('ascii').strip().strip('\x00').split()))
        #print(".",end='')
        return f
    else:
        #print()
        return None

def run(seri : serial.Serial) -> Optional[List[List[int]]]:
    seri.reset_input_buffer()
    seri.write(b'I')
    time.sleep(0.1)
    get_line(seri) # Ignore result
    seri.write(b'C')
    table : List[List[int]] = []
    while True:
        l = get_line(seri)
        if l is None:
            break
        assert len(l) == 6 # 1 for generation number and 5 for statistics
        m0 = l[1] # Population count
        n = 100*100 # Total size of grid
        # Calculate auto-correlation values
        scale = 1000 # values given as parts per thousand.
        corr = [(scale*(n*m-m0*m0)) // (m0*(n-m0)) for m in l[2:]]
        data = [l[0], (scale*m0)//n] + corr
        table += [data]
        if len(table) > 10000:
            return None
    return table

def main():
    ser = serial.Serial(
        port='/dev/ttyUSB1',
        baudrate=2000000,
        timeout=0.1,
        parity=serial.PARITY_NONE,
        stopbits=serial.STOPBITS_ONE,
        bytesize=serial.EIGHTBITS
    )

    l = 100
    res = []
    print("Start")
    for b in range(l):
        result = run(ser)
        if result is not None:
            res += [result[-1]]
            print(b, result[-1])
    print("Done")
    t = list(map(list, zip(*res)))
    for e in t:
        print(f"{statistics.mean(e):5.0f}, {statistics.pstdev(e):5.1f}")


if __name__ == "__main__":
    main()

