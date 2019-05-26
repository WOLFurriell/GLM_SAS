*=============================================================================;
*== Modelo de contagem ======================================================;
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
if feeSom = "yes" then socio2=0;
else socio2 = 1;
if ski = "yes" then Esqui2=0;
else Esqui2 = 1;
run;
proc contents data=dados;
run;

*=============================================================================;
*Medidas descritivas;
proc means data=dados min mean max median var cv;
run; 
proc freq data=dados;
table visits ski feeSom;
run;

*=============================================================================;
* Macro para Ajuste dos modelos;
%macro reg(distrib=,saida=,fit=,ParamEst=);
ods listing close;
proc genmod data=dados;
class esqui socio;
	model Visitas = rank Socio esqui renda costCon costSom costHoust/
	dist=&distrib  scale=0 type1 type3;/* obstats residuals */
	output out=&saida p=predito;
ods output Modelfit=&fit;
ods output ParameterEstimates = &ParamEst;
run;quit;
ods listing;
%mend reg;
%reg(distrib=Poisson,saida=exit_Poisson,fit=Pfit,ParamEst=ParP);
%reg(distrib=Negbin,saida=exit_Negbin,fit=Nfit,ParamEst=ParNB);

*=============================================================================;
* Gerar ajuste da frequências observada vs as teóricas;
%include "D:\Estatística\Modelos Lineares Generalizados MESTRADO\Trabalhos\Trabalho_final\Scripts\plots1.sas";

* - Medidas de ajuste ---------------------------------------------------------;
* Hipótese nula é a de que não há superdispersão;
* Hipótese alternativa é a de que existe superdispersão;
* Como o n é grande pode-se garantir as propriedades assintóticas;
data fit;
set Pfit(where=(criterion="Scaled Pearson X2" or criterion="Deviance"))
Nfit(where=(criterion="Scaled Pearson X2" or criterion="Deviance"));
format pvalue pvalue6.4;
pvalue=1-probchi(value,df);
run;
proc print data=fit;run; 

*=============================================================================;
* Macro para Ajuste dos modelos com inflacionamento de zeros;
* A escolha das variáveis do zeromodel deve ser feita quando verificamos que elas tem
impactos nos zeros;
%macro regzero(distrib=,saida=,fit=,ParamEst=);
ods listing close;
proc genmod data=dados plots=all;
class esqui socio;
model visitas = rank Socio esqui renda costCon costSom costHoust/
dist=&distrib link = log type1 type3; /* obstats residuals*/
zeromodel feesom2 costCon costSom costHoust;
output out=&saida p=predito;
ods output Modelfit=&fit;
ods output ParameterEstimates = &ParamEst;
run;quit;
ods listing;
%mend regzero;
%regzero(distrib=ZIP,saida=exit_zeroPoisson,fit=ZPfit,ParamEst=parzip);
%regzero(distrib=ZINB,saida=exit_zeroNegbin,fit=ZNfit,ParamEst=parzinb);

*- Medidas de ajuste ---------------------------------------------------------;
* Hipótese nula é a de que não há superdispersão;
* Hipótese alternativa é a de que existe superdispersão;
data fit2;
set ZPfit(where=(criterion="Scaled Pearson X2" or criterion="Deviance"))
ZNfit(where=(criterion="Scaled Pearson X2" or criterion="Deviance"));
format pvalue pvalue6.4;
pvalue=1-probchi(value,df);
run;
proc print data=fit2;run;

*=============================================================================;
* Gerar ajuste da frequências observada vs as teóricas;



*=============================================================================;
* Ajuste gráfico dos modelos ajustados vs observados;
%macro obspred(banco=);
data &banco;set &banco;
	logY=log(visits);
	logPred=log(predito);run;
ods graphics on /height=7 in width=7 in border=off ;
ods listing image_dpi=300;
ods html style=defstyle; 
proc sgplot data=&banco;
	reg  x=logY y=logPred /markerattrs=(symbol=circlefilled) lineattrs=(color=red pattern=dash);
	xaxis grid values=(0 to 5 by 1); 
	yaxis grid values=(-3.5 to 4 by 1); 
run;
%mend obspred;
%obspred(banco=exit_Negbin);
%obspred(banco=exit_Poisson);
%obspred(banco=exit_zeroNegbin);
%obspred(banco=exit_zeroPoisson);


