#pragma rtGlobals=1		// Use modern global access method.

//#include "Photon Energy - Time scan"

#define LOADBEARDATA



Menu "Load Waves"
	Submenu "Load BEAR data"
		"Single file", LoadBearDataSingle("")
		"Multiple scan files", LoadMultiScan("")
		//"Load all data in a folder", LoadBearDataInFolder()
		
		"-"
		"Load dark data", LoadDarkData("")
		"-"
		"Scale data",Scaling2("","")
		"Divide Photon Energy - Time scan data",DividePhEnTime(0,0,"")
	End
End


// LoadBearDataSingle(FileName)
Function LoadBearDataSingle(FileName)
	String FileName
	
	if (strlen(FileName) == 0)
		Variable refNum
		Open/R/D/M="Choose data file" refNum
		if (strlen(S_fileName) == 0)
			return -1
		endif
		FileName = S_fileName
	endif
	
	if (ChooseWaveNames() == -1)
		return -1
	endif
	
	LoadBearData(FileName)
	
	// Carica i file di buio
	NVAR gDarkLoad = root:WaveNames:gDarkLoad
	if (gDarkLoad == 1)
		String FolderName = GGetLeafName(FileName)
		String savedDF = GetDataFolder(1)
		SetDataFolder :$FolderName
		LoadDarkData("")
		SetDataFolder savedDF
	endif
	
End

// Carica più scan ripetuti
Function LoadMultiScan(ComplFirstFileName)
	String ComplFirstFileName
	String FileName
	String pathToFolder
	Variable index,HowMany=1
	
	if (strlen(ComplFirstFileName) == 0)
		Variable refNum
		Open/R/D/M="Choose first file" refNum
		if (strlen(S_fileName) == 0)
			return -1
		endif
		ComplFirstFileName = S_fileName
	endif
	ChooseWaveNames()
	
	Prompt HowMany,"How many file to load?"
	DoPrompt "Enter the number of files to load",HowMany
	if (V_flag || HowMany <=0 )
		return -1
	endif		
	
	SVAR Name0 = root:WaveNames:gName0
	SVAR Name1 = root:WaveNames:gName1
	SVAR Name2 = root:WaveNames:gName2
	SVAR Name3 = root:WaveNames:gName3
	SVAR Name4 = root:WaveNames:gName4
	SVAR Name5 = root:WaveNames:gName5
	SVAR Name6 = root:WaveNames:gName6
	
	FileName = GGetLeafName(ComplFirstFileName)
	pathToFolder = ComplFirstFileName[0, strlen(ComplFirstFileName) - strlen(FileName) - 1]
	
	String leafNameLeft=""
	String leafNameRight=""
	Variable pos
	pos = 0
	do
		if(CmpStr(FileName[pos],"(") == 0)
			leafNameLeft = FileName[0,pos]
			break
		endif
		pos += 1
	while (pos < strlen(FileName))
	pos = strlen(FileName)-1
	do
		if(CmpStr(FileName[pos],")") == 0)
			leafNameRight = FileName[pos,strlen(FileName)]
			break
		endif
		pos -= 1
	while (pos > 0)
	
	String FolderName
	sprintf FolderName,"%s%s",leafNameLeft[0,(strlen(leafNameLeft)-2)],leafNameRight[1,(strlen(leafNameRight)-1)]
	
	
	String savedDataFolder = GetDataFolder(1)
	NewDataFolder/O/S :$FolderName
		
	String FileToLoad
		
	for (index=1;index<=HowMany;index+=1)
		sprintf FileToLoad,"%s%s%d%s",pathToFolder,leafNameLeft,index,leafNameRight
		LoadBearData(FileToLoad)
	endfor
	
	// Carica i file di buio
	NVAR gDarkLoad = root:WaveNames:gDarkLoad
	if (gDarkLoad == 1)
		LoadDarkData("")
	endif
	
	
	SetDataFolder savedDataFolder
	
	
	
End


