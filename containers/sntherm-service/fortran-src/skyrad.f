C***********************************************************************
      subroutine skyrad (cover,tkair,ea,ceiling,errsky,clearness,nmax,
     &   ecover2,ecover3)
c %W% %G%
c Routine modified march 1990 for use in sntherm. Basic algoritm is
c unchanged.
c NOTE: I have reservations about the cloud covered portion of this
c routine.  Needs to be validated.  R.J.
c
c Description: subroutine skyrad calculates long-wave irradiance
c            on ground from sky/cloud using, wachtmann model(sasc sr #5)
c
c          author: Joan-Marie Freni
c                  sasc technologies, inc.
c                  april, 1986
c
c List of variables:
c
c     cover(3) =   fractional cloud amount
c     ceiling(3) =    cloud base height. (km) (i=1 low cloud;
c                  =2  middle cloud;  =3 high cloud)
c     tkair =       surface air temperature. (K)
c     ea =      surface air vapor pressure (mbar)
c     sz =         cloud height weighting factor
c     emfull =         clear air bulk emissivity (ids0) (full spectrum)
c     emwfull =         clear air bulk emissivity (wachtmann) (full spectrum)
c     errcld =     ground irradiance from clouds (watt/m**2) (fs)
c     errclr =     ground irradiance from clear sky (watt/m**2) (fs)
c     errsky =     sky/cloud irradiance on target scene. (watts/m**2) (fs)
c     clearness =      approximate clearness factor for the sky
c     nmax : = 1 as called from MAIN.
c     ecover2  =  effective cover for middle clouds (cover(2)*(1-cover(1))
c     ecover3  =  effective cover for high clouds (cover(3)*(1-cover(1))
c                                                *(1-cover(2))
c
c  Called from MAIN
c
c  Calls plank
c
c  Arguments
      double precision cover(3),tkair,ea,clearness
      double precision ceiling(3),ecover2,ecover3
      integer nmax
c  Local
c 
c dw: dw=.1 
c errcld: Full spectrum cloud irradiance.
c errclr: Full spectrum clear sky irradiance.
c errsky: Full spectrum total sky irradiance.
c emfull: clear sky emissivity from Idso formula.
c emwfull: clear sky emissivity from Idso formula with Wachtmann correction.
c i: looping and cloud ceiling index.
c rad: blackbody irradiance.
c sz(3): cloud weighting factors.
c w1: w1=8. 
c w2: w2=14.
c
      integer i
      double precision w1,w2,dw,emfull,emwfull,sz(3)
      double precision errcld,errclr,errsky
c
      w1=8.
      w2=14.
      dw=.1
c
c  Cloud weighting factors
c
      do 10 i=1,3
         sz(i)=80.-5. * ceiling(i)
  10  continue
c
c  Bulk emissivity
c
c    First compute clear sky emissivity from Idso formula
      emfull=.7+5.95d-05*ea*exp(1500./tkair)
c    Now apply Wachtmann correction, since Idso formula overestimates
c    emissivity
      emwfull=-.792+3.161*emfull-1.573*emfull*emfull
c
c  Clear sky irradiance
c
c     Full spectrum:
      errclr=5.67d-08*emwfull*(tkair**4)
c
c Cloud irradiance
c Note: Need to recheck this section
c
c     Full spectrum:
      if(nmax .gt. 0) then
        errcld=cover(1)*sz(1) + ecover2*sz(2) + ecover3*sz(3)
c       If cloud fraction data was not given approximate clearness with
c       estimated clearness fraction based on measured solar/theoretical
c       solar
        errcld=(1.-clearness)*sz(1)
      endif
c
c Total irradiance
c
c     Full spectrum:
      errsky=errclr+errcld
c
c  The remainder of this AFGL routine uses the Stefan-Boltzann equation
c  to compute the sky temperatures, which are not required by SNTHERM.
      return
      end
