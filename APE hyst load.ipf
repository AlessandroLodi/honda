#pragma rtGlobals=1		// Use modern global access method.

//this procedure is to load APE beamline hysteresis data. User must enter helicity (L or R)
//Either "_L" or "_R" is appended to the wavename
//Every scan is loaded separately with consecutive numbering and an average is finally calculated.
//Hysteresis is obtained by measuring Is and Im at edge and preedge, then
//hyst = ((Is_ed/Im_ed)-(Is_pre/Im_pre))/(Is_pre/Im_pre)

Menu "Load Waves"
	Submenu "APE hysteresis Data"
		"Load data from single file", LoadAPEhystDataSingle("","")
		"-"


	End
End

Function LoadAPEhystDataSingle(pathName,fileName)
	String fileName, pathName
	variable eli
	Prompt eli, "Enter circular polarisation rotation: R or L", popup "L;R"
	doprompt "Enter circular polarisation rotation: R or L", eli
	
	
	if(strlen(pathName)==0 & strlen(fileName)==0)
		// insert names for the waves
		Variable refNum
		String pathToFolder
		
		
		Open/R/D/M="Choose data file" refNum
	
		if(strlen(S_fileName) == 0)
			return -1
		endif

		
		
		fileName =  GGetLeafName2(S_fileName)
		
	
		pathToFolder = S_fileName[0, strlen(S_fileName) - strlen(fileName) - 1]
	
		NewPath/O/Q CurrentDataFilePath pathToFolder
		pathName = "CurrentDataFilePath"
	endif
	
	
//	LoadAPEhystData(eli,pathName,fileName,A_R,Is_ed_R,Im_ed_R,Is_pre_R,Im_pre_R)

	LoadAPEhystData(eli,pathName,fileName)
	
End
	
	
	
// Loads APE hyst data

//Function LoadAPEhystData(eli,pathName,fileName,A_R,Is_ed_R,Im_ed_R,Is_pre_R,Im_pre_R)

Function LoadAPEhystData(eli,pathName,fileName)

	String pathName,fileName
//	wave A_R,Is_ed_R,Im_ed_R,Is_pre_R,Im_pre_R
	variable eli
//	variable i
	String nomefile
	nomefile="hyst " + filename
	
	NewDataFolder/O/S :$nomefile

	if (eli==2)
	LoadWave/G/A/P=$pathName/B="C=1,N=A_R;C=1,N=Is_ed_R;C=1,N=Im_ed_R;C=1,N=Is_pre_R;C=1,N=Im_pre_R;C=4,N='_skip_';" fileName
	hysteresis(eli)
	endif
	if (eli==1)
	LoadWave/G/A/P=$pathName/B="C=1,N=A_L;C=1,N=Is_ed_L;C=1,N=Im_ed_L;C=1,N=Is_pre_L;C=1,N=Im_pre_L;C=4,N='_skip_';" fileName
	hysteresis(eli)
	endif

end

Function hysteresis(eli)
	variable eli

	variable nscan
	variable i
	if(eli==2)
	
		wave Is_ed_R,Im_ed_R,Is_pre_R,Im_pre_R

		nscan=countobjects("",1)/5

		if (nscan==1)
		make/N=(numpnts(Is_ed_R))/O hyst_R	 
		hyst_R=((Is_ed_R/Im_ed_R)-(Is_pre_R/Im_pre_R))/(Is_pre_R/Im_pre_R)
		display hyst_R vs A_R
		
		else
	
		make/N=(numpnts(Is_ed_R))/O Is_ed_R_av	
		make/N=(numpnts(Im_ed_R))/O Im_ed_R_av
		make/N=(numpnts(Is_pre_R))/O Is_pre_R_av	
		make/N=(numpnts(Im_pre_R))/O Im_pre_R_av
		Is_ed_R_av=Is_ed_R
		Im_ed_R_av=Im_ed_R
		Is_pre_R_av=Is_pre_R
		Im_pre_R_av=Im_pre_R
	
		for(i=1;i<nscan;i+=1)	
	
		wave Ised=$("Is_ed_R"+num2str(i))
		wave Imed=$("Im_ed_R"+num2str(i))
		wave Ispre=$("Is_pre_R"+num2str(i))
		wave Impre=$("Im_pre_R"+num2str(i))
		Is_ed_R_av=(Is_ed_R_av*(i)/(i+1))+Ised/(i+1)
		Im_ed_R_av=(Im_ed_R_av*(i)/(i+1))+Imed/(i+1)
		Is_pre_R_av=(Is_pre_R_av*(i)/(i+1))+Ispre/(i+1)
		Im_pre_R_av=(Im_pre_R_av*(i)/(i+1))+Impre/(i+1)
		
		endfor
	
		make/N=(numpnts(Is_ed_R))/O  hyst_R	 
		hyst_R=((Is_ed_R_av/Im_ed_R_av)-(Is_pre_R_av/Im_pre_R_av))/(Is_pre_R_av/Im_pre_R_av)
		display hyst_R vs A_R
	
		endif
		
	endif	

	if(eli==1)
		wave Is_ed_L,Im_ed_L,Is_pre_L,Im_pre_L

		nscan=countobjects("",1)/5

		if (nscan==1)
		make/N=(numpnts(Is_ed_L))/O hyst_L	 
		hyst_L=((Is_ed_L/Im_ed_L)-(Is_pre_L/Im_pre_L))/(Is_pre_L/Im_pre_L)
		display hyst_L vs A_L
		
		else
	
		make/N=(numpnts(Is_ed_L))/O Is_ed_L_av	
		make/N=(numpnts(Im_ed_L))/O Im_ed_L_av
		make/N=(numpnts(Is_pre_L))/O Is_pre_L_av	
		make/N=(numpnts(Im_pre_L))/O Im_pre_L_av
		Is_ed_L_av=Is_ed_L
		Im_ed_L_av=Im_ed_L
		Is_pre_L_av=Is_pre_L
		Im_pre_L_av=Im_pre_L
	
		for(i=1;i<nscan;i+=1)	
	
		wave Ised=$("Is_ed_L"+num2str(i))
		wave Imed=$("Im_ed_L"+num2str(i))
		wave Ispre=$("Is_pre_L"+num2str(i))
		wave Impre=$("Im_pre_L"+num2str(i))
		Is_ed_L_av=(Is_ed_L_av*(i)/(i+1))+Ised/(i+1)
		Im_ed_L_av=(Im_ed_L_av*(i)/(i+1))+Imed/(i+1)
		Is_pre_L_av=(Is_pre_L_av*(i)/(i+1))+Ispre/(i+1)
		Im_pre_L_av=(Im_pre_L_av*(i)/(i+1))+Impre/(i+1)
		
		endfor
	
		make/N=(numpnts(Is_ed_L))/O  hyst_L	 
		hyst_L=((Is_ed_L_av/Im_ed_L_av)-(Is_pre_L_av/Im_pre_L_av))/(Is_pre_L_av/Im_pre_L_av)
		display hyst_L vs A_L
	
		endif
		
	endif	

//	return 0
End
	
////////////

Function/S GGetLeafName2(pathStr)
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