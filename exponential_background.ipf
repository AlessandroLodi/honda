#pragma rtGlobals=1		// Use modern global access method.

#pragma rtGlobals=1		// Use modern global access method.
// la macro chiede in ingresso il nome della wave delle Y di cui si vuole trovare il fondo
// e il nome della wave di background
// Per fare il fit del background NON occorre graficare la wave Y vs. 'Calculated X wave'. Il fit viene fatto
// rispetto alla scala scelta per la wave Y. 
// Occorre poi posizionare i cursori A e B sul grafico in modo da individuare i punti tra i quali il 
// background verrà calcolato. deve inoltre essere posizionato in sequenza A,B, C un terzo cursore
//per il terzo punto in cui fare passare il background.
// N.B. Il cursore A deve stare verso le energie cinetiche maggiori (minori binding energy) e
// il cursore B deve stare verso le energie cinetiche minori (maggiori binding energy)

macro exponential_background(sp,fo)
	string sp,fo
	Prompt sp, "Enter the wavename of the spectrum"
	Prompt fo, "Enter the output wavename for the background"
	
//	variable B = pcsr(B)
//	variable A = pcsr(A)
//	variable k = vcsr(C)
//	variable g = hcsr(a)-hcsr(b)
	
	duplicate /O $sp $fo,tmp,mask
	duplicate /D/O $sp expfit
	 mask = 0
	 mask[pcsr(a)]=1
	 mask[pcsr(b)]=1
	 mask[pcsr(c)]=1
	 variable f=abs(pcsr(a)-pcsr(b))
	 variable g=abs(pcsr(a)-pcsr(c))
	 
	CurveFit/NTHR=0 /L=(g) exp $sp /M=mask /D
	string fit_sp
	fit_sp = "fit_"+sp
	duplicate/O $fit_sp expfit  
	duplicate /O/R=[(g-f),g] expfit tmp1	
	
	duplicate/O $sp $sp+"S"
	smooth 5, $sp+"S"
	$fo[0,pcsr(b)-1]=$sp+"S"  
	$fo[pcsr(b),pcsr(a)]=tmp1[p-pcsr(b)]
	$fo[pcsr(a)+1,numpnts($sp)]=$sp+"S"
	tmp = $fo
      appendtograph $fo
      remove $fit_sp
      killwaves tmp,tmp1, expfit, $fit_sp, $sp+"S"

end macro
	












CurveFit/NTHR=0 exp  xps /M=be /D 