// LoadBearData(FileName)
Function LoadBearData(ComplFileName)
	String ComplFileName
	String pathToFolder, fileName, pathName
	Variable refNum
	
	if (strlen(ComplFileName) == 0)
		Open/R/D/M="Choose data file" refNum
		if (strlen(S_fileName) == 0)
			return -1
		else
			ComplFileName = S_fileName
		endif
	endif
		
	SVAR Name0 = root:WaveNames:gName0
	SVAR Name1 = root:WaveNames:gName1
	SVAR Name2 = root:WaveNames:gName2
	SVAR Name3 = root:WaveNames:gName3
	SVAR Name4 = root:WaveNames:gName4
	SVAR Name5 = root:WaveNames:gName5
	SVAR Name6 = root:WaveNames:gName6
	NVAR gScaling = root:WaveNames:gScaling
	NVAR RingCurrentQuery = root:WaveNames:gRingCurrentQuery
	
	fileName = GGetLeafName(ComplFileName)  //estrai il nome del file dal path completo
	pathToFolder = ComplFileName[0,strlen(ComplFileName)-strlen(fileName)-1]
	
	NewPath/O/Q CurrentDataFilePath pathToFolder
	pathName = "CurrentDataFilePath"
	
	String savedDF = GetDataFolder(1)
	NewDataFolder/O/S :$fileName		// crea una folder per il file da caricare
	
	LoadWave/Q/G/N=Onda/P=$pathName fileName
	Wave Onda0,Onda1,Onda2,Onda3,Onda4,Onda5,Onda6
	
	// Verifica che le onde contengano solamente numeri. Se incontra un "non numero", imposta a NaN
	CheckWaveValidity(Onda0)	
	CheckWaveValidity(Onda1)	
	CheckWaveValidity(Onda2)	
	CheckWaveValidity(Onda3)	
	CheckWaveValidity(Onda4)	
	CheckWaveValidity(Onda5)	
	CheckWaveValidity(Onda6)
		
	
	
	// Rinomina le wave con i nomi scelti
	
	if (cmpstr(Name0,"_none_") == 0 || strlen(Name0) == 0)
		KillWaves Onda0
	else
		Note Onda0,fileName
		Rename Onda0 $Name0
	endif 
	
	if (cmpstr(Name1,"_none_") == 0 || strlen(Name1) == 0)
		KillWaves Onda1
	else
		Note Onda1,fileName
		Rename Onda1 $Name1
	endif 
	
	if (cmpstr(Name2,"_none_") == 0 || strlen(Name2) == 0)
		KillWaves Onda2
	else
		Note Onda2,fileName
		Rename Onda2 $Name2
	endif 
	
	if (cmpstr(Name3,"_none_") == 0 || strlen(Name3) == 0)
		KillWaves Onda3
	else
		Note Onda3,fileName
		Rename Onda3 $Name3
	endif 
	
	if (cmpstr(Name4,"_none_") == 0 || strlen(Name4) == 0)
		KillWaves Onda4
	else
		Note Onda4,fileName
		Rename Onda4 $Name4
	endif 
	
	if (cmpstr(Name5,"_none_") == 0 || strlen(Name5) == 0)
		KillWaves Onda5
	else
		Note Onda5,fileName
		Rename Onda5 $Name5
	endif 

	if (cmpstr(Name6,"_none_") == 0 || strlen(Name6) == 0)
		KillWaves Onda6
	else
		Note Onda6,fileName
		Rename Onda6 $Name6
	endif 
	
	if (gScaling > 1)
		//Scaling(gScaling,Onda0,Onda1,Onda2,Onda3,Onda4,Onda5)
		Scaling(gScaling,Name0,Name1,Name2,Name3,Name4,Name5,Name6)
	endif
	
		
	// Carica la corrente dell'anello
	if (RingCurrentQuery == 1)
		Variable/G V_RingCurrent = RingCurrent(pathName,fileName)
	endif
	
	
	
	SetDataFolder savedDF
	
End

