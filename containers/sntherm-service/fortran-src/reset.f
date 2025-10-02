c***********************************************************************
c  RESET resets required variables for a repeat iteration
c***********************************************************************
      subroutine reset
c %W% %G%
c
c  Called from converge, ftemp, thermal and filtrate
c
c  Calls density, function nmelt
c
      include 'const'
      include 'arrays'
c local
c
c i: looping index.
c m: m=k(i).
c
c Passed through common
c
c n: Number of nodes in model
c nold: Old number of nodes in model
c k(nd): Layer type assoicated with node
c to(nd) : Old nodal temperature [K]
c bwo(nd) : Old nodal water constituents bulk density [kg/m^3]
c td(nd) : Nodal depression temperature, t-273.15.  [K]
c td13(nd) : Nodal temperature depression from 0 C raised to (1/3) power
c flo(nd) : Nodal fraction of liquid (unfrozen) water due to both capillary
c          and adsorbed potential
c blo(nd) : Old Bulk density of liquid water [kg/m^3]
c bi(nd) : Nodal bulk density of ice [kg/m^3]
c bt(nd) : Nodal total bulk density [kg/m^3]
c dmass(nd) : Nodal mass [kg/m^2]
c bdjp(ld) : 0.75*Dry soil bulk density*plasticity index (0.75*bd*djp)
c a243(ld) : a2^^(4/3)
c bd(ld): Bulk density of dry soil material [kg/m^3]
c a1(ld) : Constant in unfrozen water formula
c melt(nd) : Signifies if node in meltzone if = 1
c dzo(nd) :  Old elemental thickness [m]
c flgo(nd) : Old fractional unfrozen water due to capillary potential
c sso(nd) : Old effective water saturation
c dice : density of ice (917) [kg/m^3]
c ssi(nd) : Irreducible water saturation 
c porosity(nd) : fractional volume of voids: between ice matrix in snow and  
c                between dry soil in general
c solidporosity(nd) : Volume of voids between dry soil and ice
c dmvol(ld) : Fractional volume of dry soil material
c ltype(ld) : Layer type 1=snow >90 =user supplied soil layer
c                2-3=soil types contained in Block Data file soil
c impermeable(nd) : 1 = Node impermeable to water 0 = Not.  See DENSITY
c idelete(nd) : 1 signifies node to be removed from model
c ipond(nd): For case of rain falling on impermeable layer, set ipond to 1.
c dicevol(nd):  Volume fraction of ice
c dliqvol(nd):  Volume fraction of liquid water
c rhowater: = Intrinsic density of water=1000. [kg/m^3].
c 
      integer i,m
c function
c
c nmelt: determines if element is in melt state.
c
      integer nmelt,iar,iiarray(nd)
      double precision darray(nd)
      n=nold
      do 10 i=1,n - newelm
         m=k(i)
         idelete(i)=0
         iskip(i)=0

         call density(to(i),bwo(i),td(i),td13(i),flo(i),blo(i),bi(i),
     1        bt(i),dmass(i),bdjp(m),a243(m),bd(m),a1(m),
     2        0,dzo(i),flgo(i),sso(i),dice,ssi(i),porosity(i),dmvol(m)
     &        ,ltype(m),impermeable(i),idelete(i),
     &        solidporosity(m),ipond(i),dicevol(i),dliqvol(i),rhowater)
         melt(i)=nmelt(to(i),th(m),tl(m))
10    continue
c Next is for DEBUG, to see if values are reset to those of past time-step
c You must also instate DEBUG** in Main.
c     m=i+1
c     do 241 iar=1,narray1
c     read(7,*)(darray(i),i=1,n)
c      do 40 i=1,n
c        if(dabs(darray(i)-array1(i,iar)) .gt. 1d-10)write(80,*)i,iar
c    1    ,darray(i),array1(i,iar)
c40        continue
c241    continue
c     do 257 iar=1,narray2
c     read(7,*)(darray(i),i=1,n)
c      do 41 i=1,n
c        if(dabs(darray(i)-array2(i,iar)) .gt. 1d-10)write(80,*)i,iar
c    1    ,darray(i),array2(i,iar)
c41        continue
c257    continue
c      do 261 iar=1,niarray
c     read(7,*)(iiarray(i),i=1,n)
c       do 42 i=1,n
c        if(iabs(iiarray(i)-iarray(i,iar)) .gt. 1d-10)write(80,*)i,iar
c    1    ,iiarray(i),iarray(i,iar)
c42        continue
c261   continue
cEnd of DEBUG section
      return
      end
