#pragma rtGlobals=1		// Use modern global access method.


macro subtract_satellite(spectr,energy,satellite)
         string spectr
         string energy
         Prompt spectr, "Enter spectrum wavename", popup, WaveList("*",";","") 
         Prompt energy, "Enter kinetic energy wavename", popup, WaveList("*",";","")
         Variable satellite 
	   Prompt satellite, "Choose photon satellite (eV)", popup "HeII;MgKa"

duplicate/O $spectr $spectr+"_sat"
variable delta = abs($energy[1]-$energy[0])
if (satellite == 2)
	Variable shift1 = 8.4
	Variable shift2 = 10.1
Variable ndelta1 = round(shift1/delta)
Variable ndelta2 = round(shift2/delta)
$spectr+"_sat" = $spectr[p] - (8/100)*$spectr[p-(ndelta1)] - (4.1/100)*$spectr[p-(ndelta2)]
endif
if (satellite == 1)
	Variable shift1 = 7.56
Variable ndelta1 = round(shift1/delta)
$spectr+"_sat" = $spectr[p] - (10/100)*$spectr[p-(ndelta1)] 
endif

end
