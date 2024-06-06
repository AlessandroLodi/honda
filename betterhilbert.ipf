#pragma rtGlobals=1		// Use modern global access method.

Function odd_construct(xw,yw) // Given two waves xw and yw, representing the x and y values of a function 
							// y(x), defined only for positive (or negative) x values, this function extends 
							// the function y(x) also for negative(positive) x values, in order to have y(x)
							// odd function: y(-x)=-y(x) 
	wave xw, yw	// The two waves. xw should contain only positive or negative values
	Duplicate /O /FREE xw xw_neg, yw_neg 	// It creates two waves, that will contain the "negative" values  
											// for xw and yw, the opposite values for xw and the
											// corresponding values for yw
	xw_neg=-xw
	yw_neg=-yw	// The values for the two "negative" waves are fixed
	Concatenate /O /NP {xw_neg,xw}, $(nameofwave(xw)+"_odd")	// It creates a new waves containing the 
															// "positive" and "negative" values for xw
															// The name of the wave is the same name
															// xw plus the string "_odd"
	Concatenate /O /NP {yw_neg,yw}, $(nameofwave(yw)+"_odd")	// The same for yw
	wave xw_odd=$(nameofwave(xw)+"_odd") 
	wave yw_odd=$(nameofwave(yw)+"_odd")
	Sort xw_odd, xw_odd, yw_odd // The xw_odd wave is ordered in ascending way, and yw_odd is ordered accordingly
End

Function even_construct(xw,yw) 
	wave xw, yw	
	Duplicate /O /FREE xw xw_neg, yw_neg 	
	xw_neg=-xw
	yw_neg=yw	
	Concatenate /O /NP {xw_neg,xw}, $(nameofwave(xw)+"_even")	
	Concatenate /O /NP {yw_neg,yw}, $(nameofwave(yw)+"_even")	
	wave xw_odd=$(nameofwave(xw)+"_even") 
	wave yw_odd=$(nameofwave(yw)+"_even")
	Sort xw_odd, xw_odd, yw_odd 
End

Function betterhilbert(xw, yw, dx)	// It calculates the Hilbert transform of the function y(x), this function being defined by 
								// the waves xw and yw. xw is supposed to be in ascending order
	wave xw, yw	// The two waves that define the function y(x) by points
	Variable dx	// The step of the interpolation: smaller the step better the interpolation, but longer the calculus
	Variable M=numpnts(xw)	// Number of points in the original wave
	Variable N=2*ceil((xw[M]-xw[0])/dx/2)	// Number of points in the interpolated wave
	Interpolate2 /T=1 /I=0 /N=(N) xw, yw	// The interpolation of the yw wave
	wave yw_L=$(nameofwave(yw)+"_L")	
	SetScale /I x, xw[0], xw[M], "", yw_L	// We set the correct scaling for the yw_L wave
	Hilberttransform /DEST=$(nameofwave(yw)+"_H_L") yw_L //We perform the Hilbert transform
	wave yw_H_L=$(nameofwave(yw)+"_H_L")
	SetScale /I x, xw[0], xw[M], "", yw_H_L	// We assign the correct scaling also at the hilbert-transformed wave
	Interpolate2 /T=1 /I=3 /X=$(nameofwave(xw)) /Y=$(nameofwave(yw)+"_H") yw_H_L	// We interpolate, to calculate the hilbert-transformed
																				// wave in the same points of xw
	killwaves yw_L, yw_H_L	// We kill the waves with many points
End

Function quickhilbert(xw,yw,dx,par,m,name)
	wave xw, yw	//x and y wave for the Hilbert transform
	variable dx	//step of the interpolation
	variable par	//0: the function is odd, 1: the function is even
	variable m	// multiplicative factor for the result
	string name	// the name of the final wave
	print par
	if (par==0)
		print 5
		print "We construct an odd function"
		odd_construct(xw,yw)
		wave xh=$(nameofwave(xw)+"_odd")
		wave yh=$(nameofwave(yw)+"_odd")
	elseif (par==1)
		print "We construct an even function"
		even_construct(xw,yw)
		wave xh=$(nameofwave(xw)+"_even")
		wave yh=$(nameofwave(yw)+"_even")
	else
		print "parity must be 0 or 1"
		return 0
	endif
	betterhilbert(xh,yh,dx)
	wave h=$(nameofwave(yh)+"_H")
	h*=m
	variable n=numpnts(xw)
	make /O /N=(n) $(name)
	wave w=$(name)
	w=h[n+1+p]
End