***********************************************************************
c Function FVAPRI calcluates water vapor pressure(mb) when rh is
c defined relative to saturation over water
c***********************************************************************
      double precision function fvapri(at,rh,e0)
c %W% %G%
c
c Called by MAIN
c
c arguments
c
c at : Air temperature.
c rh : Relative humidity
c e0 :  Saturation vapor pressure at 0 degrees C [mb]
c
      double precision at,rh,e0
c local
c
c f: f=(22.452*(at-273.16))/(at-0.61).
c
      double precision f
c
      if(at .gt. 273.15)then
        f=(17.502*(at-273.16))/(at-32.18)
      else
        f=(22.452*(at-273.16))/(at-0.61)
      endif
      fvapri=rh*e0*dexp(f)/100.
      return
      end
