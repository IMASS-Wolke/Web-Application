c***********************************************************************
c  block data SOIL contains soil characteristics. (Note: These values
c  need to be refined.)
c***********************************************************************
      block data soil
c %W% %G%
      include 'const'
      include 'arrays'
c columns of scharc are 1) intrinsic density of dry mineral solids
c                       2) bulk density of substance
c                       3) heat capacity of dry mineral solids
c                       4) thermal cond of dry bulk substance
c                       5) coarseness code.  1.=coarse   2.=fine
c                       6) plasticity index
c                       7) albedo (normal incidence)
c                       8) emissivity.
      data scharc/
c  clay
     &2.7d3,   1.0d3,  0.80d3,   1.13d-1,  2.d0,  0.2d0,  0.4d0,  0.9d0,
c  sand
     &2.7d3,   1.6d3,  0.71d3,   1.84d-1,  1.d0,  .5d-1,  0.4d0,  0.9d0/
c Soil character string description
      data soiltype/'   Snow   ','   Clay   ','   Sand   ',
     &  96*'          '/
      end
