**********************************************************************
c GETMET reads in met data from file, and generates required met
c parameters
c***********************************************************************
c
      subroutine getmet(*,imetcalc,isolarcalc,islope,iy,jday,ihour,imin,
     & ibasestep,ido,iptype,ircalc,itimezone,ititle,itm,newsno,
     & a1snow,azslope,bifall,bifallin,bp,clearness,dlatt,dlongt,
     & dsnowfall,effceiling,elev,tlsnow,tm,tmsg,albsnow,bwfall,blfall,
     & exp1)
c @(#)getmet.f	1.1 1/25/91
      include 'const'
      include 'arrays'

c*** Arguments
c imetcalc: Met generation option.
c isolarcalc : estimate solar radiation flag 2=estimate missing values only
c              1=yes 0=no
c islope : sloped terrain flag 1=yes 0=no
c iy : Year of simulation, last 2 digits (read from met time-hack)
c jday : Julian day of simulation, (read from met time-hack)
c ihour : Hour of simulation, (read from met time-hack)
c imin: Minute of simulation, (read from met time-hack)
c ibasestep: Current number of basestep from start of problem
c ido : flag if = 1 signifies hour = 5 am. used to flag operations done on 
c       a daily basis
c iptype : precipitation type (from met data) 1= rain 2 =snow
c ircalc : calculate longwave radiation if = 1
c itimezone:  Hourly difference of timezone from Greenwich mean time
c ititle : flag to print header for filtration output
c itm : read measured temperature flag 1=yes 0=no
c newsno : If > 1 signifies that snow fall has occured
c          recently (within past 72 hours)
c a1snow : unfrozen water constant
c azslope: azimuthal angle of slope (clockwise from north to falline)
c bifall: Bulk density of newly fallen dry snow - 1d2 in MAIN 
c         (0d2 if rainfall occurs)
c bp : approximate average barometric pressure [mb]
c clearness: approximate clearness factor for the sky=
c            1 - (cloud(1)+ecover2+ecover3)
c dlatt : Degrees latitude
c dlongt: Degrees longitude.
c effceiling: Effective cloud ceiling, defined as follows: 
c           effceiling=(cover(1)*ceiling(1)+ecover2*ceiling(2)+ecover3*
c     &               ceiling(3))/clearness
c elev: slope elevation angle above horizon
c tlsnow : meltzone lower limit temperatures [k}
c tm : measured surface temperature [k]
c tmsg : measured snow/ground interface temperature [k]
c albsnow : albedo of snow. If gt 1, than albedo is estimated

      integer imetcalc,isolarcalc,islope,iy,jday,ihour,imin
      integer ibasestep,ido,iptype,ircalc,itimezone,ititle
      integer itm,newsno
      double precision a1snow,azslope,bifall,bifallin,bp,clearness
      double precision dlatt,dlongt,dsnowfall,effceiling,elev
      double precision tlsnow,tm,tmsg,albsnow,bwfall,blfall
      double precision snowdepth,Ab
      double precision costheta
c***Local (nomenclature incomplete)
      integer i
cNov13,1995     double precision albm,bwfall,cosd,cosz,cosazi,coselv
      double precision albm,cosd,cosz,cosazi,coselv,tcosz
      double precision diffuse,diffuseslope,direct,directslope,dum
      double precision ecover2,ecover3,hr,gmt
      double precision sdown0,shadow,sinelv,sinz,sdownarg,sind
      double precision reflected,relazimuth,xm,albvis0,albnir0
cNov27,1996      double precision sqrtr, costheta,fvis,albvis,albnir,adjust
      double precision sqrtr, fvis,albvis,albnir,adjust,exp1
      double precision albvis1,albnir1,fdiffuse
      logical halbdone,callsol
c*** Functions
      double precision fd,fvapri,fvaprw,dmin1,wetbulb
c 1. OBTAIN MET DATA
      if(imetcalc .eq. 0)then
         if(isolarcalc .gt. 0 .or. islope .gt. 0
     & .or. ircalc .gt. 0 )then
c        Met file in this branch  must contain cloud data
          if(bifallin .gt. 0d0)then
            read(88,*,end=999)iy,jday,ihour,imin,
     &           tkair,rh,wsp,(rad(i),i=1,3),prcp,iptype,dsnowfall,
     &           (cover(i),icl(i),i=1,3)
          else
            read(88,*,end=999)iy,jday,ihour,imin,
     &          tkair,rh,wsp,(rad(i),i=1,3),prcp,iptype,dsnowfall,
     &           bwfall,(cover(i),icl(i),i=1,3)
          endif
         else
          if(bifallin .gt. 0d0)then
            read(88,*,end=999)iy,jday,ihour,imin,
     &           tkair,rh,wsp,(rad(i),i=1,3),prcp,iptype,dsnowfall
          else
c Next lines added on Nov 21, 1995
            read(88,*,end=999)iy,jday,ihour,imin,
     &           tkair,rh,wsp,(rad(i),i=1,3),prcp,iptype,dsnowfall,
     &           bwfall
          endif 
         end if
      else
         call metcalc(jday,ihour,imin,tkair,rh,wsp,prcp,iptype,
     &        dsnowfall,cover,icl,initial,dtbase,shadow)
      endif
      if(wsp .le. 0.3d0)wsp=0.3d0
      iter=1
c  precip not permitted during initial time period
      if(ibasestep .eq. 1 .and. prcp .gt. 0.0) then
         stop '** Execution Stopped. Precipitation at Start. **'
      endif
      if (ibasestep .eq. 1 .or. ihour .eq. 4)ido=1
      ititle=1
c
c  optional read of measured surface temperature
      if(itm .ge. 1)call readtm(89,iy,jday,ihour,imin,tmsg,tm,ibasestep)
c
c 2. COMPUTE EFFECTIVE CLOUD COVER AND CEILING
      if(isolarcalc .gt. 0 .or. islope .gt. 0 .or.
     & ircalc .gt. 0. .or. dint(rad(3)) .gt. 9d3)then
        do 3 i=1,3
         if(cover(i) .lt. 0d0 .or. ceiling(i) .lt. 0d0)stop  'Negative v
     &alue found for cloud cover or ceiling.  Correct data point in met
     &file'
  3     continue
        ecover2=(1d0-cover(1))
        ecover3=ecover2*cover(3)*(1d0-cover(2))
        ecover2=cover(2)*ecover2
        clearness=cover(1) + ecover2 + ecover3
        if(clearness.eq.0 ) then
           effceiling= 200
        else
           effceiling=(cover(1)*ceiling(1)+ecover2*ceiling(2)+ecover3*
     &          ceiling(3))/clearness
        endif
        clearness=1d0 - clearness
      end if

c 3. COMPUTE ALBEDO (optional) Triggered when input albedo exceeds 1 
c    or when slope option is used.  This section computes the diffuse
c    and direct albedo components.
c    Note: Further adjustments to albedo for sloped surfaces are made
c    in sections 4 and 5.
      if((albsnow .gt.1d0.or.islope.ge.1) .and.ltype(k(n)).le.1)then
c Next computes albedo for diffuse radiation
c Formulas from D. Marks dissertation, p. 61.  These formulas
c are a good fit to Figs 2a and 2c from Marshall and Warren.
c The following approximate breakdown between visible and nir is  
c estimated from data of Grenfell and Perovich, Table 2, JGR,v.89,c3,
c pp. 3573-3580, May20, 1984, where the division between vis and nir
c is taken at 0.7 microns.
c July 8 1996 - added experimental parameter (jcm)
c
        fvis=exp1
        if(fvis .gt. 1.0)then
		fvis=0.436d0 + 0.149*(1d0-clearness)
	endif

c Estimate albedos for diffuse radiation incident on horizontal surface.
        sqrtr=dsqrt(0.50*D(n))
        albvis0=1d0-sqrtr*2d0
        albnir0=0.85447*dexp(-21.23*sqrtr)

c WARNING. THIS ROUTINE ONLY COMPUTES CORRECTLY FOR CLEAR SKIES
c NEXT IS A TEMPORARY BAND-AID
c       if(clearness .lt. 1d0)then
c        albvis0=albvis0 + 0.008d0*(1d0-clearness)
c        albnir0=albnir0 + 0.170d0*(1d0-clearness)
c       endif

c Estimate albedos for direct radiation at given zenith angle.
c Here the parameters in the D-M equations have been
c refit to the data of Marshall and Warren, Figs 2b and 2d.
c It appears that in the D-M parameterization albvis0 and alnir0
c were incorrectly assumed to be for vertical incidence instead of
c for diffuse radiaton (where cosz = 1/dsqrt(3)).  The fit is still
c not great, and this needs to be redone using the original W-W algorithm 
        gmt=float(ihour+itimezone)+float(imin)/60d0
        call zen(jday,gmt,dlatt,dlongt,cosz,sind,cosd,xm,ido,hr)
cNov27,1996        dum=1d0/dsqrt(3d0)
        dum=0.57735026918963
c D-M  	albvis1=albvis0 + sqrtr*1.375d0*(1d0-cosz)
c Next added on  April 7, 1997 for case of sun below horizon
        tcosz=dmax1(cosz,0d0)
        albvis1=albvis0 + sqrtr*1.575d0*(dum-tcosz)
c D-M   albnir1=albnir0 + (2d0*sqrtr+0.1d0)*(1d0 - cosz)
        albnir1=albnir0 + (2.4d0*sqrtr+0.12d0)*(dum - tcosz)
      endif

c 4. FURTHER ADJUSTMENTS WHEN MEASURED SOLAR RADIATION IS USED.
c
c Initialize to 'null' values
      sdown=0.0
      sup=0.0
      if(ltype(k(n)) .le.1)alb(k(n))=999.
      albm=999.
c
c 4a. Compute albedo from measured values or estimate albedo if one
c of the shortwave components is bad.
      IF(isolarcalc .eq. 0 .or.(isolarcalc .eq. 2.and. rad(1) .le. 9d3))
     &    THEN 
         if(rad(1) .gt. 9000.)stop 'Incoming solar radiation is out 
     1of bounds.  If a 9999. flag is used, you must use the solar cal-
     2culation option.'
         sdown=dmax1(rad(1),0.)
         sup=dmax1(rad(2),0.)
         halbdone = .true.
	 if(rad(2) .lt. 9d3 .and. sdown .gt. 0d0)then
c         Both components available-compute
           albm=dmin1((sup/sdown),1d0)
         else if (ltype(k(n)) .gt. 1)then
c         Use default soil (non-snow) value
           albm=alb(k(n))
         else if (albsnow .lt. 1d0)then
c         Use input snow value
           albm=albsnow
         else
c         Estimate snow albedo from D-M algorithm,  Use 20% diffuse
c         for first pass into insol.f.  This albedo is revised using
c         final %diffuse.
           albvis=albvis0*0.2d0 + albvis1*0.8d0
           albnir=albnir0*0.2d0 + albnir1*0.8d0
           albm=fvis*albvis + (1d0-fvis)*albnir
           halbdone = .false.
         endif
	 if(ltype(k(n)) .le.1)alb(k(n))=albm
         if(sup .gt. sdown)sup=albm*sdown

        callsol = .false.
c 4b.  Call insolation routine for:
c     a) Updating daily values at 0400 hours (ido=1)
        if(ido .eq. 1)callsol=.true.
