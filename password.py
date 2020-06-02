import random

s = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()"

length = 10

password = "".join(random.sample(s,length))

print password