// ChooseWaveNames()
Function ChooseWaveNames()
		String Name0 = StrVarOrDefault("root:WaveNames:gName0","_none_")
		Prompt Name0, "First wave"
		String Name1 = StrVarOrDefault("root:WaveNames:gName1","_none_")
		Prompt Name1, "Second wave"
		String Name2 = StrVarOrDefault("root:WaveNames:gName2","_none_")
		Prompt Name2, "Third wave"
		String Name3 = StrVarOrDefault("root:WaveNames:gName3","_none_")
		Prompt Name3,"Fourth wave"
		String Name4 = StrVarOrDefault("root:WaveNames:gName4","_none_")
		Prompt Name4, "Fifth wave"
		String Name5 = StrVarOrDefault("root:WaveNames:gName5","_none_")
		Prompt Name5, "Sixth wave"
		String Name6 = StrVarOrDefault("root:WaveNames:gName6","_none_")
		Prompt Name6, "Seventh wave"
		Variable RingCurrentQuery = NumVarOrDefault("root:WaveNames:gRingCurrentQuery",2)
		Prompt RingCurrentQuery, "Input ring current?", popup, "Yes;No"
		Variable Scaling = NumVarOrDefault("root:WaveNames:gScaling",1)
		Prompt Scaling,"Scale waves according wave",popup,"None;1st;2nd;3rd;4th;5th;6th"
		Variable DarkLoad = NumVarOrDefault("root:WaveNames:gDarkLoad",2)
		Prompt DarkLoad, "Load dark?", popup, "Yes;No"
		DoPrompt "Enter name", Name0,Name1,Name2,Name3,Name4,Name5,Name6,RingCurrentQuery,Scaling,DarkLoad
				
		if(V_flag == 1) 
			return -1
		endif
		
		// Salva i nomi scelti per le waves nella cartella root:WaveNames
		
		String/G saveDF = GetDataFolder(1)
		NewDataFolder/O/S root:WaveNames		
		String/G gName0 = Name0
		String/G gName1 = Name1
		String/G gName2 = Name2
		String/G gName3 = Name3
		String/G gName4 = Name4
		String/G gName5 = Name5
		String/G gName6 = Name6		
		Variable/G gRingCurrentQuery = RingCurrentQuery
		Variable/G gScaling = Scaling
		Variable/G gDarkLoad = DarkLoad
		SetDataFolder $saveDF
		KillStrings saveDF	
		return 0
End