c     b) Estimating proportion of diffuse to direct radiation
c              when slope option is used
        if(islope.ge.1.and. sdown.gt.0d0)callsol=.true.
c     c) Estimating proportion of diffuse to direct radiation
c              when albedo needs to be computed
        if(.not. halbdone .and. sdown.gt.0d0)callsol=.true.

        IF( callsol ) THEN
            gmt=float(ihour+itimezone)+float(imin)/60d0
            call insol(dlatt,dlongt,jday,cover,icl,prcp,albm,
     1           gmt,sdownarg,cosz,sind,cosd,xm,sdown0,ido,
     2           direct,diffuse,hr,isolarcalc)
c        sdownarg is simulated sdown
           tcosz=dmax1(cosz,0d0)
c           if(alb(k(n)) .gt. 998)goto 110
            if(sdownarg .gt. 0d0)then
               direct=direct*(sdown/sdownarg)
            else if(islope .ge. 1)then
c              Skip slope adjustment in this case
               goto 110
            endif
            diffuse=sdown-direct
	    if(sdown .gt.0d0)then
	     fdiffuse=diffuse/sdown
            else
c Arbitrary default value for diffuse fraction.
             fdiffuse=0.2d0
            endif
        ENDIF

c  4c. Adjust observed solar for sloped terrain. Adjusted solar returned
c      as sdown.
        IF(islope .ge. 1)THEN
               call slope(sinz,tcosz,relazimuth,
     1              coselv,sdown,albm,diffuseslope,directslope,
     2              cover,icl,ecover2,ecover3,clearness,direct,
     3              diffuse,sinelv,cosazi,reflected,hr,azslope,
     &              cosd,elev,dlatt,sind)    
