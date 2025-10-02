c***********************************************************************
c  Block Data DINSOL initializes constants used in solar insolation
c  routine INSOL.
c***********************************************************************
      block data dinsol
c %W% %G%
      double precision r1,r2,t1,t2,wt
      common /insolc/  r1(4,4),r2(4,4),t1(4,4),t2(4,4),wt(4,6)
c*****Common Block /insolc/*****
c r1(4,4): = Cubic polynomial coefficients for Reflectivity
c            for clear sky
c r2(4,4): = Cubic polynomial coefficients for Reflectivity
c            for cloudy skies.
c t1(4,4): = Cubic polynomial coefficients for Transmissivty
c            for clear skies
c t2(4,4): = Cubic polynomial coefficients for Transmissivty
c            for cloudy skies.
c wt(4,6): = Biquadratic polynomial coefficients for the Weights.
c*******************************
c rclr=a0 + a1*cosz + a2*cosz^2 + a3*cosz^3, where in the
c following array the rows are a0, a1, a2 and a3, and
c the columns corespond to
c  1. Highest layer
c  2. Middle layer
c  3. Lowest layer
c  4. Smoke/fog (Not used in this model)

      data r1/.12395,.15325,.15946,.27436
     &, -.34765,-.39620,-.42185,-.43132
     &,.39478,.42095,.48800,.26920
     &,-.14627,-.14200,-.18492,-.00447/
c*******************************
c rcld=a0 + a1*cosz + a2*cosz^2 + a3*cosz^3, where in the
c following array the rows are a0, a1, a2 and a3, and
c the columns correspond to 
c  1. Thin Ci/Cs
c  2. Thick Ci/Cs
c  3. As/Ac
c  4. Low cloud

      data r2/.25674,.42111,.61394,.69143
     &,-.18077,-.04002,-.01469,-.14419
     &,-.21961,-.51833,-.17400,-.05100
     &,.25272,.40540,.14215,.06682/
c*******************************
c tclr=b0 + b1*cosz + b2*cosz^2 + b3*cosz^3, where in the
c following array the rows are b0, b1, b2 and b3, and
c the columns corespond to
c  1. Highest layer
c  2. Middle layer
c  3. Lowest layer
c  4. Smoke/fog (Not used in this model)

      data t1/.76977,.69318,.68679,.55336
     &,.49407,.68227,.71012,.61511
     &,-.44647,-.64289,-.71463,-.29816
     &,.11558,.17910,.22339,-.06663/
c*******************************
c tcld=b0 + b1*cosz + b2*cosz^2 + b3*cosz^3, where in the
c following array the rows are b0, b1, b2 and b3, and
c the columns correspond to 
c  1. Thin Ci/Cs
c  2. Thick Ci/Cs
c  3. As/Ac
c  4. Low cloud

      data  t2/.63547,.43562,.23865,.15785
     &,.35229,.26094,.20143,.32410
     &,.08709,.36428,-.01183,-.14458
     &,-.22902,-.38556,-.07892,.01457/
c*******************************
c W=c0 + c1*cosz + c2*fk + c3*fk*cosz + c4*cosz^2 + c5*fk^2, 
c where in the following array the rows are co,c1,c2,c3,c4
c and c5, and the columns correspond to 
c  1. Thin Ci/Cs
c  2. Thick Ci/Cs
c  3. As/Ac
c  4. Low cloud

      data wt/0.675,1.552,1.429,1.512
     &,-3.432,-1.957,-1.207,-1.176
     &,1.929,-1.762,-2.008,-2.160
     &,0.842,2.067,0.853,1.420
     &,2.693,0.448,0.324,-0.032
     &,-1.354,0.932,1.582,1.422/
      end