// LoadDarkData(FileName)
// Carica il file di dark e restituisce il valore medio e la deviazione standard delle onde selezionate
Function LoadDarkData(DarkFileName)
	String DarkFileName
	Variable refNum
	String pathToFolder, fileName, pathName
	
	if (strlen(DarkFileName) == 0)
		Open/R/D/M="Choose file with dark" refNum
		if(strlen(S_fileName) == 0)
			return -1
		endif
		DarkFileName = S_fileName
	endif
	
	fileName = GGetLeafName(DarkFileName)
	pathToFolder = DarkFileName[0, strlen(DarkFileName) - strlen(fileName) - 1]
	
	String NameDark0 = StrVarOrDefault("root:WaveNames:gNameDark0","_none_")
	String NameDark1 = StrVarOrDefault("root:WaveNames:gNameDark1","_none_")
	String NameDark2 = StrVarOrDefault("root:WaveNames:gNameDark2","_none_")
	String NameDark3 = StrVarOrDefault("root:WaveNames:gNameDark3","_none_")
	String NameDark4 = StrVarOrDefault("root:WaveNames:gNameDark4","_none_")
	String NameDark5 = StrVarOrDefault("root:WaveNames:gNameDark5","_none_")
	String NameDark6 = StrVarOrDefault("root:WaveNames:gNameDark6","_none_")
	
	Prompt NameDark0, "First wave"
	Prompt NameDark1, "Second wave"
	Prompt NameDark2, "Third wave"
	Prompt NameDark3,"Fourth wave"
	Prompt NameDark4, "Fifth wave"
	Prompt NameDark5, "Sixth wave"
	Prompt NameDark6, "Seventh wave"
	DoPrompt "Enter name", NameDark0,NameDark1,NameDark2,NameDark3,NameDark4,NameDark5,NameDark6
	
	String/G saveDF = GetDataFolder(1)
	NewDataFolder/O/S root:WaveNames		
	String/G gNameDark0 = NameDark0
	String/G gNameDark1 = NameDark1
	String/G gNameDark2 = NameDark2
	String/G gNameDark3 = NameDark3
	String/G gNameDark4 = NameDark4
	String/G gNameDark5 = NameDark5
	String/G gNameDark6 = NameDark6
	String sigmaNameDark0 = NameDark0+"_sdev"
	String sigmaNameDark1 = NameDark1+"_sdev"
	String sigmaNameDark2 = NameDark2+"_sdev"
	String sigmaNameDark3 = NameDark3+"_sdev"
	String sigmaNameDark4 = NameDark4+"_sdev"
	String sigmaNameDark5 = NameDark5+"_sdev"
	String sigmaNameDark6 = NameDark6+"_sdev"
	
	SetDataFolder $saveDF
	KillStrings saveDF
	
	NewPath/O/Q CurrentDataFilePath pathToFolder
	pathName = "CurrentDataFilePath"
		
	LoadWave/G/N/P=$pathName fileName
	wave wave0,wave1,wave2,wave3,wave4,wave5,wave6
	
	if(cmpstr(NameDark0,"_none_") !=0 && cmpstr(NameDark0,"") != 0)
		WaveStats/Q wave0
		Variable/G $NameDark0 = V_avg
		Variable/G $sigmaNameDark0 = V_sdev
	endif
	
	if(cmpstr(NameDark1,"_none_") !=0 && cmpstr(NameDark1,"") != 0)
		WaveStats/Q wave1
		Variable/G $NameDark1 = V_avg
		Variable/G $sigmaNameDark1 = V_sdev
	endif

	if(cmpstr(NameDark2,"_none_") !=0 && cmpstr(NameDark2,"") != 0)
		WaveStats/Q wave2
		Variable/G $NameDark2 = V_avg
		Variable/G $sigmaNameDark2 = V_sdev
	endif

	if(cmpstr(NameDark3,"_none_") !=0 && cmpstr(NameDark3,"") != 0)
		WaveStats/Q wave3
		Variable/G $NameDark3 = V_avg
		Variable/G $sigmaNameDark3 = V_sdev
	endif
	
	if(cmpstr(NameDark4,"_none_") !=0 && cmpstr(NameDark4,"") != 0)
		WaveStats/Q wave4
		Variable/G $NameDark4 = V_avg
		Variable/G $sigmaNameDark4 = V_sdev
	endif
	
	if(cmpstr(NameDark5,"_none_") !=0 && cmpstr(NameDark5,"") != 0)
		WaveStats/Q wave5
		Variable/G $NameDark5 = V_avg
		Variable/G $sigmaNameDark5 = V_sdev
	endif
	
	if(cmpstr(NameDark6,"_none_") !=0 && cmpstr(NameDark6,"") != 0)
		WaveStats/Q wave6
		Variable/G $NameDark6 = V_avg
		Variable/G $sigmaNameDark6 = V_sdev
	endif

	KillWaves wave0,wave1,wave2,wave3,wave4,wave5,wave6
	
End


///////////////////////////////////////////////////////////
Static Function/S GGetLeafName(pathStr)
	String pathStr

	String leafName
	Variable pos
	
	leafName = ""
	pos = strlen(pathStr) - 1
	do 
		if(CmpStr(pathStr[pos], ":") == 0)
			leafName = pathStr[pos+1, strlen(pathStr)]
			break
		endif
		pos -= 1
	while(pos > 0)
	
	return leafName
End

/////  CheckWaveValidity
Function CheckWaveValidity(Onda)
	Wave Onda
	Variable i
	for (i=0; i<numpnts(Onda); i+=1)
		if (numtype(Onda[i]) != 0)
			Onda[i] = Nan
		endif
	endfor
End



//// Scaling waves 
Function Scaling2(NameWaveX,NameWaveY)
	String NameWaveX,NameWaveY
	
	if (strlen(NameWaveX)==0 || strlen(NameWaveY)==0)
		Prompt NameWaveX, "Scale according:", popup,WaveList("*",";","")
		Prompt NameWaveY, "Wave to scale:", popup,WaveList("*",";","")
		DoPrompt "Scaling",NameWaveX,NameWaveY
		
		if (V_flag == 1)
			return -1
		endif
	endif
		
	Wave xWave = $NameWaveX
	Wave yWave = $NameWaveY
	
	//Variable NumPntDestFactor = 2
	Variable NumPntDestFactor = 1
	Variable NumPntDest = numpnts(xWave)*NumPntDestFactor
		
	Interpolate2/T=1/N=(NumPntDest)/J=1 xWave, yWave
	
	Wave yWave_L = $(NameWaveY + "_L")
	duplicate/O yWave_L yWave
	KillWaves yWave_L
	
