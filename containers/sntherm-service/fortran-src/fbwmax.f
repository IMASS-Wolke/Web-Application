c***********************************************************************
c  Function FBWMAX returns the bulk water density for saturated snow or
c  soil layers.  changes in density due to the relatve phases of water
c  are considered.  the thickness of saturated nodes is adjusted in
c  main (sec. xx) to account for expansion/contraction upon freezing/
c  thawing of water.
c***********************************************************************
      double precision function fbwmax(dice,fl,porosity)
c %W% %G%
c
c Called by density.f and combo.f
c
c arguments
c
c dice : density of ice (917) [kg/m^3]
c fl : Nodal fraction of unfrozen water (bl/bw)
c porosity : fractional volume of voids: between ice matrix in
c                snow and between dry matrix in soil

c 
      double precision  dice,fl,porosity
c
cRJ 6/19/94
c     fbwmax=porosity*(fl*(1d3-dice)+dice)
      fbwmax=porosity*1d3 + (1d0-porosity)*917d0
      if(fbwmax .gt. 1.0d3)fbwmax=1.0d3
      return
      end
