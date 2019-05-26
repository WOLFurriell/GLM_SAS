
*==========================================================================================;
* Modelos Poisson e Bin Negativa;
data Parnb;set Parnb;dist="Binomial Negativa";run;
data Parp;set Parp;dist="Poisson";run;
data All;
set Parnb(where=(Parameter^="Dispersion"))
    Parp(where=(Parameter^="Scale"));
run;

ods graphics on /height=6 in width=10 in border=off ;
ods listing image_dpi=500;
proc sgplot data=All;
styleattrs  datacontrastcolors=("#A51315" "#1317A5");
where Parameter ^= "Intercept";
    scatter y=Parameter x=Estimate /groupdisplay=cluster group=dist   
	markerattrs=(symbol=diamondfilled) 
	xerrorlower=LowerWaldCL xerrorupper=UpperWaldCL; 
   refline 0 / axis=x;
   xaxis grid label="Estimativa";
   yaxis grid colorbands=odd discreteorder=data reverse label="Parâmetro";
run;

*==========================================================================================;
* Modelos ZIP e ZINB;
data parzip;set Parnb;dist="ZIP";run;
data parzinb;set Parp;dist="ZINB";run;
data All2;
set parzinb(where=(Parameter^="Dispersion"))
    parzip(where=(Parameter^="Scale"));
run;
 
proc sgplot data=All2;
styleattrs  datacontrastcolors=("#A51315" "#1317A5");
where Parameter ^= "Intercept";
    scatter y=Parameter x=Estimate /groupdisplay=cluster group=dist   
	markerattrs=(symbol=diamondfilled) 
	xerrorlower=LowerWaldCL xerrorupper=UpperWaldCL; 
   refline 0 / axis=x;
   xaxis grid label="Estimativa";
   yaxis grid colorbands=odd discreteorder=data reverse label="Parâmetro";
run;

*==========================================================================================;
* Modelo final + zeros;
data Paramest;set Paramest;
set Paramest(where=(Parameter^="Dispersion"));
if ProbChiSq > 0.05 then group=1;else group=0;
run;

ods graphics on /height=6 in width=10 in border=off ;
ods listing image_dpi=300;
proc sgplot data=Paramest;
where Parameter ^= "Intercept";
    scatter y=Parameter x=Estimate /  
	markerattrs=(symbol=diamondfilled) 
	xerrorlower=LowerWaldCL xerrorupper=UpperWaldCL; 
   refline 0 / axis=x;
   xaxis grid label="Estimativa";
   yaxis grid colorbands=odd reverse label="Parâmetro";
run;


