c***********************************************************************
c Block data INIT initializes common block variables via block data
c***********************************************************************
      block data init
c %W% %G%
      include 'const'
      include 'arrays'
c
      data sdown,sdowno,sup,supo,dirdown,dirdowno,wsp,wspo,wdir,solar,
     & solaro,wdiro,rh,rho,tkair,tkairo,ea,eao,es,eso,rainrate,
     & snowrate,qsen,qseno,qlat,qlato,hg,hgo,sbt3o,sbt3,topfluxo,
     & convect,convecto,dlong,dlongo,sensheat,sensheato,dlatheat,
     & dlatheato,heatfluxbtop,tprecip,tprecipo,dto,topfluxv,topfluxk,
     & da,dr,drh,dw,dtprecip,heatfluxbtopo,soildepth,dt,flfall/54*0d0/
      data t/nd*0d0/,to/nd*0d0/,bl/nd*0/,bt/nd*0/
      data bi/nd*0d0/,gk/nd*0d0/,gv/nd*0/,qf/nd*0/
      data qs/nd*0d0/,qk/nd*0d0/,flo/nd*0/,td/nd*0/
      data do/nd*0d0/,dmass/nd*0d0/,bbo/nd*0/,thk/nd*0/
      data b/nd*0d0/,hso/nd*0d0/,ss/nd*0/,ssi/nd*0/
      data ufvapor/nd*0d0/,solidporosity/nd*0d0/,k/nd*0/
      data z/nd*0d0/,bw/nd*0d0/,u/nd*0d0/,uo/nd*0d0/,djp/ld*0d0/
      data unbar/nd*0d0/,fext/nd*0d0/,melt/nd*0/,ice/nd*0/
      data cf,cfo/2*0d0/,cl/4212.7d0/,sb/5.669d-8/,e0/6.1368d0/
      data umax/0d0/,meltsnow,n,iwet,nfront,ln,nold/6*0/,initial/1/
      data pdzdtc/nd*0d0/,ddzdtp/nd*0d0/prcp,prcpo/2*0d0/
      data nosnowcover/0d0/,a2/ld*0d0/,bdjp/ld*0d0/,a243/ld*0d0/
      data a213/ld*0d0/,a223/ld*0d0/,bdcd/ld*0d0/,cds/ld*0d0/
      data idelete/nd*0/,iskip/nd*0/,istart/0/,td13/nd*0d0/
      data ceiling/1d0,6d0,10d0/,snowrateo,rainrateo/2*0./
      data porosity/nd*1d0/,iter,newelm/2*0/,sso/nd*0d0/
      data dtbase/3600d0/,dlm/3.335d5/,dls/2.838d6/,dmvol/ld*0d0/
      data nsoil/1*0/,bmelt/nd*0d0/,ipond/nd*0/,impermeable/nd*0/
      data us/nd*0d0/,d/nd*0d0/,dsol/nd*0d0/
      data hs/nd*0d0/,f/nd*0d0/,ho/nd*0d0/,flgo/nd*0d0/,uvapor/nd*0d0/
      data iskipo/nd*0/,dbvdt/nd*0d0/,ci/nd*0d0/
      data bwo/nd*0d0/,dz/nd*0d0/,dzo/nd*0d0/,df/nd*0d0/,dsolo/nd*0d0/
      data dicevol/nd*0d0/,dliqvol/nd*0d0/,rhowater/1d3/,dice/0.917d3/
      data cover/3*0d0/,icl/3*0/rad/3*0d0/,dlv/2.5045d6/
      data prcpstore/0d0/
      end
