c***********************************************************************
c Using a combination of newton-raphson and bisection, RTSAFE finds
c the root of a function bracket bewteen x1 and x2. The root,returned
c as the function value RTSAFE will be redefined untill its accuracy 
c is known within +/- xacc. FUNCD is a used supplied subroutiune which
c returns both the function value and the first derivative of the 
c functions. From press et.al. : numerical recipes, p 258.
c***********************************************************************
      double precision function rtsafe(funcd,x1,x2,xacc,p,q,r)
c %W% %S%
c 
      include 'const'
c Called by combo
c
c Calls funcd (not existing)
c
c Arguments
c
c x1, x2: Range in which a root is expected
c
      double precision x1,x2,xacc,p,q,r
      external funcd
c local
c
c df: derivative of function.
c dtol3: dtol3= 1.0d-05
c dx: the last step size.
c dxold: the "step-size before last".
c f: the function.
c fh: function value more than at root.
c fl: function value less than at root.
c istop: Logical flag to stop routine if number of iterations exceed itmax.
c it: number of iterations.
c j: iteration index.
c maxit: maximum number of iterations.
c p: polynomial coefficient.
c q: polynomial coefficient.
c r: polynomial coefficient.
c swap: used in orienting search so f(xl) < 0. 
c temp: temporary variable.
c xl: x where f(xl) < 0 near root.
c xh: x where f(xl) > 0 near root.
c
      integer maxit,j,it
      double precision fl,fh,df,swap,f,xl,xh,dxold,dx,temp
      logical istop
      parameter (maxit=100,istop=.true.)
      call funcd(p,q,r,x1,fl,df)
      call funcd(p,q,r,x2,fh,df)
c orient the search so that f(xl)<0
      if(fl.lt.0.)then
        xl=x1
        xh=x2
      else
        xh=x1
        xl=x2
        swap=fl
        fl=fh
        fh=swap
      endif
c  initialize the guess for root, the "step size" before last."
c and the last step
      rtsafe=.5*(x1+x2)
      dxold=dabs(x2-x1)
      dx=dxold
      call funcd(p,q,r,rtsafe,f,df)
c loop over allowed iterations
      do 11 j=1,maxit
         it=j
c bisect if newton out of range or not decreasing fast enough
        if(((rtsafe-xh)*df-f)*((rtsafe-xl)*df-f).ge.0.
     &        .or. dabs(2.*f).gt.dabs(dxold*df) ) then
           dxold=dx
           dx=0.5*(xh-xl)
           rtsafe=xl+dx
c change in root is negligible
           if( dabs(xl-rtsafe).lt.dtol3)return
        else
c newton step acceptable. take it
           dxold=dx
           dx=f/df
           temp=rtsafe
           rtsafe=rtsafe-dx
           if(dabs(temp-rtsafe).lt.dtol3)return
        endif
c
c convergence criteria
c
        if(dabs(dx).lt.xacc) return
c
c the one new function evalution per iteration.
        call funcd(p,q,r,rtsafe,f,df)
c
c maintain bracket on the root.
c
        if(f.lt.0.) then
          xl=rtsafe
          fl=f
        else
          xh=rtsafe
          fh=f
        endif
11    continue
      if(istop) stop '** _rtsafe exceeding maximum iterations. execution
     & halted**'
      return
      end
