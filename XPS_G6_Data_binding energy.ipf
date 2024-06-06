#pragma rtGlobals=1		// Use modern global access method.


Menu "Load Waves"
	Submenu "XPS G6 Data"
		"Load data from single file + binding energy scale", LoadXPSG6DataSingle_be("","")
		"Load all data in a folder + binding energy scale", LoadXPSG6DataInFolder_be()
		"-"

	End
End


Function LoadXPSG6DataSingle_be(pathName,fileName)
	String fileName, pathName
	
	if(strlen(pathName)==0 & strlen(fileName)==0)
		// insert names for the waves
		String Name0 = StrVarOrDefault("root:WaveNames:gName0","_none_")
		Prompt Name0, "kinetic energy wave"
		String Name1 = StrVarOrDefault("root:WaveNames:gName1","_none_")
		Prompt Name1, "Intensity wave"
		String Name2 = StrVarOrDefault("root:WaveNames:gName2","_none_")
		Prompt Name2, "binding energy wave"
		Variable, wf = NumVarOrDefault("root:WaveNames:gwf",0)
		Variable vpol = NumVarOrDefault("root:WaveNames:gvpol",0)
		Prompt wf, "Enter analyzer work function value (eV)"
		Prompt vpol, "Enter sample polarization voltage (V)"
		Variable photon = NumVarOrDefault("root:WaveNames:gPhoton",4)
		Prompt Photon, "Choose photon energy (eV)", popup "19.8;21.2;40.8;1253.6;1486.6"
		Variable Scaling = NumVarOrDefault("root:WaveNames:gScaling",1)
		Prompt Scaling,"Scale waves according ",popup,"None;kinetic energy;binding energy"
	DoPrompt "Enter name", Name0,Name1,Name2,wf,vpol,Photon,Scaling
				
		if(V_flag == 1) 
			return -1
		endif
		
		String/G saveDF = GetDataFolder(1)
		NewDataFolder/O/S root:WaveNames		
		String/G gName0 = Name0
		String/G gName1 = Name1
		String/G gName2 = Name2
		Variable/G gwf = wf
		Variable/G gvpol = vpol 
		Variable/G gPhoton = Photon
		Variable/G gScaling = Scaling
		SetDataFolder $saveDF
		KillStrings saveDF
		
		Variable refNum
		String pathToFolder
		
		
		Open/R/D/MULT=1/M="Choose data file" refNum
	
		if(strlen(S_fileName) == 0)
			return -1
		endif
		
		String outputfile 
		outputfile = S_fileName
		Variable numFilesSelected = ItemsInList(outputfile, "\r")
		Variable i
		String NameFile
		for(i=0; i<numFilesSelected; i+=1)
				
		NameFile = StringFromList(i, outputfile, "\r")	
		fileName = GGetLeafName_be(NameFile)
	
		pathToFolder = NameFile[0, strlen(NameFile) - strlen(fileName) - 1]
	
		NewPath/O/Q CurrentDataFilePath pathToFolder
		pathName = "CurrentDataFilePath"
	
		LoadXPSG6Data_be(pathName,fileName,Name0,Name1,Name2,vpol,wf)
	
	endfor
	
	endif
	
//	LoadXPSG6Data_be(pathName,fileName,Name0,Name1,Name2,vpol,wf)
	
End


