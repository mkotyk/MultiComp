###################################################################
# Project Configuration: 
# 
# Specify the name of the design (project) and the Quartus II
# Settings File (.qsf)
###################################################################

PROJECT = Microcomputer
ASSIGNMENT_FILES = $(PROJECT).qpf $(PROJECT).qsf

###################################################################
# Part, Family, Boardfile DE1 or DE2
FAMILY = "Cyclone V"
PART = 5CEBA4F23C7
BOARD = DE0_CV
BOARDFILE = ../boards/$(BOARD)_Pins
TOP_LEVEL_ENTITY = $(BOARD)_top
VHDL_ROOT = ../vhdl
###################################################################

###################################################################
# Setup your sources here
SRCS =  $(VHDL_ROOT)/$(BOARD)/$(BOARD)_top.vhd \
		$(VHDL_ROOT)/ROMS/6809/M6809_EXT_BASIC_ROM.vhd \
		$(VHDL_ROOT)/ROMS/6502/M6502_BASIC_ROM.vhd \
		$(VHDL_ROOT)/ROMS/Z80/Z80_BASIC_ROM.vhd \
		$(VHDL_ROOT)/ROMS/Z80/Z80_CPM_BASIC_ROM.vhd \
		$(VHDL_ROOT)/Components/RAM/InternalRam1K.vhd \
		$(VHDL_ROOT)/Components/RAM/InternalRam2K.vhd \
		$(VHDL_ROOT)/Components/RAM/InternalRam4K.vhd \
		$(VHDL_ROOT)/Components/M6809/cpu09l.vhd \
		$(VHDL_ROOT)/Components/M6502/T65.vhd \
		$(VHDL_ROOT)/Components/M6502/T65_ALU.vhd \
		$(VHDL_ROOT)/Components/M6502/T65_Pack.vhd \
		$(VHDL_ROOT)/Components/M6502/T65_MCode.vhd \
		$(VHDL_ROOT)/Components/Z80/T80s.vhd \
		$(VHDL_ROOT)/Components/Z80/T80_ALU.vhd \
		$(VHDL_ROOT)/Components/Z80/T80_Reg.vhd \
		$(VHDL_ROOT)/Components/Z80/T80_MCode.vhd \
		$(VHDL_ROOT)/Components/Z80/T80_Pack.vhd \
		$(VHDL_ROOT)/Components/Z80/T80.vhd \
		$(VHDL_ROOT)/Components/SDCARD/sd_controller.vhd \
		$(VHDL_ROOT)/Components/UART/bufferedUART.vhd \
		$(VHDL_ROOT)/Components/M6800/cpu68.vhd \
		$(VHDL_ROOT)/Components/TERMINAL/CGABoldRom.vhd \
		$(VHDL_ROOT)/Components/TERMINAL/DisplayRam2K.vhd \
		$(VHDL_ROOT)/Components/TERMINAL/SBCTextDisplayRGB.vhd \
		$(VHDL_ROOT)/Components/TERMINAL/DisplayRam1K.vhd \
		$(VHDL_ROOT)/Components/TERMINAL/CGABoldRomReduced.vhd \
	    $(VHDL_ROOT)/hex_decoder.vhd


###################################################################
# Main Targets
#
# all: build everything
# clean: remove output files and database
# program: program your device with the compiled design
###################################################################

all: smart.log $(PROJECT).asm.rpt $(PROJECT).sta.rpt 

clean:
	rm -rf *.rpt *.chg smart.log *.htm *.eqn *.pin *.sof *.pof db incremental_db \
		$(PROJECT).map.summary $(PROJECT).qpf $(PROJECT).qsf


map: smart.log $(PROJECT).map.rpt
fit: smart.log $(PROJECT).fit.rpt
asm: smart.log $(PROJECT).asm.rpt
sta: smart.log $(PROJECT).sta.rpt
smart: smart.log

###################################################################
# Executable Configuration
###################################################################

MAP_ARGS = --read_settings_files=on $(addprefix --source=,$(SRCS))

FIT_ARGS = --part=$(PART) --read_settings_files=on
ASM_ARGS =
STA_ARGS =

###################################################################
# Target implementations
###################################################################

STAMP = echo done >

$(PROJECT).map.rpt: map.chg $(SOURCE_FILES)
	quartus_map $(MAP_ARGS) $(PROJECT)
	$(STAMP) fit.chg

$(PROJECT).fit.rpt: fit.chg $(PROJECT).map.rpt
	quartus_fit $(FIT_ARGS) $(PROJECT)
	$(STAMP) asm.chg
	$(STAMP) sta.chg

$(PROJECT).asm.rpt: asm.chg $(PROJECT).fit.rpt
	quartus_asm $(ASM_ARGS) $(PROJECT)

$(PROJECT).sta.rpt: sta.chg $(PROJECT).fit.rpt
	quartus_sta $(STA_ARGS) $(PROJECT)

$(PROJECT).pof: $(PROJECT).sof
	quartus_cpf -c -o ignore_epcs_id_check=on -d EPCS64  $< $@

smart.log: $(ASSIGNMENT_FILES)
	quartus_sh --determine_smart_action $(PROJECT) > smart.log

###################################################################
# Project initialization
###################################################################

$(ASSIGNMENT_FILES):
	quartus_sh --prepare -f $(FAMILY) -t $(TOP_LEVEL_ENTITY) $(PROJECT)
	-echo >> $(PROJECT).qsf
	-echo "set_global_assignment -name NUM_PARALLEL_PROCESSORS " `nproc --all` >> $(PROJECT).qsf
	-cat $(BOARDFILE) >> $(PROJECT).qsf
map.chg:
	$(STAMP) map.chg
fit.chg:
	$(STAMP) fit.chg
sta.chg:
	$(STAMP) sta.chg
asm.chg:
	$(STAMP) asm.chg

###################################################################
# Programming the device
###################################################################

program: $(PROJECT).sof
	quartus_pgm --no_banner --mode=jtag -o "P;$(PROJECT).sof"

flash: $(PROJECT).pof
	quartus_pgm --mode=AS -o "p;$(PROJECT).pof"

