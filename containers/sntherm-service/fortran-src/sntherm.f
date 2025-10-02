      program sntherm 
c***********************************************************************
c One-Dimensional Mass and Energy Balance Model for a Snowcover
c SNTHERM.89   Model developed by R. Jordan,  US Army Cold Regions
c                 Research and Engineering Lab, Hanover, NH
c              Model coded by R. Jordan, USA CRREL and
c                 J. Jones, Sparta Systems, Inc., Lexington, MA
C***********************************************************************
c Complete TECHNICAL DOCUMENTATION can be found in Jordan, R.,"A
c One-Dimensional Temperature Model for a Snow Cover," USA-CRREL
c Special Report 657, in press. A nomenclature list and user's
c instructions are contained in the file DOCUMENTATION. Instructions
c for running the code are contained in the report, "User's quide
c for CRREL one-dimensional snow temperature model," available upon
c request from R. Jordan.
c
c DISCLAIMER: Internal documentation of the code is incomplete and 
c may contain errors.  No attempt has been made to reconcile the
c nomenclature in the code with that in the Technical Report.
c In some instances they agree, but in many there are minor
c inconsistacies in definition, so that care must be taken when
c comparing the equations in the Report with those in the code.
c
c RESTRICTIONS and LIMITATIONS on the code:  SNTHERM.89 is an interim
c model, and will appear in a more complete form as SNTHERM2.  Water
c flow in soil, saturated flow, ponding,and vapor flow in soil are
c not implemented for this version.  A temporary drain has been 
c constructed which removes water from the system when it reaches 
c the snow-soil interface.

C***********************************************************************
c  1. Declare arrays and variable types
c     Principal arrays and variables are declared in ARRAYS
c     ALL REAL VARIABLES ARE DOUBLE PRECISION.  An ending of 'o'
c     in a variable name denotes the previous (old) time step.
c***********************************************************************
      include 'const'
      include 'arrays'
c Local
      integer ido,ihour,ibasestep,itimezone
      integer ifluxout,iy,jday,i,j,m,ii,isolarcalc
      integer ircalc,islope,itracks,itm
      integer iy2,jday2,ihour2
      integer ithour,newsno,iptype,ioutfiltrate
      integer ibounds(15,2),ititle,nzone,nz
      integer igood,ngoodmin,icalcstep
      integer imetcalc,imin,istboff,iqturb
c July 10 1996 - commented out iar to remove compiler warning message
c     integer iar
c
      double precision dtmin,dtmax,dssallowed,errtallowd,dtssmax,dtsum
      double precision bext,depth,dzn,dznm,pinv,tm,de0,bp,tmsg,rtmsq
      double precision snowdepth,difftemp,dtsmin,eta0
      double precision thsnow,tlsnow,ssisnow,bifall,bifallin,dmlimit
      double precision dlsdrw,overburden,dzinc,ci0,dzmin,dlvdrw
      double precision a1snow,rw,emsnow,albsnow,bwfall,blfall
      double precision rmsqt1,height(3)    
      double precision cdryair,dlatt,azslope,rhoair
      double precision bvi0,wmass,elev,bvw0
      double precision ssminsnow,thkair,thkice,dsnowfall,unbarmax
      double precision dlongt,clearness,effceiling
      double precision frh(ld),g1,g2,r1,r2,t1,t2,wt,totaltime,dum
      double precision floo(nd),dzoo(nd),TsurfEst,Esurface
c July 8 1996 added write format variable (ceretha)
      integer writefmt
c July 8 1996 added expermential parameter exp1 (ceretha)
      double precision exp1
c Sept 9 1996 added variables for water output (ceretha)
      double precision meltflux, uosave

      common /insolc/  r1(4,4),r2(4,4),t1(4,4),t2(4,4),wt(4,6)
c
c March 22, 1995    logical print,istop,recross,repeat,fullnode
      logical print,istop,recross,repeat,fullnode,thinnode
c
      character*160 fnm(nfiles),fname
c Function declarations
      integer nmelt
      double precision fvapri,fd,thrk,fvaprw,fliquid
      double precision fgrain
