c***********************************************************************
c Function FGRAIN returns the new grain diameter
c***********************************************************************
c
      double precision function fgrain(g1,g2,ufvapor,do,dliqvol,dt)
c
      include 'const'
c %W% %G%
c
c  Called from MAIN 
c
c  Arguments
c
c  g1 : Constant in grain growth for dry snow (= 5.0d-7 in MAIN)
c  g2 : Constant in grain growth for wet snow (= 4.0d-12 in MAIN)
c  ufvapor : "Average" diffusive flux at nodal centroid [(upper
c           +lower)/2]. Used in computation of graingrowth. [kg/m^2]              
c  do:  Old nodal effective grain diameter [m]
c  dliqvol:  Volume fraction of liquid water
c  dt :  Current time step [s]
c
      double precision g1,g2,ufvapor,do,dliqvol,dt
c
      if(do .le. 0d0)stop 'Execution halted in FGRAIN because do =< 0'
      if(dliqvol .lt.1d-4)then
c     Note: Cut-off bewtn dry and wet snow arbitrarily set at 0.0001
        if(dabs(ufvapor) .lt. 1.0d-6)then
c       Note: Max vapor flux available for growth arbitrarily set at 1d-6
          fgrain=do+dt*g1*dabs(ufvapor)/do
        else
          fgrain=do+g1*dt *1.0d-6/do
        endif
      else
        if(dliqvol .lt. 0.09)then 
          fgrain=do+g2*dt*(dliqvol+0.05d0)/do        
        else
          fgrain=do+g2*dt*0.14d0/do
        endif
      endif
      return
      end
