c***********************************************************************
c  QTURB3 returns wind functions qlat and qsen for the turbulent
c  transfer of latent and sensible heat.
c  Upgraded September-November 1996 to correct problems when met
c  instruments are at different levels.  Intrinsic function calls have
c  been made single precision to increase efficiency.
c***********************************************************************
      subroutine qturb3(height,Tkair,Tsurface,wsp,qlat,qsen,csk,dliqvol 
     1 ,cdryair,Cen,Chn,rw,ck,snowdepth,ltype,rce,rch,znaught,Cdn,rhoair
     2 ,bpress,istboff,ratio,icall,icalcstep,wspo,Rb 
     3 ,sqrtCdn,dlogWt,dlogWw,dlogQt,dlogQq,xlimitd)
c
c
c  Called from: MAIN(10),(16)
c
c  Arguments
c
c height : height above ground of measured met values
c tkair : Air temperature [K]
c tsurface :Surface temperature (approximated as temp of top node) [K] 
c wsp : Wind speed [m/s]
c qlat : Wind function (coefficient) for latent heat exchange [W-m/kg}
c qsen : Wind function (coefficient) for sensible heat exchange 
c        [W/(m^2 K)}
c Csk : Windless exchange coefficient for heat
c dliqvol : Volume fraction of liquid water
c cdryair : Specific heat of dry air at 0C.
c Cen : Bulk transfer coefficient for water vapor at neutral stability
c Chn : Bulk transfer coefficient for thermal energy at neutral stability
c Rw : gas constant for water vapor (461.296) [J/kg-K]
c Ck : Windless exchange coefficient for water vapor
c snowdepth : snow depth [m]
c ltype(ld) :Layer type code 
c rce : Cdn/Cen.  At air temperature measurement height
c rch : Cdn/Chn.  At air temperature measurement height.  
c znaught : Roughness length for turbulent transfer of momentum [m]
c Cdn : Drag coefficient at neutral stability
c bpress: Barometric pressure (mb)
c rhoair : Density of air  [kg/m^3]
c istboff:Don't use stab correction if 0, use full correction if 1, set
c         a maximum value on Rb of 0.16 if 2 
c ratio: windspeed computed at air temp height/measured windspeed
c icall: if 1, this is the first call to qturb from MAIN.  If 2, this
c        is the call from MAIN done after thermal balance
c icalcstep: Number of calculation step
c Rbo: Past Richardson number for icall=1, First estimate for icall=2.
c The following are passed in for no-snow case. Computed in calconstant
c sqrtCdn: Square root of Cdn
c dlogWt: Natural log of (htemp/znaught)
c dlogWw: Natural log of (hwsp/znaught)
c dlogQt: Natural log of (htemp/roughness length for moisture)
c dlogQq: Natural log of (hrh/roughness length for moisture)
c xlimitd: Upper limit on x (double precision of xlimit)
c
      double precision height(3),tkair,tsurface,wsp,Cen,Chn,ratio
      double precision qlat,qsen,cdryair,rhoair,rw,Ck,snowdepth,wspo
      double precision rce,rch,znaught,Cdn,Csk,dliqvol,bpress,Rbo
      double precision sqrtCdn,dlogWt,dlogWw,dlogQt,dlogQq,xlimitd
      integer ltype,icall,icalcstep,ipass
c
c  Local
c 
c dum: dummy variable.
c F: Unstable integral stability function for momentum 
c F2: F at measurement height for wsp or rh.
c hrh: height above snowpack for relative humidity measurement
c      (hrh=height(3)-snowdepth).
c htemp: height above snowpack for temperature measurement
c      (htemp=height(1)-snowdepth).
c hwsp: height above snowpack for wind speed measurement
c      (hwsp=height(2)-snowdepth).
c ipass: Number of passes through iterative solution for Rb
c Next 3 variables Stabx are the stability corrections
c Stabm: sqrt(Cd/Cdn), where Cd is the bulk transfer coefficient
c        for momentum (drag cofficient)
c Stabh: (Ch/Chn)/Stabm, where Ch is the bulk transfer coefficient
c         for heat
c Stabe: (Ce/Cen)/Stabm, where Ce is the bulk transfer coefficient
c        for water vapor
c Rb: Bulk Richardson number at air temp measurement height.
c Ri: Gradient Richardson number at air temp measurement height. 
c Ri2: Gradient Richardson number at measuremnt height for wsp or rh.
c x: Parameter for computing unstable correction=(1-16Ri)**0.25.
c xlimit: Upper limit on x
c zeta: Stability parameter = htemp/Monin-Obukhov length
c zeta2: Zeta at measuremnt height for wsp or rh

