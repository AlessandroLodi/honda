#pragma rtGlobals=1		// Use modern global access method.

//procedura per fare i fit con doppietti di tipo Voigt

Macro CreateFitPanel_doublets()
	String DataFolder = GetDataFolder(1)		// save
	NewDatafolder/O/S Fitting
	SetDataFolder DataFolder				// and restore
	MakeFitPanelSetup_doublets()
	 
endmacro

//creazione del pannello in cui si inserisce in numero di picchi


Proc MakeFitPanelSetup_doublets()
PauseUpdate; Silent 1		// building window...
NewPanel /K=1 /M/W=(5,5,10,10)
DoWindow/C FitSetupPanel

//SetDrawLayer UserBack
//SetDrawEnv fsize= 9
PopupMenu popupYData,pos={20,18},size={106,20},title="Y: "
PopupMenu popupYData,mode=2,popvalue="Select a Y wave",value= #"WaveList(\"*\",\";\",\"\")"
PopupMenu popupXData,pos={20,40},size={106,20},title="X: "
PopupMenu popupXData,mode=3,popvalue="Select an X wave",value= #"\"_calculated_;\"+WaveList(\"*\",\";\",\"\")"
variable/G :Fitting:npeaks = 1
SetVariable numpeaks, pos={20,62},size={120,20},title="N. of doublets"
SetVariable numpeaks, limits={1,12,1}, value= :Fitting:npeaks
Button PeakPar,  pos={40,84},size={120,20},title="enter peak parameters", proc=ParEnter_doublets

Button graph,  pos={40,120},size={120,20},title="Graph", proc=makegraph_doublets
Button fit,  pos={40,150},size={120,20},title="Fit", proc=makefit_doublets

end 


Proc ParEnter_doublets(numpeaks)
String numpeaks
DoWindow/K EnterParameter					//Kills window
NewPanel /K=1 /M/W=(2,2,15,15)			//rebuilts window
DoWindow/C EnterParameter
Autopositionwindow /M=0 /R=FitSetupPanel  EnterParameter


Variable npeaks =:Fitting:npeaks				//salva una variabile che indica il numero dei picchi voigt
											

Make/O/T/N=(7+(npeaks-1)*6,5) par_table		//crea wave di testo a 2 colonne per la lista dei parametri e constraints
Make/O/B/N=(7+(npeaks-1)*6,5,2) spar_table		// crea una wave numerica di supporto per definire lo stato delle caselle della tabella sopra, da usare con 'Listbox'
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

Variable h=1, w=1
Setdimlabel 1, 1, Param, par_table 				//definisce i label delle varie colonne della tabella dei parametri
Setdimlabel 1, 2, Hold, par_table 
Setdimlabel 1, 3, Minlim, par_table 
Setdimlabel 1, 4, Maxlim, par_table 
par_table[0][0]="Offset - K0"
spar_table[0][][1]=2							//fissa al colore 2 impostato nella wave 'cellcolor' il colore della prima riga
do	
	if( w>npeaks)
			break
	endif
	spar_table[w*6-5][][1]=2-0.5*(1-(-1)^w)		//alterna i colori 1 e 2 impostati nella wave 'cellcolor' ogni 6 righe di parametri
	spar_table[w*6-4][][1]=2-0.5*(1-(-1)^w)
	spar_table[w*6-3][][1]=2-0.5*(1-(-1)^w)
	spar_table[w*6-2][][1]=2-0.5*(1-(-1)^w)
	spar_table[w*6-1][][1]=2-0.5*(1-(-1)^w)
	spar_table[w*6-0][][1]=2-0.5*(1-(-1)^w)

w +=1
while(1)

do
	if( h>npeaks )
			break
	endif
	par_table[h*6-5][0]="Area "+num2str(h)+ " - K" + num2str(p)		//scrive nella colonna 0 della tabella i label dei parametri per i picchi
	par_table[h*6-4][0]="Gw "+num2str(h)+ " - K" + num2str(p)
	par_table[h*6-3][0]="Erg."+num2str(h)+ " - K" + num2str(p)
	par_table[h*6-2][0]="Lw "+num2str(h)+ " - K" + num2str(p) 
	par_table[h*6-1][0]="BR "+num2str(h)+ " - K" + num2str(p) 
	par_table[h*6-0][0]="SO "+num2str(h)+ " - K" + num2str(p) 
	
h+=1
while(1)

//istruzione che crea la tabella in cui inserire i parametri sulla base delle impostazioni precedenti

ListBox lb1, pos={42,9}, size={400,400}, frame=2, listWave=par_table, selWave=spar_table, colorWave=cellcolor, mode=5
SetDimLabel 2,1,backcolors, spar_table 

 
Variable/G npar = (7+(npeaks-1)*6)

//this is to build the parameter wave to be used during fitting

