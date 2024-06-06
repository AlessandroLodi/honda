#pragma rtGlobals=1		// Use modern global access method.


macro subtract_satellite_2(spectr,energy,satellite)
         string spectr
         string energy
         Prompt spectr, "Enter spectrum wavename", popup, WaveList("*",";","") 
         Prompt energy, "Enter kinetic energy wavename", popup, WaveList("*",";","")
         Variable satellite 
	   Prompt satellite, "Choose photon satellite (eV)", popup "HeII;MgKa"

duplicate/O $spectr $spectr+"_satl"
variable delta = abs($energy[1]-$energy[0])
if (satellite == 2)
	Variable shift1 = 8.4
	Variable shift2 = 10.0
Variable ndelta1 = round(shift1/delta)
Variable ndelta2 = round(shift2/delta)
$spectr+"_satl"[0]= (100/114.3)*$spectr[0]
$spectr+"_satl"[1,numpnts($spectr)] = $spectr[p] - (9.2/114.3)*$spectr+"_satl"[p-(ndelta1)] - (5.1/114.3)*$spectr+"_satl"[p-(ndelta2)]
endif
if (satellite == 1)
	Variable shift1 = 7.56
Variable ndelta1 = round(shift1/delta)
$spectr+"_satl"[0]= (100/110)*$spectr[0]
$spectr+"_satl"[1,numpnts($spectr)] = $spectr[p] - (10/100)*$spectr+"_satl"[p-(ndelta1)]  
endif

end
