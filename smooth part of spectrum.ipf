#pragma rtGlobals=1		// Use modern global access method.



macro spectrum_smooth_part(sp,fo,sf)
         string sp,fo
         Variable sf
         Prompt sp, "Enter the wavename of the spectrum"
         Prompt fo, "Enter the output wavename for the background"
         Prompt sf, "Enter smoothing factor"

	  duplicate /O $sp $fo,tmp
         //make/o/N=(numpnts($sp)) $fo,tmp

         duplicate /O/R=[pcsr(B),pcsr(A)] $sp tmp1
         
	  make/O/N=4 cursx = {hcsr(B), hcsr(D), hcsr(C), hcsr(A)}
         make/O/N=4 cursy = {vcsr(B), vcsr(D), vcsr(C), vcsr(A)}
         

        // smooth/E=3 sf, tmp1
         
         //interpolate/T=1/N=(numpnts(tmp1))/F=(sf)/Y=tmp2 tmp1
         
         CurveFit/NTHR=0 Hillequation cursy /X=cursx/D
         interpolate/T=1/N=(numpnts(tmp1))/Y=tmp2 fit_cursy
          duplicate/O $sp $sp+"S"
         //smooth 5, $sp+"S"
         $fo[0,pcsr(b)-1]=$sp+"S"
         $fo[pcsr(b),pcsr(a)]=tmp2[p-pcsr(b)]
         $fo[pcsr(a)+1,numpnts($sp)]=$sp+"S"
         tmp = $fo
         appendtograph $fo
         killwaves tmp, tmp1, tmp2, $sp+"S"
end macro
