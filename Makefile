# makefile discription.
# basic build file for cfunc library

# project-specific macros
# extension of the executable-file is modifiable(.exe .out ...)
BASEDIR = $(shell pwd)
TARGET := $(BASEDIR)/../lib/libmobiruby.a
MRBCSRC := $(patsubst %.rb,%.c,$(wildcard $(BASEDIR)/modules/mruby-cfunc/src/mrb/*.rb)) \
	$(patsubst %.rb,%.c,$(wildcard $(BASEDIR)/modules/mruby-cocoa/src/mrb/*.rb))

EXCEPT1 := $(MRBCSRC)

OBJ1 := $(patsubst %.c,%.o,$(filter-out $(EXCEPT1),$(wildcard $(BASEDIR)/modules/libffi-iOS/ios/src/**/*.c))) \
	$(patsubst %.c,%.o,$(filter-out $(EXCEPT1),$(wildcard $(BASEDIR)/modules/libffi-iOS/src/*.c))) \
	$(patsubst %.c,%.o,$(filter-out $(EXCEPT1),$(wildcard $(BASEDIR)/modules/mruby-cfunc/src/*.c))) \
	$(patsubst %.c,%.o,$(filter-out $(EXCEPT1),$(wildcard $(BASEDIR)/modules/mruby-cocoa/src/*.c)))
OBJ2 := $(patsubst %.S,%.o,$(filter-out $(EXCEPT1),$(wildcard $(BASEDIR)/modules/libffi-iOS/ios/src/**/*.S)))
OBJ3 := $(patsubst %.m,%.o,$(filter-out $(EXCEPT1),$(wildcard $(BASEDIR)/modules/mruby-cocoa/src/*.m)))
OBJMRB := $(patsubst %.c,%.o,$(MRBCSRC))
OBJS := $(OBJ1) $(OBJ2) $(OBJ3)

MRBC = $(BASEDIR)/bin/mrbc

# libraries, includes
INCLUDES = -I$(BASEDIR)/modules/libffi-iOS/ios/include \
	-I$(BASEDIR)/modules/mruby-cfunc/include \
	-I$(BASEDIR)/modules/mruby-cocoa/include \
	-I$(BASEDIR)/include

ifeq ($(strip $(COMPILE_MODE)),)
  # default compile option
  COMPILE_MODE = debug
endif

ifeq ($(COMPILE_MODE),debug)
  CFLAGS = -g -O3
else ifeq ($(COMPILE_MODE),release)
  CFLAGS = -O3
else ifeq ($(COMPILE_MODE),small)
  CFLAGS = -Os
endif

ALL_CFLAGS = -Wall -Werror-implicit-function-declaration -std=c99 $(CFLAGS) $(MRUBY_CFLAGS) $(LIBFFI_CFLAGS) $(CFUNC_CFLAGS)


##############################
# internal variables

export CP := cp
export RM_F := rm -f
export CAT := cat


##############################
# generic build targets, rules

.PHONY : all
all : $(TARGET)

# executable constructed using linker from object files
$(TARGET) : $(OBJS) $(OBJMRB)
	$(AR) r $@ $(OBJS) $(OBJMRB)


-include $(OBJS:.o=.d) $(OBJMRB:.o=.d)

# mrby complie
$(OBJMRB) : %.o : %.rb
	$(BASEDIR)/bin/mrbc -Cinit_$(*F) $<
	$(CC) $(ALL_CFLAGS) -MMD $(INCLUDES) -c $(basename $<).c -o $@

# objects compiled from source
$(OBJ1) : %.o : %.c
	$(CC) $(ALL_CFLAGS) $(INCLUDES) -c $< -o $@

# objects compiled from source
$(OBJ2) : %.o : %.S
	$(CC) $(ALL_CFLAGS) $(INCLUDES) -c $< -o $@

# objects compiled from source
$(OBJ3) : %.o : %.m
	$(CC) $(ALL_CFLAGS) $(INCLUDES) -c $< -o $@ -fobjc-abi-version=2 -fobjc-legacy-dispatch

# clean up
.PHONY : clean #cleandep
clean :
	@echo "make: removing targets, objects and depend files of `pwd`"
	-$(RM_F) $(TARGET) $(OBJS) $(OBJMRB) $(MRB)
	-$(RM_F) $(OBJS:.o=.d) $(OBJY:.o=.d)
	-$(RM_F) $(patsubst %.c,%.o,$(EXCEPT1)) $(patsubst %.c,%.d,$(EXCEPT1))
	-$(RM_F) $(patsubst %.m,%.o,$(EXCEPT1)) $(patsubst %.m,%.d,$(EXCEPT1))