Function LoadXPSG6DataInFolder_be()
	// insert names for the waves
	String Name0 = StrVarOrDefault("root:WaveNames:gName0","_none_")
	Prompt Name0, "kinetic energy wave"
	String Name1 = StrVarOrDefault("root:WaveNames:gName1","_none_")
	Prompt Name1, "Intensity wave"
	String Name2 = StrVarOrDefault("root:WaveNames:gName2","_none_")
	Prompt Name2, "binding energy wave"
	Variable, wf = NumVarOrDefault("root:WaveNames:gwf",0)
	Variable vpol = NumVarOrDefault("root:WaveNames:gvpol",0)
	Prompt wf, "Enter analyzer work function value (eV)"
	Prompt vpol, "Enter sample polarization voltage (V)"
	Variable Photon = NumVarOrDefault("root:WaveNames:gPhoton",4)
	Prompt Photon, "Choose photon energy (eV)", popup "19.8;21.2;40.8;1253.6;1486.6"
	Variable Scaling = NumVarOrDefault("root:WaveNames:gScaling",1)
	Prompt Scaling,"Scale waves according ",popup,"None;kinetic energy;binding energy"
	DoPrompt "Enter name", Name0,Name1,Name2,wf,vpol,Photon,Scaling
	
	if(V_flag == 1) 
		return -1
	endif
	
	// saves wave names for future uses
	String/G saveDF = GetDataFolder(1)
	NewDataFolder/O/S root:WaveNames		
	String/G gName0 = Name0
	String/G gName1 = Name1
	String/G gName2 = Name2
	Variable/G gwf = wf
	Variable/G gvpol = vpol 
	Variable/G gPhoton = Photon
	Variable/G gScaling = Scaling
	SetDataFolder $saveDF
	KillStrings saveDF
		
	String pathName
	NewPath/O/Q/M="Choose folder containing data files" CurrentDataFilePath
	PathInfo CurrentDataFilePath
	if(V_flag == 0)
		return -1
	endif
	
	pathName = "CurrentDataFilePath"
	
	Variable i=0, numFilesLoaded=0
	String fileName
	
	do
		fileName=IndexedFile($pathName, i, "????")
		if(strlen(fileName) == 0)
			break
		endif
		LoadXPSG6Data_be(pathName,fileName,Name0,Name1,Name2,vpol,wf)
		i += 1
		numFilesLoaded += 1
	while(1)
	
	return numFilesLoaded
	
End

Function/S GGetLeafName_be(pathStr)
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



// Loads XPS G6 data
Function LoadXPSG6Data_be(pathName,fileName,Name0,Name1,Name2,vpol,wf)
	String pathName,fileName
	String Name0,Name1,Name2
	Variable vpol, wf	
	
	NVAR gScaling = root:WaveNames:gScaling
	NVAR gPhoton = root:WaveNames:gPhoton

	String savedDataFolder = GetDataFolder(1)
	NewDataFolder/O/S :$fileName
	
	LoadWave/G/A/P=$pathName fileName
	wave wave0,wave1
	duplicate/O wave0 wave2
	switch(gPhoton)
		case 1:
		wave2 = (19.8-wave0-wf-vpol)
		break
		case 2:
		wave2 = (21.2-wave0-wf-vpol)
		break
		case 3:
		wave2 = (40.8-wave0-wf-vpol)
		break
		case 4:
		wave2 = (1253.6-wave0-wf-vpol)
		break
		case 5:
		wave2 = (1486.6-wave0-wf-vpol)
		break
	endswitch
	Variable i
	switch(gScaling)
		case 1:
			break
		case 2: 
			i=0
			do 
				i += 1
			while (numtype(wave0[numpnts(wave0)-i]) != 0) 
			SetScale/I x wave0[0],wave0[numpnts(wave0)-i],"",wave0,wave1,wave2
			break
		case 3:
			i=0
			do 
				i += 1
			while (numtype(wave2[numpnts(wave2)-i]) != 0)
			SetScale/I x wave2[0],wave2[numpnts(wave2)-i],"",wave2,wave1,wave2
			break
			endswitch
			
			
	if(cmpstr(Name0,"_none_"))
		Note wave0 fileName
		Rename wave0 $Name0
	else
		KillWaves wave0
	endif
	if(cmpstr(Name1,"_none_"))
		Note wave1 fileName
		Rename wave1 $Name1
	else
		KillWaves wave1
	endif
	if(cmpstr(Name2,"_none_"))
		Note wave2 fileName
		Rename wave2 $Name2
	else
		KillWaves wave2
	endif
	
	SetDataFolder savedDataFolder
	
	
	return 0
End
////////////////////////////////////////////////////

End