c The sign is different from D-M in the following equation because
c a different convention is used for defining relazimuth
c Nov 27, 1996    costheta=cosz*coselv+sinz*sinelv*cosazi
        ENDIF 

c  4d. Final computation of albedo 
       IF((islope.ge.1 .or. .not. halbdone).and.ltype(k(n)).le.1)THEN
c      Compute albedo for horizontal slope
             albvis=albvis0*fdiffuse + albvis1*(1d0-fdiffuse)
             albnir=albnir0*fdiffuse + albnir1*(1d0-fdiffuse)
             alb(k(n))=fvis*albvis + (1d0-fvis)*albnir
             if(snowdepth .lt.1.0 .and. snowdepth .gt. 0.)
     &        call shallow(albvis,albnir,alb(k(nsoil)),fvis)
        If(islope .ge. 1)then
c      Compute albedo for sloped surface
c      The vis-nir breakdown is adjusted by the fraction of measured 
c      to computed albedos.  Sometimes this makes the vis albedo exceed 
c      1, but not to worry, since the over-all proportion is ok.
              if(rad(2) .lt. 9d3 .and. halbdone)then
               albvis=albvis*albm/alb(k(n))
               albnir=albnir*albm/alb(k(n))
              endif
cNov27,1996 Add change in direct/diffuse ratio for slope.adjust=cosz-costheta
              adjust= - (1.-fdiffuse)*(dum - tcosz)
              if(islope .lt. 1 .or. elev .lt. 0.)then
                costheta=tcosz
                directslope=direct
               else
