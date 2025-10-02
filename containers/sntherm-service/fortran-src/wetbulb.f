c***********************************************************************
c  WETBULB computes wet-bulb temperatures from dry-bulb (tkair) and 
c  vapor pressure of air(ea). routine adapted from e. anderson, p. 188.
c***********************************************************************
      double precision function wetbulb(tkair,ea,bp)
      double precision tkair,ea,bp
c
c Called in MAIN
c
c arguments
c
c tkair : Air temperature [K]
c ea : Water Vapor pressure in air  [mb]
c bp : approximate average barometric pressure [mb]
c
c %W% %G%
c local
c
c delt: delt=eas*4278.63/((tcair+242.792)*(tcair+242.792)).
c eas: saturated Water Vapor pressure in air  [mb].
c eav: eav=2.7489d8*dexp(-4278.63/(tav+242.792)).
c i: looping index.
c tav: average of dry-bulb temperature and wet bulb temperature in celsius.
c tcair: dry-bulb temperature in celsius.
c twc: wet bulb temperature in celsius.
c
      integer i
      double precision tcair,eas,delt,twc,tav,eav
      tcair=tkair-273.15
      eas=2.7489d8*dexp(-4278.63/(tcair+242.792))
      delt=eas*4278.63/((tcair+242.792)*(tcair+242.792))
      do 100 i=1,3
         twc=delt*tcair+6.6d-4 *bp*tcair+7.59d-7*bp*tcair*tcair+ea-eas
         twc=twc/(delt+6.6d-4*bp+7.59d-7*bp*tcair)
         tav=0.5*(tcair+twc)
         eav=2.7489d8*dexp(-4278.63/(tav+242.792))
100   delt=eav*4278.63/((tav+242.792)*(tav+242.792))
      wetbulb=twc+273.15
      return
      end
