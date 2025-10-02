c***********************************************************************
c Function FVAPRW calculates water vapor pressure(mb) when rh is
c defined relative to saturation over water
c***********************************************************************
      double precision function fvaprw(at,rh,e0)
c %W% %G%
c
c Called by MAIN
c
c Arguments
c
c at : Air Temperature.
c rh : Relative humidity
c e0 :  Saturation vapor pressure at 0 degrees C [mb]
c
      double precision at,rh,e0
c Local
c
c f: f=(17.502*(at-273.16))/(at-32.18)
c
      double precision f
c
      f=(17.502*(at-273.16))/(at-32.18)
      fvaprw=rh*e0*dexp(f)/100.
      return
      end
