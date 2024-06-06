#pragma rtGlobals=1		// Use modern global access method.

//this procedure is to load APE beamline dichroism data when XMCD every point function is used. 
//Every scan is loaded separately with consecutive numbering and an average is finally calculated.
//dichroism is obtained by measuring Is and Im at every energy point for each mag field direction, then
//dich = ((Is_MP/Im_MP)-(Is__MM/Im__MM))/((Is_MP/Im_MP)+(Is__MM/Im__MM))


Menu "Load Waves"
	Submenu "APE dichroism Data"
		"Load data from single file", LoadAPEdichDataSingle("","")
		"-"

	End
End

Function LoadAPEdichDataSingle(pathName,fileName)
	String fileName, pathName
	
	if(strlen(pathName)==0 & strlen(fileName)==0)
		// insert names for the waves
		Variable refNum
		String pathToFolder
		
		
		Open/R/D/M="Choose data file" refNum
	
		if(strlen(S_fileName) == 0)
			return -1
		endif

		
		
		fileName = GGetLeafName1(S_fileName)
		
	
		pathToFolder = S_fileName[0, strlen(S_fileName) - strlen(fileName) - 1]
	
		NewPath/O/Q CurrentDataFilePath pathToFolder
		pathName = "CurrentDataFilePath"
	endif
	
	LoadAPEdichData(pathName,fileName,en,IsIm_MP,IsIm_MM)
	
End
	
	
	
// Loads APE dich data
Function LoadAPEdichData(pathName,fileName,en,IsIm_MP,IsIm_MM)
	String pathName,fileName
	wave en,IsIm_MP,IsIm_MM
	variable nscan
	variable i
	
	String nomefile
	nomefile="dichr " + filename
	
	NewDataFolder/O/S :$nomefile
	
	
	//NewDataFolder/O/S :$fileName

	
	LoadWave/G/A/P=$pathName/B="C=1,N=en;C=9,N='_skip_'; C=1,N=IsIm_MP;C=1,N=IsIm_MM;" fileName
	
	dicroismo()
end

Function dicroismo()
	variable nscan
	variable i
	wave IsIm_MP,IsIm_MM, en
	
	nscan=countobjects("",1)/3

	
	if (nscan==1)
		make/N=(numpnts(IsIm_MP))/O dichr	
		make/N=(numpnts(IsIm_MP))/O asym 
		dichr=(IsIm_MP-IsIm_MM)
		asym=(IsIm_MP-IsIm_MM)/(IsIm_MP+IsIm_MM)
		display IsIm_MP vs en
		appendtograph IsIm_MM vs en
		display dichr vs en
	
	else
	
	make/N=(numpnts(IsIm_MP))/O IsIm_MP_av	
	make/N=(numpnts(IsIm_MP))/O IsIm_MM_av
	IsIm_MP_av=IsIm_MP
	IsIm_MM_av=IsIm_MM
	
	for(i=1;i<nscan;i+=1)	// Initialize variables;continue test
										// Condition;update loop variables
													// Execute body code until continue test is FALSE
	
		wave WMP=$("IsIm_mp"+num2str(i))
		wave WMM=$("IsIm_mm"+num2str(i))
		IsIm_MP_av=(IsIm_MP_av*(i)/(i+1))+WMP/(i+1)
		IsIm_MM_av=(IsIm_MM_av*(i)/(i+1))+WMM/(i+1)
		
	endfor
	
		make/N=(numpnts(IsIm_MP))/O  dichr
		make/N=(numpnts(IsIm_MP))/O asym	 
		dichr=(IsIm_MP_av-IsIm_MM_av)
		asym=(IsIm_MP_av-IsIm_MM_av)/(IsIm_MP_av+IsIm_MM_av)
		display IsIm_MP_av vs en
		appendtograph IsIm_MM_av vs en
		display dichr vs en
	
endif	
//	return 0
End
	
////////////

Function/S GGetLeafName1(pathStr)
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
//////////////	