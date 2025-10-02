c***********************************************************************
c  Subroutine FSSEST estimates the effective saturation ss of snow      
c***********************************************************************
      double precision function fssest(sso,ak,unold,upo,bmelts,c1,dzdt)
c %W% %G%
c
c Called by filtrate
c
c arguments
c sso : Old effective water saturation
c ak : Water flux=-ak*Effective saturation^^3.
c unold : Old nodal net mass flux of water =(uo(i+1)-uo(i))/2
c upo : = uo(i+1) as called in filtrate.
c bmelt(nd) : Nodal melt function [kg/m^3]. Termed Pmelt in report=
c            bwnew*(fl(bwnew,tnew)-fl(bwnew,told))
c c1 : c1=ssim*1d3*porosity(i).
c dzdt : dzdt=dzo/dt.
c
      double precision sso,ak,unold,upo,bmelts,c1,dzdt
c local
c
c ap: ap=-(c1*dzdt*sso-unold-upo/2d0+bmelts)/(2d0*dum).
c bp: bp=ap*ap+p*p*p/27d0.
c dum: Dummy variable used in cubic solution.
c p: p=c1*dzdt/dum.
c r1: r1=-ap+dsqrt(bp).
c r2: r2=-ap-dsqrt(bp).
c
      double precision dum,p,ap,bp,r1,r2
c   cubic solution taken from handbook of chemistry and physics
      dum=ak/2d0
      p=c1*dzdt/dum
      ap=-(c1*dzdt*sso-unold-upo/2d0+bmelts)/(2d0*dum)
      bp=ap*ap+p*p*p/27d0
c   note.  since p is always positive, bp is always positive.
      r1=-ap+dsqrt(bp)
      r2=-ap-dsqrt(bp)
      fssest=dsign(1d0,r1)*dabs(r1)**(1d0/3d0)+dsign(1d0,r2)
     & *dabs(r2)**(1d0/3d0)
      dum=fssest*fssest*fssest
      return
      end