c Added limit on April 1, 1997
                costheta=dmax1(cosz*coselv+sinz*sinelv*cosazi,0.)
               endif
c Don't compute for solar elevation less than 1deg-solution becoming
c undefined.
               if(directslope .gt.0. .and. tcosz .gt. 0.0174)then
                adjust=adjust+(directslope/sdown)*(dum-costheta)
               else
                adjust=0d0
               endif
c D-M           albvis=albvis + sqrtr*1.375d0*adjust
               	albvis=albvis + sqrtr*1.575d0*adjust
c D-M           albnir=albnir + (2d0*sqrtr+0.1d0)*adjust
                albnir=albnir + (2.4d0*sqrtr+0.12d0)*adjust
c      Next is albedo corrected for slope. Added limit on Nov 27, 1996. 
	        alb(k(n))=dmin1((fvis*albvis + (1d0-fvis)*albnir),1d0)
		albm=alb(k(n))
   70        format(3f10.4,3i6,f10.4)
            endif
             sup=alb(k(n))*sdown
        ENDIF

c 5. SOLAR RADIATION IS ESTIMATED

      ELSE 
         gmt=float(ihour+itimezone)+float(imin)/60d0
         if(ltype(k(n)) .gt. 1)then
           albm=alb(k(n))
         elseif (albsnow .lt. 1d0)then
           albm=albsnow
         else