c*****SUN specific
c     real xetime,dtime,tarray(2)
c*****SUN specific
c Data statements
      data ibasestep,ii,igood,ititle/4*0/
      data rmsqt1/0d0/,tm,tmsg/2*0d0/,snowdepth/0d0/
      data dzinc/.04d0/,de0/0.9d-4/,albsnow/0.78d0/,emsnow/0.97d0/
      data rw/461.296d0/,a1snow/100D0/,dzmin/2d-3/,ci0/2117d0/
      data ssisnow/0.04d0/,thkair/2.30d-2/
      data dzn/1.66667d-2/,dznm/3.33333d-2/,cdryair/1.d3/,rhoair/1.276/
      data ido/0/,ithour/0/,newsno/0/
      data icalcstep/0/,recross/.false./,repeat/.false./
      data g1/5.0d-7/,g2/4.0d-12/
c*****DEBUG sun 4 specific only . remove for other machines
c*****DEBUG sun 4      integer ifpe,ieee_handler,sigfpe_abort
c*****DEBUG sun specific only .remove for other machines
c*****DEBUG sun 4       ifpe=ieee_handler("set","common",sigfpe_abort)
c April 13, 1998.  Commented out SUN specific code
c     integer ifpe,ieee_handler,sigfpe_abort
c*****DEBUG sun specific only .remove for other machines
c     ifpe=ieee_handler("set","common",sigfpe_abort)
c      xetime= dtime(tarray)
c***********************************************************************
c  2. Open files
c***********************************************************************
c  Read in file names from FILENAME. (see DOCUMENTATION)
c      open(81,file='c:\sntherm\current_ftp_files\jackie\FILENAME',
c     &     status='old')
      open(81,file='FILENAME',status='old')
      read(81,*) (fnm(i),i=1,nfiles)
      close(81)
c
c  Check for repeat of file names
      do 1 i=1,nfiles
        fname=fnm(i)
        do 2 j=1,nfiles
           istop = i.ne. j .and. fname .eq. fnm(j)
           if(istop) then
             write(*,*)'  **WRITE:_I/O File name repeated.**'
             stop '**Error in I/O file names. Execution Terminated **'
           endif
 2      continue
 1    continue
      open(90,file=fnm(1),status='old')
      open(88,file=fnm(2),status='old')
c  file=fnm(3) conditionally opened if itm=1 after variable read in.
c  file=fnm(4) is opened on 80 at the end of sec. 3, after 90 is closed.
       open(7, file=fnm(5),status='unknown')
      open(80,file=fnm(4),status='unknown')      !nodal information output
       open(99,file=fnm(6),status='unknown')
c***********************************************************************
c  3. Read in snowpack/soil parameters and initial data from layer.in
c     Important note: layers and elements number from the bottom up.
c***********************************************************************
c July 8 1996 added expermential parameter exp1 (ceretha)
       call getinput(ifluxout,isolarcalc,ircalc,islope,itracks,
     &    itm,ioutfiltrate,imetcalc,ngoodmin,itimezone,iy2,jday2,
     &    ihour2,pinv,bp,bext,albsnow,height,dtmin,dtsmin,dtmax,dtssmax,
     &    dssallowed,errtallowd,emsnow,dlatt,elev,dlongt,azslope,dzmin,
     &    dzn,dznm,fnm,ssisnow,frh,bifallin,dmlimit,istboff,iqturb,eta0,
     &    exp1)
       do 12 i=nsoil+1,n
        binew(i)=dmlimit/1.15d0
12     continue
c
c July 26 1996 use ifluxout as output format variable (ceretha)
c
       writefmt = ifluxout/10
       ifluxout = ifluxout - (writefmt * 10)

c***********************************************************************
c  4. Calculate constant parameters
c***********************************************************************
      call calconstant(a1snow,bp,bvi0,cdryair,ci0,dlsdrw,
     & height,rw,snowdepth,ssisnow,ssminsnow,thsnow,
     & tlsnow,bvw0,dlvdrw)
c***********************************************************************
c  5.  Initialize density; other items.
c***********************************************************************
c
      dt=dtmin
      dt=dmax1(dt,1d0)
      dto=dtmin
      totaltime=dtmin
      do 550 i=1,n
         m=k(i)
         if(do(i) .le. dtol1.and.ltype(k(i)).eq.1)then
            do(i)=fd(bi(i))
