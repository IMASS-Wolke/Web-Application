***********************************************************************
c  WRITE generates principal output file. Parameters for the top node
c  are printed following the completion of a basic time step (in sync
c  with time periods when met values are provided).  Full snow/soil
c  profiles are printed at an optional time interval specified in the
c  input parameter IPRNT
c***********************************************************************
      subroutine write(pinv,ibasestep,ihour,iy,jday,tmn,
     &     de0,bp,difftemp,rtmsq,icalcstep,fnm,tmsg,itm,
     &     height,bext,dtmin,dtmax,dtsmin,
     &     dtssmax,dssallowed,errtallowd,ngoodmin,imin,albsnow,islope,
     &     isolarcalc,ircalc,elev,azslope,bifallin,dmlimit,istboff,
     &     ssisnow,iqturb,eta0)
c %W% %G%
c Called from MAIN
c
      include 'const'
      include 'arrays'
c arguments
c
c pinv : major print-out interval [hr]
c ibasestep: Current number of basestep from start of problem
c ihour : Hour of simulation, (read from met time-hack) 
c imin: Minute of simulation, (read from met time-hack)
c iy : Year of simulation: last 2 digits, (read from met time-hack)
c jday : Julian day of simulation, (read from met time-hack)
c tmn : measured surface temperature (in readtm)
c de0 : effective diffusion coefficient for water vapor in snow  
c bp : approximate average barometric pressure [mb]
c difftemp : difference between measured and calculated surface temperature [k]
c rtmsq : rms error of (calculated - measured surface temperature)
c icalcstep : current number of calcultions from start of problem
c fnm(nfiles) : list of i/o file names
c tmsg : measured snow/ground interface temperature [k]
c itm : read measured temperature flag 1=yes 0=no
c height : height above ground of measured met values
c bext : snow extinction coefficient for near-IR
c dtmin : minimum allowed time step [s]
c dtmax : maximum allowed time step [s]
c dtsmin:  Minimum allowed time step when water flow is present [s]
c dtssmax : maximum time step for saturation criteria [s]
c dssallowed : maximum allowed nodal change in saturation per
c errtallowd: maximum allowed linearization error per time-step in heat 
c             balance eq, expressed in units of temperature [K]
c ngoodmin : minimum number of consecutive good calculations required
c
      integer ibasestep,ihour,iy,jday,istboff,iqturb
      integer itm,icalcstep,ngoodmin,imin,islope,isolarcalc,ircalc
      double precision pinv,bp,de0,tmn,difftemp,rtmsq,tmsg,eta0
      double precision height(3),bext,dtmin,dtmax,dtsmin
      double precision dtssmax,dssallowed,errtallowd,albsnow
      double precision elev,azslope,bifallin,dmlimit,ssisnow
c 
c Local
c
c dzsnow: Thickness of snow in temperature profile.
c fnm(nfiles): list of i/o file names.
c i: looping index variable.
c irem: irem = mod(jday,100).
c m: m=k(i).
c profile: name of output file for temperature profile of snow.
c tsg: t(sg)  = Predicted Snow/Ground Interface Temperature (K).
c precip : Precip type. S=snow, R=rain (character string)
c phase : Phase state, F, T or M (character string)
c
c Passed through common (incomplete)
c
c snowrateo : Old snow rate [m/s]

c rainrateo : Old Rain Rate [m/s]
c n : Number of nodes in model
c k : Layer type assoicated with node
c t : Nodal temperature [K]
c th(ld) : Upper meltzone temperature limit [K]
c tl(ld) : Lower meltzone temperature limit [K]
c
      integer i,m,irem
      double precision tsg,dzsnow,swe
      character*12 fnm(nfiles), profile
      character*1 precip,phase(nd)
      if(snowrateo.gt.0.0)then
       precip='S'
      elseif(rainrateo.gt.0.0)then
       precip='R'
      else
       precip=' '
      endif
      swe=0d0
      do 10 i=1,n
      if(i .gt.nsoil)swe=swe+(dz(i)*bw(i))/1d1
         m=k(i)
         if(t(i).gt.th(m)) then
            phase(i)='T'
         elseif(t(i).lt.tl(m)) then
            phase(i)='F'
         else
            phase(i)='M'
         endif
 10   continue