c        Next estimates variable albedo prior to insol call, assuming
c        that fdiffuse=0.2.
           albvis=albvis0*0.2d0 + albvis1*0.8d0
           albnir=albnir0*0.2d0 + albnir1*0.8d0
           albm=fvis*albvis + (1d0-fvis)*albnir
           if(snowdepth .lt. 1.0 .and. snowdepth .gt. 0.0)
     &     call shallow(albvis,albnir,alb(k(nsoil)),fvis)
         endif
         call insol(dlatt,dlongt,jday,cover,icl,prcp,albm,
     1        gmt,sdown,cosz,sind,cosd,xm,sdown0,ido,
     2        direct,diffuse,hr,isolarcalc)
	 if(sdown .gt.0d0)then
	  fdiffuse=dmax1(diffuse/sdown,0.)
         else
c Arbitrary default value for diffuse fraction.
          fdiffuse=0.2d0
         endif

        sup=0d0
        if((islope .ge.1.or. albsnow .ge. 1d0).and.ltype(k(n)).le.1
     &    .and. sdown .gt. 0d0)then
c  Now recompute vis-nir albedos for horizontal surface 
c  using diffuse-direct breakdown newly computed in insol.f call.
         albvis=albvis0*fdiffuse + albvis1*(1d0-fdiffuse)
         albnir=albnir0*fdiffuse + albnir1*(1d0-fdiffuse)
         alb(k(n))=fvis*albvis + (1d0-fvis)*albnir
         if(albsnow .lt. 1d0)then
c          Scale these to fixed albedo input, for this option
           albvis=albvis*albsnow/alb(k(n))
           albnir=albnir*albsnow/alb(k(n))
         endif
         alb(k(n))=fvis*albvis + (1d0-fvis)*albnir
         if(snowdepth .lt. 1.0 .and. snowdepth .gt. 0.)
     &   call shallow(albvis,albnir,alb(k(nsoil)),fvis)
         if (imetcalc .eq. 1 .and. isolarcalc .ne. 2)sdown=shadow
     1        *direct+diffuse
c Next is the slope adjustment
         if(islope .ge. 1 .and. sdown .gt. 0.0) then
c        Next computes solar radiation incident on sloped surface and
c        and returns it as new sdown 
               call slope(sinz,cosz,relazimuth,coselv,sdown,
     &         alb(k(n)),diffuseslope,directslope,cover,icl,
     &         ecover2,ecover3,clearness,direct,diffuse,sinelv,
     &         cosazi,reflected,hr,azslope,cosd,elev,dlatt,sind)    
c        Next adjust vis-nir albedos for sloped surface
c              costheta=cosz*coselv+sinz*sinelv*cosazi
               adjust= -(1.-fdiffuse)*(dum - cosz)
               if(directslope .gt.0.)adjust=adjust+
     &          (directslope/sdown)*(dum-cosz*coselv-sinz*sinelv*cosazi)
c D-M           albvis=albvis + sqrtr*1.375d0*adjust
               	albvis=albvis + sqrtr*1.575d0*adjust
c D-M           albnir=albnir + (2d0*sqrtr+0.1d0)*adjust
                albnir=albnir + (2.4d0*sqrtr+0.12d0)*adjust
         endif
c        Next computes variable albedo or that adjusted for slopes
          if(ltype(k(n)) .le. 1)
     &    alb(k(n))=dmin1((fvis*albvis + (1d0-fvis)*albnir),1d0)
49      format(4f10.5)
        else
