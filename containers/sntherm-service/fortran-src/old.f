c***********************************************************************
c  Subroutine OLD establishes old values from current values before
c  commencing next time iteration.
c***********************************************************************
      subroutine old(ido)
c %W% %G%
c Changes added for compaction version
c
c Called from MAIN
c
      include 'const'
      include 'arrays'
c arguments
c
c ido : flag if = 1 signifies hour = 5 am. used to flag operations done on
c       a daily basis
c
      integer ido
c local
c
c i: looping index.
c
c Passed through common
c
c to(nd): Old nodal temperature [K]
c t(nd): Nodal temperature [K]
c bwo(nd): Old nodal water constituents bulk density [kg/m^3]
c bw(nd): Nodal water constituents bulk density [kg/m^3]
c uo(nd): Old nodal convective mass flux of water [kg/m^2-s]
c u(nd): Nodal convective mass flux of water [kg/m^2-s]
c ddzdtp(nd): Nodal thickness rate change due to precipitation [m/s]
c sso(nd): Old effective water saturation
c ss(nd): Effective water saturation = (s - ssi)/(1. - ssi)
c dzo(nd): Old elemental thickness [m]
c dz(nd): Elemental thickness [m]
c blo(nd): Old Bulk density of liquid water [kg/m^3]
c bl(nd): Nodal liquid water bulk density [kg/m^3]
c bbo(nd): Old nodal conducted and convected heat plus absorbed solar
c bb(nd): Nodal conducted and convected heat plus absorbed solar
c do(nd): Old nodal effective grain diameter [m]
c d(nd): Nodal snow effective grain diameter (m)
c bmelt(nd) : Nodal melt function [kg/m^3]. Termed Pmelt in report=
c            bwnew*(fl(bwnew,tnew)-fl(bwnew,told))
c us(nd): Nodal convective mass flux of snow [kg/m^2-s]
c dsolo(nd): Old nodal solar energy absorbed [W/m^2]
c unbar(nd): Average Nodal Convective mass flux of water  [K/m^2 s]
c hso(nd): Old water-flux enthalpy-adjustment for sensible heat
c hs(nd): Water flux enthapy adjustment.
c tprecipo: Old precipitation temperature [K]
c tprecip: Precipitation temperature [K]
c prcpo: Old Precipitation Value (m/hour)
c prcp: Precipitation Value (m/hour)
c tkairo: Old Air temperature [K]
c tkair: Air temperature [K]
c eao: Old Water Vapor pressure in air[mb]
c ea: Water Vapor pressure in air  [mb]
c wspo: Old Wind speed [m/s]
c wsp: Wind speed [m/s]
c dirdowno: Old Incident longave radiation [W/m^2]
c dirdown: Incident longwave radiation [W/m^2]
c supo: Old reflected solar flux [W/m^2]
c sup: Reflected solar flux [W/m^2]
c sdowno: Old incident solar radiative flux [W/m^2]
c sdown: Incident solar radiative flux [W/m^2]
c solaro: Old net solar radiative flux [W/m^2]
c solar: Net solar radiative flux [W/m^2]
c hgo: Old geothermal heat flux [W/m^2]
c hg: Geothermal heat flux (across snow/soil interface) [W/m^2]
c wdiro: Old Wind direction
c wdir: Wind direction [degrees]
c rho: Old relative humidity
c rh: Relative humidity
c emo(ld): Old hemispherical-emissivity for material-type layer
c em(ld): Material-layer hemispherical emissivity
c qseno: Old wind function for sensible heat exchange [W s/(m^3 K)]
c qsen: Wind function (coefficient) for sensible heat exchange [W s/(m^3 K)]
c qlato: Old wind function for latent heat exchange [W s/(m^3 K)]
c qlat: Wind function (coefficient) for latent heat exchange [W s/(m^3 K)]
c snowrateo: Old snow rate [m/s]
c snowrate: Current snow rate [m/s]
c rainrateo: Old Rain Rate [m/s]
c rainrate: Rain Rate [m/s]
c ido: flag if = 1 signifies hour = 5 am. used to flag operations done on
c       a daily basis
c iwet: Flag = 1 signifies wet snow.
c dlongo: Old Net long wave radiative flux
c dlong: Net long wave radiative flux
c sensheato: Old turbulent flux of sensible heat [W/m^2]
c sensheat: Turbulent flux of sensible heat [W/m^2]
c dlatheato: Old turbulent flux of latent heat [W/m^2]
c dlatheat: Turbulent flux of latent heat [W/m^2]
c convecto: Old surface precipitation convective flux [W/m^2]
c convect: Surface precipitation convective flux [W/m^2]
c newelm: Number of new nodes to be added to model
c nold: Old number of nodes in model
c n: Number of nodes in model
c istart: Snow just started flag 1=yes 0=no
c heatfluxbtopo: Old value of heatfluxbtopo [W/m^2]
c heatfluxbtop: Heatflux across bottom ot top node [W/m^2]
c
      integer i
c
      if(initial .eq. 0)sbt3o=sbt3
      do 20 i=1,n
         if(initial .eq. 0)then
            to(i)=t(i)
            bwo(i)=bw(i)
            uo(i)=u(i)
            u(i)=0d0
            ddzdtp(i)=0d0
            sso(i)=ss(i)
            dzo(i)=dz(i)
            blo(i)=bl(i)
            bbo(i)=bb(i)
            do(i)=d(i)
            bmelt(i)=0d0
         end if
         us(i)=0.0
         dsolo(i)=dsol(i)
c  Next is removed since unbar is used in compact.f in the next iteration
c        unbar(i)=0.0
         hso(i)=hs(i)
 20   continue
      tprecipo=tprecip
      prcpo=prcp
      uo(n+1)=u(n+1)
      u(n+1)=0.0
      tkairo=tkair
      eao=ea
      eso=es
      wspo=wsp
      dirdowno=dirdown
      supo=sup
      sdowno=sdown
      solaro=solar
      hgo=hg
      wdiro=wdir
      rho=rh
      emo(ln)=em(ln)
      qseno=qsen
      qlato=qlat
      snowrateo=snowrate
      rainrateo=rainrate
      ido=0
      iwet=0
      dlongo=dlong
      sensheato=sensheat
      dlatheato=dlatheat
      convecto=convect
      newelm=0
      nold=n
      istart=0
      heatfluxbtopo=heatfluxbtop
      return
      end