c
      double precision Stabh,Stabe,Stabm,htemp,hwsp,hrh,dum,Rb
      double precision zeta,zeta2,Rb1
      real*4 x,F,F2,Ri,Ri2,xlimit
      integer i
c
c 1.Checks to be sure instrument's heights are above snow (or grass)
       do 683 i=1,3
       if (height(i).le.snowdepth)then
	  write(*,*) '  **Met Instruments Are Not Above Snow!!**'
	  stop '**Error in Layer.in, Line 3.  Execution Terminated'
       endif
683    continue
c
c  2. Next computes bulk transfer functions over snow/ice at neutral stability.
c      Bulk transfer functions for soil are constant for the run and are  
c      computed in CALCONSTANT.f
      if(ltype .eq. 1)then
         htemp=height(1)-snowdepth
         hwsp=height(2)-snowdepth
         hrh=height(3)-snowdepth
c        User can input either Cdn or znaught. If Cdn=900, the program 
c        assumes that znaught is input and it computes Cdn.
c        The transfer coefficients at neutrality are computed at the air  
c        temperature measurement height
         if(Cdn.gt. 900d0)then
            dlogWt=alog(sngl(htemp/znaught))
            sqrtCdn=.4d0/dlogWt
            Cdn=sqrtCdn*sqrtCdn
         else
            sqrtCdn=sqrt(sngl(cdn))
            dlogWt=.4d0/sqrtCdn
         endif
c        Adjusts for different in roughness lengths
         if(dabs(rch-1d0) .gt. 1d-4)then
          Chn=Cdn/rch
         else
          Chn=Cdn
         endif
         if(dabs(rce-1d0) .gt. 1d-4)then
          Cen=Cdn/rce
          dlogQt=0.4*sqrtCdn/Cen
         else
          Cen=Cdn
          dlogQt=dlogWt
         endif
c       Adjusts for different measurement heights
         if(dabs(htemp-hwsp).gt. 0.1d0)then
           dlogWw=alog(sngl(hwsp/znaught))
           if(icalcstep .le.1)ratio=dlogWt/dlogWw
c          Otherwise ratio passed in as value from past iteration.
         else
           dlogWw=dlogWt
           ratio=1d0
         endif
         if(dabs(htemp-hrh).gt. 0.1d0)then
           dlogQq=alog(sngl(hrh/htemp)) + dlogQt
         else
           dlogQq=dlogQt
         endif
      else
         htemp=height(1)
         hwsp=height(2)
         hrh=height(3)
         if(icalcstep .le.1)ratio=dlogWt/dlogWw
         if(dabs(htemp-hwsp).le. 0.1d0)ratio=1d0
      endif
c  2b. Estimate windspeed at tempeature measurement height from
c      past ratio of wspT/wsp
      wspT=wsp*ratio
c
c  3. Next computes stability correction.
c  Procedure is described in R. Jordan, "Estimating Turbulent Transfer 
c  Functions for use in Energy Balance Models", U.S. Army Cold Regions
c  Research and Engineering Lab, Internal Report 1107, April 1992. Eq.
c  numbers refer to that report.  Note: These equations are only valid
c  if measurements are made at the same levels.
c 
      ipass=1
      Rb1=Rbo
c
c  BEGIN ITERATIVE SOLUTION.  Iteration only required when hwsp .ne. htemp
c
c    Compute Bulk Richardson number Rb (eq 17)
25    Rb=19.6*htemp*(tkair-tsurface)/((tkair+tsurface)*wspT*wspT)

c Set optional maximum on Richardson number when istboff = 2.
      if(istboff .eq. 2)Rb=dmin1(Rb,0.16d0)
c
c    NEUTRAL atmospheric conditions.
        if (Rb .eq. 0d0)then
           Stabm=1d0
           Stabh=1d0
           Stabe=1d0
c
c    STABLE atmospheric conditions.
c
       else if(Rb .gt. 0d0)then     
         if(istboff .eq.1)then
           Stabm=1d0
           Stabh=1d0
           Stabe=1d0
         else if(Rb .ge. 0.2d0)then
c   Next set to finite values (not 0) to avoid division by zero
           Stabm=1d-12
           Stabh=1d-12
           Stabe=1d-12
         else 
c          Next utilizes eqs. 19a-19c
           if(rch .ne. 1)then
            dum=(2d0-rch)*(2d0-rch)-4d0*(1d0-rch)*(1d0-5d0*Rb)
            Stabm=(2d0-rch-sqrt(sngl(dum)))/(2d0*(1-rch))
           else 
            Stabm=1d0-5d0*Rb
           endif
           Stabh=Cdn*Stabm*(1d0-Stabm)/(Chn*5d0*Rb)
           Stabe=Cdn*Stabm/(Cen*(rce*Stabm+(1d0-Stabm)))
         endif
         zeta=0.4*Chn*Stabh*Rb/(Cdn*sqrtCdn*Stabm*Stabm)
         if(dabs(htemp-hwsp) .gt. 0.1d0)then
          zeta2=hwsp*zeta/htemp
          wspT=wsp*(dlogWt+5d0*zeta)/(dlogWw+5d0*zeta2)
         endif