c        Next uses fixed input albedo option with no slope
	  if(ltype(k(n)).le.1)alb(k(n))=albsnow
        end if
        sup=alb(k(n))*sdown
      END IF
c
c   Compute net solar:
 110  solar=sdown-sup

c 6. FURTHER ADJUSTMENTS FOR LONGWAVE RADIATION

c ESTIMATED DOWNWELLING LONGWAVE WHEN MEASUREMENTS ARE UNAVAILABLE
cNov3,1995     if(ircalc .eq. 1 .or. dint(rad(3)) .eq. rbad ) then
      if(ircalc .eq. 1 .or. dint(rad(3)).eq.9999)then
c   For vapor pressure calculation, see comment in section 10.
         ea=fvaprw(tkair,rh,e0)
         call skyrad(cover,tkair,ea,ceiling,dirdown,clearness,1,
     &        ecover2,ecover3)
      elseif(ircalc .eq. 3)then
c        Next reads in net Radiation.  Not implemented.
         dlong=rad(3)
      elseif(ircalc .eq. 4 .or. dint(rad(3)).eq.9999)then
         ea=fvaprw(tkair,rh,e0)
c        Next uses function of Koenig-Langlo.  Not implemented
c        call pskyrad(cover,tkair,ea,ceiling,dirdown,clearness,1,
c    &        ecover2,ecover3,forest,To(n),ifog,prcp,hlowcloud)
      else
         dirdown=rad(3)
      end if

c 7. FURTHER ADJUSTMENTS FOR PRECIPITATION
      if(prcp .gt. 0.0)then
c      Next sets upper limit of air temperature for snowfall at 275.65K.
c      This cut-off was selected based on Fig. 1, Plate 3-1, of Snow
c      Hydrology (1956).
cRJ    June 14,2000.  Next lets model select precip type 
         if(iptype .eq. 0)then
          iptype=2
          if(tkair .gt. 274.75d0)then
           iptype=1
           bwfall=1000
          endif
         elseif(tkair .gt. 275.65d0 .and. iptype .eq. 2)then
           iptype=1
           bwfall=1000
         endif
         if(ltype(ln) .gt. 1)stop 'If precipitaion occurs, you must init
     &ailze a null top layer with type code = 1'
            snowrate=0d0
            rainrate=0d0
         if(iptype .eq.1)then
c         Estimate precip temp from wetbulb temp
            tprecip=wetbulb(tkair,fvaprw(tkair,rh,e0),bp)
            rainrate=prcp/3600.
            snowrate=0d0
            if(dabs(rainrateo).lt. 1d-15)istart=1
            bwfall=1.0d3
            blfall=1.0d3
            bifall=0d0
            flfall=1d0
c  fix next later to reflect minimum temp for freezing rain
            if(tprecip .lt. 273.14)tprecip=273.14
         else
            iptype=2
            tprecip=wetbulb(tkair,fvapri(tkair,rh,e0),bp)
            tprecip=dmin1(273.15d0,tprecip)
            snowrate=prcp/3600.
            rainrate=0d0
            newsno=max0(1,newsno)
            if(dabs(bifallin).gt.950d0 .or. bifallin .lt. 0)then
cNew NP-4 algorithm for computing new-snow density on Dec 8, 1998
c Changed from bifall to bwfall on Feb 13,2002
             If(tkair .gt.258.16d0)then
               Ab=1.4*(278.15-tkair)**(-1.15)+0.008*wsp**1.7
               bwfall=500.*(1. - 0.951*exp(-Ab))
             else 
               Ab=0.008*wsp**1.7
               bwfall=500.*(1. - .904*dexp(-Ab))
             endif
c Nov 19, 1996
            else if(dabs(bifallin) .gt. 1d-7)then
             bwfall=dmax1(dabs(bifallin),30d0)
            endif
            if(dabs(snowrateo).lt. 1d-15 .or. ltype(k(n)) .gt. 1)
     &         istart=1
