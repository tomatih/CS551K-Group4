#!/usr/bin/env python3

header_name = input("Enter heading name: ")

print("/*"+"-"*50)
print(" "*(25 - len(header_name)//2) + header_name)
print("-"*50+"*/")
