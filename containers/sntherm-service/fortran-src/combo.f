c***********************************************************************
c  COMBO combines two elements and returns the following combined 
c  parameters:dz,bw,t,dmass,bbo,dsolo,flo and do.  Most of the remaining
c  combined nodal-parameters are computed by a subsequent call to
c  DENSITY.
c***********************************************************************
      subroutine combo(dz,dz2,t,t2,bw,bw2,dmass,dmass2,bbo,bbo2,dlm,ci,
     1     tl,dice,a1,dsolo,dsolo2,flo,do,do2)
c %W% %G%
c
c CALLED from COMBINENODES
c
c CALLS functions fbwmax,rtsafe,polythirdorder
c
c arguments
c
c dz, dz2 : Nodal thickness of 2 elements being combined [m]
c t, t2  : Nodal temperature of 2 elements being combined [K]
c bw, bw2 : Nodal water constituents bulk density [kg/m^3]
c dmass,dmass2  : Nodal mass of 2 elements being combined [kg/m^2].
c bbo , bbo2 : Old nodal conducted and convected heat plus absorbed solar
c dlm : Latent heat of fusion for ice(3.335E5) [J/kg]
c ci  : Specific heat of ice        [J/kg-K]
c tl : Lower meltzone temperature limit [K]
c dice : density of ice (917) [kg/m^3]
c a1 : Constant in unfrozen water formula
c dsolo, dsolo2  : Old nodal solar energy absorbed [W/m^2]
c flo  : Nodal fraction of liquid (unfrozen) water due to both capillary
c          and adsorbed potential
c do, do2 :  Old nodal effective grain diameter [m]
      double precision dz,dz2,t,t2,bw,bw2,dmass,dmass2,bbo,bbo2
      double precision dlm,ci,tl,dice,a1,dsolo,dsolo2,flo,do,do2
c
c local
c
c a: a=ci*ch+dlm*dmassliq/dmassc.
c asq: asq=(a1*td)*(a1*td)
c bl, bl2 : Nodal liquid water bulk density [kg/m^3]
c bwc: Combined nodal water constituents bulk density of nodes 1 and 2 [kg/m^3]
c bwmax: Maximum nodal water constituents bulk density [kg/m^3]
c ch: Dummy variable
c dmassc: Combined mass of nodes 1 and 2.
c dmassliq: Combined liquid water mass of nodes 1 and 2.
c dzc: Total thickness of nodes 1 and 2 (dzc=dz+dz2).
c est: Estimated root (temperature in K) of polynomial. 
c p: Coefficient of y**2 in polynomial (p=a/ci).
c q: Coefficient of y in polynomial (q=1/(a1*a1)).
c r: Constant in polynomial (r=(a-dlm)/(ci*a1*a1)). 
c td, td2 : Nodal depression temperature of elements 1 and 2 in Celsius.
c y: Temperature solved for in polynomial.
c yacc: Accuracy tolerance of root.
c y1: Lower bound of y.
c y2: Upper bound of y.
c
      double precision dzc,dmassc,bwc,td,td2,bl,bl2,dmassliq,ch,a
      double precision p,q,r,y,est,asq,bwmax
      double precision y1,y2,yacc
c
c functions
c
c fbwmax: bulk water density function.
c rtsafe: finds root of a function.
c
      double precision fbwmax,rtsafe
c
c external
c
      external polythirdorder
      dzc=dz+dz2
      dmassc=dmass+dmass2
      bwc=dmassc/dzc
      bbo=bbo+bbo2
      dsolo=dsolo+dsolo2
      do=(do*dmass+do2*dmass2)/dmassc
c
c Nov 2
c     if(t .lt. tl .and. t2 .lt. tl)then
c        t=(dmass*t+dmass2*t2)/dmassc
c     else
c    next is case where one or both elements are melting. the sum of the
c    enthalpies of the two separate elements is equated with that of the
c    combined element, and the resulting non-linear equation solved for
c    t.
         td=273.15-t
         td2=273.15-t2
         bl=bw/(1+(a1*td)*(a1*td))
         bl2=bw2/(1+(a1*td2)*(a1*td2))
         dmassliq=(bl*dz+bl2*dz2)
         flo=dmassliq/dmassc
         ch=-(dmass*td+dmass2*td2)/dmassc
         a=ci*ch+dlm*dmassliq/dmassc
         p=a/ci
         q=1/(a1*a1)
         r=(a-dlm)/(ci*a1*a1)
c next solves the polynomial y**3+p*y**2+q*y+r using the newton-
c raphson iteration technique, where y=tdc.
         y=-ch
         y1=dmin1(td,td2)
         y2=dmax1(td,td2)
         yacc=1.0d-5
c Nov 2, 1998
         yacc=1.0d-7
         est=rtsafe(polythirdorder,y1,y2,yacc,p,q,r)
         t=273.15-est
c Nov 2, 1998
         td=est
         asq=(a1*td)*(a1*td)
c Nov 2, 1998
         flo=1d0/(1d0+asq)
         bwmax=fbwmax(dice,1d0/(1d0+asq),1d0)
         if(bwc .gt. bwmax)bwc=bwmax
c     end if
      dmass=dmassc
      dz=dzc
      bw=bwc
      return
      end
