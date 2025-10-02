c***********************************************************************
c  Subroutine FZ computes snowdepth and nodal mid-point positions
c  relative to snow/soil interface
c***********************************************************************
      subroutine fz(z,dz,snowdepth,nsoil,n)
c %W% %G%
      include 'const'
c
c Called by MAIN
c
c arguments
c
c z : Nodal Cumulative distance from snow/soil interface to
c         centroid of node [m]
c dz :  Nodal thickness [m]
c snowdepth : snow depth [m]
c nsoil : Number of soil nodes
c n : Number of nodes in model
c
      integer nsoil,n
      double precision z(nd),dz(nd),snowdepth
c local
c
c i: looping index.
c
      integer i
      snowdepth=0d0
      z(1)=dz(1)/2.
      do 10 i=2,n
         if(i.ge. nsoil+1)snowdepth=snowdepth+dz(i)
            z(i)=z(i-1)+(dz(i-1)+dz(i))/2.
 10   continue
      return
      end
