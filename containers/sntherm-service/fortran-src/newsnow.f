c***********************************************************************
c  NEWSNOW adds new nodes. New precip is added in elements of thickness 
c  dzinc (default 4cm for snow/1cm for rain). Precip is combined with
c  existing mass within an element until thickness dzinc is reached. 
c  Excess precip is placed in a new top element.  After precip stops, 
c  if top element exceeds dzn or next to top element exceeds dznm, 
c  they are subdivided within SUBDIVIDE. Maximum timestep 'snowfalldtmax' 
c  is set to preclude more than one new node being added per iteration.
c***********************************************************************
      subroutine newsnow(rate,rateo,dzinc,bwfall,ssminsnow,dsnowfall,
     &   repeat,ssisnow,blfall,fullnode,a1snow)
c sntherm89.rev4 
c IMPORTANT. THIS ROUTINE WAS REVISED IN NOV, 1995 TO ACCEPT
c SWE RATHER THAN SNOW ACCUMULATION AS THE PRECIP RATE.
c
c Called from MAIN
c
      include 'const'
      include 'arrays'
c
c Arguments
c rate, rateo:  Is snowrate(o) or rainrate(o) when called from MAIN
c dzinc: Thickness of element of new precip addition (default 4cm/1cm)
c wifall: Bulk density of newly fallen snow (dry + wet)
c         (0d2 if rainfall occurs)
c ssminsnow : -ssisnow/(1d0-ssisnow)
c ssisnow : irreducible water saturation for snow [.04]
c dsnowfall:  Effective grain diameter of falling snow particle (m)
c repeat : logical flag denoting a repeat of this iteration (if true)
c blfall: Bulk density of liquid precipitation
c fullnode: Flag used to indicate whether top node is full (dz exceeds dzinc)
c a1snow : unfrozen water constant
c
      double precision rate,rateo,dzinc,bifall,ssminsnow,dsnowfall
cNov13,1995      double precision ssisnow,blfall,a1snow,bwfall,binew(nd)
      double precision ssisnow,blfall,a1snow,bwfall
      logical fullnode,repeat
c Local
c 
c avrate: average of old and current precipitation rate 
c April 4. Now using current value for avrate.
c         (avrate=(rate+rateo)/2d0).
c dum: dum=a1snow*(273.15d0-to(n))
c dzfall: dzfall=avrate*dt.
c
c Passed through common (incomplete list)
c
c bbo(n)
c bwo(nd)
c d(nd),do(nd) :
c ddztp(nd) : Chnage in nodal thickness due to added precip [m/s]
c dt: Current time step [s]
c dzo(nd): Old nodal thickness [m]
c ipond(nd): For case of rain falling on impermeable layer,set ipond to 1
c        Note: Ponding disallowed in this version
c impermeable(nd): 1 = Node impermeable to water, 0 = Not.  See DENSITY
c        Note: Impermeable node disallowed in this version
c istart: Snow just started flag 1=yes 0=no
c k(nd) :
c n: Number of nodes in model
c newelm: Number of new nodes to be added to model
c nosnowcover: no snow cover flag 1= no snow cover 0=snow cover
c nn(ln)
c nold: Old number of nodes in model
c porosity(nd) :
c ss(nd): Effective water saturation = (s - ssi)/(1. - ssi)
c sso(nd): Old effective water saturation
c to(nd) : Old nodal temperature [K]
c u(nd) :
c unbar(nd) :
c us(nd) : Mass flux of snow [kg/m^2]
c 
c
      double precision dzfall,avrate
c
c  Calculate rate of change in element thickness due to snow falling
c  during this iteration
c
      nold=n
c March28, 1995   avrate=(rate+rateo)/2d0
      avrate=rate
c    Precip has just started or previous top node is full.  Initiate a
c    new node.
      if((istart .eq.1 .and. .not. repeat).or. fullnode)then
         newelm=1
         nosnowcover=0
         n=n+newelm
        if(n .gt.nd)stop '**Number of nodes has exceeded array size**'
         us(n)=-1d3*avrate
         bifall=bwfall-blfall
         ddzdtp(n)=avrate*1d3/bifall
c        u(n+1)=-blfall*rate
         istart=0
         fullnode=.false.
         binew(n)=bifall
c    Precip is continuing.  Add precip to top node.
      else
         newelm=0
         us(n)=-1d3*avrate
         bifall=bwfall-blfall
         ddzdtp(n)=avrate*1d3/bifall
	 dzfall=ddzdtp(n)*dt
      end if
c
c  If top node is full (dz exceeds dzinc), initiate a new top node
c  for the NEXT iteration.
      if(dzfall+dzo(n) .ge. dzinc)fullnode=.true.
c
c  If there is a new node, initiate necessary parameters
c
      if(newelm .gt. 0)then
         k(n)=ln
         nn(ln)=nn(ln)+newelm
c      Next will cause new nodes to be retained in case of repeat iteration
         nold=n
c
         write(80,*) 'New element ',n,' has been added'
c       Note that the new node is initialized with 0. bulk density and is
c       augmented by an amount u or us in sec. 13.
         to(n)=tprecip
         bwo(n)=0d0
         bbo(n)=0d0
         bifall=bwfall-blfall
         flo(n)=flfall
         if(blfall .lt. 9d2)then
c        snow is being added
           ss(n)=ssminsnow
           sso(n)=ssminsnow
           ssi(n)=ssisnow
           porosity(n)=1d0-bifall/dice
           unbar(n)=0d0
           u(n)=0d0
           u(n+1)=0d0
           do(n)=dsnowfall
           d(n)=dsnowfall
c Next lines were redundant. Removed on Nov 4, 1995.
c         Next assures tnat max water content of falling snow is 20% 
c          if(to(n) .lt. 273.15-(2d0)/a1snow)then
c            dum=dmax1(a1snow*(273.15d0-to(n)),2d0)
c          else
c            dum=2d0
c          endif
c          flo(n)=1d0/(1d0+dum*dum)
           dmass(n)= -us(n)*dt
         else
c        rainwater is ponding on top
            ss(n)=1d0
            sso(n)=1d0
            ssi(n)=0d0
            porosity(n)=1d0
            do(n)=dtol1
            d(n)=do(n)
            u(n+1)=-1d3*rate
            dmass(n+1)= -us(n+1)*dt
c          Next will cause unold in FILTRATE to be 0.0
            uo(n+1)=-1d3*rateo
            u(n)=0d0
            bw(n)=1d+3
         endif
         melt(n)=0
         layertype(n)=soiltype(ltype(k(n)))
c     For case of rain falling on impermeable layer, set ipond to 1
        if(blfall .gt. 9d2 .and. (ss(n-1) .gt. 1d0-1d-14 .or.
     &    impermeable(n-1).eq. 1 .or. sso(n-1).gt. 1d0-1d-14))then
          ipond(n)=1
        else
          ipond(n)=0
        endif
      end if
      return
      end
