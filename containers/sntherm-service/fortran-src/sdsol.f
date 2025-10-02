c***********************************************************************
c Subroutine SDSOL computes absorption of solar radiation within snow
c cover.  Equation for extinction coefficient is eq. 4.26 from
c e. anderson, p.58, where the constant cv is 3.795d-3 (si units), p.80.
c***********************************************************************
      subroutine sdsol(dsol,d,dmass,fext,depth,nsoil,n,solar,bext)
c %W% %G%
c  dsol= shortwave radiation absorbed within element
c  tsolt= transmission to top of element
c  tsolb= transmission to bottom of element
c  dmass=bw*dz   d=grain diameter   cv=empirical constant(see above)
c
      include 'const'
c
c Called from MAIN
c
c arguments
c
c dsol= shortwave radiation absorbed within element
c d=grain diameter
c dmass=bw*dz
c fext(nd) : Nodal transmission coefficient for the solar flux, 
c            exp(-cv*dmass) or exp(-cv*dmass)*exp(-bext*.002)
c depth : solar penetration limit [m]
c nsoil : Number of soil nodes
c n : Number of nodes in model
c solar : Net solar radiative flux [W/m^2]
c bext : Snow extinction coefficient for near-IR

      integer nsoil,n
      double precision dsol(nd),d(nd)
      double precision dmass(nd),fext(nd),depth,solar,bext
c local
c
c cv: empirical constant (3.795d-3 (si units)).
c i: nodal index.
c j: array index (j=n+nsoil+1-i).
c tmass: total mass.
c tsolb: transmission to bottom of element.
c tsolt: transmission to top of element.
c
      integer i,j
      double precision tsolt,cv,tmass,tsolb
c
      tsolt=solar
      cv=3.795d-3
      tmass=0.0
      fext(nsoil)=0d0      
      do 10 i=nsoil+1,n
         j=n+nsoil+1-i
         tmass=tmass+dmass(j)
c  a maximum mass-depth for solar penetration is assumed, and fext is
c  not computed below this
         if(tmass .gt. depth)goto 30
         if(d(j).le.0.0) then
            write(*,*) 'node = ',j
            stop '** ERROR SDSOL: Grain Diameter <= 0.0. Execution Stopp
     &ed**'
         end if
         fext(j)=dexp(-cv*dmass(j)/dsqrt(d(j)))
         if(j .eq. n)then
            fext(n)=dexp(-bext*2d-3)*fext(n)
         end if
 10   continue
c  30   do 20 i=nsoil+1,n
c     j=n+nsoil+1-i
30    do 20 i=2,n
      j=n+2-i
         if(tsolt .le. 0d0)then
            dsol(j)=0d0
         else
            tsolb=tsolt*fext(j)
            dsol(j)=tsolt-tsolb
            tsolt=tsolb
         end if
 20   continue
      return
      end
