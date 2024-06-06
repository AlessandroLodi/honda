//questa macro serve per fittare gli spettri di assorbimento con gaussiane asimmetriche e step functions
//secondo il metodo di Stohr (NEXAFS spectroscopy, Springer, 1996, Cap.7)

#pragma rtGlobals=1		// Use modern global access method.
Macro CreateFitPanel_NEXAFS()				//macro che crea definisce il folder corrente quello di lavoro e ne crea un altro di supporto
	String DataFolder = GetDataFolder(1)		// save
	NewDatafolder/O/S Fitting					//il folder 'Fitting' sotto quello di lavoro e' il folder di supporto
	SetDataFolder DataFolder				// and restore
	MakeFitPanelSetup_NEXAFS()
	 
endmacro

// crea la finestra iniziale in cui inserire il numero dei picchi. Prima occorre inserire i parametri, poi 
//graficare la funzione risulatato o fare il fit.

Proc MakeFitPanelSetup_NEXAFS()			
PauseUpdate; Silent 1						// building window...
NewPanel /K=1 /M/W=(5,5,10,11)
DoWindow/C FitSetupPanel

//SetDrawLayer UserBack
//SetDrawEnv fsize= 9
PopupMenu popupYData,pos={20,18},size={106,20},title="Y: "
PopupMenu popupYData,mode=2,popvalue="Select a Y wave",value= #"WaveList(\"*\",\";\",\"\")"
PopupMenu popupXData,pos={20,40},size={106,20},title="X: "
PopupMenu popupXData,mode=3,popvalue="Select an X wave",value= #"\"_calculated_;\"+WaveList(\"*\",\";\",\"\")"
variable/G :Fitting:npeaks = 1
variable/G :Fitting:nsteps = 1
SetVariable numpeaks, pos={20,62},size={120,20},title="N. Asym.Gauss"
SetVariable numpeaks, limits={1,12,1}, value= :Fitting:npeaks
SetVariable numsteps, pos={20,84},size={120,20},title="N. Steps"
SetVariable numsteps, limits={1,12,1}, value= :Fitting:nsteps
Button PeakPar,  pos={40,106},size={130,20},title="enter peak parameters", proc=ParEnter_NEXAFS

Button graph,  pos={40,160},size={120,20},title="Graph", proc=makegraph_NEXAFS
Button fit,  pos={40,190},size={120,20},title="Fit", proc=makefit_NEXAFS

end 


//Procedura che permette di inserire i parametri

Proc ParEnter_NEXAFS(numpeaks)
String numpeaks
DoWindow/K EnterParameter					//Kills window
NewPanel /K=1 /M/W=(2,2,15,15)			//rebuilts window
DoWindow/C EnterParameter
Autopositionwindow /M=0 /R=FitSetupPanel  EnterParameter

Variable npeaks =:Fitting:npeaks				//salva una variabile che indica il numero dei picchi gauss
Variable nsteps =:Fitting:nsteps				//salva una variabile che indica il numero degli steps

Make/O/T/N=(5+(npeaks+nsteps-1)*4,5) par_table		//crea wave di testo a 2 colonne per la lista dei parametri e constraints
Make/O/B/N=(5+(npeaks+nsteps-1)*4,5,2) spar_table		// crea una wave numerica di supporto per definire lo stato delle caselle della tabella sopra, da usare con 'Listbox'
Make/O/W/U cellcolor = {{0,0,0},{0,65535,0},{0,65535,65535}} //crea una wave a 3 colori per poter distingure graficamente i gruppi di parametri  
MatrixTranspose cellcolor									//inverte le righe e le colonne della wave di colori per potere essere usata da 'ListBox'

if (exists("par")==1)								//se la wave dei parametri 'par' e' gia stata creata in precedenza, immette i vecchi valori nella tabella quando questa viene aperta
	par_table[][1]=num2str(par[p])
	par_table[][2]=""
