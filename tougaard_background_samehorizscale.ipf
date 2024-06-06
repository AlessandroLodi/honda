
#pragma rtGlobals=1             // Use modern global access method.
// la macro chiede in ingresso il nome della wave delle Y di cui si vuole trovare il fondo
// e il nome della wave di background tipo Tougaard (ref. S.Tougaard, Surf.Sci. 216 (1989) 343).
// Occorre prima di tutto posizionare i cursori A e B sul grafico in modo da  individuare i punti tra i quali il
// background verrà calcolato.
// N.B. Il cursore A deve stare verso le energie cinetiche maggiori (minori binding energy) e
// il cursore B deve stare verso le energie cinetiche minori (maggiori binding energy)


macro Tougaard_background(sp,fo)
         string sp,fo
//    Variable B1
         Prompt sp, "Enter the wavename of the spectrum"
         Prompt fo, "Enter the output wavename for the background"
//         Prompt B1, "Enter B1 parameter"
         

         variable h0 = vcsr(B)
         variable d = vcsr(A)
         variable g = abs(vcsr(A)-vcsr(B))
         variable e1, e2
        
	  duplicate /O $sp $fo,tmp
         //make/o/N=(numpnts($sp)) $fo,tmp

         duplicate /O/R=[pcsr(B),pcsr(A)] $sp tmp1

         make/o/N=(numpnts(tmp1)) tmp2,tmp3,
         
         tmp2 = tmp1 - d
e1 = numpnts(tmp1)
e2 = numpnts(tmp1)
         
tougaard_BK (tmp1,e1,e2,tmp2,tmp3)
         duplicate/O tmp3 tmp4
//      tmp4=tmp3*B1 + d
      tmp4=(tmp3/tmp3[0])*g + d  
         duplicate/O $sp $sp+"S"
         smooth 5, $sp+"S"
         $fo[0,pcsr(b)-1]=$sp+"S"
         $fo[pcsr(b),pcsr(a)]=tmp4[p-pcsr(b)]
         $fo[pcsr(a)+1,numpnts($sp)]=$sp+"S"
         tmp = $fo
         appendtograph $fo
         killwaves tmp, tmp1, tmp2, tmp3, tmp4, $sp+"S"
end macro

Function tougaard_BK (tmp1,e1,e2,tmp2,tmp3)
Variable e1, e2
wave tmp1, tmp2, tmp3
	for(e1 = numpnts(tmp1);e1>=0;e1-=1)
		for(e2 = numpnts(tmp1);e2>=e1;e2-=1)
		tmp3[e1]+=tmp2[e2]*((e2-e1)/(1643+(e2-e1)^2)^2)	
		endfor								
	endfor	
end
