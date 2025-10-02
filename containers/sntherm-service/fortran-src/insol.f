c***********************************************************************
c  Subroutine INSOL computes direct and diffuse solar radiation using
c  method of R. Shapiro (Need to complete documentation here)
c***********************************************************************
      subroutine insol(dlatt,dlongt,jday,cover,icl,prcp,salb,gmt,
     &sdown,cosz,sind,cosd,xm,sdowne,ido,direct,
     &diffuse,hr,isolarcalc)
c
      include 'const'
c %W% %G%
c
c Calls zen
c 
c Called from MAIN
c
c Arguments
c
c dlatt : Degrees latitude
c dlongt: Degrees longitude.
c jday : day from met data
c cover(3) : Fractional cloud cover
c icl(3) : Cloud type code
c prcp : Precipitation Value (m/hour)
c salb : Albedo of surface node (salb=alb(k(n)))
c gmt:  Greenwich mean time
c sdown : Incident solar radiative flux [W/m^2]
c cosz: cos of zenith angle.
c sind: sind=0.397850d0*sin(sigr).
c cosd: cosd=dsqrt((1d0-sind*sind)).
c xm:          xm=12d0+0.12357d0*sinp-0.004289d0*cosp+
c     &    0.153809d0*sin2p+0.060783d0*cos2p.
c sdowne: Solar insolation corrected for Earth's elliptical orbit.
c ido : flag if = 1 signifies hour = 5 am. used to flag operations done on
c       a daily basis
c direct : Direct component of insolation.
c diffuse: diffuse component of solar radiation sdown.
c hr: local hour angle (calculated in subroutine zen).
c
      double precision cover(3),dlatt,dlongt,salb,gmt,sdown,prcp
      double precision xm,sind,cosd,sdowne
      double precision direct,diffuse,hr
      integer icl(3),ido,jday
c Local
c
c cosz: cos of zenith angle.
c coszcube: cube of cosz.
c coszsq: square of cosz.
c d1: d1=1d0-(rk(1)*rk(2)).
c d2: d2=1d0-(rk(2)*rk(3)).
c d3: d3=1d0-(rk(3)*rg).
c dtol1: dtol1 = 1.0d-12
c fr: fr=cover(i).
c i: looping index.
c j: j=icl(i).
c l: array element.
c pi: pi=3.14159265.
c rcld(4): Reflectivity for clear skies
c       =r2(j,1)+r2(j,2)*cosz+r2(j,3)*coszsq+r2(j,4)*coszcube.
c rclr(4): Reflectivity for cloudy skies
c       =r1(l,1)+r1(l,2)*cosz+r1(l,3)*coszsq+r1(l,4)*coszcube.
c rk(3): Combined reflectivity of clear and cloudy skies.
c rg: Albedo of ground (rg=salb).
c r1(4,4): reflectance factor array for clear part of sky, stored in DINSOL
c r2(4,4): reflectance factor array for clouded part of sky, stored in DINSOL
c sdown0: sdown0=1369.2d0*sdowne*cosz.
c tcld(4): Transmissivity for cloudy skies
c          =t2(j,1)+t2(j,2)*cosz+t2(j,3)*coszsq+t2(j,4)*coszcube.
c tclr(4): Transmissivity for clear skies
c          =t1(l,1)+t1(l,2)*cosz+t1(l,3)*coszsq+t1(l,4)*coszcube.
c tdk(3): Direct componenet of tk(3).
c tk(3): Combined transmissivity of clear and cloudy skies.
c t1(4,4): transmittance factor array for clear part of sky, stored in DINSOL.
c t2(4,4): transmittance factor array for clouded part of sky, stored in DINSOL.
c wgt: Total weighted cloud fraction.
c wt(4,6): cloud cover factor array, stored in DINSOL.
c icla(3): cloud type code (icla(1)=icl(3),icla(2)=icl(2),
c          icla(3)=icl(1))
c covera(3): cloud cover fraction (covera(1)=cover(3),covera(2)=cover(2),
c          covera(3)=cover(1))

c
      double precision rk(3),tk(3),pi,cosz,sdown0,wgt,rcld,tcld,fr,tclr
      double precision coszsq,coszcube,d3,d2,rg,d1,rclr
      double precision r1,r2,t1,t2,wt,tdk(3),covera(3)
      integer icla(3),isolarcalc
  