Function  parameters_doublets()
NVAR gnpeaks = :Fitting:npeaks
Variable npeaks=gnpeaks
Wave/T par_table
Make/O/N=(7+(npeaks-1)*6)/D par			//makes the numeric parameter (par) wave - still empty 
par=str2num(par_table[p][1])
end

//This is to build the parameter hold string, to be used during fitting

Function hold_doublets()
NVAR gnpeaks = :Fitting:npeaks
Variable npeaks=gnpeaks
Wave spar_table
String/G ParHold = ""							//parameter hold string = ParHold
Variable c = 0
Make/O/N=(7+(npeaks-1)*6)/D hold 		//makes a numeric wave called 'hold'
Make/O/N=(7+(npeaks-1)*6)/D spar_hold 	//makes a numeric wave called 'spar_hold' equal to 2 column of spar_table
spar_hold=spar_table[p][2]

Do
	if (c>=(7+(npeaks-1)*6))
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

Function constraints_doublets()
NVAR gnpeaks = :Fitting:npeaks
Variable npeaks=gnpeaks
Wave/T par_table
Make/O/T/N=(2*(7+(npeaks-1)*6)) con
Variable m=0
do
if (m>=(7+(npeaks-1)*6))
	break
	endif
con[2*m]=par_table[m][3]
con[2*m+1]=par_table[m][4]
m +=1
while(1)
end

//this is to build the Limits text wave to be used in fitting

Function Limits_doublets()
NVAR gnpeaks = :Fitting:npeaks
Variable npeaks=gnpeaks
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
while (i<(7+(npeaks-1)*6)) 
end

//grafica la finzione senza fare il fit

Proc makegraph_doublets(graph)
String graph
parameters_doublets()
selectXYwaves_doublets()
Variable/G Ydatalen
Ydatalen = numpnts($Ydata)
FuncFit/O/Q /L=(Ydatalen)  VoigtFitdoublet par $Ydata /X=$Xdata /D //grafica senza fare il fit
string fit_trace 
fit_trace = "fit_"+Ydata
ModifyGraph rgb($fit_trace)=(0,0,65535)

//plots different doublets
String voigtd = "vgtdbl"
string voigtdd
 	variable nn=numpnts($Xdata)
	variable nopts= trunc(numpnts(w1)/6),i=1
	do
		if( i>nopts )
			break
		endif
		make/O/N=(nn) vgt
		voigtdd=voigtd+num2str(i)
		vgt = w1[0] + w1[i*6-5]*(Voigt(w1[i*6-5+1]*($Xdata[p]-w1[i*6-5+2]),w1[i*6-5+3])+ (w1[i*6-5+4])*Voigt(w1[i*6-5+1]*($Xdata[p]-w1[i*6-5+2]+w1[i*6-5+5]),w1[i*6-5+3]))
		duplicate/O vgt $voigtdd
		CheckDisplayed $voigtdd
		if ( V_flag != 1)							//checks if voigt doublet waves exist on the graph
			appendtograph $voigtdd vs $Xdata         //if they not exist on the graph then they are plotted
		endif 
		i+=1
	while(1)
KillWaves vgt
end

//procedura per fare il fit

Proc makefit_doublets(fit)
String fit 
selectXYwaves_doublets()
parameters_doublets()
hold_doublets()
constraints_doublets()
Limits_doublets() 
Variable/G Ydatalen=numpnts($Ydata)
String/G Fix = "\""+ParHold+"\""
FuncFit /H="Fix" /L=(Ydatalen) VoigtFitdoublet par $Ydata /X=$Xdata  /D  /C=Limits
par_table[][1]=num2str(par[p])
string fit_trace  
fit_trace = "fit_"+Ydata
ModifyGraph rgb($fit_trace)=(0,0,65535)


//plots different doublets
String voigtd = "vgtdbl"
string voigtdd
 	variable nn=numpnts($Xdata)
	variable nopts= trunc(numpnts(w1)/6),i=1
	do
		if( i>nopts )
			break
		endif
		make/O/N=(nn) vgt
		voigtdd=voigtd+num2str(i)
		vgt = w1[0] + w1[i*6-5]*(Voigt(w1[i*6-5+1]*($Xdata[p]-w1[i*6-5+2]),w1[i*6-5+3])+ (w1[i*6-5+4])*Voigt(w1[i*6-5+1]*($Xdata[p]-w1[i*6-5+2]+w1[i*6-5+5]),w1[i*6-5+3]))
		duplicate/O vgt $voigtdd
		CheckDisplayed $voigtdd
		if ( V_flag != 1)							//checks if voigt doublet waves exist on the graph
			appendtograph $voigtdd vs $Xdata         //if they not exist on the graph then they are plotted
		endif 
		i+=1
	while(1)
KillWaves vgt
end

//function to select the waves to be fitted
	
Function selectXYwaves_doublets()	
	String/G Ydata
	ControlInfo popupYData; Ydata=S_Value
	String/G Xdata
	ControlInfo popupXData; Xdata=S_Value
end  