End

//// Scaling
Function Scaling(gScaling,Name0,Name1,Name2,Name3,Name4,Name5,Name6)
	Variable gScaling
	String Name0,Name1,Name2,Name3,Name4,Name5,Name6
	
	
	
	switch(gScaling)
		case 2:
			if (cmpstr(Name1,"_none_") != 0 && strlen(Name1) != 0)
				Scaling2(Name0,Name1)
			endif 
			if (cmpstr(Name2,"_none_") != 0 && strlen(Name2) != 0)
				Scaling2(Name0,Name2)
			endif 
			if (cmpstr(Name3,"_none_") != 0 && strlen(Name3) != 0)
				Scaling2(Name0,Name3)
			endif 
			if (cmpstr(Name4,"_none_") != 0 && strlen(Name4) != 0)
				Scaling2(Name0,Name4)
			endif 
			if (cmpstr(Name5,"_none_") != 0 && strlen(Name5) != 0)
				Scaling2(Name0,Name5)
			endif 
			break
		case 3:
			if (cmpstr(Name0,"_none_") != 0 && strlen(Name0) != 0)
				Scaling2(Name1,Name0)
			endif 
			if (cmpstr(Name2,"_none_") != 0 && strlen(Name2) != 0)
				Scaling2(Name1,Name2)
			endif 
			if (cmpstr(Name3,"_none_") != 0 && strlen(Name3) != 0)
				Scaling2(Name1,Name3)
			endif 
			if (cmpstr(Name4,"_none_") != 0 && strlen(Name4) != 0)
				Scaling2(Name1,Name4)
			endif 
			if (cmpstr(Name5,"_none_") != 0 && strlen(Name5) != 0)
				Scaling2(Name1,Name5)
			endif 
			break
		case 4:
			if (cmpstr(Name0,"_none_") != 0 && strlen(Name0) != 0)
				Scaling2(Name2,Name0)
			endif 
			if (cmpstr(Name1,"_none_") != 0 && strlen(Name1) != 0)
				Scaling2(Name2,Name1)
			endif 
			if (cmpstr(Name3,"_none_") != 0 && strlen(Name3) != 0)
				Scaling2(Name2,Name3)
			endif 
			if (cmpstr(Name4,"_none_") != 0 && strlen(Name4) != 0)
				Scaling2(Name2,Name4)
			endif 
			if (cmpstr(Name5,"_none_") != 0 && strlen(Name5) != 0)
				Scaling2(Name2,Name5)
			endif 
			break
		case 5:
			if (cmpstr(Name0,"_none_") != 0 && strlen(Name0) != 0)
				Scaling2(Name3,Name0)
			endif 
			if (cmpstr(Name1,"_none_") != 0 && strlen(Name1) != 0)
				Scaling2(Name3,Name1)
			endif 
			if (cmpstr(Name2,"_none_") != 0 && strlen(Name2) != 0)
				Scaling2(Name3,Name2)
			endif 
			if (cmpstr(Name4,"_none_") != 0 && strlen(Name4) != 0)
				Scaling2(Name3,Name4)
			endif 
			if (cmpstr(Name5,"_none_") != 0 && strlen(Name5) != 0)
				Scaling2(Name3,Name5)
			endif 
			break
		case 6:
			if (cmpstr(Name0,"_none_") != 0 && strlen(Name0) != 0)
				Scaling2(Name4,Name0)
			endif 
			if (cmpstr(Name1,"_none_") != 0 && strlen(Name1) != 0)
				Scaling2(Name4,Name1)
			endif 
			if (cmpstr(Name2,"_none_") != 0 && strlen(Name2) != 0)
				Scaling2(Name4,Name2)
			endif 
			if (cmpstr(Name3,"_none_") != 0 && strlen(Name3) != 0)
				Scaling2(Name4,Name3)
			endif 
			if (cmpstr(Name5,"_none_") != 0 && strlen(Name5) != 0)
				Scaling2(Name4,Name5)
			endif 
			break
		case 7:
			if (cmpstr(Name0,"_none_") != 0 && strlen(Name0) != 0)
				Scaling2(Name4,Name0)
			endif 
			if (cmpstr(Name1,"_none_") != 0 && strlen(Name1) != 0)
				Scaling2(Name4,Name1)
			endif 
			if (cmpstr(Name2,"_none_") != 0 && strlen(Name2) != 0)
				Scaling2(Name4,Name2)
			endif 
			if (cmpstr(Name3,"_none_") != 0 && strlen(Name3) != 0)
				Scaling2(Name4,Name3)
			endif 
			if (cmpstr(Name4,"_none_") != 0 && strlen(Name4) != 0)
				Scaling2(Name4,Name5)
			endif 
			break
	endswitch
	
	
