#pragma rtGlobals=1		// Use modern global access method.

//this procedure is to load BL7A beamline hysteresis data. 
//one has to upload two waves, for pre-edge and edge data. 
//Every scan is loaded separately with consecutive numbering and an average is finally calculated.
//hysteresis is obtained by measuring Is and Im at every field point, then
//hyst = ((Is/Im)edge-(Is/Im)pre)/((Is/Im)pre)
//to avoid problems in loop closing, every loop starts at max applied positive field instead of zero



Menu "Load Waves"
	Submenu "BL7A hysteresis Data"
		"Load data from single file", LoadBL7hystDataSingle("","")
		"-"


	End
End

Function LoadBL7hystDataSingle(fileName_pre,filename_edg)
	String fileName_pre, fileName_edg
	
	if(strlen(fileName_pre)==0 &  strlen(fileName_edg)==0)
		// insert names for the waves
		Variable refNum
		String pathToFolder_pre, pathToFolder_edg
		
		Open/R/D/M="Choose data file for Pre-edge" refNum
	
		if(strlen(S_fileName) == 0)
			return -1
		endif
		
		fileName_pre = GGetLeafName3(S_fileName)
		pathToFolder_pre = S_fileName[0, strlen(S_fileName) - strlen(fileName_pre) - 1]
		
		Open/R/D/M="Choose data file for Edge" refNum
	
		if(strlen(S_fileName) == 0)
			return -1
		endif
		
		fileName_edg = GGetLeafName3(S_fileName)
		pathToFolder_edg = S_fileName[0, strlen(S_fileName) - strlen(fileName_pre) - 1]
	
	endif
	
	LoadBL7hystData(fileName_pre,fileName_edg,pathToFolder_pre,pathToFolder_edg)
	
End
	
	
	
// Loads BL7A hyst data
Function LoadBL7hystData(fileName_pre,fileName_edg,pathToFolder_pre,pathToFolder_edg)
	String fileName_pre,fileName_edg
	String pathToFolder_pre, pathToFolder_edg	
	String nomefile
	String pathName
	pathName = "CurrentDataFilePath"
	
	nomefile="hyst_(pre)" + filename_pre + "(edg)" +filename_edg
	
	NewDataFolder/O/S :$nomefile
	
	NewPath/O/Q CurrentDataFilePath pathToFolder_pre
	LoadWave/G/A/P=$pathName/B="C=1,N=A_pre;C=1,N=Im_pre;C=1,N=Is_pre;C=1,N='_skip_';" fileName_pre
	NewPath/O/Q CurrentDataFilePath pathToFolder_edg
	LoadWave/G/A/P=$pathName/B="C=1,N=A_edg;C=1,N=Im_edg;C=1,N=Is_edg;C=1,N='_skip_';" fileName_edg
	hyster()

end

Function hyster()
	variable i,j,k,g,h
	variable npts
//	variable nscan


		wave A_pre,Im_pre,Is_pre,Inorm_pre
		duplicate Is_pre Inorm_pre
		Inorm_pre=Is_pre/Im_pre		
		npts=numpnts(A_pre)-1
		j=0
		k=0
			
		for(i=0; i<=npts; i +=1)
			if(A_pre[i]==Wavemax(A_pre))
				if (j==0)
				h=i
				endif
			j+=1
			if (j==2)
				if(k==0)
				g=i-h
				endif
			k+=1
			
			duplicate/R=[i-g,i-1] A_pre $("A_pre"+num2str(k))
			duplicate/R=[i-g,i-1] Is_pre $("Is_pre"+num2str(k))
			duplicate/R=[i-g,i-1] Im_pre $("Im_pre"+num2str(k))
			duplicate/R=[i-g,i-1] Inorm_pre $("Inorm_pre"+num2str(k))
			j=0
			i=i-1
			endif
			endif
		endfor
				
		make/N=(g)/O Is_pre_av	
		make/N=(g)/O Im_pre_av
		make/N=(g)/O A_pre_av
		make/N=(g)/O Inorm_pre_av	
		Is_pre_av=0
		Im_pre_av=0
		A_pre_av=0
		Inorm_pre_av=0
	
		for(i=1;i<=k;i+=1)	
	
		wave Ispre=$("Is_pre"+num2str(i))
		wave Impre=$("Im_pre"+num2str(i))
		wave Apre=$("A_pre"+num2str(i))
		wave Inpre=$("Inorm_pre"+num2str(i))
		Is_pre_av=(Is_pre_av*(i)/(i+1))+Ispre/(i+1)
		Im_pre_av=(Im_pre_av*(i)/(i+1))+Impre/(i+1)
		A_pre_av=Apre
		Inorm_pre_av=(Inorm_pre_av*(i)/(i+1))+Inpre/(i+1)

		endfor

// display Inorm_pre_av vs A_pre_av

		wave A_edg,Is_edg,Im_edg, Inrom_edg, hyst
		duplicate Is_edg Inorm_edg
		Inorm_edg=Is_edg/Im_edg
		
		duplicate Inorm_edg hyst
		hyst=(Inorm_edg-Inorm_pre)/(Inorm_pre) 
//		display hyst vs A_edg
		
		npts=numpnts(A_edg)-1
		j=0
		k=0
		
		for(i=0; i<=npts; i +=1)
			if(A_edg[i]==Wavemax(A_edg))
				if (j==0)
				h=i
				endif
			j+=1
			if (j==2)
				if(k==0)
				g=i-h
				endif
			k+=1
	
			duplicate/R=[i-g,i-1] A_edg $("A_edg"+num2str(k))
			duplicate/R=[i-g,i-1] Is_edg $("Is_edg"+num2str(k))
			duplicate/R=[i-g,i-1] Im_edg $("Im_edg"+num2str(k))
			duplicate/R=[i-g,i-1] Inorm_edg $("Inorm_edg"+num2str(k))
			duplicate/R=[i-g,i-1] hyst $("hyst"+num2str(k))
			
			if (k==1)
			display $("hyst"+num2str(k)) vs $("A_edg"+num2str(k))
			else
			appendtograph $("hyst"+num2str(k)) vs $("A_edg"+num2str(k))
			modifygraph lStyle($("hyst"+num2str(k)))=k
			endif
			
			j=0
			i=i-1
			endif
			endif
		endfor
		
		
		make/N=(g)/O Is_edg_av	
		make/N=(g)/O Im_edg_av
		make/N=(g)/O A_edg_av
		make/N=(g)/O Inorm_edg_av		
		Is_edg_av=0
		Im_edg_av=0
		A_edg_av=0
		Inorm_edg_av=0

	
		for(i=1;i<=k;i+=1)	
	
		wave Isedg=$("Is_edg"+num2str(i))
		wave Imedg=$("Im_edg"+num2str(i))
		wave Aedg=$("A_edg"+num2str(i))
		wave Inedg=$("Inorm_edg"+num2str(i))
		Is_edg_av=(Is_edg_av*(i)/(i+1))+Isedg/(i+1)
		Im_edg_av=(Im_edg_av*(i)/(i+1))+Imedg/(i+1)
		A_edg_av=Aedg
		Inorm_edg_av=(Inorm_edg_av*(i)/(i+1))+Inedg/(i+1)
				
		endfor
		
		duplicate Inorm_edg_av hyst_av
		hyst_av= (Inorm_edg_av-Inorm_pre_av)/(Inorm_pre_av) 
		appendtograph hyst_av vs A_edg_av	
		modifygraph  lSize(hyst_av)=2
		
// display Inorm_edg_av vs A_edg_av	
	

//	return 0
End
	

////////////

Function/S GGetLeafName3(pathStr)
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