c Arrays r1,r2,t1,t2,and wt are initialized in block data dinsol.f
      common /insolc/  r1(4,4),r2(4,4),t1(4,4),t2(4,4),wt(4,6)
      integer i,j,l
c
      pi=3.14159265
c initialize sdown
      sdown=0d0
c  calculate cosine of zenith angle
      call zen(jday,gmt,dlatt,dlongt,cosz,sind,cosd,xm,ido,hr)
c
c comput extra-terrestrial insolation
c  account for variation of sun/earth distance due to
c  eliptical orbit. Redone daily at 0500 hours.
      if(ido .eq.1)then
        sdowne=2d0*pi*float((jday-2))/365.242d0
        sdowne=(1.0001399d0+0.0167261d0*cos(sdowne))
        sdowne=sdowne*sdowne
        if(isolarcalc .eq.2 .and. sdown .lt. 9d3)return
      end if
c  if sun is below horizon - no need to go on
      if(cosz.le.0d0) then
         sdown=0d0
         direct=0.0
         diffuse=0.0
         return
      endif
c
      coszsq=cosz*cosz
      coszcube=coszsq*cosz
      sdown0=1369.2d0*sdowne*cosz
c Equate cloud array elements of Shapiro (high=1, midddle=2, low=3) with
c those of SNTHERM (high=3, middle=2, low=3)
      icla(1)=icl(3)
      icla(2)=icl(2)
      icla(3)=icl(1)
      covera(1)=cover(3)
      covera(2)=cover(2)
      covera(3)=cover(1)
c  if precipitation is reported, cover type and fraction
c  are completely determined
      if(prcp .le. dtol1)goto10
c  prcpitation is reported
      covera(1)=1d0
      covera(2)=1d0
      covera(3)=1d0
      icla(1)=2
      icla(2)=3
      icla(3)=4
10    continue
      do 1000 i=1,3
c
c  Initialize parameters
c
         wgt=0d0
         rcld=0d0
         tcld=0d0
         rclr=0d0
         tclr=0d0
         j=icla(i)
         fr=covera(i)
         l=i
c     if(isg.eq.1.and.i.eq.3)l=4.  Smoke/fog not included in this version
         if(j.eq.0)goto 800
c
         wgt=wt(j,1)+wt(j,2)*cosz+wt(j,3)*fr+wt(j,4)*cosz*fr
     &        +wt(j,5)*coszsq+wt(j,6)*fr*fr
         wgt=wgt*fr
c
         if(fr.lt. 0.05d0)wgt=0d0
         if(fr.gt. 0.95d0)wgt=1d0
c
         if(wgt .gt. 0d0)then
            rcld=r2(j,1)+r2(j,2)*cosz+r2(j,3)*coszsq+r2(j,4)*coszcube
            tcld=t2(j,1)+t2(j,2)*cosz+t2(j,3)*coszsq+t2(j,4)*coszcube
         end if
c
c  Compute reflectivity and transmitivity for each layer
c
 800     if(wgt .lt. 1d0)then
            rclr=r1(l,1)+r1(l,2)*cosz+r1(l,3)*coszsq+r1(l,4)*coszcube
            tclr=t1(l,1)+t1(l,2)*cosz+t1(l,3)*coszsq+t1(l,4)*coszcube
         end if
         rk(i)=wgt*rcld+(1d0-wgt)*rclr
         tk(i)=wgt*tcld+(1d0-wgt)*tclr
c
c  Direct componenet of tk
c
         tdk(i)=tk(i)-rk(i)
         if(tdk(i) .lt. 0d0)tdk(i)=0d0
 1000 continue
c calculation of insolation at the ground-sdown

      rg=salb
      d1=1d0-(rk(1)*rk(2))
      d2=1d0-(rk(2)*rk(3))
      d3=1d0-(rk(3)*rg)
      sdown=d1*d2-(rk(1)*rk(3)*tk(2)*tk(2))
      sdown=d3*sdown-(d1*rk(2)*rg*tk(3)*tk(3))
      sdown=sdown-(rk(1)*rg*tk(2)*tk(2)*tk(3)*tk(3))
      sdown=(tk(1)*tk(2)*tk(3)*sdown0)/sdown
      if(sdown.le.0d0) then
         sdown=0d0
         direct=0.0
         diffuse=0.0
      else
c
c  Direct component of insolation
c
         direct=tdk(1)*tdk(2)*tdk(3)*sdown0
c
c  Diffuse component of insolation
c
         diffuse=sdown-direct
      endif
      return
      end