c The percentage of liquid water by mass is arbitrarily set to vary  
c linearly with air temperature, from that at tlsnow to 40% max at 275.15.
c Dec 26,1996
         if(tkair .le. 275.15 .and. tkair .ge. tlsnow)then
           dum=a1snow*(273.15-tlsnow)
c          Next is liquid fraction (bl/bw) at temperature tlsnow
           dum=1./(1. + dum*dum)
           flfall=dum+(.4-dum)*(tkair-tlsnow)/(275.15-tlsnow)
           flfall=dum+(.1-dum)*(tkair-tlsnow)/(275.15-tlsnow)
         else
           flfall = 0.4d0
           flfall = 0.1d0
         endif
c After flfall is computed, get tprecip from freezing curve for snow
         if(flfall .gt. 0d0 .and. tkair .ge. tlsnow)then
           tprecip=273.15d0 - dsqrt((1d0/flfall)-1d0)/a1snow
         else
           tprecip=tkair
           dum=a1snow*(273.15-tprecip)
           flfall=1./(1. + dum*dum)
           if(flfall .lt. 1d-4)flfall=0d0
         endif
         bwfall=dmax1(bwfall,30d0)
         bifall=(1d0-flfall)*bwfall
         blfall=bwfall-bifall
         if(dsnowfall.gt. .09 .or.dsnowfall.eq.0) then
           dsnowfall=fd(bifall)
         endif
        endif
      else
         snowrate=0d0
         rainrate=0d0
      end if
c  newsno>1 if there has been new snowfall within the past 72 hours
      if(newsno .ge. 1)newsno=newsno+1
      if(newsno .gt. 72.*3600./dtbase)newsno=0
     
      return
 999  return 1
      end
c**********************************************************************
cSHALLOW computes albedo for shallow snow cover. R.Jordan 9/31/96
cSpectral procedure of Choudhury and Chang, 1979, Two-stream theory of
creflectance of snow, IEEE Trans. Geosci. Elec., GE-17, 63-68; adapted
cfor 2 broad-bands.
C**********************************************************************
      subroutine shallow(albinfv,albinfn,albsoil,fvis)

      include 'const'
      include 'arrays'

c Passed arguments
      double precision albinfv,albinfn,albsoil,fvis
      integer i
c Local variables
      real*4 c1,c2,c3,tau,Ar,Qabs,albvis,albnir,dum,wmass
     & ,totmass,radius

      radius=0.
      totmass=0.
      do 10 i=nsoil+1,n
      wmass=bw(i)*dzo(i)
      totmass=totmass+wmass
      radius=radius+.5*d(i)*wmass
10    continue
      radius=radius/totmass     

      tau=1.5*totmass/(dice*radius)

c .2-.7 micron waveband
      c1=albinfv*albsoil-1.
      c2=albinfv-albsoil
      Qabs=0.25*radius
      Ar=0.866*sqrt(Qabs*(Qabs+0.065*(2.-Qabs)))
      dum=albsoil - albinfv
      if(dum .gt. 0d0)then
       Ar=Ar*exp(4.*dum)
      endif
      c3=c2*exp(-2.*Ar*tau)
      albvis=(c1*albinfv+c3)/(c1+albinfv*c3)

c .7-2.4 micron waveband
      c1=albinfn*albsoil-1.
      c2=albinfn-albsoil
      Qabs=0.015
      Ar=0.866*sqrt(Qabs*(Qabs+0.065*(2.-Qabs)))
      dum=albsoil - albinfn
      if(dum .gt. 0d0)then
       Ar=Ar*exp(4.*dum)
      endif
      c3=c2*exp(-2.*Ar*tau)
      albnir=(c1*albinfn+c3)/(c1+albinfn*c3)

c Estmated all-band albedo for shallow snow.
      alb(k(n))=fvis*albvis + (1.-fvis)*albnir
      albinfv=albvis
      albinfn=albnir

      return
      end