endif
if (exists("con")==1)								//se la wave delle contraints 'con' e' gia stata creata in precedenza, immette i vecchi valori nella tabella quando questa viene aperta
	par_table[][3] = con[2*p]
	par_table[][4]= con[2*p+1]
endif	
	
spar_table[][0][0]=0; spar_table[][1][0]=2; spar_table[][2][0]=32; spar_table[][3][0]=2; spar_table[][4][0]=2 //definisce i valori nella tabella di supporto. In particolare setta come checkbox la colonna 2

if (exists("spar_hold")==1)
	spar_table[][2] = spar_hold[p]
endif


Variable h=1,l=1+npeaks, w=1
Setdimlabel 1, 1, Param, par_table 				//definisce i label delle varie colonne della tabella dei parametri
Setdimlabel 1, 2, Hold, par_table 
Setdimlabel 1, 3, Minlim, par_table 
Setdimlabel 1, 4, Maxlim, par_table 
par_table[0][0]="Offset - K0"
spar_table[0][][1]=2							//fissa al colore 2 impostato nella wave 'cellcolor' il colore della prima riga
do	
	if( w>npeaks+nsteps)
			break
	endif
	spar_table[w*4-3][][1]=2-0.5*(1-(-1)^w)		//alterna i colori 1 e 2 impostati nella wave 'cellcolor' ogni 4 righe di parametri
	spar_table[w*4-2][][1]=2-0.5*(1-(-1)^w)
	spar_table[w*4-1][][1]=2-0.5*(1-(-1)^w)
	spar_table[w*4-0][][1]=2-0.5*(1-(-1)^w)

w +=1
while(1)

do
	if( h>npeaks )
			break
	endif
	par_table[h*4-3][0]="Amp."+num2str(h)+ " - K" + num2str(p)		//scrive nella colonna 0 della tabella i label dei parametri per le gaussiane
	par_table[h*4-2][0]="Erg."+num2str(h)+ " - K" + num2str(p)
	par_table[h*4-1][0]="m"+num2str(h)+ " - K" + num2str(p)
	par_table[h*4-0][0]="B"+num2str(h)+ " - K" + num2str(p) 
h+=1
while(1)

do
	if( l>nsteps+npeaks )
			break
	endif
	par_table[l*4-3][0]="Amp.S"+num2str(l)+ " - K" + num2str(p)	//scrive nella colonna 0 della tabella i label dei parametri per i gradini step
	par_table[l*4-2][0]="Erg.S"+num2str(l)+ " - K" + num2str(p)
	par_table[l*4-1][0]="Wg S"+num2str(l)+ " - K" + num2str(p)
	par_table[l*4-0][0]="Tau S"+num2str(l)+ " - K" + num2str(p) 

l+=1
while(1)

//istruzione che crea la tabella in cui inserire i parametri sulla base delle impostazioni precedenti

ListBox lb1, pos={42,9}, size={400,400}, frame=2, listWave=par_table, selWave=spar_table, colorWave=cellcolor, mode=5
SetDimLabel 2,1,backcolors, spar_table 

 
Variable/G npar = (5+(npeaks+nsteps-1)*4)

//this is to build the parameter wave to be used during fitting

Function  parameters_NEXAFS()
NVAR gnpeaks = :Fitting:npeaks
NVAR gnsteps = :Fitting:nsteps
Variable npeaks=gnpeaks
Variable nsteps=gnsteps
Wave/T par_table
Make/O/N=(5+(npeaks+nsteps-1)*4)/D par			//makes the numeric parameter (par) wave - still empty 
par=str2num(par_table[p][1])
end

//This is to build the parameter hold string, to be used during fitting

Function hold_NEXAFS()
NVAR gnpeaks = :Fitting:npeaks
NVAR gnsteps = :Fitting:nsteps
Variable npeaks=gnpeaks
Variable nsteps=gnsteps
Wave spar_table
String/G ParHold = ""							//parameter hold string = ParHold
Variable c = 0
Make/O/N=(5+(npeaks+nsteps-1)*4)/D hold 		//makes a numeric wave called 'hold'
Make/O/N=(5+(npeaks+nsteps-1)*4)/D spar_hold 		//makes a numeric wave called 'spar_hold' equal to 2 column of spar_table
spar_hold=spar_table[p][2]