c
      if(ibasestep .eq. 1) then
         write(80,551)
551   format (/,'WARNING: DID YOU CONVERT PRECIP IN YOUR OLD',
     &    ' MET FILES TO SNOW WATER EQUIV (M/HR)'/)
         write(80,30)n
30    format (/,20x,'Results of CRREL Snow Temperature Model:REV4',/,/,
     & 2x,'Input Data for This Run:',/,
     & /,5x,'Number of Nodes n=',i3)
         write(80,35)ln,pinv,(height(i),i=1,3),dtmin,dtmax,dtsmin,
     & dtssmax,dssallowed,errtallowd,ngoodmin
 35   format(5x,'Number of Layer Types ln=',i4,/,
     &5x,'Major Print-Out Interval pinv=',f6.1,' (hr)',/,
     &5x,'Met Instrument Height above Surface ',/,
     &10x,'Air Temperature   ',f6.2,' (m)'/,
     &10x,'Wind Speed        ',f6.2,' (m)'/,
     &10x,'Relative Humidity ',f6.2,' (m)'/,
     &5x,'Minimum Time Step dtmin= ',f6.1,' (s) ',/,
     &5x,'Maximum Time Step dtmax= ',f6.1,' (s)',/,
     &5x,'Minimum Time Step if Water Flow Present dtsmin= ',
     &f6.1,' (s)',/,
     &5x,'Maximum Time Step for Saturation Criteria dtssmax= ',f6.1,
     &' (s)'/,5x,'Max. Allowed Nodal Change in Saturation ',/,10x,
     &'per Time Step ','dssallowed=',1pe11.4,/,
     &5x,'Maximum Allowed Error in Temperature Estimation ',/,10x,
     & 'per Time Step errtallowd=',1pe11.4,/,
     &5x,'Number of Consecutive Satisfactory Iterations Before ',
     &/,10x,'Time Step Increase ','ngoodmin=',i5)
      if(isolarcalc .le. 2)then
        write(80,*)'     Solar Radiation is Measured'
      else
        write(80,*)'     Solar Radiation is Estimated'
      endif
      if(ircalc .le. 2)then
        write(80,*)'     Longwave Radiation is Measured'
      else
        write(80,*)'     Longwave Radiation is Estimated'
      endif
      if(islope .gt. 0 .and. elev .gt.0d0)then
        write(80,67)elev,azslope
67      format(5x,'Radiation adjusted for slope of elevation of',f4.0
     &   ,' degrees, at an'/,6x,' azimuthal angle of',f4.0,' degrees',
     &   ' counterclockwise from North.')
      endif
      write(80,37)bp,bext,em(k(n))
   37 format(5x,'Barometric Pressure (mb) bp=',f6.1/,
     &5x,'Surface Node Extinction Coefficient bext=',f6.2,' (1/m)'/,
     &5x,'Surface Emissivity em=',f11.4)
      write(80,94)ssisnow
   94 format(5x,'Residual Saturation for Snow is', f6.3)
      if(albsnow .lt. 1d0 )then
        write(80,45) albsnow
      else if(islope.ge.1)then
       write(80,48)
       write(80,49)
      else if(isolarcalc .eq.2)then
       write(80,47)
       write(80,49)
      else
       write(80,46)
       write(80,49)
      endif
45    format(5x,'Surface Albedo=',f11.4)
46    Format(5x,'Surface Albedo is estimated')
47    Format(5x,'Surface Albedo is estimated for bad data points')
48    Format(5x,'Surface Albedo is estimated for sloped surfaces')
49    format(7x,
     & 'WARNING:ESTIMATED ALBEDOS ARE ONLY VALID FOR CLEAR SKIES')  
      if(bifallin .gt. 950d0)then
        write(80,*)'     New Snow Density is Estimated from Temperature'
      elseif(bifallin .gt. 0d0)then
        write(80,71)bifallin
71      format(5x,'New Snow Density has a Fixed Value of',f4.0,
     &  '(kg/m3)')
      else
        write(80,*)'     New Snow Density is Input From Metfile'
      endif
      write(80,72)dmlimit
72    format(5x,'Upper Limit on Destructive Metamorphism Compaction is',
     & f4.0,'(kg/m3)')
      write(80,50)eta0
