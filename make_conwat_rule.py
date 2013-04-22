for i in range(512):
    bits = '{0:09b}'.format(i)
    s = bits.count('1')
    c = int(bits[4])
    s -= c
    if s == 2:
        newvalue = c
    elif s == 3:
        newvalue = 1
    else:
        newvalue = 0

    print "\t\t\t9'b{0:s}_{1:s}_{2:s}: wdata = 1'b{3:d};".format(bits[:3], bits[3:6], bits[6:], newvalue)
