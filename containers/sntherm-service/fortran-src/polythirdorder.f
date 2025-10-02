c***********************************************************************
c POLYTHIRDORDER returns the value of the function and the first
c derivative, both evaluated at x. (Include reference)
c***********************************************************************
      subroutine polythirdorder(p,q,r,x,fx,dfxdx)
c %W% %G%
c
c
c function = x^3 + p*x^2 + q*x + r
c
c     called from rtsafe (a root solver which is called in combo)
c
c  arguments
c
c    x     : function to be calculated at this point
c    fx    : value of function at x
c    dfxdx : value of first derivative at x
c
c from common block /coefficients/ which are determined in combo
c
c    p     : coefficent of x^2
c    q     : coefficent of x
c    r     : constant
c    s     : not used
c
c arguments
      double precision p,q,r,x,fx,dfxdx
c      include coefficients
c
c local
c
c xcube: x**3.
c xsqr: x**2.
c
      double precision xsqr,xcube
c
      xsqr=x*x
      xcube=x*xsqr
c calculate value of function and first derivative
      fx= xcube+ p*xsqr + q*x + r
      dfxdx= 3*xsqr + 2*p*x + q
      return
      end
