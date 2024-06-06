#pragma rtGlobals=1		// Use modern global access method.
//  DONIACH-SUNJIC

// w[0] = offset
// w[1] = ampiezza
// w[2] = parametro di asimmetria
// w[3] = posizione
// w[4] = FWHM senza asimmetria

Function DoniachSunjic(w,x) : FitFunc
	Wave w; Variable x
		duplicate/O w, w1
	
	variable nupts= numpnts(w),h=1
	do
		if( h>=nupts )
			break
		endif
		w1[h] = w[h]
		w1[h+1] = w[h+1]
		w1[h+2] = w[h+2]
		w1[h+3] = w[h+3]
		h+=4
	while(1)
	

	variable npts= numpnts(w)
	variable nPeaks = floor((numpnts(w)-1)/4)
	variable j=1,i=1
	variable r = w[0],r1,theta,epsilon
	
	for(i = 1; i <= nPeaks; i += 1)
		epsilon = w[i+2]-x
		r1 = w[i] * gamma(1-w[i+1])/(epsilon*epsilon + w[i+3]*w[i+3]/4)^((1-w[i+1])/2)
		theta = (1-w[i+1])*atan(epsilon/w[i+3])
		r1 *= cos(pi*w[i+1]/2+theta)
		r += r1
	endfor
	
	return r
		
End