End
			
			
			
		
// Carica la corrente dell'anello	
Function RingCurrent(pathName,fileName)
	String pathName,fileName

	String dummyString,dummy1,dummy2
	Variable refNum
	Variable rc1,rc2
	Variable StartScan,EndScan
	Variable giorno,mese,anno,ora,minuti,secondi
	
	Open/R/Z=2/P=$pathName refNum as fileName
		
	FReadLine refNum, dummyString
	FReadLine refNum, dummyString
	sscanf dummyString, "Scan beginning: %s\t%s",dummy1,dummy2
	sscanf dummy1,"%i/%i/%i",giorno,mese,anno
	sscanf dummy2,"%i.%i.%i",ora,minuti,secondi
	StartScan = date2secs(anno,mese,giorno) + (ora*3600+minuti*60+secondi)
		
	FReadLine refNum, dummyString
	sscanf dummyString, "Ring current (mA): %f", rc1
	
	FReadLine refNum, dummyString
	sscanf dummyString, "Scan end: %s\t%s",dummy1,dummy2
	sscanf dummy1,"%i/%i/%i",giorno,mese,anno
	sscanf dummy2,"%i.%i.%i",ora,minuti,secondi
	EndScan = date2secs(anno,mese,giorno) + (ora*3600+minuti*60+secondi)
	
	FReadLine refNum, dummyString
	sscanf dummyString, "Ring current (mA): %f", rc2
	
	return ((rc1+rc2)/2)
	//Variable V_DurataScan = EndScan - StartScan
	
	
End

////////////////////////////////////

Function LoadMacroPhEnTime()
	Variable i = 0
	String S_Index,S_PhEn,S_Inst1,S_Inst2,S_Inst3
	String ListaOnde = WaveList("*",";","")
	
	Prompt S_Index,"Choose wave with the indexes",popup(ListaOnde)
	Prompt S_PhEn,"Choose wave with the photon energy",popup(ListaOnde)
	Prompt S_Inst1,"Choose Instrument 1",popup("_none_;"+ListaOnde)
	Prompt S_Inst2,"Choose Instrument 2",popup("_none_;"+ListaOnde)
	Prompt S_Inst3,"Choose Instrument 3",popup("_none_;"+ListaOnde)
	
	DoPrompt "Parameters",S_Index,S_PhEn,S_Inst1,S_Inst2,S_Inst3
	
	Wave index = $S_Index
	Wave PhEn = $S_PhEn
	if (cmpstr(S_Inst1,"_none_") != 0)
		Wave Inst1 = $S_Inst1
	endif
	if(cmpstr(S_Inst2,"_none_") != 0)
		Wave Inst2 = $S_Inst2
	endif
	if(cmpstr(S_Inst3,"_none_") != 0)
		Wave Inst3 = $S_Inst3
	endif
	
	
	Variable ind0 = index[0]
	// calcola la lunghezza di ciascuno scan
	do
		i+=1
	while (index[i] != ind0)

	Variable numpunti = numpnts(index)/i
	Variable l=0
	
	Make/N=(numpunti) PhEn_2
	if (cmpstr(S_Inst1,"_none_") != 0)
		Make/N=(numpunti) Inst1_2
	endif
	if(cmpstr(S_Inst2,"_none_") != 0)
		Make/N=(numpunti) Inst2_2
	endif
	if(cmpstr(S_Inst3,"_none_") != 0)
		Make/N=(numpunti) Inst3_2
	endif
	
	
	
	
End