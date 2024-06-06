#pragma rtGlobals=1		// Use modern global access method.

//The program inputs are the vector of the frequency
//(or energy) components, the vector of the imaginary
//part of the susceptibility under examination, and
//the value of the moment considered. 
//The two vectors must have the same length 
//and the frequency vector omega must be equispaced. 
//If imgkk is the imaginary part of a linear susceptibility, 
//alpha must be 0. 
//If imgkk is the imaginary part of the nth 
//harmonic generation susceptibility, alpha=0,1,..2n. 
//If imgkk is the imaginary part of a pump and probe
//susceptibility, alpha=0 or 1.
//This file is mdified version of the file that accompanies the book 
//"Kramers-Kronig Relations in Optical Materials Research"
//by Lucarini, V., Saarinen, J.J., Peiponen, K.-E., Vartiainen, E.M. 
//Springer, Heidelberg, 2005
//where the theory and applications are fully developed.
//The output is the estimate of the real part as obtained
//with K-K relations.

macro KKimg2real(omega,imgkk,rekk,alpha)
         string omega,imgkk, rekk
         Variable alpha
         Prompt omega, "Enter the input wavename of the frequency or energy"
         Prompt imgkk, "Enter the input wavename of the imaginary part"
         Prompt rekk, "Enter the output wavename for the real part"
         Prompt alpha, "enter alpha ==> 0 "
         duplicate/O $imgkk imgkk1
         duplicate/O $imgkk rekk1
         duplicate/O $omega omega1
         
         KKtransformimg2real(omega1,imgkk1,rekk1,alpha)
         duplicate/O rekk1 $rekk  
	 
	 end

function KKtransformimg2real(omega,imgkk,rekk,alpha)
	wave omega,imgkk, rekk
       Variable alpha
       alpha=0

	 variable g
	 g= numpnts(omega)
	
	 
	 variable deltaomega
	 deltaomega=omega[1]-omega[0];
//Here we compute the frequency (or energy) interval

	make/O/N=(numpnts(omega))/D ai
	make/O/N=(numpnts(omega))/D bi
//two waves for intermediate calculations are initialised
	  
	variable j
	variable beta1
	j=1
	beta1=0
	variable k
	for (k=1; k < g; k+=1) 
	bi[0]=beta1+imgkk[k]*omega[k]^(2*alpha+1)/(omega[k]^2-omega[0]^2)
	beta1=bi[0]
	endfor
	rekk[0]=2/pi*deltaomega*bi[0]*omega[0]^(-2*alpha)
//First element of the output: the principal part integration
//is computed by excluding the first element of the input 

	Variable alpha1
	j = g 
	alpha1=0; 
	for (k=0; k < g-1; k+=1)
	ai[g-1]=alpha1+imgkk[k]*omega[k]^(2*alpha+1)/(omega[k]^2-omega[g-1]^2)
	alpha1=ai[g-1]
	endfor
	rekk[g-1]=2/pi*deltaomega*ai[g-1]*omega[g-1]^(-2*alpha)
	//Last element of the output: the principal part integration
	//is computed by excluding the last element of the input
	
	for (j=1; j < g-1; j+=1)
	//Loop on the inner components of the output vector. 
	
	alpha1=0
	beta1=0
	for (k=0; k <= j-1; k+=1)
	ai[j]=alpha1+imgkk[k]*omega[k]^(2*alpha+1)/(omega[k]^2-omega[j]^2)
	alpha1=ai[j]
	endfor
	
	for (k=j+1; k < g-1; k+=1)
	bi[j]=beta1+imgkk[k]*omega[k]^(2*alpha+1)/(omega[k]^2-omega[j]^2)
	beta1=bi[j]
	endfor
	rekk[j]=2/pi*deltaomega*(ai[j]+bi[j])*omega[j]^(-2*alpha)
	endfor
//Last element of the output: the principal part integration
//is computed by excluding the last element of  the input

 // Return rekk
 // the line above was triggering an ambigous 
 
 Return 0

end     