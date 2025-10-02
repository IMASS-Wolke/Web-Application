#
# @(#)Makefile	5.4 1/28/91
# 

# DEBUGGING 
FFLAGS = -C -u -g
FFLAGS_1 = -C -g
# OPTIMIZED

#FFLAGS = -O
#FFLAGS_1 = -O

OBJ = sntherm.o \
      calconstant.o \
      combinenodes.o combo.o compact.o converge.o dblcurve.o density.o \
      diffusion.o dinsol.o fa.o fbb.o fbwmax.o fd.o fgrain.o filtrate.o \
      fliquid.o flux.o fsat.o fssest.o ftemp.o fvapri.o fvaprw.o fz.o \
      getinput.o getmet.o\
      init.o insol.o meltzone.o metcalc.o newsnow.o nlimit.o nmelt.o \
      old.o outfiltrate.o polythirdorder.o porosty.o  readtm.o \
      reset.o rtsafe.o sdsol.o skyrad.o soil.o soilchart.o slope.o \
      subdivide.o subtime.o thermal.o thparam.o thrk.o tridiag.o \
      wetbulb.o wlimit.o write.o write2.o zen.o qturb.o

LIB = -lm

default : sntherm

sntherm : $(OBJ)
	f77 -o $@ $(FFLAGS) $(OBJ) $(LIB)
