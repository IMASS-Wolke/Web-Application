c***********************************************************************
c Subroutine SUBTIME interpolates linearly between consecutive 
c meteorological data poinmts
c***********************************************************************
         subroutine subtime(repeat)
c %W% %G%
      include 'const'
      include 'arrays'
c
c called from main
c
c arguments
c
c repeat : logical flag denoting a repeat of this iteration (if true)
c
      logical repeat
c
      if(iter .le. 1 .and. .not. repeat)then
c       Next forces step function for tkair at start of precip.
         if(istart .eq. 1)tkairo=tkair
         da=(tkair-tkairo)/dtbase
         dr=(dirdown-dirdowno)/dtbase
         drh=(rh-rho)/dtbase
         dis=(solar-solaro)/dtbase
         dw=(wsp-wspo)/dtbase
         if(istart .eq. 1)tprecipo=tprecip
         dtprecip=(tprecip-tprecipo)/dtbase
c        Recheck the best way to interpolate precip
c        Past read-in precip value is stored , since it is
c        not hit bt interpoaltion routine due to built-in tolerance
         prcpo=prcpstore
c  Next added on March 27,1995.  Eliminates interpolation of precip
         prcpo=prcp
         dprecip=(prcp-prcpo)/dtbase
         prcpstore=prcp
      end if
      tkair=tkairo+da*dt
      tprecip=tprecipo+dtprecip*dt
      wsp=wspo+dw*dt
      rh=rho+drh*dt
      dirdown=dirdowno+dr*dt
      solar=solaro+dis*dt
      solar=dmax1(0d0,solar)
      prcp=prcpo+dprecip*dt
      return
      end
