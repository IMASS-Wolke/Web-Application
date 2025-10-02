C***********************************************************************
c  WLIMIT computes mass water content limits for soil, where the
c  lower limit corresponds with the minimum drainage level and the
c  upper limit correcponds with the staturation level.
c***********************************************************************
      subroutine wlimit(bwo,bdjp,dice,i,ssi,porosity)
c %W% %G%
c arguments
c
c bwo: Old nodal water constituents bulk density [kg/m^3]
c bdjp : 0.75*Dry soil bulk density*plasticity index (0.75*bd*djp)
c dice : density of ice (917) [kg/m^3]
c i : loop or index variable
c ssi : Irreducible water saturation (0.07)

c porosity : fractional volume of voids: between ice matrix in
c                snow and between dry matrix in soil

c
c Called from MAIN
c
      double precision bwo,bdjp,dice,ssi,porosity
      integer i
      if(bwo.lt.bdjp)then
         print *,'**warning. water content is below minimum for this so
     1il type. Decrease plasticity index to decrease water content**'
         bwo=bdjp
      end if
      if(bwo .gt. 0.95*dice*porosity)then
cJan29,2002   format('**warning. water content truncated to saturation level
5        format('**warning. water content truncated to .95*saturation level
     1for node',i3)
        bwo=0.95*dice*porosity
        if(bwo.lt.bdjp)then
         write(*,*)'Minimum water content for this soil type exceeds sat  
     &uration.  Either lower the plasticity index or increase the porosi  
     &ty and restart the program'
          stop
         endif
      end if
c     ssi=dmax1(bdjp,bwo)/(1d3*porosity) ! ssi not used for soil
     
      return
      end
