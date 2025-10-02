C***********************************************************************
c Function DBLCURVE computes the slope of the freezing curve, based on 
c the method of I.E. Guryanov. (1985): "Thermal-physical characteristics 
c of frozen, thawing and unfrozen ground."  Fourth International
c Symposium on Ground Freezing, Sapporo.
c***********************************************************************
      double precision function dblcurve (td,bw,bdjp,a1,a243,td13,flg,
     &melt)
c
c Note: DBLCURVE is defined here as the change in bl per unit Td,
c whereas F in the Technical Report (eq. 4.18) is the change in frac-
c tional liquid water (bl/bw) per unit time.
c
c CALLED by thparam
c   
c Arguments
c
c td : Nodal depression temperature, t-273.15.  [K]
c bw : Nodal water constituents bulk density [kg/m^3]
c bdjp : 0.75*Dry soil bulk density*plasticity index (0.75*bd*djp)
c a1 : Constant in unfrozen water formula
c a243 : a2^^(4/3)
c td13 : Nodal temperature depression from 0 C raised to (1/3) power
c flg :
c melt :

      double precision td,bw,bdjp,a1,a243,td13,flg
      integer melt
c 
c Local
c
c a1flg: a1flg=a1*flg.
c dum: dum=a243*td13.
c f2: f2=1.33333*dum*bdjp /(tdum*tdum).
c tdum: tdum=1.+td*dum.
c
      double precision a1flg,dum,tdum,f2
c
      if((a1*td .gt. 1.d3 .or. td .le. 0.0) .and. melt .lt. 1)then
c        The slope of the freezing curve is arbitrarily set to 0 for
c        a1*Td>1000.
         dblcurve=0.0
      else
         a1flg=a1*flg
         dblcurve=2*td*a1flg*a1flg*(bw-bdjp)
      end if
      if(bdjp .gt. 0.0) then
         dum=a243*td13
         tdum=1.+td*dum
         f2=1.33333*dum*bdjp /(tdum*tdum)
         dblcurve=dblcurve+f2
      end if
      return
      end
