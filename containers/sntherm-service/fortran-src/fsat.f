c***********************************************************************
c  Function FSAT calculates the effective saturation of snow
c***********************************************************************
      double precision function fsat(bl,porosity,ssi,ssim)
c %W% %G%
c  ssi = intrinsic saturation (threshold where water flow commences)
c  ssim=1.-ssi
c
c Called by density
c
c arguments
c
c bl : Nodal liquid water bulk density [kg/m^3]
c porosity : fractional volume of voids: between ice matrix in
c                snow and between dry matrix in soil
c ssi : Irreducible water saturation (0.04)
c ssim: =1d0-ssi
c
      double precision bl,porosity,ssi,ssim
c
      if(bl .gt. 0d0 .and. porosity .gt.0d0)then
         fsat=((bl/(1.d3*porosity))-ssi)/ssim
      else
         fsat=-ssi/ssim
      end if
      if(fsat .gt. 1d0)fsat=1d0+1d-7
      return
      end
