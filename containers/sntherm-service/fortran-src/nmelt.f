c***********************************************************************
c  Function NMELT determines if element is in melt state.
c***********************************************************************
      integer function nmelt(t,th,tl)
c %W% %G%
c
c Called by combinenodes, reset and MAIN
c
c Arguments
c
c t : Nodal temperature [K]
c th : Upper meltzone temperature limit [K]
c tl : Lower meltzone temperature limit [K]
      double precision t,th,tl
      if(t .gt. th .or. t .lt. tl)then
         nmelt=0
      else
         nmelt=1
      end if
      return
      end
