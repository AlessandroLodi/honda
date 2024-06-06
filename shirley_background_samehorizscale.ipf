
#pragma rtGlobals=1             // Use modern global access method.
// la macro chiede in ingresso il nome della wave delle Y di cui si vuole trovare il fondo
// e il nome della wave di background tipo shirley (ref. D.A. Shirley, Phys.Rev.B 5 (1972) 4709).
// Occorre prima di tutto posizionare i cursori A e B sul grafico in modo da  individuare i punti tra i quali il
// background verrà calcolato.
// N.B. Il cursore A deve stare verso le energie cinetiche maggiori (minori binding energy) e
// il cursore B deve stare verso le energie cinetiche minori (maggiori binding energy)


macro shirley_background(sp,fo,ko)
         string sp,fo,ko
         Prompt sp, "Enter the wavename of the spectrum"
         Prompt fo, "Enter the output wavename for the background"
         Prompt ko, "Enter the wavename of the x axis"

         variable h0 = vcsr(B)
         variable d = vcsr(A)
         variable g = vcsr(A)-vcsr(B)


	  duplicate /O $sp $fo,tmp
         //make/o/N=(numpnts($sp)) $fo,tmp

         duplicate /O/R=[pcsr(B),pcsr(A)] $sp tmp1

         make/o/N=(numpnts(tmp1)) tmp2,tmp3,

         tmp2 = tmp1 - d
         tmp3=tmp2[0]*(area(tmp2,p,numpnts(tmp2))/(area(tmp2,0,numpnts(tmp2)))) + d
         duplicate/O $sp $sp+"S"
         smooth 5, $sp+"S"
         $fo[0,pcsr(b)-1]=$sp+"S"
         $fo[pcsr(b),pcsr(a)]=tmp3[p-pcsr(b)]
         $fo[pcsr(a)+1,numpnts($sp)]=$sp+"S"
         tmp = $fo
         appendtograph $fo vs $ko
         killwaves tmp, tmp1, tmp2, tmp3, $sp+"S"
end macro