c           for the initial step, bmelt is used to flag unavailable
c           grain diameter data.
            bmelt(i)=999d0
         endif
         d(i)=do(i)
         call density(to(i),bwo(i),td(i),td13(i),flo(i),blo(i),bi(i),
     1        bt(i),dmass(i),bdjp(m),a243(m),bd(m),a1(m),
     2        0,dzo(i),flgo(i),sso(i),dice,ssi(i),porosity(i),
     &        dmvol(m),ltype(m),impermeable(i),idelete(i),
     &        solidporosity(i),ipond(i),dicevol(i),dliqvol(i), 
     &        rhowater)
         if(sso(i) .gt. .95d0)then
           print *,'Initial value of effective saturation illegally',
     &     ' exceeded 0.95 for node',i,'.  Lower water content slightly'
     &     ,' and restart program.'
           stop
         endif
         bw(i)=bwo(i)
         bl(i)=blo(i)
         ss(i)=sso(i)
         melt(i)=nmelt(to(i),th(m),tl(m))
         floo(i)=flo(i)
 550  continue
      sbt3o=sb*to(n)*to(n)*to(n)
      eso=fvapri(to(n),1.0d2,e0)
      es=eso
      ct(1)=((cl*flo(1)+ci(1)*(1.-flo(1)))*bwo(1)+bdcd(k(1)))/bt(1)
c***********************************************************************
ct*t*t*t*t*t*t*t*t*t*t*t*t*t*t*t*t*t*t*t*t*t*t*t*t*t*t*t*t*t*t*t*t*t*t*t
c     Begin loop over time steps. This is the main loop!  New met
c     parameters are read at the basic time step rate (usually once per
c     hour). Iteration time steps range between dtmin and dtmax seconds
c     and are automatically determined by the code in order that
c     convergence criteria are met.  Met parameters are linearly
c     interpolated between past and current read-in values.
ct*t*t*t*t*t*t*t*t*t*t*t*t*t*t*t*t*t*t*t*t*t*t*t*t*t*t*t*t*t*t*t*t*t*t*t
c***********************************************************************
1001  icalcstep=icalcstep+1
      if(iter .eq. 0)then
         ibasestep=ibasestep+1
c***********************************************************************
c  6a. Read in met data
c***********************************************************************
c July 8 1996 added expermential parameter exp1 (ceretha)
c  read in met data for this time interval
         call getmet(*999,imetcalc,isolarcalc,islope,iy,jday,ihour,imin,
     & ibasestep,ido,iptype,ircalc,itimezone,ititle,itm,newsno,
     & a1snow,azslope,bifall,bifallin,bp,clearness,dlatt,dlongt,
c    & dsnowfall,effceiling,elev,tlsnow,tm,tmsg)
     & dsnowfall,effceiling,elev,tlsnow,tm,tmsg,albsnow,bwfall,blfall,
     & exp1)
      end if
c***********************************************************************
c
c  6b. Subdivide basic time interval and interpolate read-in met values
c     If new node initialized in this iteration, use minimum time step 
c     dtmin
c***********************************************************************
123   if(istart.eq.1 .or. fullnode) dt=dtmin
      if(initial .le. 0)call subtime(repeat)
c
c  Next can be re-instated to see if arrays are being reset properly
c  You must also instate the DEBUG section within reset.f	
c  Set the flux ouput option to 0, since this file is used as a
c  scratch file.
c     m=i+1
c     do 241 iar=1,narray1
c      write(7,*)(array1(i,iar),i=1,n)
c241    continue
c     do 257 iar=1,narray2
c      write(7,*)(array2(i,iar),i=1,n)
c257    continue
c     do 261 iar=1,niarray
c     write(7,*)(iarray(i,iar),i=1,n)
c261   continue
c
c      rewind 7
c
c***********************************************************************
c  7.  Snowfall, sleet or rain ponding on impermeable top element
c***********************************************************************
c  If the top node is impermeable and rainfall occurs, initiate a new
c  top node.
      if((impermeable(n).eq.1.or.sso(n).gt.1d0).and.rainrate.gt.0d0)then
c     Ponding is not implemented in SNTHERM.89
         call newsnow(rainrate,rainrateo,1d-2,1d3,ssminsnow,1d-3,
     1     repeat,0d0,1d3,fullnode,a1snow)
      end if
c  Add new nodes for snowfall
c March 27,1995     if(snowrate.gt.0.0 .or. snowrateo.gt.0.0) then
      if(snowrate.gt.0.0) then
         call newsnow(snowrate,snowrateo,dzinc,bwfall,ssminsnow
     1    ,dsnowfall,repeat,ssisnow,blfall,fullnode,a1snow)
      endif
