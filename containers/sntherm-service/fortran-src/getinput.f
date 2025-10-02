c***********************************************************************
c  GETINPUT reads input data from file
c***********************************************************************
      subroutine getinput(ifluxout,isolarcalc,ircalc,islope,itracks,
     &    itm,ioutfiltrate,imetcalc,ngoodmin,itimezone,iy2,jday2,
     &    ihour2,pinv,bp,bext,albsnow,height,dtmin,dtsmin,dtmax,dtssmax,
     &    dssallowed,errtallowd,emsnow,dlatt,elev,dlongt, azslope,dzmin,
     &    dzn,dznm,fnm,ssisnow,frh,bifallin,dmlimit,istboff,iqturb,eta0,
     &    exp1)

      include 'const'
      include 'arrays'  
      
c**Arguments (no nomenclature yet)

      integer ifluxout,isolarcalc,ircalc,islope,itracks,itm
      integer ioutfiltrate,imetcalc,ngoodmin,itimezone,iy2
      integer jday2,ihour2,istboff,iqturb
      double precision pinv,bp,bext,albsnow,height(3)
      double precision dtmin,dtsmin,dtmax,dtssmax,dssallowed,errtallowd
      double precision emsnow,dlatt,elev,ssisnow,frh(ld),eta0
      double precision dlongt,azslope,dmlimit
      double precision dzmin,dzn,dznm,bifallin
c  July 8 1996 - added experemental parameter  (jcm)
      double precision exp1
      character*160 fnm(nfiles)
 
c** Local
      integer i

      read(90,*)ln,pinv,ifluxout,bp,isolarcalc,ircalc,islope,itracks
     1,bext,itm,ioutfiltrate,dtbase,imetcalc,albsnow,ssisnow,bifallin
     2,dmlimit,istboff,iqturb,eta0
      if(itm.eq.1) open(89,file=fnm(3),status='old')

c     If met generation is optioned, radiation must be computed
      if(imetcalc .eq. 1)then
        isolarcalc=1
        ircalc=1
      endif
c  Measurement heights for airtemp, wsp and rh(or dewpoint)
      Read(90,*)height(1),height(2),height(3)
c  Layer parameters
      read(90,*)(nn(i),ltype(i),qtz(i),znaught(i),cd(i),rce(i),rch(i),
     1           ck(i),csk(i),frh(i),i=1,ln)

c  Convergence related input
      read(90,*)ngoodmin,dtmin,dtsmin,dtmax,dtssmax,dssallowed,
     & errtallowd
      if(dint(dtmax) .gt. dint(dtbase/2d0))dtmax=real(dint(dtbase/2d0))
      if(dint(dtssmax) .gt. dint(dtbase/2d0))dtssmax=real(dint(dtbase/
     &  2d0))
      if(dtsmin .gt. 10.001)stop '**Max allowable DTSMIN is 10 sec**'
c  now call look-up chart to get soil parameters for this soil type.
c  if ltype >= 90, then the subroutine reads in user-suppllied
c  parameters from layer.in.
      do 24 i=1,ln
         n=n+nn(i)
         if (ltype(i) .eq. 1 )then
c     This is a snow layer
            if(nn(i) .gt. 0)then
               nosnowcover=0
            else
               nosnowcover=1
            endif
            bd(i)=0.0
            djp(i)=0.0
            alb(i)=albsnow
            em(i)=emsnow
         else
c  soilchart read from main input file for material codes >=90
c else gets info from BLOCK Data file
            call soilchart(ltype(i),i,90)
            nsoil= nsoil+nn(i)
         end if
 24   continue
 
      if(n .ge.nd)stop'Array size (nd)is less than node number (n)+1'
     
c  insolation and slope parameters
      if(islope + isolarcalc .gt. 0)then
        read(90,*)dlatt,dlongt,elev,azslope,itimezone
      if(dlatt .le. 0)stop 'Slope opt. not implemented for S. Hemisph.'
      endif
c  July 8 1996 - changed track parameters to experemental parameters  (jcm)
      if(itracks.eq.2) then
	read(90,*)exp1
      else
	exp1 = 999.0
      endif
c  initial node values
      do 666 i=1,n
         read(90,*,end=39)to(i),dzo(i),bwo(i),do(i)
         if(dzo(i) .lt. dzmin)print *,
     &   'WARNING: Initial thickness of node ',i,
     &   'is less than prescribed minimum of ',sngl(dzmin)
         go to 666
 39      stop 'ERROR: End of data list found in layer.in file.'
666   continue
      close(90)
      open(80,file=fnm(4),status='unknown')
      if(dzo(n) .gt. dzn)write(80,*)'WARNING: Initial thickness of node'
     &,n,'exceeds prescribed maximum of ',sngl(dzn)
      if(dzo(n-1) .gt. dznm)write(80,*)'WARNING: Initial thickness of no
     &de',n-1,'exceeds prescribed maximum of ',sngl(dznm)

      return
      end
