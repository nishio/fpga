def print_rule(bits, newvalue):
    print "\t\t\t9'b{0:s}_{1:s}_{2:s}: wdata = 1'b{3:d};".format(bits[:3], bits[3:6], bits[6:], newvalue)

for i in range(512):
    bits = '{0:09b}'.format(i)
    s = bits.count('1')
    c = int(bits[4])
    s -= c
    if s == 2:
        newvalue = c
        if newvalue:
            print_rule(bits, 1)
    elif s == 3:
        newvalue = 1
        if c:
            bits = bits[:4] + 'x' + bits[5:]
            print_rule(bits, 1)
    else:
        pass

print "\t\t\tdefault: wdata = 1'b0;"
