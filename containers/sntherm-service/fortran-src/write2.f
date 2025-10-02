ci**********************************************************************
c  ABBREVIATED OUTPUT
c  This routine was rewritten on 10/12/94 to produce abbreviated output.
c  Programmer:Ceretha McKenzie

c  WRITE generates principal output file. Parameters for the top node
c  are printed following the completion of a basic time step (in sync
c  with time periods when met values are provided).  Full snow/soil
c  profiles are printed at an optional time interval specified in the
c  input parameter IPRNT
c***********************************************************************
      subroutine write2(pinv,ibasestep,imin,ihour,iy,jday,icalcstep,
     &      meltflux, fmt)
c %W% %G%
c Called from MAIN
c
      include 'const'
      include 'arrays'
c arguments
c
c pinv : major print-out interval [hr]
c ibasestep: Current number of basestep from start of problem
c imin: Minute of simulation, (read from met time-hack)
c ihour : Hour of simulation, (read from met time-hack) 
c iy : Year of simulation: last 2 digits, (read from met time-hack)
c jday : Julian day of simulation, (read from met time-hack)
c icalcstep : current number of calcultions from start of problem
c             balance eq, expressed in units of temperature [K]
c fmt : format (2 or 3)
c
      integer ibasestep,imin,ihour,iy,jday,icalcstep
      double precision pinv
      double precision meltflux
      integer fmt
c 
c Local
c
c i: looping index variable.
c m: m=k(i).
c tsg: t(sg)  = Predicted Snow/Ground Interface Temperature (K).
c precip : Precip type. S=snow, R=rain (character string)
c phase : Phase state, F, T or M (character string)
c
c Passed through common (incomplete)
c
c snowrateo : Old snow rate [m/s]
c rainrateo : Old Rain Rate [m/s]
c n : Number of nodes in model
c k : Layer type assoicated with node
c t : Nodal temperature [K]
c th(ld) : Upper meltzone temperature limit [K]
c tl(ld) : Lower meltzone temperature limit [K]
c
      integer i,m
      double precision tsg
      character*1 precip,phase(nd)
      double precision swe, depth, cold
      integer iout,isoil

      if(ibasestep .eq. 2 .or.((ibasestep)/pinv-dint((ibasestep
     &)/pinv)) .lt. 1d-7 .or. pinv .eq. 99)then
	iout = 1
      else 
      	if (fmt .eq. 2)then 
		goto 34
	else
		iout = 0
	endif
      endif

      if (fmt .eq. 2)then 
	isoil=nsoil
      else
	isoil=1
      endif


      precip=' '
      if(snowrateo.gt.0.0) precip='S'
      if(rainrateo.gt.0.0) precip='R'

      swe=0d0
      depth=0d0
      cold=0d0

      do 10 i=1,n
	 if(i .gt.nsoil) then
		swe=swe+(dz(i)*bw(i))
		depth=depth+dz(i)
		cold=cold+bw(i)*dz(i)*ct(i)*(273.15-t(i))
	 endif
         m=k(i)
         if(t(i).gt.th(m)) then
            phase(i)='T'
         elseif(t(i).lt.tl(m)) then
            phase(i)='F'
         else
            phase(i)='M'
         endif
 10   continue

      if(n .gt. nsoil)then
         tsg= (t(nsoil)*dz(nsoil+1)+t(nsoil+1)*dz(nsoil))/
     &     (dz(nsoil+1)+dz(nsoil))
      else
         tsg=t(nsoil)
      endif

c Print-out results of this iteration. Order of print-out for time-hack and
c profile changed of 10/12/94. Time-hack is now first

         write(80,53)iy,jday,ihour,imin,t(n),tsg,tkair,n,
     &        phase(n),icalcstep,precip,swe,depth,-meltflux,cold

  53   format(i2,i4,1x,i3,i3,2x,3f11.3,2x,i4,1x,a1,i7,1x,a1,'|',3f11.3,
     &        1f13.1)
c
c  Print nodal profiles
c
      if(pinv .gt. dtol1)then

      if(iout .eq. 1) then
         write(80,61)(i,phase(i),dz(i),z(i)-soildepth,t(i),bt(i),bw(i),
     &        bl(i),ct(i),thk(i),d(i),layertype(i),i=n,isoil,-1)

 61   format('+',/,
     & 102(i3,1x,a1,3x,f8.5,3x,f8.5,4x,f8.3,3(2x,f10.4),3x,
     & f8.1,3x,f8.5,1x,f8.6,a10,/)/)

      endif
      endif

 34   continue
      return
      end