c Nov. 20, 1996. Nodal array size check
      if(n .gt. nd-1)stop 'Increase nodal array size nd in "const"'

c**********************************************************************
c     8.  Compaction rate for snow
c**********************************************************************
      if(nosnowcover .eq. 1)goto 45
c  Natural compaction and metamorphosis.  The compaction rate
c  is recalculated for every new basestep or continuously when the snow
c  is wet or during new snowfall and for 72 hours afterwards.
      iwet=0
      do 370 i=nsoil+1,n
        if(flo(i) .gt. 1d-3)iwet=1
370   continue
      if(iter .eq. 1 .or. iwet .eq. 1 .or. newsno .ge. 1)then
         overburden=0.0
         do 377 i=n,nsoil+1,-1
            overburden=overburden+dmass(i)
            if(ltype(k(i)) .gt. 1)goto 377
            call compact(bi(i),to(i),blo(i),overburden,pdzdtc(i),ss(i),
     &      dice,bwo(i),flo(i),floo(i),dto,unbar(i),dzo(i),dzoo(i),
     &      melt(i),dmlimit,eta0,binew(i),i,n)
 377     continue
      end if
c 
c  Phase change related density changes are treated in Sec. 14.
c
c**********************************************************************
c  9.  Optical parameters and solar extinction
c**********************************************************************
c  Calculate dsol if there is solar radiation, otherwise dsol = 0.0.
c
45    if(solar .gt. 0d0 .and. nosnowcover .eq. 0)then
         depth=30.
         call sdsol(dsol,d,dmass,fext,depth,n-nn(ln),n,solar,bext)
      elseif(solar .le. 0d0)then
c April 24, 1996        do 112 i=n+1-nn(ln),n+1
        do 112 i=1,n+1
           dsol(i)=0d0
112     continue
c April 24, 1996  IMPORTANT CHANGE for bare soil case
      else
           dsol(n)=solar
           dsol(n+1)=0d0
         do 113 i=1,n-1
           dsol(i)=0d0
113      continue
      end if
C***********************************************************************
c  10.  Top fluxes and stability functions
c***********************************************************************
c  Use fvapri if rh is defined relative to ice saturation, fvaprw
c  if relative to water saturation.
c     ea=fvapri(tkair,rh,e0)
      ea=fvaprw(tkair,rh,e0)
c    Call QTURB to compute wind functions
      m=k(n)
c    First estimate new surface temperature, for a better computation
c    of the Richardson number. Added in Nov, 1996.
       if(icalcstep.le.1 .or. melt(n).eq.1 .or. dabs(u(n+1)).gt.0d0
     &  .or. thinnode)then
        if(thinnode .and. prcp .gt. 0d0)then
         TsurfEst=Tprecip
        else
         TsurfEst=To(n)
        endif
       else 
        if(wspo .ne. 0d0)then
         qsen=(qsen-csk(m))*wsp/wspo + csk(m)
         qlat=(qlat-ck(m))*wsp/wspo + ck(m)
        endif
        topfluxk=(em(m)*dirdown+qsen*tkair+qlat*(ea+frh(m)*eso*
     &    21.452d0)+3d0*em(k(n)) *sbt3o*to(n))/2d0
        topfluxv=-(qsen+frh(k(n))*22.452d0*eso*qlat/to(n)+4d0*em(k(n))
     &    *sbt3o)/2d0
        dum=qs(n)*dto/dt
        TsurfEst=(dum*To(n)+.5d0*dsol(n)+topfluxk+bbo(n)
     &   -heatfluxbtop)/(dum-topfluxv)
c       Limit temperature change to 5 degree/hour.
        if(Tsurfest .gt. To(n))TsurfEst=dmin1(TsurfEst,To(n)+dt/720.)
        if(Tsurfest .lt. To(n))TsurfEst=dmax1(TsurfEst,To(n)-dt/720.)
       endif
       Esurface=fvapri(TsurfEst,1.0d2,e0)
       m=k(n)
       call qturb(height,Tkair,TsurfEst,Ea,Esurface,wsp,wspo,qlat,
     1 qsen,dliqvol(n),cdryair,Rw,Ck(m),Csk(m),snowdepth,ltype(m),
     2 znaught(m),Cd(m),rhoair,bp,dlogTt(m),dlogQq(m),dlogWw(m))
