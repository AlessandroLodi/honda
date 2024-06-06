#pragma rtGlobals=1		// Use modern global access method.
// routine per fare il fit di Step gaussiani secondo il metodo di Sthor (NEXAFS spectroscopy, Springer,
// 1996). l'onda dei parametri è composta da:
// w[0] = offset
// w[1] = valore massimo della funzione
// w[2] = posizione del picco
// w[3] = FWHM dell'allargamento gaussiano
// w[4] = coefficiente decadimento esponenziale dopo lo step. Se messo a zero, non si ha decadimento 
//esponenziale
//possono essere fittate piu' n gaussiane asimmetriche inserendo n*4 parametri come espressi da w[1]-w[4]

Function StepGauss(w,x)
	Wave w; Variable x
	
	Variable r= w[0]
	Variable npts = numpnts(w),i=1
	do
		if( i>=npts )
			break
		endif
		if (x <= w[i+1]+w[i+2]) 
			r += w[i]*(0.5+0.5*erf((x-w[i+1])/(w[i+2]/1.665)))
		else
			r += w[i]*(0.5+0.5*erf((x-w[i+1])/(w[i+2]/1.665)))*exp(-(w[i+3]*(x-w[i+1]-w[i+2])))
		endif
		i+=4
	while(1)
	return r
End