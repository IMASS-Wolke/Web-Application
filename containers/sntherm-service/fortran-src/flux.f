c***********************************************************************
c  Subroutine FLUX creates output file containing summary of surface
c  fluxes and meteorological parameters
c***********************************************************************
      subroutine flux(jday,ihour,ibasestep,iptype,height,iy,clearness,
     &  imin,isolarcalc,effceiling,islope,ffmt)
c %W% %G%
c
c Called from MAIN 
c
      include 'const'
      include 'arrays'
c arguments
c
c jday : Julian day of simulation, (read from met time-hack)
c ihour : Hour of simulation, (read from met time-hack)
c ibasestep: Current number of basestep from start of problem
c initial : Flag =1 for first calculation then set to 0
c iptype : precipitation type (from met data) 1= rain 2 =snow
c height : height above ground of measured met values
c iy : Year of simulation: last 2 digits, (read from met time-hack)
c clearness: approximate clearness factor for the sky
c imin: Minute of simulation, (read from met time-hack)
c isolarcalc: Estimate solar radiation flag 2=estimate missing values only 
c             1=yes 0=no
c islope : Adjust solar radiation for slope  1=yes  0=no
c effceiling: Effective cloud ceiling, computed in GETMETc 
c 
c July 10 1996 - added bert's output format  (jcm)
c ffmt: format type 1=default -1=bert's
c
      integer jday,ihour,ibasestep,iptype,iy,imin,isolarcalc,islope
      double precision height(3),clearness,effceiling
      integer ffmt
c
c local
c
c dqest: net change in heat content of snowcover(dqest=solar+dlong+hg+
c        sensheat+dlatheat).
c i: index of array height.
c type: Precipitation type
c     :type = 'R' means rain.
c     :type = 'S' means snow.
c     :type = ' ' otherwise.
c doheading : Logical flag. T=print heading   F=do not print heading
c doformat945 : T=use format 945 for first print of hour=0 or 12 
c       F=use format 928.
c
c Passed through common
c
c solar: Net solar radiative flux [W/m^2]
c dlong: Net long wave radiative flux
c hg: Geothermal heat flux (across snow/soil interface) [W/m^2]
c sensheat: Turbulent flux of sensible heat [W/m^2]
c dlatheat: Turbulent flux of latent heat [W/m^2]
c prcp: Precipitation Value (m/hour)
c tkair: Air temperature [K]
c wsp: Wind speed [m/s]
c rh: Relative humidity
c
      integer i
      double precision dqest
      character*1 type
      logical doheading,doformat945

c July 10 1996 - added bert's output format  (jcm)

      double precision dtime

      if(ffmt .eq. 2) then

         dqest=solar+dlong+2d0*hg+sensheat+dlatheat
c Dec 1, 1997      dtime=jday + (ihour / 24.0) + (imin / 60.0)
         dtime=jday + (ihour / 24.0) + (imin / 1440.0)

         write(7,2)dtime,solar,dlong,sensheat,dlatheat,2d0*hg,dqest
 
2        format(f8.4,2x,6(f6.1,6x))
         goto 10

      endif

      if(initial .eq.1)doheading=.true.      
      doformat945=.true.
      if(iptype.eq.1) then
         type='R'
      elseif(iptype.eq.2) then
         type='S'
      else
         type=' '
      endif
440   format(/,t12,'change in',t48,'*components*',t95,'*meteorological c
     &onditions*')
41    format('date-time heat content net solar   net longw   heat from
     & sensible     latent    ',' prcp ','   ',f4.2,'m    ',f4.2,
     &'m',3x,f4.2,'m',4x,'cloud    cloud')
42    format(t11,'of snowpack  radiation  radiation      soil    heat tr
     &ansfr heat transfr','      ','    temp     wnsp     rh    ceiling'
     &,'   cover')
      if((ihour .eq. 0 .or. ibasestep .eq. 1) .and. doheading)then
         write(7,440)
         write(7,41)(height(i),i=1,3)
         write(7,42)
         write(7,51)
         doheading=.false.
      end if
      if(ihour .ne. 0)doheading=.true.
c
cJune 25, 1996      dqest=solar+dlong+hg+sensheat+dlatheat
      dqest=solar+dlong+2d0*hg+sensheat+dlatheat
c     if(ihour .ne. 0 .or. ihour .ne. 12)doformat945=.false.
      if(isolarcalc .eq. 0 .and. islope .eq. 0)then 
        if((ihour.eq.0.or.ihour.eq.12).and. doformat945)then
cJune 25,1996  write(7,945)iy,jday,ihour,imin,dqest,solar,dlong,hg,
         write(7,945)iy,jday,ihour,imin,dqest,solar,dlong,2d0*hg,
     &   sensheat,dlatheat,prcp,type,tkair-273.15,wsp,rh
945     format(i2,'/',i3,1x,i2,1x,i2,f6.1,3x,'|',2x,f6.1,6x,f6.1,3x,3(
     &  2x,f6.1,4x),'|',1x,f5.3,1x,a1,2(1x,f6.2,2x),1x,f5.0,'**N/A***')
         doformat945=.false.
        else
cJune 25, 1996         write(7,928)ihour,imin,dqest,solar,dlong,hg,
         write(7,928)ihour,imin,dqest,solar,dlong,2d0*hg,
     &   sensheat,dlatheat,prcp,type,tkair-273.15,wsp,rh
928      format(7x,i2,1x,i2,f6.1,3x,'|',2x,f6.1,6x,f6.1,3x,3(2x,
     &   f6.1,4x),'|',1x,f5.3,1x,a1,2(1x,f6.2,2x),1x,f5.0,'**N/A***')
         doformat945=.true.
        endif
      else
       if((ihour.eq.0.or.ihour.eq.12) .and. doformat945)then
cJune 25, 1996  write(7,45)iy,jday,ihour,imin,dqest,solar,dlong,hg,sensheat,
        write(7,45)iy,jday,ihour,imin,dqest,solar,dlong,2d0*hg,sensheat,
     &   dlatheat,prcp,type,tkair-273.15,wsp,rh,effceiling,1d0-clearness 
45       format(i2,'/',i3,1x,i2,1x,i2,f6.1,3x,'|',2x,f6.1,6x,f6.1,3x,3(
     &   2x,f6.1,4x),'|',1x,f5.3,1x,a1,2(1x,f6.2,2x),1x,f5.0,2f9.2)
         doformat945=.false.
       else 
cJune 25, 1996 write(7,28)ihour,imin,dqest,solar,dlong,hg,sensheat,dlatheat
        write(7,28)ihour,imin,dqest,solar,dlong,2d0*hg,sensheat,dlatheat
     &,prcp,type,tkair-273.15,wsp,rh,effceiling,1d0-clearness
28     format(7x,i2,1x,i2,f6.1,3x,'|',2x,f6.1,6x,f6.1,3x,3(2x,
     &f6.1,4x),'|',1x,f5.3,1x,a1,2(1x,f6.2,2x),1x,f5.0,2f9.2)
         doformat945=.true.
       endif
      end if
51    format (9x,6('  (w/m**2)  '),'   (m) ','   (degr c)  (m/s)    (%)
     &  (1000m)  (frac)'/)
10    return
      end