c Next added on March 28, 1995. No evaporation for dry soil.
c     if(n .le. nsoil .and. bwo(n) .le. 1d-10)qlat=0d0
c Jan 29,2001.  Shuts down latent heat flux for low of high water content
      if(n .le. nsoil)then
         frh(k(n))=1d0
         if(bwo(n).ge.0.95 *1d3*porosity(n)  .and. ea .gt.eso)qlat=0d0
         if(bwo(n) .le. bdjp(m) + 1d-1 .and. ea .lt. eso) qlat=0d0
      endif
      if(initial .ge. 1)then
         dlong= em(m)*(dirdown-sbt3o*to(n)) 
         sensheat=qsen*(tkair-to(n))
         dlatheat=qlat*(ea-frh(m)*eso)
         convect=0d0
      end if
      u(n+1)=-1.0d3*rainrate
      topfluxk=(em(k(n))*dirdown+qsen*tkair+qlat*(ea+frh(k(n))*eso*
     &    21.452d0)+3d0*em(k(n)) *sbt3o*to(n)-cl*u(n+1)*tprecip)/2d0
c Jan 7,2002  if(n .le. nsoil)topfluxk=topfluxk+cl*u(n+1)*tprecip/2d0
      if(n .le. nsoil)topfluxk=topfluxk+cl*u(n+1)*to(n)/2d0
      topfluxv=-(qsen+frh(k(n))*22.452d0*eso*qlat/to(n)+4d0*em(k(n))
     &*sbt3o)/2d0
c***********************************************************************
c  11.  Water infiltration from rain or melt
c***********************************************************************
c  Do this section if there is water flow.
c  Skip if a new node has been initialized during this iteration.
c  Snowcover/soil elements are grouped into nzone blocks where there
c  is contiguous water flow.  Block limits are designated in routine
c  NLIMIT.
      if(newelm.gt.0) goto 500
      call nlimit(ibounds,nzone)
      if(nzone .gt. 0)then
      do 65 i=1,nzone
        nz=i
        if(ibounds(nz,2).gt.ibounds(nz,1).or.ibounds(nz,1).lt.1)stop
     &  '**Execution halted in MAIN sec 11.  Incorrect node bounds**'
          call filtrate(ibounds(nz,2),ibounds(nz,1),
     1    *1001,dzmin)
65    continue
      if(ioutfiltrate.eq.1)call outfiltrate(ititle,ibounds,ihour,dtsum,
     1   nzone,jday)
      endif
      unbarmax=0d0
      umax=0d0
      do 451 i=1,n
         umax=dmin1(u(i),umax)
         if(sso(i) .lt. 1d0 .or. i.eq. n)then
            unbar(i)=(uo(i+1)-uo(i)+u(i+1)-u(i))/2d0
cTemp. Used in drain. Remove later
            if (i .le. nsoil) unbar(i) = 0d0
cTempend
         else
            unbar(i)=u(i+1)-u(i)
cTemp.  Used in drain. Remove later
            if (i .le. nsoil) unbar(i) = 0d0
cTempend      
            if(dabs(unbar(i)) .gt. 1d-10)stop '**Net flow for saturated 
     &element is not zero.  Something must be wrong in FILTRATE routine
     &**'
         endif
         unbarmax=dmin1(unbar(i),unbarmax)
 451  continue
c***********************************************************************
c  12.  Sublimation and diffusion of water vapor in snow
c***********************************************************************
c  Based on old temperatures, calculate mass diffused vapor flux.
c  For surface element, change thickness dzo to correspond to mass
c  evaporative losses/gains.
c
 500  call diffusion(de0,bp,bvi0,dlsdrw,frh,dlvdrw,bvw0)
c***********************************************************************
c  12b  Compute new effective grain size for snow
c***********************************************************************
c
      do 42 i=nsoil+1,n
         if(ltype(k(i)) .gt. 1)goto 42
         d(i)=fgrain(g1,g2,ufvapor(i),do(i),dliqvol(i),dt)
c Max grain size arbitrarily set at 5mm. 
         if(d(i) .gt. 5d-3)d(i)=5d-3
42    continue
c
c***********************************************************************
c  13.  Calculate new values for dmass, bw, bt, dz and expansion/
c  contraction of water saturated elements with phase change.
c***********************************************************************
       do 390 i=1,n
