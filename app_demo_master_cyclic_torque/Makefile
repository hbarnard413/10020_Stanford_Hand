FLAGS = -static
FLAGS += -std=c99

LIBS += -lsncn_ctrlproto -lsncn_motor_drive
LIBS += -lethercat -lm

# Installation directory of the  EtherCAT Master by IgH EtherLAB
ETHERCAT_MASTER_INSTALLDIR := /opt/etherlab

CTRL_PROTO_PATH := ..
MOTORCONTROL_PATH := ..

ifneq (,$(wildcard ../../sc_sncn_motorcontrol/.))
	MOTORCONTROL_PATH := ../../sc_sncn_motorcontrol
endif

ifneq (,$(wildcard ../../sc_sncn_ctrlproto/.)) 
	CTRL_PROTO_PATH := ../../sc_sncn_ctrlproto
endif

INCLUDE_DIRS += -I $(ETHERCAT_MASTER_INSTALLDIR)/include
INCLUDE_DIRS += -I ../motor_config

INCLUDE_DIRS += -I $(CTRL_PROTO_PATH)/inc_ctrlproto-common
INCLUDE_DIRS += -I $(CTRL_PROTO_PATH)/lib_linux_ctrlproto/include
INCLUDE_DIRS += -I $(CTRL_PROTO_PATH)/lib_linux_motor_drive/include
INCLUDE_DIRS += -I $(MOTORCONTROL_PATH)/module_profile/include
INCLUDE_DIRS += -I $(MOTORCONTROL_PATH)/module_motorcontrol_common/include
INCLUDE_DIRS += -I $(MOTORCONTROL_PATH)/module_hall/include
INCLUDE_DIRS += -I $(MOTORCONTROL_PATH)/module_qei/include

LIB_DIRS += -L $(ETHERCAT_MASTER_INSTALLDIR)/lib
LIB_DIRS += -L $(CTRL_PROTO_PATH)/lib_linux_ctrlproto/lib
LIB_DIRS += -L $(CTRL_PROTO_PATH)/lib_linux_motor_drive/lib

# Needed for checking if Linux machine
UNAME := $(shell uname)

all:
		@echo Bulding dependency: lib_linux_ctrlproto...
		@cd $(CTRL_PROTO_PATH)/lib_linux_ctrlproto; make
		@echo 
		@echo Bulding dependency: lib_linux_motor_drive...
		@cd $(CTRL_PROTO_PATH)/lib_linux_motor_drive; make
		@echo 
		@echo Bulding application...
ifneq "$(UNAME)" "Linux"
		@echo
		@echo "------------------------------------------------------------------------------------------------------"
		@echo "||Your System isn't Linux, so the Master Application for the Linux Ethercat Master can not be built.||"
		@echo "------------------------------------------------------------------------------------------------------"
		@echo
else
		@if test -d $(ETHERCAT_MASTER_INSTALLDIR); \
		then \
		mkdir bin -p;\
		gcc src/main.c  $(LIBS) $(INCLUDE_DIRS) $(LIB_DIRS) $(FLAGS) -o bin/$(notdir $(shell pwd)); \
		echo ;\
		echo "Run your application by typing: sudo bin/$(notdir $(shell pwd))" ;\
		echo ;\
		else echo \
		"\n\
		-----------------------------------------------------------------------------------------------------------------\n\
		||Ethercat Master is not installed at given directory if you installed it elsewhere change location in Makefile||\n\
		-----------------------------------------------------------------------------------------------------------------\n";\
		fi
endif

clean:
	rm -f bin/$(notdir $(shell pwd))
