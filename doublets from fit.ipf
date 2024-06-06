
#pragma rtGlobals=1		// Use modern global access method.
//This macro calculates and plots voigt doublets after a fit made with VoigtFit_doublets.ipf.
//the active window should be the graph where voigt doublets will be displayed. 
//It asks in input the doublet names to be used and the energy wave name. The output doublets will be named
//with the common name used followed by a progressive number.
//the routine will use as parameters to calculate doublets those contained in the wave called 'w1', produced 
//while executing the fit with the VoigtFit_doublets.ipf function

 macro doublets_from_fit(voigtd,en)
 string voigtd,en
 prompt voigtd, "Enter name common name for voigt doublets"
 prompt en "Enter name of X wave"
 string voigtdd
 	variable nn=numpnts($en)
	variable nopts= trunc(numpnts(w1)/6),i=1
	do
		if( i>nopts )
			break
		endif
		make/O/N=(nn) vgt
		voigtdd=voigtd+num2str(i)
		vgt = w1[0] + w1[i*6-5]*(Voigt(w1[i*6-5+1]*($en[p]-w1[i*6-5+2]),w1[i*6-5+3])+ (w1[i*6-5+4])*Voigt(w1[i*6-5+1]*($en[p]-w1[i*6-5+2]+w1[i*6-5+5]),w1[i*6-5+3]))
		duplicate/O vgt, $voigtdd
		appendtograph $voigtdd vs $en 
		i+=1
	while(1)