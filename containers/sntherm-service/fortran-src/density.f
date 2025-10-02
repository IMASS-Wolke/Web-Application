c***********************************************************************
c  DENSITY updates the bulk densities and other mass related items.
c  The fraction is determined from a freezing curve (function FLIQUID) as
c  a function of depression temperature, Td=273.15-t. 
c***********************************************************************
      subroutine density(t,bw,td,td13,flo,bl,bi,bt,dmass,bdjp,a243,bd
     &     ,a1,melt,dz,flgo,ss,dice,ssi,porosity,dmvol,
     &     ltype,impermeable,idelete,solidporosity,ipond,
     &      dicevol,dliqvol,rhowater)
c
      include 'const'
c %W% %G%
c
c Calling routines : MAIN,NEWSNOW,COMBINENODES,RESET
c
c Calls POROSTY, functions fliquid,fsat,fbwmax
c
c Arguments
c
c t : Nodal temperature [K]
c bw : Nodal water constituents bulk density [kg/m^3]
c td : Nodal depression temperature, t-273.15.  [K]
c td13 : Nodal temperature depression from 0 C raised to (1/3) power
c flo : Nodal fraction of liquid (unfrozen) water due to both capillary
c          and adsorbed potential
c bl : Nodal liquid water bulk density [kg/m^3]
c bi : Nodal bulk density of ice [kg/m^3]
c bt : Nodal total bulk density [kg/m^3]
c dmass : Nodal mass [kg/m^2]
c bdjp : 0.75*Dry soil bulk density*plasticity index (0.75*bd*djp)
c a243 : a2^^(4/3)
c bd : Bulk density of dry soil material [kg/m^3]
c a1 : Constant in unfrozen water formula
c melt : Signifies if node in meltzone if = 1
c dz :  Nodal thickness [m]
c flgo : Old fractional unfrozen water due to capillary potential
c ss : Effective water saturation = (s - ssi)/(1. - ssi)
c dice : density of ice (917) [kg/m^3]
c ssi : Irreducible water saturation (0.07)
c porosity : fractional volume of voids: between ice matrix in snow and  
c                between dry soil in general
c dmvol : Fractional volume of dry soil material
c ltype : Layer type 1=snow >90 =user supplied soil layer
c                2-3=soil types contained in Block Data file soil
c impermeable : 1 = Node impermeable to water 0 = Not.  See DENSITY
c idelete : 1 signifies node to be removed from model
c ipond: For case of rain falling on impermeable layer, set ipond to 1.
c dicevol:  Volume fraction of ice
c dliqvol:  Volume fraction of liquid water
c rhowater: = Intrinsic density of water=1000. [kg/m^3].
c
      integer melt,ltype,impermeable,idelete,ipond
      double precision t,bw,td,td13,flo,bl,bi,bt,dmass,bdjp,a243,bd
      double precision a1,dz,flgo,ss,dice,ssi,porosity,dmvol
      double precision solidporosity,dicevol,dliqvol,rhowater
c
c Local
c
c a1td: a1td=a1*td.
c ssim: ssim=1d0-ssi.
c dtol1: dtol1 = 1.0d-12
      double precision a1td,ssim
c
c Functions
c
c fliquid: liquid water function of temperature, water content.
c fsat: effective saturation of snow function.
c fbwmax: bulk water density of saturated snow or soil layers. 
c
      double precision fliquid,fsat,fbwmax
c
c  Node is at or above freezing
      if(t-273.15d0 .gt. -1d-6)then
         td=0d0
         td13=0d0
         flo=1d0
         flgo=1d0
c        Next handles special case of totally melted snow element.
         if(ltype .lt. 2 .and. dabs(flo-1d0) .lt. 1d-6 .and. ipond .eq.
     &     0)then
c           Setting IDELETE=1 causes this element to combine with
c           its lower neighbor in COMBINENODES.
            t=273.15d0
            idelete=1
            dz=dtol1
            bw=dmass/dz
            bl=bw
            bi=0d0
            return
         end if
         bl=bw
c  Node is below freezing
      else
         td=273.15d0-t
         a1td=a1*td
         if(a1td .gt. 1d3)then
            flgo=0d0
         else
            flgo=1./(1.+a1td*a1td)
         end if
         if(bdjp .gt. 0.0)td13=td**(1./3.)
c
c      Note: For nodes in the melt zone, liquid water is already known
c      and is therefore not recalculated.  However, for the initial time 
c      step 'melt' is set to 0 to force initialization of bl.
         if(melt .eq. 0) then
             bl=fliquid(bw,td,bdjp,a243,td13,flgo)
         endif
         flo=1d0
         if(bw .gt. 0d0)flo=bl/bw
c        Impermeable layers not permitted in SNTHERM.89
c        Impermeable layers (ice lenses) are arbitrarily considered to
c        develop perforations when 90% melted. See additional comments
c        below.
         if(flo .gt. 9d-1)impermeable=0
      end if
c
      if(ss .lt.1d0 .or. bw .le. 0d0)then
c     this element is unsaturated or contains no water
        bi=bw-bl
c       note: the next are normally redundant, except that they may be
c       needed in newsnow, combo or subdivide
        bt=bl+bi+bd
        dmass= bt*dz
      else
c     this element is saturated, so that changes in bulk density
c     result from phase changes
        bw=fbwmax(dice,flo,porosity)
        dz=dmass/bw
        bl=flo*bw
        bi=bw-bl
        bt=bw+bd
c      note: adjustments to soil varaibles in response to freeze/thaw
c            volume changes have not yet been included in the model.
      end if
c
c
c Compute volume fractions
c
      dicevol=bi/dice
      if(bl .lt. 1d3)dliqvol=bl/rhowater
c
c Compute porosity
c
      call porosty(dicevol,dmvol,ltype,porosity,solidporosity)
c
c Nodes are designated as impermeable if their pororsity is below 10%.
c They remain impermeable (with water ponding on top) until 90% melted.
c
      if(porosity .lt.1d-1 .and. impermeable .eq. 0)then
        impermeable=1
      else
        impermeable=0
      endif
cTEMP. Disallow ponding in SNTHERM.89.
         impermeable=0
cTEMP
c
c Compute residual saturation, 1-residual satiuration. (This section is 
c not really needed now, but is retained for a future version of SNTHERM)
c
      if(ltype .lt. 2)then
        ssim=1d0-ssi
      else 
c Jan29,2002       ssi=bw/(1d3*(1d0-dmvol))+1d-6
        ssim=1d0-ssi
      endif
c
c Compute effective saturation
c
cTEMP. Saturated flow not permitted in SNTHERM.89
      if(ss .gt. .9999d0)ss=.9999d0
cTEMP
      if(ss .lt. 1d0 .and. impermeable .eq.0)then
         ss=fsat(bl,porosity,ssi,ssim)
      else if (ss .lt. 1d0 .and. impermeable .eq. 1)then
         ss=-ssi/ssim
      else
c     Note: Desaturation of elements is handled within routine FILTRATE.
         ss=1d0+1d-7
      endif
      return
      end
