for i in range(1024):
    bits = '{0:09b}'.format(i)
    s = bits.count('1')
    c = int(bits[4])
    s -= c
    if s == 2:
        newvalue = c
    if s == 3:
        newvalue = 1
    else:
        newvalue = 0

    print "\t\t\t9'b{0:s}: newvalue = 1'b{1:d};".format(bits, newvalue)