c June 25, 1996
         if(ltype(k(i)) .gt.1)then
            ddzdtp(i)=0d0
            pdzdtc(i)=0d0
         endif
c      Next adjusts mass for snowfall 
         wmass=bwo(i)*dzo(i)-us(i)*dt
cTemp. Vapor flow in soil disallowed in SNTHERM.89
         if(ltype(k(i)) .gt. 1 .and. i.ne. n)uvapor(i)=0d0
cTempend
         if(i.eq.n .and. ltype(k(i)).eq.1.and. dmass(n).lt. 80d0*dzmin 
     &    .and. prcp .gt. 0d0) uvapor(n)=0d0  !Feb 13, 2002
         if(wmass-(unbar(i)+uvapor(i))*dt.lt.dtol2)then
c Next 3 lines added on March 28, 1995
        if(newelm .eq.1)write(80,*)'New snow is evaporating or',
     &  'melting faster than it is accumulating.  Increase the snowfall'
     &  ,'rate until this no longer happens, set to 0 or'
     &  , ' combine with neighboring time hack'
c        Ablation of this element has occurred. Flag it for deletion
c        and goto end of loop.
          idelete(i)=1
          iskip(i)=1
          dz(i)=dzo(i)+ddzdtp(i)*dt
          goto 61
         endif
c      Next adjusts mass for water flow
         wmass=wmass-unbar(i)*dt
