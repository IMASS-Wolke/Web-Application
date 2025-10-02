c***********************************************************************
c  FILTRATE models the infiltration of water through the snowpack,
c  based on the gravity flow algorithm of S. Colbeck, (1971),'One-
c  dimensional water flow through snow.' Usa-crrel research report
c  296. The options included in this routine for ponding and saturated
c  flow are disallowed in SNTHERM.89 and should be disregarded.
c  Feb 13, 2002. Cleaed up routine, mainly eliminating unused branches.
cc***********************************************************************
      subroutine filtrate(ib,it,*,dzmin)
c %W% %G%
c
c Called from MAIN 
c
c Calls TRIDIAG,RESET, functions FSSEST,FA
c
      include 'const'
      include 'arrays'
c
c Arguments
c
c dzmin : minimum nodal thickness (except for precipitation cases) [m]
c ib : = Lower node in flow zone = ibounds(nz,2)
c it : = Upper node in flow zone = ibounds(nz,1) 
c where
c ibounds(15,2) : boundaries (element numbers) of zones
c            where there is contiguous water flow
c nz : Index denoting number of flowzone
c
      integer ib,it
      double precision dzmin
c
c Local
c
c ak: Mass water flow coefficient [kg/m^2], where u=-ak*ss^3
c bmelts: Phase change term M in fluid flow eq.within Report [kg/m^2 s] 
c c1: c1=ssim*1d3*porosity(i).
c cs: Constant in linearizarion approximation for se^3
c dzdt: dzdt=dzo(i)/dt.
c i: looping index.
c l: linear equation matrix reference number.
c g: Specific gravity of ice-1 =1.0905
c n2: Number of elements in block of contiguous water flow (n2=it+1-ib).
c ms: Slope in linearizarion approximation for se^3
c ssest: Estmated effective saturation, computed in function SSEST.
c ssmin: ssmin=-ssi(i)/(1d0-ssi(i)).
c ssim: ssim=1.-ssi
c sw: Liquid water saturation.
c thinelement: logical flag - true if dmass(n) < 0.8d2*dzmin.
c unold: .5 * Net nodal water flux for past time period [kg/m^2].
c utopmax: Maximum outflow (utopmax from thin surface element [kg/m^2 s]
c
      integer i,l,n2
      double precision c1,unold,dzdt,ak,utopmax,x(nd)
      double precision bmelts,ssest,sw,ssmin,ssim,g,ms,bs
      logical thinelement
c
c Passed through common.
c
c porosity{nd): fractional volume of voids: between ice matrix in snow and
c           between dry matrix in soil.
c u(nd): Nodal convective mass flux of water [kg/m^2-s]
c uo(nd): Old nodal convective mass flux of water [kg/m^2-s]
c dzo(nd): Old nodal thickness [m]
c sso(nd): Old effective water saturation
c ssi(nd): Irreducible water saturation 
c ss(nd): Effective water saturation = (s - ssi)/(1. - ssi)
c nsoil: Number of soil nodes
c d(nd): Nodal snow effective grain diameter (m)
c bi(nd): Nodal bulk density of ice [kg/m^3]
c bd(nd): Bulk density of dry soil material [kg/m^3]
c b(nd): Constant array in linear equation matrix
c k(nd): Layer type assoicated with node
c a(nd,3): Coefficient array in linear equation matrix
c impermeable(nd): 1 = Node impermeable to water, 0 = Not.  See DENSITY
c n: Number of nodes in model
c dlm: Latent heat of fusion for ice(3.335E5) [J/kg]
c dmass(nd): Nodal mass [kg/m^2]
c dt: Current time step [s]
c bbo(nd): Old nodal conducted and convected heat plus absorbed solar
c hso(nd): Old water-flux enthalpy-adjustment for sensible heat
c dsol(nd): Nodal absorbed solar radiation
c dsolo(nd): Old nodal solar energy absorbed [W/m^2]
c ci: Specific heat of ice  [J/kg-K]
c us(nd): Nodal convective mass flux of snow [kg/m^2-s]
c tprecip: Precipitation temperature [K]
c to(nd): Old nodal temperature [K]
c pdzdtc(nd):Frac rate of change in nodal thickness due to compaction [s-1]
c
c  Functions
c
      double precision fssest,fa
      g=1.0959d0
c
c Identify a thin surface element
c
c Feb 13,2002      if(dmass(n) .lt. 1d2*dzmin)then
      if(dmass(n) .lt. 0.8d2*dzmin)then
         thinelement=.true.
      else
         thinelement=.false.
      endif
c
c  LOOP through this FLOWZONE.
c  A solution to the water flow equation is found for a block of n2
c  elements of contiguous water flow, extending from elements ib
c  to it.  The corresponding linear equation matrix reference number
c  l extends from 1 to n2.
c
      n2=it+1-ib
100   do 30 i=it,ib,-1
c    A. COMPUTE GENERAL PARAMETERS
         l=i-it+n2
         ssim=1d0-ssi(i)
         c1=ssim*1d3*porosity(i)
         unold=(uo(i+1)-uo(i))/2.
         dzdt=dzo(i)/dt
         sw=ssim*sso(i)+ssi(i)
         x(l) = 0d0
         if(i.le.nsoil)then
c          write(*,*)it,nsoil
c          stop  'No water flow in soil for sntherm.89'
         end if
c
c    B. ESTIMATE THE AMOUNT OF MELT, assuming that there
c    is no change in temperature within the element, so that t=to.
         if(sso(i) .lt. 1d0)then
c        this element is not saturated
         if(i .lt. n)then
            bmelts=(2d0*(bbo(i)+unold*hso(i))+(dsol(i)-dsolo(i))/2d0)
     1      *(1d0-g*sw)/dlm - 1d3*sw*dzo(i)*pdzdtc(i)
c        Variable pdzdtc=-CR (compaction rate as defined in report)
         else
c     conducted and convected heat exiting top node is heatfluxbtopo,
c     which is calculated in subroutine fbb.  topfluxk and topfluxv are
c     calculated in section XX. of main.
          if(.not. thinelement)then
          bmelts=(.5*dsol(n)+(unold+.5*(u(n+1)-uo(n)))*hso(i)+topfluxk
     1        +to(n)*topfluxv+bbo(n)-heatfluxbtopo)*(1d0-g*sw)/dlm
     2        -1d3*sw*dzo(i)*pdzdtc(i)
           else
c         Since thermal balance is skipped for thin elements, also set
c         bmelt to 0.0.
             bmelts=0d0
           endif
         end if
      else
        stop 'Saturated flow not allowed in sntherm.89'
      end if
c
c   C. COMPUTE EFFECTIVE SATURATION, SS. The effective saturation ss 
c   is estimated here since it is needed to estimate u.  However, it is 
c   definitively calculated following the thermal balance, when the 
c   final value for bmelt is known.
c
c   Maximum outflow for surface thin node is limited to inflow
      if(thinelement)then
c  Feb 13,2002       utopmax=flfall*dmass(n)/dt
       utopmax=(flfall*dmass(n)- 1d3*porosity(n)*ssi(n)*dzo(n))/dt
       utopmax=dmax1(utopmax,0d0)
      endif
c
      if(i .lt. n)then
        a(l,3)=-ak*ms/2.
        b(l)=0.5d0*ak*bs
      else
        a(n2,3)=0d0
        b(n2)=-u(n+1)/2.
      end if
      ak=fa(d(i),bi(i),bd(k(i)),sso(i))
      if(i .gt. ib .and. i .ne. it)then
        ms=sso(i)*sso(i)
        bs=-2d0*ms*sso(i)
        ms=3*ms
      else
        ssest=fssest(sso(i),ak,unold,uo(i+1),bmelts,c1,dzdt)
        ms=ssest*ssest
        bs=0d0
      endif
      a(l,1)=0d0
      a(l,2)=c1*dzdt+ak*ms/2.
      b(l)=b(l)-unold+c1*dzdt*sso(i)+bmelts-ak*bs/2d0
      if(i .eq. n .and. thinelement)then  !Feb 13, 2002
        ssest=(dabs(utopmax)/ak)**(1d0/3d0)
        a(l,2)=1d0
        b(l)=ssest
      endif
30    continue
c
      call tridiag(n2,a,x,b)
c
c  Now LOOP through the flowzone again.  
c  D. CALCULATE FLOWS, U, FROM NEW SS. u= -ak*ss**3. 
      do 10 i=it,ib,-1
      l=i+n2-it
         ssmin=-ssi(i)/(1d0-ssi(i))
         ss(i)=x(l)
         if(ss(i) .lt. ssmin)ss(i)=ssmin
         if(ss(i) .gt. 0d0)then
           ak=fa(d(i),bi(i),bd(k(i)),ss(i))
           u(i)=-ak*ss(i)*ss(i)*ss(i)
         else
           u(i)=0d0
         end if
      if(i .ne. l)ss(l)=0d0
10    continue
      do 25 i=ib,it
      l=i+n2-it
      if(ss(i) .gt. .9999d0)ss(i)=.99999d0
25    continue
      return
      end
