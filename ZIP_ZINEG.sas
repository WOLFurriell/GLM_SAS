*=============================================================================;
*== ZIP ===============================================================================================;
*=============================================================================;
ods listing close;
proc genmod data=dados;
class ski feeSom;
model visits = /
dist=zip;
zeromodel;
output out=zip predicted=pred pzero=pzero;
run;quit;
ods listing;
proc means data=dados noprint;
var visits;
output out=maxcount max=max N=N;
run;
data _null_;set maxcount;
call symput('N',N);
call symput('max',max);
run;
%let max=%sysfunc(strip(&max));
data zip(drop= i);
set zip;
lambda=pred/(1-pzero);
array ep{0:&max} ep0-ep&max;
array c{0:&max} c0-c&max;
do i = 0 to &max;
if i=0 then ep{i}= pzero + (1-pzero)*pdf('POISSON',i,lambda);
else ep{i}= (1-pzero)*pdf('POISSON',i,lambda);
c{i}=ifn(visits=i,1,0);
end;
run;
proc means data=zip noprint;
var ep0 - ep&max c0-c&max;
output out=ep(drop=_TYPE_ _FREQ_) mean(ep0-ep&max)=ep0-ep&max;
output out=p(drop=_TYPE_ _FREQ_) mean(c0-c&max)=p0-p&max;
run;
proc transpose data=ep out=ep(rename=(col1=zip) drop=_NAME_);
run;
proc transpose data=p out=p(rename=(col1=p) drop=_NAME_);
run;
data zipprob;
merge ep p;
zipdiff=p-zip;
visits=_N_ -1;
label zip='ZIP Probabilities'
p='Relative Frequencies'
zipdiff="Observado menos Predito";
run;

*=============================================================================;
*== ZINB ==============================================================================================;
*=============================================================================;
ods listing close;
proc genmod data=dados;
class ski feeSom;
model visits = /
dist=zinb;
zeromodel;
output out=zinb predicted=pred pzero=pzero;
ods output ParameterEstimates=zinbparms;
run;quit;
ods listing;
data zinbparms;
set zinbparms(where=(Parameter="Dispersion"));
keep estimate;
call symput('k',estimate);
run;
data zinb(drop= i);
set zinb;
	lambda=pred/(1-pzero);
	k=&k;
	array ep{0:&max} ep0-ep&max;
	array c{0:&max} c0-c&max;
		do i = 0 to &max;
		if i=0 then ep{i}= pzero + (1-pzero)*pdf('NEGBINOMIAL',i,(1/(1+k*lambda)),(1/k));
	else ep{i}= (1-pzero)*pdf('NEGBINOMIAL',i,(1/(1+k*lambda)),(1/k));
	c{i}=ifn(visits=i,1,0);
end;
run;
proc means data=zinb noprint;
	var ep0 - ep&max c0-c&max;
	output out=ep(drop=_TYPE_ _FREQ_) mean(ep0-ep&max)=ep0-ep&max;
	output out=p(drop=_TYPE_ _FREQ_) mean(c0-c&max)=p0-p&max;
run;
proc transpose data=ep out=ep(rename=(col1=zinb) drop=_NAME_);run;
proc transpose data=p out=p(rename=(col1=p) drop=_NAME_);run;
data zinbprob;
	merge ep p;
	zinbdiff=p-zinb;
	visits=_N_ -1;
	label zinb='ZINB Probabilities'
	p='Relative Frequencies'
	zinbdiff='Observado menos Predito';
run;
proc freq data=dados;
tables visits/out=freqout;
run;
data freqout;
set freqout;
pct=PERCENT/100;
poisson=pdf("POISSON",visits,2.2443096);
negbin=pdf("NEGBINOMIAL",visits,1/(1+2.2443096),1);  /*PDF('NEGBINOMIAL',m,p,n), p=n/(n + mu)*/
run;
data Freqout;
merge Freqout Zipprob zinbprob;
by visits;
if pct = . then delete;
run;

*======================================================================================================;
*Layout para gráficos no SAS;
proc template;
  define style styles.defstyle;
  parent=styles.default;
    style body from body /
          background = white;
    class graphgridlines  /
          contrastcolor=white;
    class graphbackground /
          color=white;
    class graphwalls /
          color=BWH;
end;run;
*=====================================================================================================;
*=== Gráfico Observado vs Predito ====================================================================;
ods graphics on /height=6 in width=10 in border=off ;
ods listing image_dpi=500;
symbol1 color="#000000" value=DiamondFilled height=2.5;                                                                                             
symbol2 color="#1388A5" value=Dot height=1.8; 
symbol3 color="#F2282B" value=TriangleFilled height=1.5; 
legend1 position=(top right inside)value=("Observado" "ZIP" "ZINB") 
label=none across=1 down=3 cborder="#000000";
axis1 order=(0 to 0.7 by 0.1) offset=(2)width=1 minor=none label=(a=90 j=c h=1.75 "Probabilidade" ); 
axis2 order=(0 to 90 by 10) offset=(2)width=1 minor=none label=(j=c h=1.75);  
proc gplot data=freqout;
plot pct*visits zip*visits zinb*visits/overlay autovref autohref 
chref=white cvref=white cframe=BWH legend=legend1 vaxis=axis1 haxis=axis2;
run;
ods listing;

*=====================================================================================================;
*=== Gráfico Observado menos predito ====================================================================;
ods graphics on /height=6 in width=10 in border=off ;
ods listing image_dpi=500;
ods html style=defstyle; 
proc sgplot data=freqout;
series x=visits y=zipdiff/
	lineattrs=(pattern=ShortDash color="#A51315")
	markers markerattrs=(symbol=CircleFilled size=9px color="#A51315")
	legendlabel="ZIP";
series x=visits y=zinbdiff/
	lineattrs=(pattern=ShortDash color="#1317A5")
	markers markerattrs=(symbol=StarFilled size=9px color="#1317A5")
	legendlabel="ZINB";
refline 0/ axis=y;
xaxis type=discrete grid;
yaxis grid; 
run;
ods listing;