Do
	if (c>=(5+(npeaks+nsteps-1)*4))
		break
	endif
	if (spar_table[c][2]<34)
		hold[c]=0									//assigns 0 the the 'hold' string if selWave element in column 2 (checkbox) is not selected 
	else											// (depends on bit n, where the col value can be 2^n=1,2,4,8,16,32,64,.. see listBox help)
		hold[c]=1									//assigns 1 the the 'hold' string if selWave element in column 2 (checkbox) is selected
	endif
	ParHold=ParHold+num2str(hold[c])				//builds a string  corresponding to the 'hold' numeric wave
c +=1
While(1)
end

//this is to build the constraints text wave
//makes the text wave of the lower and upper limits, to be used to buit T_Constraints wave

Function constraints_NEXAFS()
NVAR gnpeaks = :Fitting:npeaks
NVAR gnsteps = :Fitting:nsteps
Variable npeaks=gnpeaks
Variable nsteps=gnsteps
Wave/T par_table
Make/O/T/N=(2*(5+(npeaks+nsteps-1)*4)) con
Variable m=0
do
if (m>=(5+(npeaks+nsteps-1)*4))
	break
	endif
con[2*m]=par_table[m][3]
con[2*m+1]=par_table[m][4]
m +=1
while(1)
end

//this is to build the Limits text wave to be used in fitting

Function Limits_NEXAFS()
NVAR gnpeaks = :Fitting:npeaks
NVAR gnsteps = :Fitting:nsteps
Variable npeaks=gnpeaks
Variable nsteps=gnsteps
Wave/T con
String/G ParHold
Make/O/T/N=1 Limits
Variable i=0
Variable n=0
Do 
	if (cmpstr(ParHold[i],"0")==0)
	Redimension/N=(2*n) Limits
		Limits[2*n] = {"k"+num2str(i)+" > "+con[2*i], "k"+num2str(i)+" < "+con[(2*i)+1]}
		n +=1
	endif
i +=1
while (i<(5+(npeaks+nsteps-1)*4)) 
end

Proc makegraph_NEXAFS(graph)
String graph
parameters_NEXAFS()
selectXYwaves_NEXAFS()
Variable/G Ydatalen
Ydatalen = numpnts($Ydata)
FuncFit/O/Q /L=(Ydatalen)  NEXAFS par $Ydata /X=$Xdata /D //grafica senza fare il fit
string fit_trace 
fit_trace = "fit_"+Ydata
ModifyGraph rgb($fit_trace)=(0,0,65535)

//plots different curves
String comp = "comp"
string compd
 	variable nn=numpnts($Xdata)
	variable nopts= trunc((numpnts(par)-1)/4),i=1
	
	do
		if( i>nopts )
			break
		endif
		make/O/D/N=(nn) cmp
		compd=comp+num2str(i)
		if (i < :Fitting:npeaks+1)
		cmp = par[0]+ par[i*4-3]*exp(-(( ($Xdata[p]-par[i*4-3+1])/( ($Xdata[p]*par[i*4-3+2]+par[i*4-3+3]) / (sqrt(2*ln(4))) ))^2))
		endif
		if (i >= :Fitting:npeaks+1)
			cmp = ($Xdata[p] <= par[i*4-3+1]+par[i*4-3+2]) ? par[0] + par[i*4-3]*(0.5+0.5*erf(($Xdata[p]-par[i*4-3+1])/(par[i*4-3+2]/1.665))) : par[0] + par[i*4-3]*(0.5+0.5*erf(($Xdata[p]-par[i*4-3+1])/(par[i*4-3+2]/1.665)))*(exp(-(par[i*4-3+3]*($Xdata[p]-par[i*4-3+1]-par[i*4-3+2]))))
		endif
		duplicate/O cmp $compd
		CheckDisplayed $compd
		if ( V_flag != 1)							//checks if curve waves exist on the graph
			appendtograph $compd vs $Xdata         //if they not exist on the graph then they are plotted
		endif 
		i+=1
	while(1)
