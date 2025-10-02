c***********************************************************************
c  TRIDIAG is the Tri-Diagonal-Matrix algorithm. Reference:
c***********************************************************************
      subroutine tridiag(n,a,t,b)
c %W% %G%
c arguments
c
c a(nd,3) : Coefficient array in linear equation matrix
c b(nd) : Constant array in linear equation matrix
c n : Number of nodes in model
c t(nd) : Nodal temperature [K]
c
c Called from filtrate and thermal
c

      include 'const'
      integer n
      double precision a(nd,3),t(nd),b(nd)
c local
c
c at: at=a(i,1)/a(i-1,2).
c i: looping index.
c m: array index (m=n-i).
c n1: n1=n-1. Used in back substitution loop.
c
      integer i,n1,m
      double precision at
c
      t(1)=b(1)
      do 15 i=2,n
         at=a(i,1)/a(i-1,2)
         a(i,2)=a(i,2)-at*a(i-1,3)
         t(i)=b(i)-at*t(i-1)
 15   continue

c        back substition

      n1=n-1
      t(n)=t(n)/a(n,2)
      do 10 i=1,n1
         m=n-i
         t(m)=(t(m)-a(m,3)*t(m+1))/a(m,2)
  10  continue
      return
      end
