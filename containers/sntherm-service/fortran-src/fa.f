c***********************************************************************
c  Function FA computes coefficient 'a' used in estimating mass water
c  flow u through snow as a function of effective water saturation ss,
c  where u = -a*ss**3 in kg/(s m**2).  Maximum permeability of snow
c  to the liquid water phase is estimated from algorithm of Shimizu.
c***********************************************************************
c
c  Called by FILTRATE
c
      double precision function fa(d,bi,bd,ss)
c %W% %G%
c arguments
c
c d :  Nodal snow effective grain diameter (m)
c bi : Nodal bulk density of ice [kg/m^3]
c bd : Bulk density of dry soil material [kg/m^3]
c ss : Effective water saturation = (s - ssi)/(1. - ssi)
c
      double precision bi,d,ss,bd
c
c Note: Saturated flow and flow in soil disallowed for this version
      if(ss .lt. 0.0 .or. (ss .ge. 1.0 .and. bd .le.0.))then
         fa=0.0
      else
         fa=4.2129d8*d*d*dexp(-7.8d-3*(bi+bd))
      end if
      return
      end
