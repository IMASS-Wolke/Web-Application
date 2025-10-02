c***********************************************************************
c  NLIMIT determines boundaries (element numbers) of zones
c  where there is contiguous water flow, where potential water
c  flow is assumed when the effective saturation ss exceeds 0.0.
c  Fifteen separate zones are provided for; the first dimension in
c  ibound must be increased if this number is exceeded.'
c***********************************************************************
      subroutine nlimit(ibounds,nzone)
c %W% %G%
      include 'const'
      include 'arrays'
c
c  Called from MAIN
c
c  arguments
c
c ibounds(15,2) : boundaries (element numbers) of flowzones, where
c      ibounds(i,1)=upper boundary and ibounds(i,2)=lower boundary
c nzone : number of flowzones of contiguous water flow
c      
      integer ibounds(15,2),nzone
c  local
c
c i: looping index.
c j: second array element of ibounds.
c j1: flag to increment number of zones where there is contiguous water flow.
c n: Number of nodes in model
c nsoil: Number of soil nodes
c impermeable: 1 = Node impermeable to water, 0 = Not.  See DENSITY
c sso: Old effective water saturation
c 
      integer j,j1,i
c
c  initialize ibounds to 0
      do 5 i=1,15
      do 5 j=1,2
      ibounds(i,j)=0
5     continue
c
      nzone=0
c Next added on Jan 29,2002
      if(n .le. nsoil)return
      j1=1
c Reinstate later: Temp sink created at snow/ground interface
c      do 10 i=n,1,-1  
      do 10 i=n,nsoil+1,-1
c Changed back on March 06,2002     do 10 i=n,nsoil,-1
c Set top of zone.  Loop from top down until a node with mobile water is
c found.  Set this as the upper boundary and increment j1 from 1 to 2.
      if(sso(i) .gt. 0d0 .and. j1 .lt. 2)then
        nzone=nzone+1
       if(nzone.gt.15)stop '**execution halted in nlimit. dimensions on i
     1bounds exceeded 15 and must be increased.**'
        ibounds(nzone,1)=i
        if(i .eq. nsoil+1)ibounds(nzone,2)=i !Added on March 13,2002
        j1=j1+1
c
c Set bottom of zone.  Only activate these branches when j1 = 2.
      else if(sso(i) .le. 0d0 .and. j1 .gt. 1)then
        ibounds(nzone,2)=i+1
        j1=1
      else if(impermeable(i) .ge. 1 .and. j1 .gt. 1)then
        ibounds(nzone,2)=i+1
        j1=1
c Remove later (temp for sink)
      else if (j1 .gt. 1 .and. i .eq. nsoil + 1)then ! Mar 13,2002
        ibounds(nzone,2) = nsoil + 1
        j1=1
c Remove later
      else 
        continue
      end if
10    continue
      return
      end
