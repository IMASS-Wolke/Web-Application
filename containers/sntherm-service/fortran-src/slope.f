C***********************************************************************
        subroutine slope(sinz,cosz,relazimuth,coselv,sdown,salb,
     &     diffuseslope,directslope,cover,icl,ecover2,ecover3,
     &       clearness,direct,diffuse,sinelv,cosazi,reflected,hr,
     &     azslope,cosd,elev,dlatt,sind)

c %W% %G%
c
c  SLOPE adjusts incident solar radiation 'sdown' for a sloped surface,
c  where 'elev' is the angle of elevation above the horizontal and
c  'azslope'is the azimuthal angle measured clockwise from due north to
c  the fall line.  Reference: R. Shapiro, AFGL-TR-87-0200, Appendix B.
c  Coded by R. Jordan, USA-CRREL.
c
c  Called from MAIN
c
c  Nomenclature
c
c   sinz = sin of zenith angle
c   cosz = cos of zenith angle
c   azslope = azimuthal angle of slope (clockwise from north to falline)
c   azsolar = azimuthal angle of sun (clockwise from north)
c   relazimuth = abs(slope azimuth - solar azimuth) - pi  (Should = 0. 
c     for sun facing slopes)
c   elev = slope elevation angle above horizon
c   coselv = cosine of slope elevation
c   sinelv = sine of slope elevation
c   cosazi = cosine of relative azimuthal angle
c   hr = local hour angle (calculated in subroutine zen)
c   salb = albedo of surface node (salb=sup/sdown)
c   cover(3) = array of cloud cover fractions (low, middle, high)
c   icl(3) = array of cloud code types
c   sdown = incident solar radiation on flat surface.  Returned as
c                 adjusted radiation for sloped surface
c   clearness = combined effective clearness of sky
c   direct = direct component of solar radiation sdown
c   diffuse = diffuse component of solar radiation sdown
c   relected = reflected radiation from slope surface
c   diffuseslope = diffuse radiation incident on sloped surface
c   diffuseclear = diffuse radiation incident on sloped surface
c                  under clear skies
c   directslope = direct radiation incident on sloped surface
c   ratio = ratio of radiance received from solar quadrature to that
c            from anti-solar quadrature (eq. B-1)
c   diffuseovc = diffuse contribution for heavy overcast middle and
c                    lower layers
c   diffusetop = diffuse contribution from top layer
c   dlatt =Degrees latitude
c
c  Arguments
      double precision cosz,azslope,cosd,elev,direct,diffuse,hr,cover(3)
      double precision reflected,diffuseslope,directslope,sdown,salb
      double precision dlatt
      integer icl(3)
c  Local
c
c   azsolar = azimuthal angle of sun (clockwise from north).
c   clearness = combined effective clearness of sky.
c   cosazi = cosine of relative azimuthal angle.
c   coselv = cosine of slope elevation.
c   diffuseclear = diffuse radiation incident on sloped surface
c                  under clear skies.
c   diffuseovc = diffuse contribution for heavy overcast middle and
c                    lower layers.
c   diffusetop = iffuse contribution from top layer.
c   ecover12 = effective cover of bottom two layers.
c   ecover2 = effective cover of middle layer.
c   ecover3 = effective cover of upper layer.
c   pi = 3.14159265.
c   ratio = ratio of radiance received from solar quadrature to that
c            from anti-solar quadrature (eq. B-1).
c   relazimuth = slope azimuth - solar azimuth + pi  (Should = 0. for sun
c     facing slopes).
c   sinelv = sine of slope elevation.
c   sinz = sin of zenith angle.
c   dlattr = latitude in radians
c   sind = sine of solar declination
c
      double precision ratio,pi,diffuseovc,diffusetop,diffuseclear
      double precision sinz,relazimuth,coselv,sinelv,cosazi,clearness
      double precision ecover2,ecover3,ecover12,azsolar,dlattr,sind
c
c  Don't proceed if incoming solar is <= 0.
c
      if(sdown.le.0d0)then
        sdown=0d0
        directslope=0d0
        reflected=0d0
        diffuseclear=0d0
        return
      endif
c
      pi = 3.14159265
      sinz = sqrt(1-cosz*cosz)
      ratio =1. +  0.5*sinz  +  4.*sinz*cosz
      coselv = cos(elev*pi/180.)
      sinelv = sin(elev*pi/180.)
      dlattr=dlatt*pi/180.
c  Eq. for solar azimuth taken from Smithsonian Meteorological Tables,
c  Sixth revised edition, Robert J. List, p.497.  The procedure for
c  resolving quadrature ambiguity comes from Duffett-Smith, Practical
c  Astronomy with your Calculator, New York, Cambridge University 
c  Press, 1988, 3rd ed., page 36. 
c Note: Need to redo this for Southern Hemisphere
      if(sinz .eq.0d0)then
        azsolar=pi
      else if(sind-dsin(dlattr)*cosz .le.0d0)then
        azsolar=dasin(cosd*dsin(hr)/sinz) + pi 
      else if (hr .gt. 0d0)then
        azsolar=2*pi-dasin(cosd*dsin(hr)/sinz)
      else
        azsolar=-dasin(cosd*dsin(hr)/sinz)
      endif
      relazimuth = dabs(pi*azslope/180. - azsolar) - pi
      relazimuth = dabs(relazimuth)
      cosazi=dcos(relazimuth)
c
c  Direct beam radiation on sloping surface (B-9)
      directslope=direct*(coselv+sinz*sinelv*cosazi/cosz)
      if(directslope .lt. 0d0)directslope=0d0
c
c  Diffuse radiation on sloping surface  (B-6)
      diffuseclear=diffuse*((pi-relazimuth)*(ratio+coselv)
     &     + relazimuth*(1. + ratio*coselv))/(pi*(1.+ratio))
c
c  Reflected  radiation on sloping surface (B-10)
      reflected=sdown*salb*(1.-coselv)/2.
c
c  Total downward solar for sloped surface under clear skies
c
      if(clearness .gt. 0.95)then
        diffuseslope=diffuseclear
        sdown=diffuseslope+directslope+reflected
        return
      endif
c
c  For cloudy skies, use an isotropic distribution of diffuse
c  radiation if there are heavy overcast low or middle clouds, or
c  thick cirrus clouds.  For thin cirrus clouds, the distribution is
c  the same as for clear skies.
c
c  Next determines diffuse component for top cloud layer
c    Use clear sky distribution for thin cirrus clouds
      if(icl(3) .eq. 1) then
        diffusetop = diffuseclear
c    Use isotropic distribution for thick cirrus clouds
      else if (icl(3) .eq. 2) then
        diffusetop = diffuse*(1.+coselv)/2.
      end if
c   Next is diffuse component for heavy overcast low or middle clouds
      diffuseovc=diffuse*(1.+coselv)/2.
c
c   Next is total diffuse as weighted combo of levels 1/2 and 3.
      ecover12 = cover(1) + ecover2
      if(ecover12 .gt. 0.95)then
        directslope=0.0
      endif
      diffuseslope=ecover12*diffuseovc + (1.-ecover12-ecover3)*
     &diffuseclear+ecover3*diffusetop
      sdown=directslope + diffuseslope + reflected
      return
      end

