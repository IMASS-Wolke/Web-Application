c***********************************************************************
c THPARAM computes thermal parameters
c***********************************************************************
      subroutine thparam
c @(#)thparam.f	5.3 1/28/91 
      include 'const'
      include 'arrays'
c
c Called from MAIN
c
c Calls function dblcurve 
c
c
c Local
c
c i: Nodal looping index
c m: Layer index = k(i)
c cl12: cl12=cl/2
c dum0: dum0=a223*td13*td13.
c dum1: dum1=dum0+1d0.
c dum2: dum2=1.4142136d0*a213*td13.
c dzm:  dzm=dz(i-1)
c thkm: thkm=thk(i-1)
c
      integer i,m
      double precision dum1,dum2,dum0
      double precision dzm,thkm,cl12

c Passed through common
c
c to(nd) : Old nodal temperature [K]
c ci(nd) : Specific heat of ice        [J/kg-K]
c ct(nd) : Nodal combined specific heat of all constituents [J/kg-K]
c bw(nd) : Nodal water constituents bulk density [kg/m^3]
c td(nd) : Nodal depression temperature, t-273.15.  [K]
c td13(nd) : Nodal temperature depression from 0 C raised to (1/3) power
c flo(nd) : Nodal fraction of liquid (unfrozen) water due to both capillary
c          and adsorbed potential, blo/bwo
c gk(nd) : Constant for calculating temperature from melt [K]
c gv(nd) : Coefficient for calculating temperature from melt
c ho(nd) : Water flux enthapy adjustment
c f(nd) : Slope of freezing curve for node [kg/m^3 K] (Note:f is
c   defined here as the change in bl over dT, and in the report as
c   the change in the fraction of liquid water over dT).
c bdjp(ld) : 0.75*Dry soil bulk density*plasticity index (0.75*bd*djp)
c a1(ld) : Constant in unfrozen water formula
c a2(ld) : Constant in unfrozen water formula
c a243(ld) : a2^^(4/3)
c ltype(ld) : Layer type 1=snow >=90 user supplied soil layer
c dz(nd) :  Elemental thickness [m]
c thk(nd) : Current Nodal thermal conductivity [W/m-K]
c bt(nd) : Nodal total bulk density [kg/m^3]
c unbar(nd) : Average nodal convective mass flux of water  [K/m^2 s]
c dt :  Current time step [s]
c melt(nd) : Signifies if node in meltzone if = 1
c cl : Specific heat of water at 273.15 K (4217.7) [J/kg-K]
c dlm : Latent heat of fusion for ice(3.335E5) [J/kg]
c qk(nd) :.5*(thermal conductivity at upper nodal boundary/dz) 
c qs(nd) : Coefficient on nodal stored heat
c bdcd(ld) : Dry soil bulk density*specific heat (bd*cd)
c flgo(nd) : Old fractional unfrozen water due to capillary potential
c qf(nd) : .5*specific heat of water*nodal mass water flux 
c u(nd) : Nodal convective mass flux of water [kg/m^2-s]
c a213(ld) : a2^^(1/3)
c a223(ld) : a2^^(2/3)
c dbvdt(nd) :1)Change in saturation vapor density per degree K [kg/m^3 K]
c           :2)Change in bulk vapor density per degree K [kg/m^3 K]
c dls : Latent heat of sublimation of ice (2.838E6) [J/kg] at 273.15
c hs(nd) : Water flux enthapy adjustment.
c uvapor(nd) : Net diffusive mass flux of water vapor for element [K/m^2 s]
c n : Number of nodes in model
c
c
c Functions
c
      double precision dblcurve
c
      cl12 = 0.5*cl
c Loop through all nodes
      do 100 i=2,n
         m= k(i)
         dzm= dz(i-1)
         thkm= thk(i-1)
         if(to(i) .le. 273.15d0)then
c Node is below freezing
            ci(i)=-13.3d0+7.8d0*to(i)
            if(dabs(unbar(i)) .gt. 0d0)then
c           Case where this is water flow
                  hs(i)=(cl-ci(i))*273.15d0+ci(i)*to(i)
               if(ltype(m) .gt. 1)then
                  dum0=a223(m)*td13(i)*td13(i)
                  dum1=dum0+1d0
                  dum2=1.4142136d0*a213(m)*td13(i)
                  hs(i)=hs(i)-((cl-ci(i))*(1d0/bw(i)))*
     &                 ((bw(i)-bdjp(m))*datan(a1(m)*td(i))/a1(m)+
     1                 .75d0*bdjp(m)*(dlog((dum1-dum2)/(dum1+dum2))
     2                 +2d0*datan(dum2/(1d0-dum0)))/(1.414213d0*a2(m)))
               end if
               ho(i)=hs(i)-(1.-flgo(i))*dlm
            else
c           It isn't necessary to calculate ho when there is no flow
               ho(i)=0d0
               hs(i)=0d0
            end if
            f(i)=dblcurve(td(i),bw(i),bdjp(m),a1(m),a243(m),td13(i),
     &           flgo(i),melt(i))
            ct(i)=(bdcd(m)+bw(i)*(cl*flo(i)+ci(i)*(1.-flo(i))))/bt(i)
c           if(melt(i) .eq. 0 )then
            if(melt(i) .eq. 0 .or. bw(i) .lt. 1d0)then
               qs(i)=(bt(i)*ct(i)+f(i)*dlm+dbvdt(i)*dls)*dz(i)/dt
               gk(i)=0.0
               gv(i)=1.0
            else
               gv(i)=1/f(i)
               gk(i)=to(i)
               qs(i)=(bt(i)*ct(i)+dbvdt(i)*dls)*dz(i)/dt
            end if
         else
c Node is above freezing
            ho(i)=cl*to(i)
            hs(i)=ho(i)
            f(i)=0.0
            ct(i)=(bdcd(m)+cl*bw(i))/bt(i)
            qs(i)=bt(i)*ct(i)*dz(i)/dt
            gk(i)=0.0
            gv(i)=1.0
         end if
c        if(i.eq.n)qs(i)=qs(i)+ct(i)*uvapor(i)/2d0
         if(i.gt.1)qk(i)=thk(i)*thkm/(thk(i)*dzm+thkm*dz(i))
         qf(i)=-cl12*u(i)
 100  continue
      return
      end
