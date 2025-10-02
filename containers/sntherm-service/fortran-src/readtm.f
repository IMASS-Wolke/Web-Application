C***********************************************************************
c READTM reads measured temperature values and converts to Kelvin
c***********************************************************************
      subroutine readtm(ifn,iy1,ij1,ih1,im1,tmsg,tmn,ibasestep)
c %W% %G%
c
c    ifn    : file unit number
c    iy1    : met data year
c    ij1    : met data day
c    ih1    : met data hour
c    im1    : met data minute
c    tmsg   : measured snow/ground interface temperature
c    tmn    : measured surface temperature (first value)
c    ibasestep: Current number of basestep from start of problem
c
c Called from MAIN
c
c arguments
      integer ifn,ij1,ih1,im1,iy1,ibasestep
      double precision tmsg,tmn
c local
c
c ih2: day in file of measured values.
c ij2: hour in file of measured values.
c im2: minute in file of measured values.
c junk: file heading descriptor.
c tmn2: measured surface temperature (second value)
c 
      integer ij2,ih2,im2,iy2
      double precision tmn2
      character*132 junk
c
      if (iy1 .eq. 87) then 
        read(ifn,6)ij2,ih2,tmsg,tmn,tmn2
      else if (iy1 .eq. 90) then
c**need to skip over 4 heading lines and read in imin
        if (ibasestep .le. 1) then
          read(ifn,15)junk
          read(ifn,15)junk
          read(ifn,15)junk
          read(ifn,15)junk
          read(ifn,5)ij2,ih2,im2,tmsg,tmn,tmn2
        else
          read(ifn,5)ij2,ih2,im2,tmsg,tmn,tmn2
        end if
      else
        read(ifn,*)iy2,ij2,ih2,im2,tmsg,tmn
c        continue
      end if
      if(ij1.ne.ij2 .or. ih1.ne.ih2 .or. im1.ne.im2) then
         stop '** file of measured values out of sync with met data**'
      end if
      if(tmsg.lt.1d2)tmsg=tmsg+273.15
      if(tmn.lt.1d2)tmn=tmn+273.15
 5    format(2x,i3,1x,i2,i2,5x,f5.1,94x,f6.1,f6.1)
 6    format(3x,i2,1x,i2,4x,f5.1,43x,f6.1,f6.1)
 15   format(a132)
      return
      end
