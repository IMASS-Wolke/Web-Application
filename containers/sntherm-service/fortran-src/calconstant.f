c***********************************************************************
c CALCONSTANT computes constant parameters
c***********************************************************************
      subroutine calconstant(a1snow,bp,bvi0,cdryair,ci0,dlsdrw,
     & height,rw,snowdepth,ssisnow,ssminsnow,thsnow,
     & tlsnow,bvw0,dlvdrw)
c @(#)calconstant.f	1.1 1/25/91

c Arguments 

c a1snow : unfrozen water constant
c bp : approximate average barometric pressure [mb]
c bvi0 : constant for vapor diffusion, with respect to ice
c bvw0 : constant for vapor diffusion, with respect to water
c cdryair : specific heat of dry air [j/kg-k]
c ci0 : specific heat of ice at 273.15 k [j/kg-k]
c dlsdrw : constant for vapor diffusion dls/rw
c dlvdrw : constant for vapor diffusion dlv/rw
c height(3) : height above ground of measured met values
c rw : gas constant for water vapor (461.296) [j/kg-K]
c snowdepth : snow depth [m]
c ssisnow : Irreducible water saturation for snow [.04]
c ssminsnow : -ssisnow/(1d0-ssisnow)
c thsnow : meltzone upper limit temperatures [k]
c tlsnow : meltzone lower limit temperatures [k}

      include 'const'
      include 'arrays'

      double precision a1snow,bp,bvi0,cdryair,ci0,dlsdrw
      double precision height(3),rw,snowdepth,ssisnow,ssminsnow
      double precision thsnow,tlsnow,bvw0,dlvdrw
c
c*** Local
      integer i,ii,j
      double precision dicem,dkm
c  the following loop initializes constants for each layer.  layers are
c  either snow or a selected soil type
      ii=0
      do 13 j=1,ln
c  next specifiies unfrozen water constants
         a1(j)=0.2/(.01+djp(j))
         if(ltype(j).eq. 1)a1(j)=a1snow
         if(ltype(j) .gt.1)a2(j)=.01/(.1+djp(j))
         bdjp(j)=0.75*bd(j)*djp(j)
         a243(j)=a2(j)**(4./3.)
         a213(j)=a2(j)**(1d0/3d0)
         a223(j)=a213(j)*a213(j)
         bdcd(j)=bd(j)*cds(j)
c  next calculates soil constants needed in function thrk for
c     calculating thermal conductivity of soil.
         if(ltype(j) .gt. 1)then
            dkm=7.7**qtz(j)*2.0**(1.0-qtz(j))
            if(icoarse(j).eq.1.and.qtz(j).lt.0.20) then
               dkm=7.7**qtz(j)*3.0**(1.0-qtz(j))
            endif
            dmvol(j)=bd(j)/rhod(j)
            dkmg(j)=dkm**dmvol(j)
            dksatu(j)=dkmg(j)*0.57**(1d0-dmvol(j))
         end if
c  Next computes meltzone limits
         call meltzone(th(j),tl(j),bdjp(j),ci0,bdcd(j),
     2        a1(j),dlm,cl,flglim(j,1),flglim(j,2),
     3        tdl(j,1),tdl13(j,1),tdl(j,2),tdl13(j,2),dice,dmvol(j))
c  Next computes bulk transfer functions for over soil
c  (Coefficients for transfer over snow are computed in QTURB)
         if(ltype(j) .gt. 1)then
           if(cd(j).gt. 900d0)then
             dlogWw(j)=dlog(height(2)/znaught(j))
             sqrtCdn(j)=.4d0/dlogWw(j)
             Cd(j)=sqrtCdn(j)*sqrtCdn(j)
          else
             sqrtCdn(j)=dsqrt(Cd(j))
             dlogWw(j)=.4d0/sqrtCdn(j)
             znaught(j)=height(2)*dexp(-dlogWw(j))
          endif
          Ch(j)=cd(j)/rch(j)
          Ce(j)=cd(j)/rce(j)
          dlogQq(j)=0.4*sqrtCdn(j)/Ce(j)
          dlogTt(j)=0.4*sqrtCdn(j)/Ch(j)
       else
          thsnow=th(j)
          tlsnow=tl(j)
          if(cd(j) .lt. 900d0)then 
             if(cd(j) .gt. 1d0)stop 'Bad input value for Cd'
             write(*,*)'Warning. You may want to input the roughness len
     &gth instead' 
             sqrtCdn(j)=dsqrt(Cd(j))
             dlogWw(j)=.4d0/sqrtCdn(j)
             znaught(j)=height(2)*dexp(-dlogWw(j))
          endif
       endif
c  next loops through all elements within this layer
       do 33 i=1,nn(j)
c         ii is the node subscript
c         k(ii) stores layer subscript corresponding to node ii
          ii=ii+1
          k(ii)=j
          layertype(ii)=soiltype(ltype(j))
          if(ltype(j) .gt. 1)then
c          Soil layer
             if(ii .le. nsoil)soildepth=soildepth+dzo(ii)
             z(ii)=soildepth-dzo(ii)/2.
             call wlimit(bwo(ii),bdjp(j),dice,j
     1            ,ssi(ii),(1d0-dmvol(j)))
cTEMP.      Soil grainsize is not used in SNTHERM.89 and is set to
c           dummy value.
             do(ii) = 1d-4
          else
c          Snow layer
             ssi(ii)=ssisnow
             if(bwo(ii).gt.dice)bwo(ii)=dice
          end if
 33    continue
 13   continue
c  Next calculates constants for vapor diffusion
      dlsdrw=dls/rw
      bvi0=100.*e0*dexp(dlsdrw/273.15)/rw
      dlvdrw=dlv/rw
      bvw0=100.*e0*dexp(dlvdrw/273.15)/rw
c  Calculate snowdepth
      call fz(z,dzo,snowdepth,nsoil,n)
c  Other constants
      dicem=1.d3-dice
      nold=n
      gk(1)=0d0
      gv(1)=1d0
      ssminsnow=-ssisnow/(1d0-ssisnow)
      return
      end
