*=============================================================================;
*== Gráficos ======================================================;
*=============================================================================;

proc freq data=dados;
tables visits/out=freqout;
run;
data freqout;
set freqout;
	pct=percent/100;
	poisson=pdf("POISSON",visits,2.2443096);
	negbin=pdf("NEGBINOMIAL",visits,1/(1+2.2443096),1);  /*PDF('NEGBINOMIAL',m,p,n), p=n/(n + mu)*/
nbindiff=pct*visits-negbin*visits;
poisdiff=pct*visits-poisson*visits;
label nbindiff="Observado menos Predito"
poisdiff="Observado menos Predito";
run;

*=====================================================================================================;
*=== Gráfico Observado vs Predito ====================================================================;
ods graphics on /height=7 in width=7 in border=off ;
ods listing image_dpi=300;
symbol1 color="#000000" value=DiamondFilled height=2.5;                                                                                             
symbol2 color="#1388A5" value=Dot height=1.8; 
symbol3 color="#F2282B" value=TriangleFilled height=1.5; 
legend1 position=(top right inside)value=("Observado" "Poisson" "Bin Negativa") 
label=none across=1 down=3 cborder="#000000";
axis1 order=(0 to 0.7 by 0.1) offset=(2)width=1 minor=none label=(a=90 j=c h=1.75 "Probabilidade" ); 
axis2 order=(0 to 90 by 10) offset=(2)width=1 minor=none label=(j=c h=1.75);  
proc gplot data=freqout;
plot pct*visits poisson*visits negbin*visits/overlay autovref autohref 
chref=white cvref=white cframe=BWH legend=legend1 vaxis=axis1 haxis=axis2;
run;

*=====================================================================================================;
*=== Gráfico Observado - predito ====================================================================;
ods listing close;
ods graphics on /height=6 in width=10 in border=off ;
ods listing image_dpi=500;
ods html style=defstyle; 
proc sgplot data=freqout;
series x=visits y=poisdiff/
	lineattrs=(pattern=ShortDash color="#A51315")
	markers markerattrs=(symbol=CircleFilled size=9px color="#A51315")
	legendlabel="Poisson";
series x=visits y=nbindiff/
	lineattrs=(pattern=ShortDash color="#1317A5")
	markers markerattrs=(symbol=StarFilled size=9px color="#1317A5")
	legendlabel="Bin Negativa";
refline 0/ axis=y;
xaxis type=discrete grid;
yaxis grid; 
run;
