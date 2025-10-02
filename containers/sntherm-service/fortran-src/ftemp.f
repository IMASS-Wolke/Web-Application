************************************************************************
c Subroutine FTEMP estimates liquid water and temperature from melt
c***********************************************************************
      subroutine ftemp(t,dt,bl,bw,a1,a243,unbar,dz,dzo,bdjp,td13,tl,
     &     th,blo,bmelt,flgo,blmin,blmax,dtmin,
     &     redo,ok,recross,f,errtallowd,*)
c
      include 'const'
c %W% %G%
c
c Called from THERMAL
c
c Calls RESET
c
c arguments
c
c t : Nodal temperature [K]
c dt :  Current time step [s]
c bl : Nodal liquid water bulk density [kg/m^3]
c bw : Nodal water constituents bulk density [kg/m^3]
c a1 : Constant in unfrozen water formula
c a243 : a2^^(4/3)
c unbar : Average nodal convective mass flux of water  [K/m^2 s]
c dz :  Elemental thickness [m]
c dzo : Old elemental thickness [m]
c bdjp : 0.75*Dry soil bulk density*plasticity index (0.75*bd*djp)
c td13 : Nodal temperature depression from 0 C raised to (1/3) power
c tl: Lower meltzone temperature limit [K]
c th : Upper meltzone temperature limit [K]
c blo : Old Bulk density of liquid water [kg/m^3]
c bmelt : Nodal melt function [kg/m^3]. Termed Pmelt in report=
c            bwnew*(fl(bwnew,tnew)-fl(bwnew,told))
c flgo : Old fractional unfrozen water due to capillary potential
c blmax: Bulk density of liquid water corresponding to upper melt
c         zone limit [kg/m^3]
c blmin: Bulk density of liquid water corresponding to lower melt
c         zone limit [kg/m^3]
c dtmin : minimum allowed time step [s]
c f : Slope of freezing curve for node [kg/m^3 K] (Note:f is
c   defined here as the change in bl over dT, and in the report as
c   the change in the fraction of liquid water over dT).
c redo: Logical flag defined in thermal.f denoting that it is ok to redo
c       iter.,=dt .gt.1.1*dtmin .and. istart.eq.0.and.iskip(n).eq.0
c recross : Used in trapping overshot phase boundary.
c ok : Used in trapping overshot phase boundary.
c errtallowd: maximum allowed linearization error per time-step in heat balance
c       eq, expressed in units of temperature [K]
c
      double precision t,dt,bl,bw,a1,a243,unbar,dz,bdjp,td13,tl
      double precision th,blo,bmelt,flgo,blmin,blmax,dtmin
      double precision f,dzo,errtallowd
      logical ok,redo,recross
c local
c
c bdjpbl: bdjpbl=bdjp/bl.
c dfydy: dfydy=5*yforth+3*p*ysqr+2*q*y.
c est: est=y-fy/dfydy.
c fy: fy=y*yforth+p*ycube+q*ysqr+s.
c it: iteration counter for Newton-Raphson method.
c p: coefficient of y**3 term of polynomial (p=(1d0-bdjpbl)/a243).
c q: coefficient of y**2 term of polynomial (q=(s+bdjpbl)/(a1*a1)).
c ratio: Density ratio (ratio=bw/bl).
c s: constant term of polynomial.
c y: y=td13*td13 as used in polynomial. 
c ycube: y**3 or ycube=y*ysqr.
c yforth: y**4 or yforth=ysqr*ysqr.
c ysqr: y**2 or ysqr=y*y.
c dtol1: dtol1 = 1.0d-12
c
      integer it
      double precision ratio,bdjpbl,s,y,yforth,ysqr,est,p,q,ycube
      double precision fy,dfydy
c
c  ALL NODES CALLED BY THIS ROUTINE ARE WITHIN THE MELT ZONE.
c
c  In next, t=bmelt represents bwnew*(fl(bwnew,tnew)-fl(bwnew,told))
      bmelt=t
c  Now use bmelt to update bl (through application of continuity eq.)
      bl=bmelt+(blo*dzo-unbar*flgo*dt)/dz
c
c  The next section is a "safety net" in the eventuallity that a phase
c  boundary is way over-shot.  Since the timestep is automatically
c  shortened as a boundary is approached, this should not normally occur.
c  If the meltzone boundary was crossed and the computed bl overshoots the 
c  boundary value by more than 5%, then redo the iteration if the timestep 
c  dt is greater than dtmin.
c     The bottom phase boundary is over-shot by more than 5%
      if(bl .lt. .95d0*blmin)then
        if(redo)then
c       redo iteration if dt>1.1*dtmin and snow hasn't just started
c       and thermal balance isn't being skipped for this node.
           ok=.false.
           dt=dmin1(0.1d0,dtmin)
           recross=.true.
           call reset
           return 1
        endif
        bl=.95d0*blmin
c     The upper phase boundary is over-shot by more than 5%
      else if (bl .gt. 1.05d0*blmax)then
        if(redo)then
           ok=.false.
           dt=dmin1(0.1d0,dtmin)
           recross=.true.
           call reset
           return 1
        endif
        bl=1.05d0*blmax
      endif
c
c  Calculate new t from new bl.
c
        bl=dmin1(bl,bw-dtol1)
        ratio=bw/bl
c  Next does computation for snow or non-colloidal soil
        if(bdjp .le. 0d0)then
         t=273.15d0-dsqrt(ratio-1d0)/a1
c  Next branch added on Jan 29,2001
        elseif(bw .le. bdjp)then
         t=273.15d0-(((bdjp/bl)-1d0)/a243)**0.75d0
c  Next does computation for colloidal soil
        else
         s=(1d0-ratio)
         bdjpbl=bdjp/bl
         p=(1d0-bdjpbl)/a243
         q=(s+bdjpbl)/(a1*a1)
         s=s/(a1*a1*a243)
         y=td13*td13
c       next solves the poynomial y**5+p*y**3+q*y**2+s using the newton-
c       raphson-bisection iteration technique.
         it=0
 10      ysqr=y*y
         ycube=y*ysqr
         yforth=ysqr*ysqr
         fy=y*yforth+p*ycube+q*ysqr+s
         dfydy=5*yforth+3*p*ysqr+2d0*q*y
         est=y-fy/dfydy
         it=it+1
         if(it .gt. 200) then
c           stop ' ** execution terminated. it > 200 in ftemp.f **'
            write(*,*)' ** Warning it > 200 in ftemp.f **'
           ok=.false.
           dt=dmin1(1d0,dtmin)
           recross=.true.
           call reset
           return 1
         endif
         if(dabs((est-y)*f)/(th-tl) .lt. dmin1(errtallowd*1d-1,1d-3)
     &   )goto 20
         y=est
         goto 10
20       if(est .gt. 0.0)then
            t=273.15d0-est*dsqrt(est)
         else
            t=273.15d0
         end if
        end if
c     end if
      return
      end
