#pragma rtGlobals=1		// Use modern global access method.
// routine per fare il fit di gaussiane asimmetriche secondo il metodo di Sthor (NEXAFS spectroscopy, Springer,
// 1996). l'onda dei parametri è composta da:
// w[0] = offset
// w[1] = valore massimo della funzione
// w[2] = posizione del picco
// w[3], w[4] = parametri che influenzano la larghezza asimmetrica --> FWHM = x*w[3]+w[4]
//possono essere fittate piu' n gaussiane asimmetriche inserendo n*4 parametri come espressi da w[1]-w[4]

Function AsymGauss(w,x)
	Wave w; Variable x
	
	Variable r= w[0]
	Variable npts = numpnts(w),i=1
	do
		if( i>=npts )
			break
		endif
		r += w[i]*exp(-(( (x-w[i+1])/( (x*w[i+2]+w[i+3]) / (sqrt(2*ln(4))) ))^2))
		i+=4
	while(1)
	return r
End