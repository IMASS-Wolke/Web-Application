c***********************************************************************
c  Subroutine FBB returns the sum of one-half the nodal net conductive
c  and convective energy fluxes and the nodal absorbed solar energy,
c  defined as bb.  This is done for efficiency purposes, to preclude
c  repeated re-summation of these terms, which appear of the
c  right-hand-side of the heat equation.
c***********************************************************************
      subroutine fbb(qk,t,dsol,qf,topflux,bb,n,heatfluxbtop,nsoil)
c %W% %G%
c
c  Called by MAIN
c
c  arguments
c
c qk : .5*(thermal conductivity at upper nodal boundary/nodal thickness), 
c t : Nodal temperature [K]
c dsol : Nodal absorbed solar radiation
c qf : .5*specific heat of water*nodal mass water flux 
c topflux: Energy flux across air/media interface, excluding solar 
c          flux [W/m^2]
c to : Old nodal temperature [K]
c bb : .5*(Nodal conducted and convected heat plus absorbed solar)
c n : Number of nodes in model
c heatfluxbtop : .5*Heatflux across bottom of top node [W/m^2]
c
      integer n
      double precision qk(n),qf(n),t(n),dsol(n),topflux,bb(n)
      double precision heatfluxbtop
c  local
c
c heatfluxb : .5*Heatflux across lower boundary of node [W/m^2]
c heatfluxt:  .5*Heatflux across upper boundary of node [W/m^2]
c i        : looping index.
c nsoil    : Number of soil nodes
c
      double precision heatfluxb,heatfluxt
      integer i,nsoil
      heatfluxb=0.0
      do 20 i=1,n
creinstate next later, and omit subsequent statement.
c     if(i .lt. n)then
      if(i .lt. n .and. i .gt. nsoil)then
         heatfluxt=qk(i+1)*(t(i+1)-t(i))+qf(i+1)*t(i+1)
ctemp Next branch is part of temporary sink. Omit later.
      else if(i .ne. n .and. i .le. nsoil)then
         heatfluxt=qk(i+1)*(t(i+1)-t(i))
ctemp
      else
         heatfluxt=0d0
         heatfluxbtop=heatfluxb
      end if
ctemp.  Omit later
      if(i .eq. nsoil+1)heatfluxb=heatfluxb+qf(i)*t(i)
ctemp
      bb(i)=heatfluxt-heatfluxb+.5*dsol(i)
      heatfluxb=heatfluxt
20    continue
      bb(n)=bb(n)+topflux
      return
      end
