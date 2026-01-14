#!/usr/bin/env python3

from sys import argv

def extract_joltage(line: str):
    last_but_one = len(line) - 1
    max1 = None
    max2 = None
    for idx, ch in enumerate(line):
        if idx < last_but_one:
            if not max1 or ch > max1:
                max1 = ch
                max2 = None
            elif not max2 or ch > max2:
                max2 = ch
        else:
            if not max2 or ch > max2:
                max2 = ch
    assert(max1 and max2)
    return (ord(max1) - ord('0')) * 10 + (ord(max2) - ord('0'))

def main():
    fin = 0 if len(argv) != 2 else argv[1]
    lines = open(fin).read().strip().split("\n")
    result = 0
    for line in lines:
        result += extract_joltage(line)
    print(result)

if __name__ == "__main__":
    main()
