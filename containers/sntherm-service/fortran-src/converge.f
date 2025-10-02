c***********************************************************************
c CONVERGE checks the convergence of the solution scheme with
c regards to linearization error in estimaing temperature and
c nodal change in saturation
c***********************************************************************
      subroutine converge(repeat,igood,ngoodmin,dtsum,dssallowed,
     &   errtallowd,dtmin,dtmax,dtsmin,dtssmax,print)
c %W% %G%
      include 'const'
      include 'arrays'

c
c calling routine : main
c
c calls routines  : reset
c
c Argument list
c
c   igood      : consecutive good calculations counter
c   ngoodmin   : minimum number of consecutive good calculations required
c              before increasing time step
c   iter       : if = 0 denotes new basic time period, not = 1
c   dtsum      : running total time limited to a maximum of dtbase
c   dssallowed : maximum allowed nodal change in saturation per
c               calculation time step
c   errtallowd: maximum allowed linearization error per time-step in heat balance
c               eq, expressed in units of temperature [K]
c   dtmin      : minimum allowed time step
c   dtsmin     : minimum allowed time step when water flow is present
c   dtssmax    : maximum time step for repeat calculation for
c               saturation criteria
c   dtmax      : maximum allowed time step
c   print      : print (if true) flag, usually at the hour
c   repeat : logical flag denoting a repeat of this iteration (if true)
c
c
      integer igood,ngoodmin
      double precision dtsum,dtsmin
      double precision dssallowed,errtallowd,dtmin,dtssmax,dtmax
      logical print,repeat
c
c Local
c
c   convchk   : Flag used to test whether convergence test is needed 
c             : (convchk=idelete(i).eq.0 .and. iskip(i) .eq. 0).
c   dss       : nodal change in saturation.
c   dssmax    : maximum nodal change in saturation
c   deltamassl : time change in mass of liquid water, used in
c                temperature criterion.
c   cxmass    : dummy variable used in temperature criterion.
c   flux      : dummy variable used in temperature criterion.
c   errtempmax: maximum error in temperature estimation
c   errtemp   : error in temperature estimation
c   hconverge : logical flag denoting temperaure convergence met (if true)
c   h1rstwarn : logical flag denoting first temperaure convergence
c             : warning for this basic time step (if true)
c   i         : loop counter
c   nodeh     : node not meeting change in stored heat convergence
c   nodes     : node not meeting change in saturation convergence
c   notmet    : =true means convergence criterion not met.
c   ok        : logical flag denoting temperature and saturation convergence 
c             : met (if true).
c   ratio     : temperature error/ allowed temperature error
c   sconverge : logical flag denoting saturation convergence met (if true)
c   s1rstwarn : logical flag denoting first saturation convergence
c             : warning for this basic time step (if true)
c   tolerance : used in testing convergence criterion.
c   tolerance2: used in assuring that timestep hits dtbase
c
c Passed through common
c
c   dt        : Current time step [s]
c   dto       : Old time step [s]
c   idelete(nd) : 1 signifies node to be removed from model
c   iskip(nd) : 1 signifies that convergence criteria are skipped for
c               this node      
c   iskipo(nd : Past value for iskip
c   n         : Number of nodes in model
c   ct(nd)    : Nodal combined specific heat of all constituents [J/kg-K]
c   dbvdt(nd) :1)Change in saturation vapor density per degree K [kg/m^3 K]
c             :2)Change in bulk vapor density per degree K [kg/m^3 K]
c   dls       : Latent heat of sublimation of ice (2.838E6) [J/kg] at 273.15
c   dlm       : Latent heat of fusion for ice(3.335E5) [J/kg]
c   dz(nd)    : Elemental thickness [m]
c   dzo(nd)   : Old elemental thickness [m]
c   bl(nd)    : Nodal liquid water bulk density [kg/m^3]
c   blo(nd)   : Old Bulk density of liquid water [kg/m^3]
c   bt(nd)    : Nodal total bulk density [kg/m^3]
c   bb(nd)    : Nodal conducted and convected heat plus absorbed solar
c   bbo(nd)   : Old nodal conducted and convected heat plus absorbed solar
c   dmass(nd) : Nodal mass [kg/m^2]
c   us(nd)    : Nodal convective mass flux of snow [kg/m^2-s] 
c   ci        : Specific heat of ice  [J/kg-K]
c   tprecip   : Precipitation temperature [K]
c   to(nd)    : Old nodal temperature [K]
c   flfall    : Fraction of liquid water within falling precip.
c   flo(nd)   : Nodal fraction of liquid (unfrozen) water due to both capillary
c               and adsorbed potential
c   ss(nd)    : Effective water saturation = (s - ssi)/(1. - ssi)
c   sso(nd)   : Old effective water saturation
c
      logical hconverge,sconverge,ok,convchk,notmet,h1rstwarn,
     @s1rstwarn
      integer i,nodeh,nodes
      double precision tolerance,dss,deltamassl,tolerance2
      double precision dssmax,errtempmax,errtemp,ratio,cxmass,flux
      parameter (tolerance=0.99d-3,tolerance2=0.99d-6)
c
      dto=dt
      dssmax=0.0
      errtempmax=0.0
      nodeh=2
      nodes=2
      ratio=0.0
      print=.false.
      if(iter .le. 1) then
        h1rstwarn = .true.
        s1rstwarn = .true.
      endif
