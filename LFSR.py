"""
linear feedback shift register
"""

taps = (161, 167) # other options (126, 127) (77, 81) (62, 63) (20, 33)

print "\t\tlfsr[0] <= ^{%s};" % (", ".join("lfsr[%d]" % (x - 1) for x in taps))
for i in range(1, max(taps)):
    print "\t\tlfsr[%d] <= lfsr[%d];" % (i, i - 1)
