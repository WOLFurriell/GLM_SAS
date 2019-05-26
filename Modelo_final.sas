*=============================================================================;
*== Modelo de contagem FINAL ======================================================;
*=============================================================================;
proc delete data=_all_;
run;
*=============================================================================;
* Importando os dados;
filename file "D:\Estatística\Modelos Lineares Generalizados MESTRADO\Trabalhos\Trabalho_final\bancos\dados.csv";
proc import datafile=file out=dados dbms = csv replace;
	getnames = yes;
run;
proc print data=dados(obs=3);
run;
*=============================================================================;
*Adicionando Labels ao banco;
data dados;
set dados;
	label 
	VAR1 = "Obs"
	visits = "Número anual de visitas ao lago Somerville"
	quality = "Ranking de qualidade do lago Somerville"
	ski = "Pratica esqui aquático no lago Somerville?"
	income = "Renda anual"
	feeSom = "Sócio do parque Somerville?"
	costCon = "Gastos quando visita o lago Conroe"
	costSom = "Gastos quando visita o lago Somerville"
	costHoust = "Gastos quando visita o lago Houston"; 
run;
data dados(rename=(visits=Visitas quality=Rank ski=Esqui income=Renda feeSom=socio));set dados;
if feeSom = "yes" then Socio2=0;
else Socio2 = 1;
if ski = "yes" then Esqui2=0;
else Esqui2 = 1;
run;
proc contents data=dados;
run;
*===============================================================================================;
* Criando uma média dos custos;
data dados;
set dados;
mediacost=mean(costCon,costSom,costHoust);
run;
proc contents data=dados;
run;

*==========================================================================================;
*O modelo Final;
ods html style=defstyle; 
ods listing close;
proc genmod data=dados plots=all;
class esqui socio;
model visitas = rank esqui2 costCon costSom costHoust/
dist=ZINB link = log type1 type3;
zeromodel;
output out=saida PZERO=pzero PRED=predito RESRAW=resraw STDRESCHI=stdreschi
RESCHI=reschi XBETA=xbeta STDXBETA=srdxbeta;
ods output Modelfit=fit2;
ods output ParameterEstimates = ParamEst;
ods output ZeroParameterEstimates = zeroParamEst;
run;quit;
ods listing;
data fit;
set fit2(where=(criterion="Scaled Pearson X2" or criterion="Deviance"));
format pvalue pvalue6.4;
pvalue=1-probchi(value,df);
run;
proc print data=fit;run; 

data teste;
LR=2*(762.0412-825.3070);
valorp= 1-probchi(LR,2);
quit;proc print data=teste;run;

*==========================================================================================;
* Análise do resíduo do modelo;
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

data saida;set saida;
if reschi > 5 then label=VAR1;
if resraw < -1000 then label2=VAR1;
run;
ods html style=defstyle; 
ods graphics on /height=7 in width=7 in border=off ;
ods listing image_dpi=300;
proc sgplot data=saida;
	scatter y=reschi x=predito/datalabel=label
markerattrs=(symbol=circlefilled color=black);
refline 0/lineattrs=(color=red thickness=3);
xaxis grid; 
yaxis grid; 
run;

ods graphics on /height=7 in width=7 in border=off ;
ods listing image_dpi=300;
ods html style=defstyle; 
proc sgplot data=saida;
	scatter y=resraw x=predito/datalabel=label2
markerattrs=(symbol=circlefilled color=black);
refline 0/lineattrs=(color=red thickness=3);
xaxis grid; 
yaxis grid; 
run;


data exit_Poisson;set exit_Poisson;
if cooksd > 0.08 then labcooksd=indice;run;
proc sgplot data=exit_Poisson;
	scatter y=cooksd x=indice/datalabel=labcooksd
markerattrs=(symbol=circlefilled color=black);
xaxis grid; 
yaxis grid; 
run;



data dados2;
set dados;
if VAR1 = 554 then delete;
run;
*==========================================================================================;
*O modelo Final;
ods html style=defstyle; 
ods listing close;
proc genmod data=dados2 plots=all;
class esqui socio;
model visitas = rank esqui2 costCon costSom costHoust/
dist=ZINB link = log type1 type3;
zeromodel;
estimate "Rank" rank 1/exp;
estimate "Esqui" esqui2 1/exp;
estimate "Gasto Con" costCon 1/exp;
estimate "Gasto Somerville" costSom 1/exp;
estimate "Gasto Houst" costHoust 1/exp;
run;quit;
ods listing;