c
c determine nodes causing worst convergence problems.
c
      do 10 i=2,n
c
c if current node is to be deleted (as if from melt) or combined with
c another, then convergence test skipped. if converge criteria are not
c met, converge will cause code to reduce time step until minimum step
c is reached.
c
         convchk=idelete(i).eq.0.and.iskip(i).eq.0.and.iskipo(i).eq.0
         if( convchk ) then
c          Next checks temperature criteria
            cxmass= (ct(i)+dbvdt(i)*dls/bt(i))*dmass(i)
            flux=bb(i)+bbo(i)
            if(us(i) .lt. 0d0)flux=flux-us(i)*ci(i)*(tprecip-to(i))
     &         -us(i)*dlm*(flfall-flo(i))
            deltamassl=bl(i)*dz(i)-blo(i)*dzo(i)
            errtemp=dabs(dto*(flux-dlm*(deltamassl/dt+unbar(i))
     &        +unbar(i)*hs(i))/cxmass-(t(i)-to(i)))
            if(errtemp.gt.errtempmax) then
               nodeh=i
               errtempmax=errtemp
            endif
c          Next checks saturation criteria
            dss= dabs(ss(i)-sso(i))
            if(dss.gt.dssmax .and.ss(i).gt.0d0) then
               nodes=i
               dssmax=dss
            endif
         endif
 10   continue
c
c compare actual error/change to allowed
c
      ratio=errtempmax/errtallowd
      hconverge= errtempmax .le. errtallowd
      sconverge= dssmax .le. dabs(dssallowed)
c
      ok = hconverge .and. sconverge
      notmet=.false.
c
      if( ok ) then
c  ok convergence : increment the good calculation counter, estimate
c  the next time step, and keep going.
c
         repeat=.false.
         igood=igood+1
         iter=iter+1
         if(dabs(unbar(nodes)) .gt. 1d-7)then
c        This is a period of water infiltration
            dt=dmin1(dto,porosity(nodes)/(4d0*dabs(unbar(nodes))))
            dt=dmax1(dt,1d-2)
            if(dt .lt. dto)igood=0
          endif
c
c       Try increasing the time step if the number of consecutive good
c       calculations exceeds the minimum required.
         if(igood .ge. ngoodmin)then
c March22, 1995            dt = dmin1( dabs(dto/ratio),1.5*dto,dtmax)
            dt = dmin1( dabs(dto/ratio),1.5*dto,(1-iwet)*dtmax+
     &      iwet*dtssmax)
            dt=dmax1(dt,1d-2)
c November 13, 1996. Set minimum on qs for top node.  Increases accuracy
c of temperature prediction-important for stability correction.
            dt=dmin1(qs(n)*dto/4d0,dt)
            igood=0
         endif
      else
c Convergence criteria not met:
         igood=0
         repeat=.true.
         if(dto .le. dtmin+tolerance) notmet=.true.
      end if
c
c Convergence criteria not met at minimum time step. notify
c user and continue.
c
      if(notmet)then
         repeat=.false.
         dt=dtmin
         dt=dmax1(dt,1d-2)
         iter=iter+1
CNOTE!!: Fix next statements later so that the max occurs for that basic
c time period are printed out (instead of first occurrance)
         if(h1rstwarn)then
           write(80,100)dto
         if(.not.hconverge) write(80,101) nodeh,errtempmax,errtallowd
         h1rstwarn = .false.
         endif
         if(s1rstwarn)then
           write(80,100)dto
         if(.not.sconverge) write(80,102) nodes,dssmax,dssallowed
         s1rstwarn = .false.
        end if
      end if
c
      if(.not. repeat)then
          dtsum= dtsum + dto
c
c       insure that time step + running time hit dtbase
c
      if( dabs(dtsum-dtbase) .le. tolerance2 .or.dtsum.gt.dtbase) then
          dtsum=0.0
          iter=0
          igood=0
          dt=dto
          dt=dmax1(dt,1d-2)
          print=.true.
      else
           dt = dmin1(dt, dabs(dtbase - dtsum + tolerance2) )
           dt=dmax1(dt,1d-2)
      endif
c
      else
c
c convergence criteria not met.
c reduce time step and repeat calculation.
c
      if(.not.hconverge) then
         dt=dmin1(dabs(0.67*dto*1.0/ratio),0.67*dto)
      else
         if(dabs(unbar(nodes)) .gt. 1d-9)then
           dt=dmin1(dtssmax,0.67*dto,porosity(nodes)/(4d0*dabs
     &            (unbar(nodes))))
         else
           dt=dmin1(dtssmax,0.67*dto)
         end if
      endif
      dt=dmin1(dt,dtmax)
      dt=dmax1(dt,1d-2)
c
c reset appropriate conditions
c
      call reset
      endif
c
      return
 100  format(/,'***convergence not obtained for time step of ',
     &1pe11.4,'sec in CONVERGE ***',/)
 101  format('   at node=',i4,' error in temperature est= ',1pe11.4,' >
     & ',' allowed= ',1pe11.4)
 102  format('   at node=',i4,' change in saturation= ',1pe11.4,' > ',
     &' allowed= ',1pe11.4)
      end
