#pragma rtGlobals=1		// Use modern global access method.


Menu "Load Waves"
	Submenu "XPS G6 Data"
		"Load data from single file", LoadXPSG6DataSingle("","")
		"Load all data in a folder", LoadXPSG6DataInFolder()
		"-"

	End
End


Function LoadXPSG6DataSingle(pathName,fileName)
	String fileName, pathName
	
	if(strlen(pathName)==0 & strlen(fileName)==0)
		// insert names for the waves
		String Name0 = StrVarOrDefault("root:WaveNames:gName0","_none_")
		Prompt Name0, "First wave"
		String Name1 = StrVarOrDefault("root:WaveNames:gName1","_none_")
		Prompt Name1, "Second wave"
		Variable Scaling = NumVarOrDefault("root:WaveNames:gScaling",1)
		Prompt Scaling,"Scale waves according wave",popup,"None;1st;2nd"
		DoPrompt "Enter name", Name0,Name1,Scaling
				
		if(V_flag == 1) 
			return -1
		endif
		
		String/G saveDF = GetDataFolder(1)
		NewDataFolder/O/S root:WaveNames		
		String/G gName0 = Name0
		String/G gName1 = Name1

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
		
		LoadXPSG6Data(pathName,fileName,Name0,Name1)
		
endfor
endif
			
		
//		Open/R/D/M="Choose data file" refNum
//	
//		if(strlen(S_fileName) == 0)
//			return -1
//		endif
//	
//		fileName = GGetLeafName(S_fileName)
//	
//		pathToFolder = S_fileName[0, strlen(S_fileName) - strlen(fileName) - 1]
//	
//		NewPath/O/Q CurrentDataFilePath pathToFolder
//		pathName = "CurrentDataFilePath"
//	endif
//	
//	LoadXPSG6Data(pathName,fileName,Name0,Name1)
	
End


Function LoadXPSG6DataInFolder()
	// insert names for the waves
	String Name0 = StrVarOrDefault("root:WaveNames:gName0","_none_")
	Prompt Name0, "First wave"
	String Name1 = StrVarOrDefault("root:WaveNames:gName1","_none_")
	Prompt Name1, "Second wave"
	
	Variable Scaling = NumVarOrDefault("root:WaveNames:gScaling",1)
	Prompt Scaling,"Scale waves according ",popup,"None;1st;2nd"
	DoPrompt "Enter name", Name0,Name1,Scaling
	
	if(V_flag == 1) 
		return -1
	endif
	
	// saves wave names for future uses
	String/G saveDF = GetDataFolder(1)
	NewDataFolder/O/S root:WaveNames		
	String/G gName0 = Name0
	String/G gName1 = Name1
	
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
		LoadXPSG6Data(pathName,fileName,Name0,Name1)
		i += 1
		numFilesLoaded += 1
	while(1)
	
	return numFilesLoaded
	
End

Function/S GGetLeafName(pathStr)
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
Function LoadXPSG6Data(pathName,fileName,Name0,Name1)
	String pathName,fileName
	String Name0,Name1	
	
	NVAR gScaling = root:WaveNames:gScaling

	String savedDataFolder = GetDataFolder(1)
	NewDataFolder/O/S :$fileName
	
	LoadWave/G/A/P=$pathName fileName
	wave wave0,wave1
	Variable i
	
	switch(gScaling)
		case 1:
			break
		case 2: 
			i=0
			do 
				i += 1
			while (numtype(wave0[numpnts(wave0)-i]) != 0) 
			SetScale/I x wave0[0],wave0[numpnts(wave0)-i],"",wave0,wave1
			break
		case 3:
			i=0
			do 
				i += 1
			while (numtype(wave1[numpnts(wave1)-i]) != 0)
			SetScale/I x wave1[0],wave1[numpnts(wave1)-i],"",wave0,wave1
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
	
	
	SetDataFolder savedDataFolder
	
	
	return 0
End
////////////////////////////////////////////////////

End