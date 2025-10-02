c***********************************************************************
c  DIFFUSION computes mass diffusive vapor flux within snowcover.
c***********************************************************************
      subroutine diffusion(de0,bp,bvi0,dlsdrw,frh,dlvdrw,bvw0)
c
c Called from MAIN
c
      include 'const'
      include 'arrays'
c
c Arguments
c
c de0 : effective diffusion coefficient for water vapor in snow  
c          [m^2/s] at 1000mb and 273.15k
c bp : approximate average barometric pressure [mb]
c bvi0 : constant for vapor diffusion, with respect to ice
c bvw0 : constant for vapor diffusion, with respect to water
c dlsdrw : constant for vapor diffusion dls/rw
c dlvdrw : constant for vapor diffusion dlv/rw
c frh : Fractional saturation of water vapor
      double precision de0,bp,dlsdrw,bvi0,frh(ld),vaporvol,dlvdrw
      double precision bvw0
c
c Local
c
c de: diffusion coefficient.
c i: looping index.
c
      integer i
      double precision de,dum
c
c Passed through common (incomplete)
c
c df(nd)     : Coefficient for vapor diffision
c              = de*change in sat. vapor pressure with temp
c uvapor(nd) : Net diffusive mass flux of water vapor for element [Kg/m^2 s]
c ufvapor(nd : "Average" diffusive flux at nodal centroid [(upper+
c              lower)/2]. Used in computation of graingrowth.[Kg/m^2 s]               
c dbvdt(nd)  : 1)Variation in saturated vapor density with temp 2) Variation
c        in saturated bulk vapor density with temp=vaporvolr*(1)  [kg/m^3 s]
c vaporvol(nd): volume fraction available for vapor
c
c
c  Vapor flux from surface of bare soil. (Vapor flow within soil
c  disallowed for SNTHERM.89)
c
      if(n .le.nsoil)then
       if(dliqvol(n) .gt. 0.02. or. t(n) .gt. 273.15)then
         uvapor(n)=-(eao-frh(k(n))*eso)*qlato/dlv
       else
         uvapor(n)=-(eao-frh(k(n))*eso)*qlato/dls
       endif
        if(qlat .eq. 0)uvapor(n)=0d0
         return
      endif
c      
c  Snow nodes only for this model version    
c
      do 10 i=1,n
      if(ss(i) .lt. 1d0 .and. porosity(i) .gt. 0d0)then
c       Compute diffusion coefficient
         if(ltype(k(i)) .eq. 1)then
c        For snow
            de=de0*(1000./bp)*(to(i)/273.16)**6d0
         else
c        For soil.  From Farouki, p. 55
c        Note:  Soil option is not included in this version
           de=0.161d-5*porosity(i)*(1000./bp)*(to(i)/273.)**2.3d0
c            de=0d0
         endif
         if(ltype(k(i)) .eq. 1)then
          if(dliqvol(i) .gt. 0.02)then
           dbvdt(i)=bvw0*dexp(-dlvdrw/to(i))*(dlvdrw/to(i)-1.0)/to(i)**2
          else
           dbvdt(i)=bvi0*dexp(-dlsdrw/to(i))*(dlsdrw/to(i)-1.0)/to(i)**2
          endif
           df(i)=de*dbvdt(i)
           vaporvol=solidporosity(i)-dliqvol(i)
           dbvdt(i)=vaporvol*dbvdt(i)
         else
           dbvdt(i)=0d0
           df(i)=0d0
           vaporvol=solidporosity(i)-dliqvol(i)
           dbvdt(i)=vaporvol*dbvdt(i)
         end if
      else
c  vapor diffusion cannot occur within a water saturated element
        df(i)=0d0
        dbvdt(i)=0d0
      end if
10    continue
c
c  Vapor flux across lower nodal boundary
      do 20 i=nsoil+1,n
      if(df(i).le.0d0 .or. df(i-1).le.0d0 .or. ltype(k(i)).gt.1)then
      uvapor(i)=0d0
      else
      uvapor(i)=2*df(i-1)*df(i)*(to(i)-to(i-1))/(dzo(i)*df(i-1)+dzo(i-1)
     &*df(i))
      end if
20    continue
c
c  Vapor flux across upper nodal boundary, net flux and "average" flux
c  at centroid (used in grain growth algorithm)
      do 30 i=nsoil+1,n-1
      if(df(i).gt.0d0 .and. df(i+1).gt.0d0 .and. ltype(k(i)).eq.1)then
      dum=
     &2*df(i)*df(i+1)*(to(i+1)-to(i))/(dzo(i+1)*df(i)+dzo(i)*df(i+1))
      ufvapor(i)=0.5d0*(dabs(uvapor(i))+dabs(dum))
      uvapor(i)=uvapor(i)-dum
      end if
30    continue
c Note:mass vapor flux across air interface is (eao-frh*eso)*qlato/dls
      if(dliqvol(i) .le. 0.02)then
c       dum=(eao-frh(k(i))*eso)*qlato/dls
        dum=(eao-frh(k(n))*eso)*qlato/dls
      else
c       dum=(eao-frh(k(i))*eso)*qlato/dlv
        dum=(eao-frh(k(n))*eso)*qlato/dlv
      endif
      ufvapor(n)=0.5d0*(dabs(uvapor(n))+dabs(dum))
      uvapor(n)=uvapor(n)-dum
      return
      end
