
#pragma rtGlobals=1		// Use modern global access method.
// come voigtfit, ma dove ci sono due parametri in piu', il primo per il branching ratio, il secondo per lo spin orbita
//A fitting function utilizing the Voigt profile (a convolution between a Gaussian and a Lorentzian). 
//Can handle a number of peaks depending on the number of points in the coefficient wave w (w1). 
//If w1 contains 7 points then one peak will be generated as follows:
//w1[0]+w1[1]*(Voigt(w1[2]*(x-w1[3]),w1[4]) 
//Parameter w1[0] sets the DC offset, w1[1] sets the amplitude, w1[2]  affects the width, w1[3] sets the location of the peak and w1[4] adjusts the 
//shape (but also affects the amplitude).
//After the fit, you can use the returned coefficients to calculate the area (a) along with the half width at half max for the Gaussian (wg), Lorentzian (wl) and the Voigt (wv). Assuming the coefficient wave is named coef:
//	a= coef[1]*sqrt(pi)/coef[2]
//	wg= sqrt(ln(2))/coef[2] ---> Wg = (sqrt(ln(2))/coef[2])*2   (FWHM)
//	wl= coef[4]/coef[2]      ----> Wl = (coef[4]/coef[2])  (FWHM)
//	wv= wl/2 + sqrt( wl^2/4 + wg^2)
//
//data in the parameter file are entered in eV and in FWHM mode. 
//That is 
//w[0] is the dc offset, 
//w[1] is the area a (intensity); 
//w[2] is the FWHM of  the gaussian
//w[3] sets the position of the peak;
//w[4] is the FWHM of the lorentzian;

//
//You can generate multiple peaks by appending 4 additional coefficient values to the coefficient wave for each peak.
// Each set of four is analogous to coefficients 1-4.

Function VoigtFitsinglet(w,x)
	Wave w; Variable x
	duplicate/O w, w1
	
	variable nupts= numpnts(w),j=1
	do
		if( j>=nupts )
			break
		endif
		w1[j] = (w[j]/w[j+1])*(sqrt(ln(2))/sqrt(pi))*2
		w1[j+1] = (sqrt(ln(2))/w[j+1])*2
		w1[j+2] = w[j+2]
		w1[j+3] = (w[j+3]/w[j+1])*sqrt(ln(2))
		j+=4
	while(1)
	
	Variable r= w1[0]
	variable npts= numpnts(w),i=1
	do
		if( i>=npts )
			break
		endif
		r += w1[i]*(VoigtFunc(w1[i+1]*(x-w1[i+2]),w1[i+3]))
		i+=4
	while(1)
	return r
End