c***********************************************************************
c  Subroutine POROSTY calculates porosity of snow/soil medium
c***********************************************************************
      subroutine porosty(dicevol,dmvol,ltype,porosity,solidporosity)
c %W% %G%
c
c Called from density
c
c arguments
c
c dicevol:  Volume fraction of ice
c dmvol : Fractional volume of dry soil material
c ltype : Layer type 1=snow >=90=user supplied soil layer
c                2-3=soil types contained in Block Data file soil
c porosity : fractional volume of voids: between ice matrix in
c                snow and between dry matrix in soil
c solidporosity : Volume of voids between dry soil and ice
c
      double precision dicevol,dmvol,porosity,solidporosity
      integer ltype
c
      if (ltype .le. 1)then
        porosity=1d0-dicevol
        solidporosity=porosity
      else
        porosity=1d0-dmvol
        solidporosity=porosity-dicevol
      endif
      if(porosity .gt. 1d0)porosity=1d0
      if(porosity .lt. 0d0)porosity=0d0
      if(solidporosity .gt. 1d0)solidporosity=1d0
      if(solidporosity .lt. 0d0)solidporosity=0d0
      return
      end
