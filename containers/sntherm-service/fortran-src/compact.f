c***********************************************************************
c COMPACT calculates the  natural compaction rate of snow cover
c***********************************************************************
      subroutine compact(bi,t,bl,overburden,pdzdt,ss,dice,
     1 bwo,flo,floo,dto,unbar,dzo,dzoo,melt,dmlimit,eta0,binew, 
     2 i,n)
c  SNTHERM89.REV4
cxx Routine adapted from e. anderson , p. 82-83.  Units have been changed
cxx to si system.  

c Routine changed extensively in Oct-Nov, 1995. The recommended coeffi-
c cients on the 'overburden' components are those used by Brun 
c et al. (1989), J. of Glac., 35,121.  The cut-off for compaction due
c to destructive metamorphism has been made an input.  The cut-off is
c taken as the smaller of this value and the density of the newly
c fallen snow compacted by 15%.   The cut-off for melt compaction 
c has been lowered to 350 kg/m3, except for the top node, where
c ablation alwalys occurs through a loss in snowdepth.   

c May 12, 1992.  Changes made to add compaction due to snow melt.
c
c CALLED from MAIN
c
c No CALLS to subroutines or functions.
c
c arguments
c
c bi : Nodal bulk density of ice [kg/m^3]
c t : Nodal temperature [K]
c bl : Nodal liquid water bulk density [kg/m^3]
c overburden : pressure of overlying snow [kg/m^2]
c pdzdt : Nodal rate of change in fractional-thickness due to 
c             compaction [fraction/s]
c ss : Effective water saturation = (s - ssi)/(1. - ssi)
c dice : density of ice (917) [kg/m^3]
c bwo : Old nodal bulk water density [kg/m^3]
c flo : Old nodal mass fraction of liquid water
c floo : Nodal mass fraction of liquid water from time period before last
c dto : Old time step [s]
c unbar : Average nodal convective mass flux of water [kg/m^2-s]
c dzo : Old elemental thickness [m]
c dzoo : Elemental thickness from time period before last [m]
c melt : Signifies if node in meltzone if = 1
c
      double precision bi,t,bl,overburden,pdzdt,ss,dice,dmlimit
      double precision bwo,flo,floo,dto,unbar,dzo,dzoo,eta0,binew
      integer melt,i,n
c
c local
c
cNowVariable c1: = 2.777d-7 m2/(kg s).
c c2: = 21d-3 m3/kg.
c changed above t0 value used by Brun et al. 23d-3 m3/kg
c c3: = 2.777d-6 1/s.
c c4: = 0.04 1/k.
c c5: = 2.0. 
c c6: = 5.15d-7.
c c7: = 4d0.
c ddz1: Rate of settling of snowpack due to destructive metamorphism.
c ddz2: Rate of compaction of snowpack due to overburden.
c dexpf: dexpf=dexp(-c4*(273.15-t)).
c dm: Critical density.  Input. Above this, settling function is damped
c nodalmelt : Water flux resulting from nodal melt  [kg/m^2-s]
c ddz3 : Rate of compaction of snowpack due to melt [1/s]
c
      double precision c2,c3,c4,c5,dm,ddz1,ddz2,c6,c7,dexpf
      double precision nodalmelt,ddz3
      data c2,c3,c4,c5/23d-3,2.777d-6,0.04,2.0/
c     data c1,c2,c3,c4,c5,dm/2.777d-7,21d-3,2.777d-6,0.04,2.0,0.15d3/
      data c6/5.15d-7/,c7/4d0/
c Disallow compaction for ice and for water saturated node.
      if(bi  .ge. dice .or. ss .ge. 1.)return
      dexpf=dexp(-c4*(273.15-t))
c Settling as a result of destructive metamorphism
      ddz1=-c3*dexpf
      dm=dmin1(dmlimit,1.15d0*binew)
      if(bi .gt. dm) ddz1=ddz1*dexp(-46.0d-3*(bi-dm))
c Liquid water term
      if(bl .gt. 0.01)ddz1=ddz1*c5
c Compaction due to overburden
c     ddz2=-overburden*c1*dexp(-0.08*(273.15-t)-c2*bi)
      ddz2=-overburden*dexp(-0.08*(273.15-t)-c2*bi)/eta0
c Compaction occurring during melt
      if(melt .gt. 0)then
       nodalmelt=bwo*(flo-floo)*dzo/dto+unbar*(1d0-floo)
c      Changed next on Nov 30, 1992 RJ
c      if(nodalmelt .gt. 0d0)then
       if(nodalmelt .gt. 0d0 .and. bi*dzoo .gt. 0d0
c    &    .and. bi .lt. 800d0)then
     &    .and.(bi .lt. 250d0 .or. i .eq.n))then
         ddz3=-nodalmelt/(bi*dzoo)
       else
         ddz3=0d0
       endif
      else
       ddz3=0d0
      endif
c Time rate of fractional change in dz (units of s-1)
      pdzdt=ddz1+ddz2+ddz3
      return
      end
