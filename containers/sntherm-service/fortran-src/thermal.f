***********************************************************************
c THERMAL sets up the principal A(1,1) and B(1) matrices for solving
c the linear heat balance equation set. It also solves for the new
c temp T and melt BMELT by application of the tridiagonal matrix
c algorithm.  For nodes within the meltzone, T is determined from
c BMELT within subroutine FTEMP.
c***********************************************************************
      subroutine thermal(dtmin,dzmin,recross,*,errtallowd) 
c %W% %G%
c 
c Called from MAIN
c
c Calls TRIDIAG,FTEMP function FLIQUID
      include 'const'
      include 'arrays'
c Arguments
c
c dtmin : minimum allowed time step [s]
c dzmin : minimum nodal thickness (except for precipitation cases) [m]
c recross : Used in trapping overshot phase boundary.
c errtallowd: maximum allowed linearization error per time-step in heat balance
c             eq, expressed in units of temperature [K]
c
      logical recross
      double precision dtmin,errtallowd,dzmin
c
c Local
c
c blmax: Bulk density of liquid water corresponding to upper melt
c         zone limit [kg/m^3]
c blmin: Bulk density of liquid water corresponding to lower melt
c         zone limit [kg/m^3]
c i: looping index.
c j: looping index.
c m: m=k(i)
c ok: Used in trapping overshot phase boundary.
c redo: Logical flag denoting that it is ok to redo the iteration
c       = dt .gt.1.1*dtmin .and. istart.eq.0.and.iskip(n).eq.0
c
c Passed through common Iincomplete) 
c
c a(nd,3) : Coefficient array in linear equation matrix
c b(nd) : Constant array in linear equation matrix
c bbo(nd) : .5*(Old nodal conducted and convected heat plus absorbed solar)
c dsol(nd) : Nodal absorbed solar radiation [W/m^2]
c gk(nd) : Constant for calculating temperature from melt [K]
c gv(nd) : Coefficient for calculating temperature from melt
c iskip(nd) : 1 signifies that convergence criteria are skipped for
c              this node
c n: Number of nodes in model
c nsoil: Number of soil nodes
c melt(nd): Signifies if node in meltzone if = 1
c qf(nd) : .5*specific heat of water*nodal mass water flux 
c qk(nd) : .5*(thermal conductivity at upper nodal boundary/nodal thickness), 
c qs(nd) : Coefficient on nodal stored heat [W/m^2 K]
c unbar(nd) : Average nodal convective mass flux of water  [K/m^2 s]
c
c
      integer i,m,j
      double precision blmin,blmax
      logical ok,redo
c function
c
c fliquid: liquid water as function of temperature and liquid water content.
c
      double precision fliquid
c
11    format(10g13.5)
c
c interior nodes
      do 10 i=2,n-1
         a(i,1)=-qk(i)
         if(i .gt. nsoil)then
           a(i,2)=qs(i)+qf(i)+qk(i+1)+qk(i)
           a(i,3)=-(qf(i+1)+qk(i+1))
         else
c Temp  Temporary creation of sink at snow/soil interface
           a(i,2)=qs(i)+qk(i+1)+qk(i)
           a(i,3)=-qk(i+1)
         endif
c Temp
         b(i)=qs(i)*to(i)+unbar(i)*ho(i)+.5*dsol(i)+bbo(i)-a(i,1)*
     &   gk(i-1)-a(i,2)*gk(i)-a(i,3)*gk(i+1)
         a(i,1)=a(i,1)*gv(i-1)
c        if(melt(i).gt.0)
         if(melt(i).gt.0 .and. bw(i) .ge. 1d0)
     &                a(i,2)=dlm*dz(i)/dt+a(i,2)*gv(i)
         a(i,3)=a(i,3)*gv(i+1)
 10   continue
c
c top node
c Nov 12, 1996     if(dmass(n) .gt. 1d2*dzmin)then
      if(dmass(n) .gt. 0.8d2*dzmin)then
         a(n,1)=-qk(n)
         a(n,2)=qs(n)+qf(n)+qk(n)-topfluxv
         a(n,3)=0.0
         b(n)=qs(n)*to(n)+unbar(n)*ho(n)+.5*dsol(n)+bbo(n)-a(n,1)*
     1   gk(n-1)-a(n,2)*gk(n)+topfluxk-ci(n)*us(n)*(tprecip-to(n))
         a(n,1)=a(n,1)*gv(n-1)
c        if(melt(n) .gt. 0)then
         if(melt(i).gt.0 .and. bw(i) .ge. 1d0)then
            a(n,2)=dlm*dz(n)/dt+a(n,2)*gv(n)
         end if
      else
c
c     circumvent thermal balance for top elements with minimal mass
c Next added on March 22, 1995
         melt(n)=0
         a(n,3)=0d0
         a(n,2)=1d0
         a(n,1)=0d0
         if(prcp .le. 0d0)then
           b(n)=to(n)
         else
           b(n)=tprecip
           b(n)=(tprecip+to(n-1))/2d0
           if(ltype(k(n)) .le. 1)b(n)=dmin1(th(k(n)),b(n))
         endif
        iskip(n)=1
      end if
c
c  bottom specified constant temperature boundary
      a(1,3)=0d0
      a(1,2)=1d0
      a(1,1)=0d0
      b(1)=to(1)
c
c solve the tridiagonal matrix
      call tridiag(n,a,t,b)
c
c Next first checks to see if melt-zone has been skipped.  If so,
c reset variables and redo this time-step.
c For elements which were within the meltzone, call FTEMP to solve for
c new temp as a function of bmelt.  FTEMP also checks to see if 
c the node has over-shot the meltzone. If the phase boundary was 
c over-shot by more than 5%, the time step is shortened and the itera- 
c tion is repeated.  See routine FTEMP for details.
c     redo=dt .gt. 1.1*dtmin .and. istart .eq.0 .and. iskip(n) .eq. 0
c March(May?) 25, 1995
      redo=dt .gt. 1.1*dtmin .and. istart .eq.0
      ok=.true.
c11.10.03      do 40 j=1,n
      do 40 j=1,n-1
      if(bw(i) .le. 1d0)goto 40 !11.10.03
      i=n+1-j
      m=k(i)
c     if(melt(i) .le. 0)then
      if(melt(i) .le. 0 .or. bw(i) .lt. 1d0)then
c Check to see if melt-zone was totally skipped
        if(to(i) .lt. tl(m).and. t(i).gt.th(m) .or.
     1   to(i) .gt. th(m) .and. t(i) .lt. tl(m))then
           ok=.false.
           dt=dmin1(0.1d0,dtmin)
           recross=.true.
           call reset
           return 1
         endif
       else
         blmin=fliquid(bw(i),tdl(m,1),bdjp(m),a243(m),tdl13(m,1)
     &          ,flglim(m,1))
         blmax=fliquid(bw(i),tdl(m,2),bdjp(m),a243(m),tdl13(m,2)
     &          ,flglim(m,2))
         call ftemp(t(i),dt,bl(i),bw(i),a1(m),
     1      a243(m),unbar(i),dz(i),dzo(i),bdjp(m),td13(i),tl(m),
     2      th(m),blo(i),bmelt(i),
     3      flgo(i),blmin,blmax,dtmin,redo,ok,recross,f(i),
     4      errtallowd,*50)
      endif
      goto 40
c  Next is situation where iteration is being repeated (which was
c  determined in FTEMP)
50    return 1
40    continue
      return
      end
