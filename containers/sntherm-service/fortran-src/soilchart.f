      
c***********************************************************************
c  Subroutine SOILCHART supplies soil characteristics
c***********************************************************************
      subroutine soilchart(ii,j,iunit)
c %W% %G%
      include 'const'
      include 'arrays'
c
c Called from MAIN

c arguments
c
c ii : index variable
c j : index or loop variable
c iunit: unit file number 
      integer ii,j,iunit
c
c local
c
c i: Index=ii-1
c
      integer i
c
c Passed through common
c
c rhod(ld): Intrinsic density of dry soil material [kg/m^3]
c bd(ld): Bulk density of dry soil material [kg/m^3]
c cds(ld): heat capacity of dry mineral solids
c dkdry(ld): Dry soil thermal conductivity [W/m-K]
c icoarse(ld): Soil coarseness code (1=coarse  2=fine)
c djp(ld): Plasticity index
c alb(ld): Material-layer albedo
c em(ld): Material-layer hemispherical emissivity
c scharc(8,ld): Array defined as follows:
c columns of scharc are 1) intrinsic density of dry mineral solids
c                       2) bulk density of substance
c                       3) heat capacity of dry mineral solids
c                       4) thermal cond of dry bulk substance
c                       5) coarseness code 1=coarse  2=fine
c                       6) plasticity index
c                       7) albedo (normal incidence)
c                       8) emissivity
c soiltype(numsoiltype): Name of soil type (Chacracter variable)
c

c
      i=ii-1
      if(ii .lt. 90)then
         rhod(j)=scharc(1,i)
         bd(j)=scharc(2,i)
         cds(j)=scharc(3,i)
         dkdry(j)=scharc(4,i)
         icoarse(j)=dint(scharc(5,i))
         djp(j)=scharc(6,i)
         alb(j)=scharc(7,i)
         em(j)=scharc(8,i)
      else
         read(iunit,*)soiltype(ii),rhod(j),bd(j),cds(j),dkdry(j),
     &        icoarse(j),djp(j),alb(j),em(j)
      end if
      return
      end