KillWaves cmp
end


Proc makefit_NEXAFS(fit)
String fit 
selectXYwaves_NEXAFS()
parameters_NEXAFS()
hold_NEXAFS()
constraints_NEXAFS()
Limits_NEXAFS() 
Variable/G Ydatalen=numpnts($Ydata)
String/G Fix = "\""+ParHold+"\""
FuncFit /H="Fix" /L=(Ydatalen) NEXAFS par $Ydata /X=$Xdata  /D  /C=Limits
par_table[][1]=num2str(par[p])
string fit_trace  
fit_trace = "fit_"+Ydata
ModifyGraph rgb($fit_trace)=(0,0,65535)

//plots different curves
String comp = "comp"
string compd
 	variable nn=numpnts($Xdata)
	variable nopts= trunc((numpnts(par)-1)/4),i=1
	
	do
		if( i>nopts )
			break
		endif
		make/O/D/N=(nn) cmp
		compd=comp+num2str(i)
		if (i < :Fitting:npeaks+1)
		cmp = par[0]+ par[i*4-3]*exp(-(( ($Xdata[p]-par[i*4-3+1])/( ($Xdata[p]*par[i*4-3+2]+par[i*4-3+3]) / (sqrt(2*ln(4))) ))^2))
		endif
		if (i >= :Fitting:npeaks+1)
			cmp = ($Xdata[p] <= par[i*4-3+1]+par[i*4-3+2]) ? par[0] + par[i*4-3]*(0.5+0.5*erf(($Xdata[p]-par[i*4-3+1])/(par[i*4-3+2]/1.665))) : par[0] + par[i*4-3]*(0.5+0.5*erf(($Xdata[p]-par[i*4-3+1])/(par[i*4-3+2]/1.665)))*(exp(-(par[i*4-3+3]*($Xdata[p]-par[i*4-3+1]-par[i*4-3+2]))))
		endif
		duplicate/O cmp $compd
		CheckDisplayed $compd
		if ( V_flag != 1)							//checks if curve waves exist on the graph
			appendtograph $compd vs $Xdata         //if they not exist on the graph then they are plotted
		endif 
		i+=1
	while(1)
KillWaves cmp
end
	
Function selectXYwaves_NEXAFS()	
	String/G Ydata
	ControlInfo popupYData; Ydata=S_Value
	String/G Xdata
	ControlInfo popupXData; Xdata=S_Value
end  


Function NEXAFS(w,x)
	Wave w; Variable x
	NVAR gnpeaks = :Fitting:npeaks
	NVAR gnsteps = :Fitting:nsteps
	Variable npeaks=gnpeaks
	Variable nsteps=gnsteps	
	Variable r= w[0]
	
	variable npts= trunc((numpnts(w)-1)/4),i=1

	do
		if( i>npts )
			break
		endif
		if (i < npeaks +1)
			r += w[i*4-3]*exp(-(( (x-w[i*4-3+1])/( (x*w[i*4-3+2]+w[i*4-3+3]) / (sqrt(2*ln(4))) ))^2))
		endif 
		if (i >= npeaks +1)
			r += (x <= w[i*4-3+1]+w[i*4-3+2]) ? w[i*4-3]*(0.5+0.5*erf((x-w[i*4-3+1])/(w[i*4-3+2]/1.665))) : w[i*4-3]*(0.5+0.5*erf((x-w[i*4-3+1])/(w[i*4-3+2]/1.665)))*exp(-(w[i*4-3+3]*(x-w[i*4-3+1]-w[i*4-3+2])))
		endif
		i+=1
				
	while(1)
	return r
End