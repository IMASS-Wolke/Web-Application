c***********************************************************************
c  MELTZONE determines temperature limits th and tl for the meltzone,
c  and computes the corresponding fractional water content limits
c  flgliml and flglimh for the capillary portion of the freezing curve.
c***********************************************************************
      subroutine meltzone(th,tl,bdjp,ci,bdcd,a1,dlm,cl,flgliml,flglimh,
     1     tdl,tdl13,tdh,tdh13,dice,dmvol)   
c %W% %G%
c
c Called from MAIN
c 
c arguments
c
c th : Upper meltzone temperature limit [K]
c tl : Lower meltzone temperature limit [K]
c bdjp : 0.75*Dry soil bulk density*plasticity index (0.75*bd*djp)
c ci : Specific heat of ice        [J/kg-K]
c bdcd : Dry soil bulk density*specific heat (bd*cd)
c a1 : Constant in unfrozen water formula
c dlm : Latent heat of fusion for ice(3.335E5) [J/kg]
c cl : Specific heat of water at 273.15 K (4217.7) [J/kg-K]
c flgliml,flglimh: Called as flglim(j,1), flglim(j,2) where
c flglim(nd,2) : Value of unfrozen water fraction 'flg' at phase boundaries
c tdl : Depression temperature at upper phase boundaries [K]
c tdl13: tdl(ld,2)^^(1/3) at lower boundary
c tdh: Depression temperature at lower phase boundaries [K]
c tdh13: tdl(ld,2)^^(1/3) at upper boundary
c dice : density of ice (917) [kg/m^3]
c dmvol : Fractional volume of dry soil material
c
      double precision th,tl,bdjp,ci,bdcd,a1,dlm,cl,dice,dmvol
      double precision flgliml,flglimh,tdl,tdl13,tdh,tdh13
c local
      double precision bwmid,denom,dum
c
c  Note: Bwmid is an estimated average water content, taken as the
c  midpoint between the sataurated and minimum drainage levels, the
c  latter being taken as .75*bd*jp=bdjp.
c  denom: denominator (denom=a1*a1*(ci*bwmid+bdcd)/dlm).
c  dum: dummy variable.
c
      if(bdcd .gt. 0d0)then
         bwmid=(bdjp+dice*(1d0-dmvol))/2d0
      else
         bwmid=1d0
      endif
      denom=a1*a1*(ci*bwmid+bdcd)/dlm
      tl=273.15d0-(2d0*bwmid/denom)**.33333d0
      th=273.15d0-(cl*bwmid+bdcd)/(2d0*dlm*bwmid*a1*a1)
      tdl=273.15d0-tl
      tdl13=tdl**.33333d0
      dum=a1*tdl
      flgliml=1d0/(1d0+dum*dum)
      tdh=273.15d0-th
      tdh13=tdh**.33333d0
      dum=a1*tdh
      flglimh=1d0/(1d0+dum*dum)
      return
      end
