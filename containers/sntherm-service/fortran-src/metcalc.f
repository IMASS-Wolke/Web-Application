C***********************************************************************
c  METCALC is a user supplied routine to generated hypothetical met
c  data
c***********************************************************************
      subroutine metcalc(jday,ihour,imin,tkair,rh,wsp,prcp,iptype,
     &   dsnowfall,cover,icl,initial,dtbase,shadow)
c %W% %G%
c
c  Calling routine:  MAIN
c
c  Arguments
c
c jday : day from met data
c ihour : met data hour
c imin: Met Data Minute.
c tkair : Air temperature [K]
c rh : Relative humidity
c wsp : Wind speed [m/s]
c prcp : Precipitation Value (m/hour)
c iptype : precipitation type (from met data) 1= rain 2 =snow
c dsnowfall:  Effective grain diameter of falling snow particle (m)
c cover(3) : Fractional cloud cover
c icl(3) : Cloud type code
c initial : Flag =1 for first calculation then set to 0
c dtbase : basic time interval between input meteorological data [s]
c shadow: .8d0 if dcos(float(iseconds)*pi/360d0) > .5d0, 0d0 otherwise.
c
      double precision tkair,rh,wsp,prcp,dsnowfall,cover(3),dtbase
      double precision shadow
      integer jday,ihour,imin,icl(3),initial,iptype
c  Local
c 
c dum: dum=dcos(float(iseconds)*pi/360d0)
c iseconds: time of day in seconds.
c pi: pi=3.14159265.
c
       double precision dum,pi
       integer iseconds
c
      pi=3.14159265
      pi=3.14159265
      if(initial .eq.1)then
        jday=36
        ihour=0
        imin=0
        iseconds=dble(3600)*dble(ihour)+dble(60)*dble(imin)
      else
        iseconds=iseconds+dint(dtbase)
        if(iseconds .gt. 86399)iseconds=dble(0)
        ihour=int(sngl(float(iseconds)/3600d0))
        imin=sngl(iseconds-dble(3600)*dble(ihour))
        imin=int(float(imin)/60.)
      endif
      tkair=273.15d0
      rh=100d0
      wsp=0d0
      prcp=3.60d-2
      if(initial.eq.1)prcp=0d0
c      write(80,*)'prcp=',prcp,iseconds
      if(iseconds .ge. 10800)prcp=0d0
      if(iseconds .gt. 20000)stop
      iptype=1
      dsnowfall=0d0
      dum=dcos(float(iseconds)*pi/360d0)
cc    if(dum .gt. .5d0)then
cc       cover(1)=.1d0
cc       shadow=.8d0
cc    else
cc       cover(1)=.1d0
cc       shadow=0d0
cc    endif
      cover(2)=1d0
      cover(3)=1d0
      cover(1)=1d0
      icl(1)=4
      icl(2)=3
      icl(3)=2
      return
      end
