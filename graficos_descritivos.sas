*=============================================================================;
*== Gráficos descritivos ===============================================================;
*=============================================================================;

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
  end;
run;
ods html style=defstyle; 

*=============================================================================;
*Gráfico de barras;

ods graphics on /height=6 in width=10 in border=off ;
ods listing image_dpi=300;
ods html style=defstyle; 
proc sgplot data=dados;
  vbar visits/fillattrs=graphdata1;
  xaxis grid; 
  yaxis grid values=(0 to 450 by 50) label="Frequência"; 
run;
ods listing close;

*=============================================================================;
*Box plot;

%macro box(Y=,X=,banco=);
ods graphics on /height=7 in width=7 in border=off ;
ods listing image_dpi=300;
ods html style=defstyle; 
proc sgplot data=dados;
  vbox &Y/ category=&X fillattrs=graphdata1;
xaxis grid; 
yaxis grid; 
run;
%mend box;

*=============================================================================;
*Dispersão;
%macro disper(Y=,X=,banco=);
ods graphics on /height=7 in width=7 in border=off ;
ods listing image_dpi=300;
ods html style=defstyle; 
proc sgplot data=&banco;
	reg  x=&X y=&Y /markerattrs=(symbol=circlefilled) lineattrs=(color=red pattern=dash);
xaxis grid; 
yaxis grid; 
run;
%mend disper;

*=============================================================================;
*Grade de gráficos;
%disper(Y=visits,X=quality,banco=dados);
%disper(Y=visits,X=income,banco=dados);
%disper(Y=visits,X=costCon,banco=dados);
%disper(Y=visits,X=costSom,banco=dados);
%disper(Y=visits,X=costHoust,banco=dados);
%box(Y=visits,X=feeSom,banco=dados);
%box(Y=visits,X=ski,banco=dados);

*=============================================================================;
*Gráficos para vefiricar a concentração de zeros;

proc sort data=dados out=order;
by feeSom;
run;
ods graphics on /height=6 in width=7 in border=off ;
ods html style=defstyle; 
ods listing close;
proc sgplot data=order;
  vbar visits/fillattrs=graphdata1;
  by feeSom;
  xaxis grid; 
  yaxis grid label="Frequência"; 
run;quit;
ods listing;
