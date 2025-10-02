c***********************************************************************
c  ZENITH computes solar zenith angle.  Reference:
c***********************************************************************
      subroutine zen(jday,gmt,dlatt,dlongt,cosz,sind,cosd,xm,ido,hr)
c %W% %G%
c
c Called from INSOL
c
c Nomenclature: Fill in, from Shapiro algorithm.
c Argument
c jday : day from met data
c gmt:  Greenwich mean time
c dlatt : Degrees latitude
c dlongt: Degrees longitude.
c cosz: cos of zenith angle.
c sind: sind=0.397850d0*sin(sigr).
c cosd: cosd=dsqrt((1d0-sind*sind)).
c xm: xm=12d0+0.12357d0*sinp-0.004289d0*cosp+0.153809d0*sin2p
c        +0.060783d0*cos2p.
c ido : flag if = 1 signifies hour = 5 am. used to flag operations done on
c       a daily basis
c hr : local hour angle in radians
c
      double precision gmt,dlatt,dlongt,cosz,xm,hr
      integer jday,ido
c Local
c
c cosp: cosine of phir.
c cos2p: cos(2*phir).
c dlattr: latitude converted to radians.
c frad: converts degrees to radians.
c h: local hour angle in degrees.
c phi: converts met day to solar longitude in degrees.
c phir: phi converted to radians.
c sig: sig=279.9348d0+phi+1.914827d0*sinp-0.079525d0*cosp 
c          +0.019938d0*sin2p-0.001639d0*cos2p.
c sigr: sig converted to radians.
c sind: sine of declination.
c sinp: sine of phir.
c sin2p: sin(2*phir).
c
      double precision phi,phir,
     &sig,sigr,sind,cosd,h,dlattr,frad,sinp,cosp,sin2p,cos2p
c
      frad=.017453292d0
c Recalculate daily at 0500 hours
      if(ido .eq. 1)then
         phi=360d0*(float(jday-1))/365.242d0
         phir=phi*frad
         sinp=dsin(phir)
         cosp=dcos(phir)
         sin2p=2d0*sinp*cosp
         cos2p=2d0*cosp*cosp-1d0
         sig=279.9348d0+phi+1.914827d0*sinp-0.079525d0*cosp
     &    +0.019938d0*sin2p-0.001639d0*cos2p
         sigr=sig*frad
c    compute sin and cos of declination
         sind=0.397850d0*sin(sigr)
         cosd=dsqrt((1d0-sind*sind))
         xm=12d0+0.12357d0*sinp-0.004289d0*cosp+
     &    0.153809d0*sin2p+0.060783d0*cos2p
      end if
c compute local hour angle
      h=15d0*(gmt-xm)-dlongt
      hr=h*frad
      dlattr=dlatt*frad
      cosz=dsin(dlattr)*sind+dcos(dlattr)*cosd*dcos(hr)
      return
      end