50    format(5x,'The Viscosity Coefficient Eta0 Is',
     & g11.4,'(kg-s/m2)')
      if(istboff .eq. 1)then
        write(80,*)'     Stability Correction for Stable Conditions is',
     & ' Off.'
c April 7, 1996
c     else
      else if(istboff .eq. 0)then
        write(80,*)'     Stability Correction for Stable Conditions is',
     & ' On.'
c April 7, 1996
      else
        write(80,*)'     Stability Correction for Stable Conditions has' 
     & ,' a minimum.'
      endif
c Nov 19, 1996
      write(80,*)'     Corrections are Computed in QTURB3 (Nov, 1996)' 
      m=k(n)
      write(80,73)100d0*znaught(m),Cd(m)
73    format('     Rougnhness length and Cd are',f5.2,' (cm) and',f8.5)
      write(80,74)rch(m)
74    Format('     Ratio Cd/Ch is ',f4.2)
      write(80,75)rce(m)
75    Format('     Ratio Cd/Ce is ',f4.2)
      write(80,76)csk(m)
76    format('     Windless Convection Coefficent for Sensible Heat is',
     &f5.2,' (J/K m3)')
      write(80,77)ck(m)
77    format('     Windless Convection Coefficent for Latent Heat is',
     &f5.2,' (W/m2 mb)'/)

C
      write(80,36)
 36   format(5x,'LEGEND : ',/,15x,'P = Nodal Phase where ',/,
     &20x,'T = Thaw',/,20x,'M = Melt',/,20x,'F = Frozen ',/,
     &15x,'dz = Nodal Thickness (m) ',/,15x,'z = Distance From Nodal ',
     &'Mid-Point to Ground Surface',/,
     &15x,'t = Nodal Temperature (K)',/,15x,'bt = Nodal Bulk Total ',
     &'Density (kg/m^3)',/,15x,'bw = Nodal Bulk Water Density (kg/m^3)'
     &,/15x,'bl = Nodal Bulk Liquid Density (kg/m^3)',/,
     &15x,'ct = Nodal Effective Specific Heat (J/kg-K)',/,
     &15x,'thk = Nodal Effective Thermal Conductivity (W/m-K)',/,
     &15x,'tm = Measured Surface Temperature (K) (if Available)',/,
     &15x,'t(n) = Predicted Surface Temperature (K)',/,
     &15x,'tmsg = Measured Snow/Ground Interface Temperature  (K)',
     &'(if Available)',/,
     &15x,'t(sg) = Predicted Snow/Ground Interface Temperature (K) ',/
     &15x,'tkair = Air Temperature (K)',/,
     &15x,'rms error is based on t(n)-tm ',//,
     &5x,'NOTE : Nodes Numbered in Decreasing Order from Surface',//)
          write(80,32) fnm(1)
 32       format(/,10x,'INITIAL CONDITIONS FROM FILE :',a14,//,
     & 11x,'Temperature',4x,'Nodal Thickness',1x,'Bulk Water Density',
     &'  Grain Diameter','    Layer Type',/
     & 11x,'    (k)    ',4x,'      (m)      ',1x,'    (kg/m^3)      ',
     & '      (mm)      ',/)
          do 33 i= n,1,-1
          if(bmelt(i) .lt. 900d0)then
             write(80,'(5h     ,i3,5h     ,f6.1,10h          ,f7.3,
     &            10h          ,f7.2,10h          ,f8.6,8x,a10)') i,
     &            to(i),dzo(i),bwo(i),d(i),layertype(i)
          else
             write(80,'(5h     ,i3,5h     ,f6.1,10h          ,f7.3,
     &            10h          ,f7.2,18h             na   ,8x,a10)') i,
     &            to(i),dzo(i),bwo(i),layertype(i)
          endif
          bmelt(i)=0d0
c         'bmelt' was used as a temporary flag. see comment in main.
 33       continue
          write(80,31)
          do 1 i=1,nfiles
             write(80,'(10h          ,a12)') fnm(i)
 1        continue
 31   format(/,' I/O File Names: ',/)
      return
      endif
c
c  Print nodal profiles
c
      if(pinv .gt. dtol1)then
c      if(ibasestep.eq.2.or.(ihour/pinv-dint(ihour/pinv).lt.1d-7.and.
c    &imin .eq. 0).or. pinv .eq. 99)then
c Changed from every xth hour to every xth basestep
      if(ibasestep .eq. 2 .or.((ibasestep)/pinv-dint((ibasestep
     &)/pinv)) .lt. 1d-7 .or. pinv .eq. 99)then
         write(80,61)(i,phase(i),dz(i),z(i)-soildepth,t(i),bt(i),bwo(i),
     &        blo(i),ct(i),thk(i),d(i),layertype(i),i=n,1,-1)
 61   format(/,2x,'i',1x,'P',5x,'dz(i) ',6x,'z(i) ',6x,'t(i) ',7x,
     & 'bt(i) ',6x,'bw(i) ',6x,'bl(i) ',6x,'ct(i) ',4x,'thk(i) ',4x,
     & 'd(i)  ',1x, 'layer',/,
     & 11x,'(m)',8x,'(m)',8x,'(K)',8x,'(kg/m^3)',4x,'(kg/m^3)',4x,
     & '(kg/m^3)',3x,'(J/kg-K)',3x,'(W/m-K)',4x,' (m)  '
     & //,102(i3,1x,a1,3x,f8.5,3x,f8.5,4x,f8.3,3(2x,f10.4),3x,
     & f8.1,3x,f8.5,1x,f8.6,a10,/)/)
