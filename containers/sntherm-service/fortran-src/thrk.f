c***********************************************************************
c  THRK computes the thermal conductivity of partially saturated soil
c***********************************************************************
      double precision function thrk(t,dicevol,dliqvol,dkmg,
     &     icoarse,dkdry,dksatu,porosity,fl)
c %W% %G%
c
c Called from MAIN
c

c  Method is generally that of Johansen, excerpted from Farouki (1981),
c  Thermal properties of soils,  USA-CRREL Monograph 81-1.
C
C Arguments
c
c t : Nodal temperature [K]
c dicevol : fractional volume of ice
c dliqvol : fractional volume of liquid water
c dkmg : dkm**dmvol, where dkm is the mineral conductivity and
c         dmvol is the fractional volume of dry minerals.
c icoarse : soil coarseness code. 1 = coarse   2 = fine
c dksat : thermal conductivity for saturated soil (j/(k s m))
c dkdry : thermal conductivity for dry soil  (j/(k s m))
c dksatu : Thermal conductivity of saturated soil [W/m-K]
c porosity : fractional volume between soil grains=1.-dmvol
c fl : Element of flo(nd) as called by density.f and combo.f
c
      double precision t,dicevol,dliqvol,dkmg,dkdry,dksatu
      double precision porosity,fl
      integer icoarse
c 
c local
c
c dke : kersten number
c dksat: thermal conductivity for saturated soil (j/(k s m)).
c satw: relative total water content of soil.
c
      double precision satw,dksat,dke
c
      satw=(dliqvol+dicevol)/porosity
c Jan29, 2001  Next  is for pavements. Use input value for bulk pavement. 
      if(porosity .lt. 0.10d0)then
       thrk = dkdry
       return
      endif
      if (t .ge. 273.15) then
c  Unfrozen soil
         if(icoarse .eq. 1)dke = 0.7*dlog10(satw) + 1.0
c Jan 3,2002        if(icoarse .eq. 2)dke = dlog10(satw) + 1.0
         if(icoarse .ne. 1)dke = dlog10(satw) + 1.0
         dksat = dksatu
c Next added on Jan 3,2002
         dke=dmax1(dke,0d0)
         dke=dmin1(dke,1d0)
      else
c  Frozen soil
         dke = satw
         dksat = dkmg*2.49d-1**(fl*porosity)*2.29d0**porosity
      end if
      thrk  =  dke*dksat + (1-dke)*dkdry
      return
      end
