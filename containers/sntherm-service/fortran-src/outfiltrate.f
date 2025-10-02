c***********************************************************************
c  OUTFILTRATE creates an output file which contains computed
c  parameters relating to water infiltration.
c***********************************************************************
      subroutine outfiltrate(ititle,ibounds,ihour,dtsum,nzone,jday)
      include 'const'
      include 'arrays'
c %W% %G%
c
c Called from MAIN
c
c Calls function fa
c
c arguments
c
c ititle : flag to print header for filtration output
c ibounds(15,2) : boundaries (element numbers) of zones
c ihour : Hour of simulation, (read from met time-hack)
c dtsum : time from start of input data interval [s]
c nzone : number of zones of contiguous water flow
c jday : Julian day of simulation, (read from met time-hack)
c
      integer ititle,ibounds(15,2),ihour,nzone,jday
      double precision dtsum
c
c local
c
c duma: mass water flow coefficient through snow, where
c       u=-duma*sso^3
c fa: function fa.f.
c i: index related to j as i=n+ibounds(nzone,2)-j.
c j: looping index.
c se: is the equilibrium effective saturation for the current rainfall.
c     Not implemented
c
c Passed through common
c
c u(nd): Nodal convective mass flux of water [kg/m^2-s]
c sso(nd): Old effective water saturation
c ss(nd): Effective water saturation = (s - ssi)/(1. - ssi)
c bw(nd): Nodal water constituents bulk density [kg/m^3]
c flo(nd): Nodal fraction of liquid (unfrozen) water due to both capillary
c      and adsorbed potential =blo/bwo
c d(nd): Nodal snow effective grain diameter (m)
c n: Number of nodes in model
c bi(nd): Nodal bulk density of ice [kg/m^3]
c bd(nd): Bulk density of dry soil material [kg/m^3]
c k(nd): Layer type assoicated with node
c
c function
c
c fa: computes coefficient 'a' used in estimating mass water flow u 
c     through snow as a function of effective water saturation ss
c
      integer i,j
      double precision fa,duma,se
      if(ititle.eq.1)write(99,16)
16    format('day hour dtsum  rainrate node    sso       ss         u',
     & '        bw        fl      ak        d',/)
      ititle=0
      do 18 j=ibounds(nzone,2),ibounds(nzone,1)
         i=ibounds(nzone,1)+ibounds(nzone,2)-j
c     se is the equilibrium effective saturation for the current rainfall
         duma=fa(d(i),bi(i),bd(k(i)),sso(i))
c     Note: Computation of se not implemented 
         se=0.0
         if(duma .gt.0d0)se=(-u(n+1)/duma)**.33333d0
      write(99,88)jday,ihour,dtsum,u(n+1),i,sso(i),ss(i),u(i),bw(i),
     1        flo(i),duma,d(i)
18    continue
 88   format(i3,i3,f8.1,1x,e9.3,1x,i3,4(1x,e9.3),1x,f7.3,2(1x,e9.3),/)
      return
      end
