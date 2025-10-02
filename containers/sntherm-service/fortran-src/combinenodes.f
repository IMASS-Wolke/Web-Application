c
c***********************************************************************
c  COMBINENODES checks for elements which are below prescribed minima
c  for thickness or mass. It then determines which neighboring element
c  to best combine with, and executes the combination in routine COMBO.
c***********************************************************************
      subroutine combinenodes(dzmin,a1snow,thsnow,tlsnow,ssisnow)
c %W% %G%
c
c  If snow element thickness is less than a prescribed minimum or
c  element has totally melted, combine with neighboring element.
c  Only one combination of elements is permitted per time step.
c  Idelete=1 if element has totally melted, which is determined
c  within DENSITY.
c
c  Called from: MAIN
c
c  Calls: COMBO,DENSITY, function NMELT
c
      include 'const'
      include 'arrays'
c

c  Arguments
c
c dzmin : minimum nodal thickness (except for precipitation cases) [m]
c a1snow : unfrozen water constant
c thsnow : meltzone upper limit temperatures [k]
c tlsnow : meltzone lower limit temperatures [k}
c ssisnow : irreducible water saturation for snow [.04]
c
      double precision dzmin,a1snow,thsnow,tlsnow,ssisnow
c
c Local
c
c i: Nodal looping index.
c iar: Nodal index in common arrays.
c j: Node index.
c l: Node index.
c m: i+1 nodal array element.
c neighbor: Adjacent node selected for combination.
c
c Passed through common (incomplete list)
c
c dzo(nd) : Old elemental thickness [m]
c dmass(nd) : Elemental mass [kg/m^2]
c idelete(nd) : 1 signifies node to be removed from model 
c iskip(nd) : 1 signifies that convergence criteria are skipped for
c              this node
c ipond(nd) : Ponding flag.  Disallowed for this version
c n : Number of nodes in model
c nn : Number of nodes in each layer type, lowest to surface
c nsoil : Number of soil nodes
c nosnowcover : no snow cover flag 1= no snow cover 0=snow cover
c ltype(ld) : Layer type 1=snow 99=user supplied soil layer
c         2-3=soil types contained in Block Data file soil
c flo(nd) : Nodal fraction of liquid (unfrozen) water due to both
c       capillary and adsorbed potential
c k(nd) : Layer type assoicated with node
c nold : Old number of nodes in model
c ln : Number of different layers
c dt : Current time step [s]
c
c Functions
c
c nmelt: Function NMELT determines if element is in melt state.
c
      integer i,j,l,m,neighbor,nmelt,iar
c
      do 50 i=nsoil+1,n
c Nov 5, 1996      if( ((dzo(i) .lt. dzmin .or. dmass(i) .lt. 100d0*dzmin )
         if( ((dzo(i) .lt. dzmin .or. dmass(i) .lt. 80d0*dzmin )
     &  .and.((snowrate.le.0d0.and.ipond(i).eq.0).or.i.ne.n)).or.
     &   idelete(i) .eq. 1)then
            dt=1d0
c     First determine which neighbor to combine with.  This is
c     generally the thinnest neighbor, except for the cases noted below.
c
c      If top node is removed, combine with bottom neighbor.
            if(i.eq. n)then
               if(nn(ln) .gt. 1)then
                  neighbor=n-1
               else
c             Snow is all gone
                  n=n-1
                  nn(ln)=0
                  nosnowcover=1
c Nov 5, 1966
                  istart=1
		  write(80,'(17h All snow is gone)')
c March28, 1995   return
                  goto 99
               end if
c       If the bottom neighbor is not snow, combine with the top neighbor
            else if(ltype(k(i-1)) .gt. 1)then
               neighbor=i+1
c       If element is entirely melted, combine with bottom neighbor
            else if (flo(i) .ge. 1d0)then
               neighbor=i-1
c       If none of the above special cases apply, combine with the
c       thinnest neighbor
            else
               neighbor=i-1
               if(dzo(i+1) .lt. dzo(i-1))neighbor=i+1
            end if
            goto 60
         end if
 50   continue
c    No thin element was found.  return.
      return
c
c  node l and j are combined and stored as node j.
c
 60   if(neighbor .lt. i)then
         j=neighbor
         l=i
      else
         j=i
         l=neighbor
      end if
      iskip(j)=1
      nold=n
      n=n-1
c
c  Now combine
c
      if(idelete(i) .le.0)then
         write(80,'(7h Nodes ,i4,4h AND,i4,14h combined into,i4)') l,j,j
      else
         write(80,'(6h Node ,i4,36h is totally melted and combined into,
     15h node,i4)')i,j
      endif
c
      call combo(dzo(j),dzo(l),to(j),to(l),bwo(j),bwo(l),dmass(j)
     1     ,dmass(l),bbo(j),bbo(l),dlm,ci(j),tlsnow,dice,a1snow,
     2     dsolo(j),dsolo(l),flo(j),do(l),do(j))
      nn(ln)=nn(ln)-1
      melt(j)=nmelt(to(j),thsnow,tlsnow)
      call density(to(j),bwo(j),td(j),0d0,flo(j),blo(j),bi(j),bt(j),
c Next changed on 3/4/94
c    1     dmass(j),0d0,0d0,0d0,a1snow,melt(j),dzo(j),flgo(j),
     1     dmass(j),0d0,0d0,0d0,a1snow,0,dzo(j),flgo(j),
     2     sso(j),dice,ssisnow,porosity(j),0d0,ltype(k(j)),
     3     impermeable(j),0,solidporosity(k(j)),ipond(j),dicevol(j),
     4     dliqvol(j),rhowater)
c
c Now shift all elements above this down one.
c
      if(n .gt. j)then
      do 150 i=j+1,n
      m=i+1
      do 24 iar=1,narray1
         array1(i,iar)=array1(m,iar)
24    continue
      do 25 iar=1,narray2
         array2(i,iar)=array2(m,iar)
25    continue
      do 26 iar=1,niarray
         iarray(i,iar)=iarray(m,iar)
26    continue
150   continue
      end if
c  zero out arrays for top node
c March 28, 1995      do 20 iar=1,narray1
99    do 20 iar=1,narray1
      array1(nold,iar)=0d0
20    continue
      do 21 iar=1,narray2
      array2(nold,iar)=0d0
21    continue
      do 22 iar=1,niarray
      iarray(nold,iar)=0
22    continue
      uo(n+1)=uo(nold+1)
      u(nold+1)=0d0
      uo(nold+1)=0d0
      return
      end
