c***********************************************************************
c function FD estimates snow grain size as a function of snow density.
c Routine taken from E. Anderson, eq. 5.1, p. 79-80.  Constants changed
c to si units. This routine is used as a default measure to estimate
c grain sizes if they are not input.
c***********************************************************************
      double precision function fd(bi)
c %W% %G%
      include 'const'
c
c Called by MAIN
c
c argument
c bi : Nodal bulk density of ice [kg/m^3]
c
      double precision  bi
c local
c
c bisqr: bisqr=bi*bi or bi**2.
c
      double precision bisqr
c
c  set grain diameter to zero for pure ice or pure liquid water.
      if( dabs(bi - 0.917d3).lt.dtol1 .or. bi .ge. 1.d3)then
         fd=0.0
      else if(bi .ge. 4.d2)then
         fd=2.976d-3
      else
         bisqr=bi*bi
         fd=1.6d-4+1.1d-13*bisqr*bisqr
c10/24/95        if(fd .lt. 4d-4)fd=4d-4
         if(fd .lt.2.5d-5)fd=2.5d-5
      end if
      return
      end