c
c     UNSTABLE atmospheric conditions
c     Computes Gradient Richardson Number (Ri) from Bulk Number (Rb)
c 
      else
c     First estimate Ri, x, and F using neutral values Chn and Cdn
c     (eqs 20, 11, 12 and 14)
        Ri=Rb*.4d0*Chn/(Cdn*sqrtCdn)
c     Set an upper limit on x so that reciprocal stability corrections 
c     are approximately 2
      if(ipass .le. 1 .and. ltype .le. 1)then
       dum=sqrtCdn/(11.315736 + 1.0/sqrtCdn)
       if(Chn .lt. dum .and. Cen .lt. dum)then
        xlimit=(8.* exp(sngl(.2/sqrtCdn)+1.57)  )**.25
       else if( Cen .gt. Chn)then
        xlimit=(4.* exp(sngl(.2*sqrtCdn/Cen))  )**.25
       else
        xlimit=(4.* exp(sngl(.2*sqrtCdn/Chn))  )**.25
       endif
      elseif(ltype .gt. 1)then
       xlimit=sngl(xlimitd)
      endif
        x=amin1((1.0-16.0*Ri)**0.25,xlimit)
        F=alog((1+x*x)/2.0)+2.0*alog((1.0+x)/2.0)-2.0*atan(x)+1.57
c
c     Using these estimates, compute stability functions and get
c     new esimate for Ri.  (Eq. 21-after some manipulation)
        Stabm=1.0/(1.0-sqrtCdn*F/.4)
        Stabh=1.0/(1.0-2.0*Chn*alog((1+x*x)/2.0)/(.4*sqrtCdn))
        Ri=Ri*Stabh/(Stabm*Stabm)
c
c     Get adjusted values for x and F and use these to compute
c     final values for stability correction.
        x=amin1((1.0-16.0*Ri)**0.25,xlimit)
        F=alog((1.0+x*x)/2.0)+2.0*alog((1.0+x)/2.0)-2.0*atan(x)+1.57
        Stabm=1.0/(1.0-sqrtCdn*F/.4)
        Stabh=1.0/(1.0-2.0*Chn*alog((1+x*x)/2.0)/(.4*sqrtCdn))
        Stabe=1.0/(1.0-2.0*Cen*alog((1+x*x)/2.0)/(.4*sqrtCdn))

        if(dabs(htemp-hwsp) .gt. 0.1d0)then
         Ri2=hwsp*Ri/htemp
         x=amin1((1.0-16.0*Ri2)**0.25,xlimit)
         F2=alog((1.0+x*x)/2.0)+2.0*alog((1.0+x)/2.0)-2.0*atan(x)+1.57
         wspT=wsp*(dlogWt-F)/(dlogWw-F2)
        endif
      end if
c Make up to three passes to correct for simultaneous solution of Rb
c and wspT.  Do next block if ipass .lt. 3 and the criertia not met.
      if(dabs(Rb-Rb1) .gt. 0.005 .and. ipass .lt. 3
     &   .and. dabs(htemp-hwsp) .gt. 0.1d0)then
       ipass=ipass+1
       Rb1=Rb
       goto 25
      endif
      Rbo=Rb
      ratio=wspT/wsp
c
c  4. Compute semi-empirical exchange coefficients as defined in eqs. 22.
c  and 23  The empirical parameters Ck and Csk are limits for windless 
c  exchange.  They need to be replaced later by theorectical functions.

c  Adjust qlat if humidity and air temp are measured at different levels.
      if(dabs(hrh-htemp) .gt. 0.1d0)then
        zeta2=zeta*hrh/htemp
        Stabe=Stabe*(dlogQt+5.*zeta)/(dlogQq+5.*zeta2)
      endif
      if(dliqvol .gt. 0.020 .or. tsurface .gt. 273.15)then
c     Vapor at equilibrium with respect to water
        qlat= Ck+Stabm*Stabe*Cen*2.5045d8*wspT/(rw*tkair)	
      else
c     Vapor at equilibrium with respect to ice
        qlat= Ck+Stabm*Stabe*Cen*2.838d8*wspT/(rw*tkair)	
      endif
c    Gas constant for dry air (287J/kg-K) is from "Handbook of 
c    Meteorology,"Berry, et al, 1945, McGraw-Hill, p. 353.
      rhoair=1d2*bpress/(287d0*tkair)      
      qsen = Csk + cdryair*rhoair*Chn*Stabm*Stabh*wspT
      return
      end
