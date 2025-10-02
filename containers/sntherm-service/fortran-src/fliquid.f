C***********************************************************************
c  Function FLIQUID calculates liquid water as a function of temperature
c  and water content. Based on Method of I. E. Guryanov. (1985):
c "Thermal-physical characteristics of frozen, thawing and unfrozen 
c  ground."  Fourth International Symposium on Ground Freezing, Sapporo.
c***********************************************************************
      double precision function fliquid(bw,td,bdjp,a243,td13,flg)
c %W% %G%
c 
c Called from MAIN,DENSITY,THERMAL
c
c arguments
c
c bw : Nodal water constituents bulk density [kg/m^3]
c td : Nodal depression temperature, t-273.15.  [K]
c bdjp : 0.75*Dry soil bulk density*plasticity index (0.75*bd*djp)
c a243 : a2^^(4/3)
c a2 : Constant in unfrozen water formula
c td13 : Nodal temperature depression raised to (1/3) power
c flg :  Fraction of unfrozen capillary water
c
      double precision bw,td,bdjp,a243,td13,flg
c
       if(td.lt.0.0)stop 'negative value for td found in function fliqui
     1d'
       fliquid=(bw-bdjp)*flg
c  Note: flg fractionis calculated in routine DENSITY.
       if(bdjp .gt. 0.0)fliquid=fliquid+bdjp/(1.+a243*td13*td)
      return
      end
