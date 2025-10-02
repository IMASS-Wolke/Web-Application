c***********************************************************************
c  SUBDIVIDE subdivides top or next to top node it they exceed 
c  respectively dzn or dznm m. 
c***********************************************************************
c April 4, 1995    subroutine subdivide(dzn,dznm,a1snow,dzinc)
      subroutine subdivide(dzn,dznm,a1snow,dzinc,floo)
      include 'const'
      include 'arrays'
c %W% %G%
c 
c Called from MAIN
c
c Calls DENSITY
c
c Arguments
c
c dzn : surface node maximum thickness [m] after snowfall has stopped
c dznm : node under surface node maximum thickness [m] after snowfall
c        has stopped
c a1snow : unfrozen water constant
c dzinc : maximum thickness for new snow nodes [m]
c
c April 4, 1995  double precision dzn,dznm,a1snow,dzinc
      double precision dzn,dznm,a1snow,dzinc,floo(nd)
c
c Local
c
c bold: Old BB value of node being subdivided (bold=bbo(ndiv)).
c dzold: Old thickness of node being subdivided (dzold=dzo(ndiv)).
c propor: mass/thickness proportion.
c
c Passed through common (nomenclature incomplete)
c
c dzo(nd): Old elemental thickness [m]
c i: nodal index.
c iar: array element index.
c m: array element.
c n: Number of nodes in model
c narray1: Vectors in common block array1 =30 (in ARRAYS)
c narray2: Vectors in common block array2 =24 (in ARRAYS). Should be 
c          increased if vectors are added.
c niarray: Vectors in common block iarray =8 (in ARRAYS). Should be
c          increased if vectors are added.
c ndiv: index denoting node to be subdivided

c 
      double precision propor,dzold,bold
      integer i,iar,m,ndiv
      if(dzo(n) .gt. dzn)then
c  Top node will be subdivided
         write(80,*)'Subdivided Top Node : ',n
         ndiv=n
         goto 30
      else if(dzo(n-1) .gt. dznm .or. dzo(n-1) .gt. .9*dzinc)then
c  Next to top node will be subdivided. Move top node up.
         write(80,*)'Subdivided Node : ',n-1
         ndiv=n-1
         m=n+1
         do 24 iar=1,narray1
            array1(m,iar)=array1(n,iar)
24       continue
         do 25 iar=1,narray2
            array2(m,iar)=array2(n,iar)
25       continue
         do 26 iar=1,niarray
            iarray(m,iar)=iarray(n,iar)
26       continue
         u(m+1)=u(n+1)
         uo(m+1)=uo(n+1)
         layertype(m)=soiltype(ltype(k(n)))
         goto 30
      else
c  No thick node was found
         return
      end if
c
c  Now start subdivision process.  First set all new nodal array values
c  to that of node being subdivided.
c
30    m=ndiv+1
      uvapor(ndiv)=0d0
      do 34 iar=1,narray1
         array1(m,iar)=array1(ndiv,iar)
34    continue
      do 35 iar=1,narray2
         array2(m,iar)=array2(ndiv,iar)
35    continue
      do 36 iar=1,niarray
         iarray(m,iar)=iarray(ndiv,iar)
36    continue
      n=n+1
      nn(k(ndiv))=nn(k(ndiv))+1
      layertype(m)=soiltype(ltype(k(ndiv)))
      if(ltype(k(ndiv)).gt.1)nsoil=nsoil+1
c
c  Now assign 1/3 of mass/thickness to upper node and 2/3 to lower node.
      propor=2./3.
      dzold=dzo(ndiv)
      bold=bbo(ndiv)
      binew(ndiv+1)=binew(ndiv)
      do 10 i=ndiv,ndiv+1
         dzo(i)=dzold*propor
         bbo(i)=bold*propor
c        First melt=0 forces calculation of bl in density
         m=k(ndiv)
         if(ltype(m).le. 1)then
         call density(to(i),bwo(i),td(i),0d0,flo(i),blo(i),bi(i),
     1      bt(i),dmass(i),0d0,0d0,0d0,a1snow,0,dzo(i),
     2      flgo(i),ss(i),dice,ssi(i),porosity(i),dmvol(m),
     3      ltype(m),impermeable(i),idelete(i),
     4      solidporosity(m),ipond(i),dicevol(i),dliqvol(i),rhowater)
         else
         call density(to(i),bwo(i),td(i),td13(i),flo(i),blo(i),bi(i),
     1      bt(i),dmass(i),bdjp(m),a243(m),bd(m),a1(m),0,dzo(i),
     2      flgo(i),ss(i),dice,ssi(i),porosity(i),dmvol(m),
     3      ltype(m),impermeable(i),idelete(i),
     4      solidporosity(m),ipond(i),dicevol(i),dliqvol(i),rhowater)
         endif
         melt(i)=melt(ndiv)
         propor=1./3.
c Next added on April 4, 1995
         floo(i)=flo(i)
 10   continue
      return
      end