c      Next adjusts interior nodes or surface soil node for vapor
c      flux.  (Surface snow node handled later.
        if(i.lt.n .or. (i .eq. n .and. ltype(k(n)) .gt. 1)) then  
          wmass=wmass-dt*uvapor(i)
        endif
c      Next block computes change in dz, and bew bulk water density. 
         if((ss(i).lt.1d0.and.porosity(i).gt.0d0))then
c       Case of unsaturated node
c          Change due to snowfall or ponding
            dz(i)=dzo(i)+ddzdtp(i)*dt
c          Change due to compaction
            dz(i)=dz(i)*(1d0+pdzdtc(i)*dt)
            bw(i)=wmass/dz(i)
            if(i.eq.n .and. ltype(k(n)) .eq. 1)then
c           For top snow node, adjustments to mass because of vapor flux
c           are made by changing thickness dz rather than bulk density.
              dz(n)=(wmass-dt*uvapor(n))/bw(n)
            end if
        elseif(i .eq. n .and. ddzdtp(n) .gt. 0d0)then
           dz(n)=wmass/bw(i)
        else
           continue
        end if
61       m=k(i)
         bl(i)=fliquid(bw(i),td(i),bdjp(m),a243(m),td13(i),
     &    flgo(i))
         bt(i)=bw(i)+bd(m)
         dmass(i)=bt(i)*dz(i)
 390  continue
        if(dmass(n) .lt. 80d0*dzmin)iskip(n)=1
        if(dz(n) .lt. 0d0)idelete(n)=1
        thinnode=.false.
        if(dmass(n) .lt. 80d0*dzmin)thinnode=.true.
c1.27.03  Without next, wrong gv and gk switches were selected
        if(iskip(n) .eq. 1)melt(n)=0 !1.27.03
C***********************************************************************
c
c***     END MASS BALANCE   ***
c
c  IMPORTANT PROGRAMMING NOTE:  Only the 'old' designations should be
c  used for variables BWO and DZO prior to Sec. 13 and for variables TO
c  and BLO prior to the thermal balance.
c***********************************************************************
c  14.  Calculation  of thermal parameters
c***********************************************************************
      do 37 i=1,n
      if(ltype(k(i)) .eq. 1)then
c  Effective thermal conductivity of snow, including vapor diffusion.
c  (Note: Temp relationship for thkice has been removed for now)
c        thkice=780d0/to(i)-0.615d0
         thkice=2.290d0
         thk(i) = thkair+(7.75d-5 *bw(i)+ 1.105d-6*bw(i)*bw(i))*(thkice
     1   -thkair)
        if(dliqvol(i) .le.0.02)then
          thk(i)=thk(i)+dls*df(i)
        else
          thk(i)=thk(i)+dlv*df(i)
        endif
      else
c  thermal conductivity for soil.  recalculate for unfrozen soil only
c  when the water content changes.
         m=k(i)
         if(ibasestep .eq.1)goto 557
         if(dabs(bwo(i)- bw(i)).lt.dtol1 .and. to(i).gt.273.15)goto 37
 557     thk(i)=thrk(to(i),dicevol(i),dliqvol(i),dkmg(m),
     1        icoarse(m),dkdry(m),dksatu(m),porosity(i),flo(i))
      endif
 37   continue
c  other thermal parameters
      call thparam

c***********************************************************************
c  15.  Do next if this is the initial iteration
c        Skip energy balance and go to print-out.
c***********************************************************************
      if(initial .eq. 1)then
         if(nsoil .lt.n)hg=-qk(nsoil+1)*(to(nsoil+1)-to(nsoil))
         call old(ido)
         call fbb(qk,to,dsol,qf,topfluxk+topfluxv*to(n),bbo,n,
     1        heatfluxbtop,nsoil)
         dtsum=0d0
         print= .true.
         iter=0
         topfluxo=topfluxk+to(n)*topfluxv
c July 10 1996 - added Bert's flux format (ceretha)
         if(ifluxout .ne. 0)call flux(jday,ihour,ibasestep,iptype,
     &    height,iy,clearness,imin,isolarcalc,effceiling,islope,
     &    ifluxout)
         initial=0
         goto 1000
      end if
c***********************************************************************
c  16.  Thermal balance
c***********************************************************************
      call thermal(dtmin,dzmin,recross,*1001,
     &     errtallowd)
c  Calculate top fluxes using newly calculated top node temperature
      m=k(n)
       es=fvapri(t(n),1.0d2,e0)
       call qturb(height,Tkair,T(n),Ea,es,wsp,wspo,qlat,
     1 qsen,dliqvol(n),cdryair,Rw,Ck(m),Csk(m),snowdepth,ltype(m),
     2 znaught(m),Cd(m),rhoair,bp,dlogTt(m),dlogQq(m),dlogWw(m))
      sbt3=sb*t(n)*t(n)*t(n)
      dlong= em(m)*(dirdown-sbt3*t(n))
      if(n .le. nsoil)then
         if(bwo(n).ge.0.95 *1d3*porosity(n)  .and. ea .gt.eso)qlat=0d0
         if(bwo(n) .le. bdjp(m)+ 1d-1.and. ea .lt. eso) qlat=0d0
      endif
      if(nsoil .lt.n)hg=-qk(nsoil+1)*(t(nsoil+1)-t(nsoil))
      sensheat=qsen*(tkair-t(n))
      dlatheat=qlat*(ea-frh(m)*es)
      convect=-cl*u(n+1)*tprecip
c Jan 7, 2002    if(n .le. nsoil)convect=convect+cl*u(n+1)*t(n)/2d0
      if(n .le. nsoil)convect=convect+cl*u(n+1)*t(n)
      topfluxo=(dlong+sensheat+dlatheat+convect)/2d0
      call fbb(qk,t,dsol,qf,topfluxo,bb,n,heatfluxbtop,nsoil)
C***********************************************************************
c  17.  Final adjustments.  Adjust liquid water fraction after thermal
c       balance, determine melt state and element midpoint position.
c***********************************************************************
      qf(n+1)=.5*cl*u(n+1)
      unbarmax=0d0
      umax=0d0
      do 40 i=1,n
         m=k(i)
      if(i .gt. nsoil)then
        floo(i)=flo(i)
        dzoo(i)=dzo(i)
      endif
         call density(t(i),bw(i),td(i),td13(i),flo(i),bl(i),bi(i),bt(i),
     1        dmass(i),bdjp(m),a243(m),bd(m),a1(m),melt(i),dz(i),
     2        flgo(i),ss(i),dice,ssi(i),porosity(i),dmvol(m),
     &        ltype(m),impermeable(i),idelete(i),
     &        solidporosity(i),ipond(i),dicevol(i),dliqvol(i),rhowater)
         if(idelete(i) .eq. 1)then
cRJ11.10.03             iskip(i-1)=1
             if(i .gt. 1)iskip(i-1)=1
             iskip(i)=1
         endif
         ci(i)=-13.3+7.8*t(i)
         melt(i)=nmelt(t(i),th(m),tl(m))
         umax=dmin1(u(i),umax)
         unbar(i)=(uo(i+1)-uo(i)+u(i+1)-u(i))/2d0
c Next added on Jan 7, 2002
         if(i .le. nsoil)unbar(i)=0d0
         unbarmax=dmin1(unbar(i),unbarmax)
 40   continue
      if(thinnode)melt(n)=0
      call fz(z,dz,snowdepth,nsoil,n)
C***********************************************************************
c  18.  Check if convergence criteria are met. Estimate next time step.
C***********************************************************************
      call converge(repeat,igood,ngoodmin,dtsum,dssallowed,
     1     errtallowd,dtmin,dtmax,dtsmin,dtssmax,print)
c***********************************************************************
c  19.  Optionally print-out summary of met conditions and top fluxes.
c***********************************************************************
c July 10 1996 - added Bert's flux format (ceretha)
      if((iter.eq.0 .or. print) .and. ifluxout .ne. 0)call flux
     &(jday,ihour,ibasestep,iptype,height,iy,clearness,imin,isolarcalc,
     & effceiling,islope,ifluxout)
c***********************************************************************
c  20.  Establish old values for mass, thermal and met parameters.
c       Or if convergence criteria not met, repeat past iteration.
c***********************************************************************
      if(.not. repeat)then
c Sept 9 1996 - added water output variables (ceretha)
	 uosave=uo(nsoil+1)
         call old(ido)
         totaltime=totaltime+dt
      else
         goto 1001
      endif
c***********************************************************************
c  21.  Combine or divide thin or thick snow elements
C***********************************************************************
c
c  After precip has stopped, divide thick snow or ponded water elemnts
      if((prcp .le.0d0.and.(dzo(n).gt.dzn .or. dzo(n-1) .gt. dznm)))then
        nold=n
c April 4, 1995      call subdivide(dzn,dznm,a1snow,dzinc)
        call subdivide(dzn,dznm,a1snow,dzinc,floo)
        dt=1d0
      end if
c Unless it is snowing or water is ponding on top, combine thin elements
      call combinenodes(dzmin,a1snow,thsnow,tlsnow,ssisnow)
c  Reset idelete and iskip flags
      do 3000 i=1,n+1
        iskipo(i)=iskip(i)
        iskip(i)=0
        idelete(i)=0
3000  continue
      nold=n
C***********************************************************************
c   22.  Print-out for this basic time step..
c        If measured surface temps are provided, compute rms error.
c***********************************************************************
c Sept 9 1996 - added variables for water output (ceretha)

1000  meltflux=meltflux + 0.5 * (uosave + uo(nsoil+1)) * dto

      if(ibasestep .eq.0 .or. print)then
         if(itm .ge. 1)then
            if(ltype(k(n)).eq.1 .and.tm .gt. 273.1.and.tm.lt.373.15)then
               tm=273.15
            endif
            if(tm.lt.373.15 .and. ibasestep .gt. 1)then
               rmsqt1=rmsqt1+(tm-t(n))**2
               difftemp=t(n)-tm
               rtmsq=dsqrt(rmsqt1/dble(ibasestep))
            endif
         endif
c
c July 8 1996 added option to write shortened output format (ceretha)
c
	 if (writefmt .eq. 0)then
          call write(pinv,ibasestep,ihour,iy,jday,tm,
     &        de0,bp,difftemp,rtmsq,icalcstep,fnm,tmsg,itm,
     &        height,bext,dtmin,dtmax,dtsmin,
     &        dtssmax,dssallowed,errtallowd,ngoodmin,imin,albsnow,
     &        islope,isolarcalc,ircalc,elev,azslope,
     &        bifallin,dmlimit,istboff,ssisnow,iqturb,eta0)
	 else if (writefmt .ge. 2)then
	  call write2(pinv,ibasestep,imin,ihour,iy,jday,icalcstep,
     &	      meltflux,writefmt)
	 endif
         meltflux=0d0

      endif
cMoved on June 17, 1997      meltflux=0d0
c
      goto 1001
 999  if(itm .ge.1)then
         write(80,2000)rtmsq
2000    format(/,5x,'root mean square error of surface temp = ',f10.4,/)
      end if
c***********************************************************************
c   23.  Closure
c***********************************************************************
C*****SUN Specific
c     xetime= dtime(tarray)
c     write(*,5000)tarray(1),tarray(2)
c     write(80,5000) tarray(1),tarray(2)
c5000  format(/,' CPU = ',1pe11.3,'  SYSTEM= ',1pe11.3)
c*****SUN Specific
      stop '** Execution Completed ** '
      end
