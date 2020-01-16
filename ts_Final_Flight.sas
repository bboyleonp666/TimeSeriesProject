/*Locate Dataset Directory*/
%macro datasets_dir;
%local fr rc cwd;
%let rc = %sysfunc(filename(fr,.));
%let cwd = %sysfunc(pathname(&fr));
%let rc = %sysfunc(filename(fr));

%let data = data;
%let datasets_dir = &cwd\data;
&datasets_dir
%mend datasets_dir;

/*File Variable*/
%let NetIncome_file = Flight_Comany_NetIncome_2005_2019.csv;
%let Income_file = Flight_Comany_Income_2005_2019.csv;

/*Data for Net Income*/
data temp;
infile "%datasets_dir\&NetIncome_file" firstobs = 2 delimiter = ",";
input Company ShortName $ time $ NetIncome;
proc sort data = temp;
by time;
proc transpose data = temp out = Flight_NetIncome_Wide prefix = NetIncome;
by time;
id company;
var netincome;
data Flight_NetIncome;
set flight_netincome_wide(drop = _name_);
rename
	Netincome2610 = net_China
	Netincome2612 = net_AirChina
	Netincome2618 = net_Eva;
label
	time = "�~��"
	Netincome2610 = "�د��Q"
	Netincome2612 = "�����Q"
	Netincome2618 = "���a��Q";
if time < 200803 then delete;
proc print data = flight_netincome label;
run;
/*Data for Income*/
data temp;
infile "%datasets_dir\&Income_file" firstobs = 2 delimiter = ",";
input Company ShortName $ time $ Income;
proc sort data = temp;
by time;
proc transpose data = temp out = Flight_Income_Wide prefix = Income;
by time;
id company;
var income;
data Flight_Income;
set flight_income_wide(drop = _name_);
rename
	income2610 = income_China
	income2612 = income_AirChina
	income2618 = income_Eva;
label
	time = "�~��"
	income2610 = "�د��禬"
	income2612 = "�����禬"
	income2618 = "���a�禬";
if time < 200803 then delete;
proc print data = flight_income label;
run;
/*Merge Income and Net Income*/
data Flight;
merge Flight_Income Flight_NetIncome ;
by time;
proc print; run;

/*Time Series Plots*/
/*Income*/
proc gplot data = Flight;
title "Time Series Plot for Income";
plot (income_:) *time / overlay legend;
symbol1 interpol = join value = line c = blue v = dot; 
symbol2 interpol = join value = line c = green v = dot;
symbol3 interpol = join value = line c = red v = dot;
run;
/*Net Income*/
proc gplot data = Flight;
title "Time Series Plot for Net Income";
plot (net_:) * time / overlay legend;
symbol1 interpol = join value = line c = blue v = dot; 
symbol2 interpol = join value = line c = green v = dot;
symbol3 interpol = join value = line c = red v = dot;
run;

/*������ Air China*/
proc arima data = Flight;
identify var = net_airchina nlag = 15 stationarity = (adf=4);
run;
proc arima data = Flight;
identify var = net_airchina(1) nlag = 15 stationarity = (adf=4);
run;
proc arima data = Flight;
identify var = net_airchina(1) nlag = 15 stationarity = (adf=4);
estimate p = 3 method = ml;
ods output ResidualCorrPanel = res_net_AirChina;
run;

data res_NetAirchina;
set res_net_AirChina(keep = residual);
res_sq = residual**2;
proc arima data = res_NetAirchina;
identify var = res_sq nlag = 12 stationarity = (adf=4);
estimate p=5;
run;
/*Final model ARIMA(3,1,0)-ARCH(5)*/

/*���a��� EVA*/
proc arima data = Flight;
identify var = net_eva nlag = 15 stationarity = (adf=4);
run;
proc arima data = Flight;
identify var = net_eva(1) nlag = 15 stationarity = (adf=4);
run;
proc arima data = Flight;
identify var = net_eva(1) nlag = 15 stationarity = (adf=4);
estimate p = 3 method = ml;
ods output ResidualCorrPanel = res_net_EVA;
run;

data res_NetEva;
set res_net_EVA(keep = residual);
res_sq = residual**2;
proc arima data = res_NetEva;
identify var = res_sq nlag = 12 stationarity = (adf=4);
estimate p=2;
run;
proc arima data = res_NetEva;
identify var = res_sq nlag = 12 stationarity = (adf=4);
estimate p=3;
run;
/*Model                                      AIC
   ARIMA(3,1,0)-ARCH(2)         2780.878
   ARIMA(3,1,0)-ARCH(3)         2779.108

   �� AR(3) ���Y�Ƥ����
   �ҥH Final model:  ARIMA(5,1,0)-ARCH(2)
*/

/*���د�� China*/
proc arima data = Flight;
identify var = net_china nlag = 15 stationarity = (adf=4);
run;
proc arima data = Flight;
identify var = net_china nlag = 15 stationarity = (adf=4);
estimate p = 5 method = ml;
ods output ResidualCorrPanel = res_net_China;
run;

data res_NetChina;
set res_net_China(keep = residual);
res_sq = residual**2;
proc arima data = res_NetChina;
identify var = res_sq nlag = 12 stationarity = (adf=4);
run;

%macro VARModel;
ods select none;
proc varmax data = flight;
model net: / p = &i noint lagmax = 3 
					print = (estimates diagnose);
ods output LogLikelihood = LLH;
ods output InfoCriteria = IC;
/*output out=for lead=5;*/
run;
data Info;
set LLH IC;
if _n_ in (1 4);
drop cvalue1;
if label1 = "��Ʒ���" then label1 = "LogLike";
rename 
	label1 = Criterion
	nvalue1 = Value;
proc print; run;
proc transpose data = Info 
	out = Info_T(drop = _name_);
var value;
id Criterion;
data InfoTable_&i;
p = &i;
set info_t;
run;
ods select all;
%mend VARModel;

%macro All_VARModel;
%do i = 1 %to 10;
	%VARModel(&i);
%end;
data AllModel;
set InfoTable_:;
proc print data = AllModel; run;
%mend All_VARModel;
%All_VARModel;


/*Fit VAR Model*/
proc varmax data = flight;
model net: / p = 1 noint dftest cointtest=(johansen);
title "Without Normalization";
run;
proc varmax data = flight;
model net: / p = 1 cointtest = (johansen=(normalize=net_china));
title "With Normalization";
run;

proc varmax data = flight;
   model net: / p = 2 noint dftest cointtest=(johansen);
run;

proc varmax data = flight;
model  net: / p = 1 
					noint 
					lagmax = 3 
					print=(iarr estimates);
cointeg rank = 1 normalize = net_china;
run;
