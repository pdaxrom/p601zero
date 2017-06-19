UNIASM = DEVEL/uniasm

all: $(UNIASM) bootloader ../mcu_rom.v ../vrom.v ../mcu_pll.v ../vpu_cache.v

$(UNIASM):
	make -C $(shell dirname $(UNIASM)) $(shell basename $(UNIASM))

rom.mem: ROM.ASM BOOTROM.INC DEVMAP.INC
	$(UNIASM) ROM.ASM ROM.LST ROM.CMD
	hexdump -v -e '"%04_ax: " 16/1 "%02x " "\n"' ROM.CMD > rom.mem
	cp -f ROM.CMD rom.bin

vrom.mem:
	gzip -dc video.roz | hexdump -v -e '"%04_ax: " 16/1 "%02x " "\n"' > vrom.mem

../mcu_rom.v: rom.mem
	export LD_LIBRARY_PATH="/opt/diamond/3.9_x64/tcltk/lib:/opt/diamond/3.9_x64/ispfpga/bin/lin64:/opt/diamond/3.9_x64/bin/lin64:/opt/diamond/3.9_x64/ispfpga/bin/lin64"; \
	export FOUNDRY="/opt/diamond/3.9_x64/ispfpga"; \
	cd .. && \
	/opt/diamond/3.9_x64/ispfpga/bin/lin64/scuba -w -n mcu_rom -lang verilog -synth lse -bus_exp 7 -bb -arch xo2c00 -type rom -addr_width 8 -num_rows 2048 -data_width 8 -outdata REGISTERED -cascade -1 -resetmode SYNC -sync_reset  -memfile ROM/rom.mem -memformat orca

../vrom.v: vrom.mem
	export LD_LIBRARY_PATH="/opt/diamond/3.9_x64/tcltk/lib:/opt/diamond/3.9_x64/ispfpga/bin/lin64:/opt/diamond/3.9_x64/bin/lin64:/opt/diamond/3.9_x64/ispfpga/bin/lin64"; \
	export FOUNDRY="/opt/diamond/3.9_x64/ispfpga"; \
	cd .. && \
	/opt/diamond/3.9_x64/ispfpga/bin/lin64/scuba -w -n vrom -lang verilog -synth lse -bus_exp 7 -bb -arch xo2c00 -type bram -wp 00 -rp 1100 -addr_width 11 -data_width 8 -num_rows 2048 -cascade -1 -memfile ROM/vrom.mem -memformat orca
#	/opt/diamond/3.9_x64/ispfpga/bin/lin64/scuba -w -n vrom -lang verilog -synth lse -bus_exp 7 -bb -arch xo2c00 -type rom -addr_width 8 -num_rows 2048 -data_width 8 -outdata UNREGISTERED -cascade -1 -resetmode SYNC -sync_reset  -memfile ROM/vrom.mem -memformat orca

../vpu_cache.v:
	export LD_LIBRARY_PATH="/opt/diamond/3.9_x64/tcltk/lib:/opt/diamond/3.9_x64/ispfpga/bin/lin64:/opt/diamond/3.9_x64/bin/lin64:/opt/diamond/3.9_x64/ispfpga/bin/lin64"; \
	export FOUNDRY="/opt/diamond/3.9_x64/ispfpga"; \
	cd .. && \
	/opt/diamond/3.9_x64/ispfpga/bin/lin64/scuba -w -n vpu_cache -lang verilog -synth lse -bus_exp 7 -bb -arch xo2c00 -type sdpram -rdata_width 8 -data_width 8 -num_rows 64 -outData UNREGISTERED

../mcu_pll.v:
	export LD_LIBRARY_PATH="/opt/diamond/3.9_x64/tcltk/lib:/opt/diamond/3.9_x64/ispfpga/bin/lin64:/opt/diamond/3.9_x64/bin/lin64:/opt/diamond/3.9_x64/ispfpga/bin/lin64"; \
	export FOUNDRY="/opt/diamond/3.9_x64/ispfpga"; \
	cd .. && \
	/opt/diamond/3.9_x64/ispfpga/bin/lin64/scuba -w -n mcu_pll -lang verilog -synth lse -arch xo2c00 -type pll -fin 12 -fclkop 24 -fclkop_tol 0.0 -fclkos 6 -fclkos_tol 0.0 -fclkos2 8 -fclkos2_tol 0.0 -trimp 0 -phasep 0 -trimp_r -trims 0 -phases 0 -trims_r -phases2 0 -phase_cntl STATIC -fb_mode 1 

bootloader: bootloader.c
	$(CC) $^ -o $@ -Wall -O2 -g

clean:
	rm -f rom.bin *.LST *.CMD *.o *.mem bootloader ../mcu_rom.v ../vrom.v ../mcu_pll.v ../vpu_cache.v