c
C     Temperature profiles for snow
cTEMP
      goto 888
      profile(1:1)='o'
      profile(2:2)=char( iy/10 + 48)
      profile(3:3)=char( mod(iy,10) + 48)
      profile(4:4)=char( jday/100 + 48)
      irem = mod(jday,100)
      profile(5:5)=char( irem/10 + 48)
      profile(6:6)=char( mod(irem,10) + 48)
      profile(7:7)=char( ihour/10 + 48)
      profile(8:8)=char( mod(ihour,10) + 48)
      profile(9:12)='.dat'
            open(100,file=profile,status='unknown')
            dzsnow=dz(nsoil+1)/2.0
            write(100,'(f10.4,1h ,f10.4,1h ,a8)')t(nsoil+1),dzsnow,
     &           profile(2:8)
           do 3001 i=nsoil+2,n
              dzsnow=z(i)-z(nsoil+1)+dz(nsoil+1)/2.0
              write(100,'(f10.4,1h ,f10.4)') t(i),dzsnow
3001       continue
           close(100)
cTEMP
888   continue

         if(itm.ge.1) then
            write(80,151)
         else
            write(80,152)
         endif
      endif
      endif
c
c     print out the results of this iteration
 127  format(3g10.4,2g15.4)
 151  format(//,2x,'date-time',9x,'tm',9x,'t(n)',6x,'tmsg',7x,'t(sg)'
     &     ,6x,'tkair',4x,' t(n)-tm ',3x,'rms error',1x,'nodes',1x,
     &     'calc-iter',/)
 152  format(//,2x,'date-time',9x,'t(n)',7x,'t(sg)'
     &     ,6x,'tkair',4x,1x,'nodes',1x, 'calc-iter',/)
      if(n .gt. nsoil)then
         tsg= (t(nsoil)*dz(nsoil+1)+t(nsoil+1)*dz(nsoil))/
     &     (dz(nsoil+1)+dz(nsoil))
      else
         tsg=t(nsoil)
      endif
      if(itm.ge.1) then
         write(80,52)iy,jday,ihour,imin,tmn,t(n),tmsg,tsg,tkair,difftemp
     &       ,rtmsq,n,phase(n),icalcstep,precip
      else
         write(80,53)iy,jday,ihour,imin,t(n),tsg,tkair,n,
     &        phase(n),icalcstep,precip
      endif
 52   format(i2,i3,1x,i3,i3,2x,5f11.3,3x,f7.3,5x,f7.3,2x,i4,
     &     1x,a1,i7,1x,a1)
 53   format(i2,i3,1x,i3,i3,2x,3f11.3,2x,i4,1x,a1,i7,1x,a1)
c 952  format(i2,b'###',1x,b'##','0000',14f8.3,/,12x,14f8.3)
 34   continue
      return
      end
