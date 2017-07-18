AS11 = ../DEVEL/AS11/as11

all: $(AS11) buf34-zpx.cmd KERNEL.SYS

$(AS11):
	make -C $(shell dirname $(AS11)) $(shell basename $(AS11))

KERNEL.SYS: buf34-zpx.cmd
	cp -f $< $@

.SUFFIXES: .asm .s19 .cmd

.asm.s19:
	$(AS11) $< - L > $(basename $@).lst

.s19.cmd:
	objcopy -I srec -O binary $< $@

clean:
	rm -f *.cmd *.s19 *.lst KERNEL.SYS
