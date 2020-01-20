/*------------------------------------------------------------------------------------------------------------------*/
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
/*------------------------------------------------------------------------------------------------------------------*/
/*Locate Dataset Directory*/
%macro cwd;
%local fr rc cwd;
%let rc = %sysfunc(filename(fr,.));
%let cwd = %sysfunc(pathname(&fr));
%let rc = %sysfunc(filename(fr));
&cwd
%mend cwd;
/*------------------------------------------------------------------------------------------------------------------*/
/*Model Selection for VAR*/
%macro VARModel(dataset, var, P, DIF);
ods select none;
proc varmax data = &dataset;
model &var / p = &P;
ods output LogLikelihood = LLH;
ods output InfoCriteria = IC;
/*output out=for lead=5;*/
run;
data Info;
set LLH IC;
/*if _n_ in (1 4);*/
drop cvalue1;
if label1 = "癸计阀" then label1 = "LogLike";
rename 
	label1 = Criterion
	nvalue1 = Value;
proc transpose data = Info 
	out = Info_T(drop = _name_);
var value;
id Criterion;
data InfoTable_&P;
p = &P;
set info_t;
run;
ods select all;
%mend VARModel;
/*------------------------------------------------------------------------------------------------------------------*/
%macro VARModels(dataset, var);
%do i = 1 %to 10;
	%VARModel(&dataset, &var, &i);
%end;
data AllModel;
set InfoTable_:;
proc sort;
by p;
proc print data = AllModel; run;
%mend VARModels;
/*------------------------------------------------------------------------------------------------------------------*/
/*File Variable*/
%let NetIncome_file = Flight_Comany_NetIncome_2005_2019.csv;
%let Income_file = Flight_Comany_Income_2005_2019.csv;
%let Oil_file = International_Price_of_Crude_Oil_2005_2019.csv;
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
	time = "る"
	Netincome2610 = "地を (China)"
	Netincome2612 = "いを (Air China)"
	Netincome2618 = "篴を (EVA)";
if time < 200803 then delete;
/*proc print data = flight_netincome label; run;*/
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
	time = "る"
	income2610 = "地犁Μ (China)"
	income2612 = "い犁Μ (Air China)"
	income2618 = "篴犁Μ (EVA)";
if time < 200803 then delete;
/*proc print data = flight_income label; run;*/
/*Data for Crude Oil*/
proc import datafile = "%datasets_dir\&Oil_file" out = temp 
	dbms = csv replace;
data Oil_Price;
set temp;
rename POILBREUSDM = Oil_Price;
label POILBREUSDM = "猳基 (Oil Price)";
	/*Process Time Data*/
	Year = year(date);
	if month(date) = 1 then YEAR = year - 1;
	if month(date) = 1 then MONTH = "12";
	else MONTH = cat("0", month(date) - 1);
	Time = cat(YEAR, MONTH);

/*Keep year after 2008*/
if time < 200803 then delete;
/*Keep only two columns*/
keep POILBREUSDM Time;
proc sort;
by time;
run;
/*proc print label; run;*/

/*Merge Income and Net Income*/
data Flight;
merge Flight_Income Flight_NetIncome Oil_Price;
by time;
season = cat(substr(time, 1, 4), cat("Q", substr(time, 5, 6) / 3));
drop income_airchina net_airchina; *drop data related to Air China;
/*------------------------------------------------------------------------------------------------------------------*/
/*Output as pdf file*/
ods pdf file = "SAS_outputs.pdf";
/*------------------------------------------------------------------------------------------------------------------*/
/* read data
	200803 - 201712 -- Flight(Train)
	201803 - 201909 -- Test*/
title "Flight Training Data Table";
proc print data = flight; run;
title "Flight Testing Data Table";
proc print data = test; run;

/*Standardize the data*/
proc standard data = flight mean = 0 std = 1 out = Flight_Std;
var income: net: oil_price;
data Flight_Std;
set flight_std;
term = _n_;
run;
/*proc print data = flight_Std; run;*/
/*------------------------------------------------------------------------------------------------------------------*/
/*Time Series Plots*/
/*Income*/
ods graphics on / width = 1080px;
proc sgplot data = flight_std;
title height = 25pt "Time Series Plot for Income and Oil Price";
series x = season y = income_china / lineattrs = (color=blue thickness=3);
series x = season y = income_eva / lineattrs = (color=green thickness=3);
series x = season y =  oil_price / lineattrs = (color=red thickness=3);
yaxis label = "Normalized Data" labelattrs = (size=15) valueattrs = (size=10) values = (-3.5 to 4 by 1);
xaxis label = "Season" labelattrs = (size=15);
/*xaxis label = "Season" labelattrs = (size=15)  valuesrotate = diagnoal2;*/
run;
/*Net Income*/
proc sgplot data = flight_std;
title height = 25pt "Time Series Plot for Net Income and Oil Price";
series x = season y = net_china / lineattrs = (color=blue thickness=3);
series x = season y = net_eva / lineattrs = (color=green thickness=3);
series x = season y =  oil_price / lineattrs = (color=red thickness=3);
yaxis label = "Normalized Data" labelattrs = (size=15) valueattrs = (size=10)  values = (-3.5 to 4 by 1);
xaxis label = "Season" labelattrs = (size=15);
run;
/*------------------------------------------------------------------------------------------------------------------*/
title "Check Breakpoint of Log Income of China";
proc autoreg data = flight_std;
model net_china = term / chow = (5 6 7 8);
model net_eva = term / chow = (10 11 12 13);
ods select ChowTest DiagnosticsPanel;
run;

proc print data = flight; run;
/*Dataset Adjustment*/
data Test Flight_adj Fight_adj_NoTrim;
set flight;
/*Add min value to variables containing negative value
   Add 1 to avoid facing negative infinite problem when applying log transformation*/
net_China = net_China + 1098628 + 1;
net_Eva = net_Eva + 1652777 + 1;

/*log transformation*/
LogChina = log(income_china);
LogEva = log(income_eva);
net_LogChina = log(net_China);
net_LogEva = log(net_Eva);
LogOil = log(oil_price);

label
	LogChina = "地犁Μ (China)"
	LogEva = "篴犁Μ (EVA)"
	net_LogChina = "地を (China)"
	net_LogEva = "篴を (EVA)";

if time >= "201903" then output Test;
if time > "200909" & time < "201903" then output Flight_adj;
if time < "201903"  then output Fight_adj_NoTrim;

title "Adjust Flight Data Table -- Test";
proc print data = Test; run;
title "Adjust Flight Data Table -- Remove Terms before the Breakpoint";
proc print data = Flight_adj; run;
title "Adjust Flight Data Table -- Original Version";
proc print data = Fight_adj_NoTrim; run;



/*We hope to keep the long term relation, so we kept the data after Term = 7*/
proc sgplot data = flight_adj;
title height = 25pt "Time Series Plot for Income and Oil Price";
series x = season y = logchina/ lineattrs = (color=blue thickness=3);
series x = season y = logeva / lineattrs = (color=green thickness=3);
/*series x = time y =  logoil / lineattrs = (color=red thickness=3);*/
yaxis label = "Log Transformed Data" labelattrs = (size=15) valueattrs = (size=10);
xaxis label = "Season" labelattrs = (size=15);
run;
/*Net Income*/
proc sgplot data = flight_adj;
title height = 25pt "Time Series Plot for Net Income and Oil Price";
series x = season y = net_logchina / lineattrs = (color=blue thickness=3);
series x = season y = net_logeva / lineattrs = (color=green thickness=3);
/*series x = time y =  oil_price / lineattrs = (color=red thickness=3);*/
yaxis label = "Log Transformed Data" labelattrs = (size=15) valueattrs = (size=10);
xaxis label = "Season" labelattrs = (size=15);
run;

%let dataset = flight_adj;
%let log_income = LogChina LogEva;           *Variables for all the log transformated income;
%let log_net = net_LogChina net_LogEva;    *Variables for all the log transformated net income;
/*------------------------------------------------------------------------------------------------------------------*/
/*Fit VAR model of income*/
/*Analysis for Income*/
/*Dickey-Fuller Test
   H0: non-stationary
   Some Reject H0 while some not*/
title "Dickey-Fuller Unit Root Test for Log Income";
proc varmax data = flight_adj;
model &log_income / p = 1 dftest;
ods select DFTest;
run;

/*Model selection for Operating Income*/
title "Model Criterion for Log Income";
%VARModels(&dataset, &log_income);
/*Pick the one with smallest AIC value: 4*/
title "Model for Log Income with p = 4";
proc varmax data = flight_adj;
model &log_income / p = 4 lagmax = 3
									dftest cointtest=(johansen)
									print = (estimates diagnose);
output lead =7 out = var_log_pred;
run;
/*Granger Causality Test*/
title "Granger Causality Test";
proc varmax data = flight_adj;
model &log_income = LogOil / p = 4;
causal group1 = (logchina logeva) group2 = (LogOil);
causal group1 = (logchina) group2 = (LogOil);
causal group1 = (logeva) group2 = (LogOil);
causal group1 = (logeva) group2 = (logchina);
ods select CausalityTest GroupVars;
run;
/*------------------------------------------------------------------------------------------------------------------*/
/*Analysis for Net Income*/
title "Dickey-Fuller Unit Root Test for Log Net Income";
proc varmax data = flight_adj;
model &log_net / p = 1 dftest;
ods select DFTest;
run;

/*Model selection for Net income*/
title "Model Criterion for Log Net Income";
%VARModels(&dataset, &log_net);
/*Min AIC: p = 1*/
title "Model for Log Net Income with p = 1";
proc varmax data = flight_adj;
model &log_net / p = 1 lagmax = 3
							dftest cointtest=(johansen)
							print = (estimates diagnose);
run;
title "Granger Causality Test";
proc varmax data = flight_adj;
model net_log: =  LogOil / p = 1;
causal group1 = (net_LogChina net_LogEva) group2 = (LogOil);
causal group1 = (net_LogChina) group2 = (LogOil);
causal group1 = (net_LogEva) group2 = (LogOil);
causal group1 = (net_logchina) group2 = (net_logeva);
ods select CausalityTest GroupVars;
run;
title "DF test for VARX(1, 0)";
proc varmax data = flight_adj;
model net_log: =  LogOil / p = 1 dftest;
ods select DFtest;
run;

ods graphics on / width = 640px;
title "VARX(1, 0) Model";
proc varmax data = flight_adj plot = impulse;
model net_log: =  LogOil / p = 1 lagnax=7 dftest  printform=univariate
                         print=(impulsx=(all) estimates);
output lead = 7  out = varx_netlog_pred;
run;

/*Fit ARIMA model*/
/*------------------------------------------------------------------------------------------------------------------*/
/*い地 China*/
title "Fit Model for Log Income of China";
proc arima data = Flight_adj;
identify var = logchina nlag = 15 stationarity = (adf=4);
estimate p = 5 method = ml;
ods select ChiSqAuto StationarityTests SeriesCorrPanel ChiSqAuto ResidualCorrPanel  ModelDescription ARPolynomial  Forecasts;
ods output ResidualCorrPanel = res_LogChina;
forecast  id = term out = logchina_pred lead = 7;
run;
title "Fit Model for Log Income of China -- GARCH";
data res_LogChina;
set res_LogChina(keep = residual);
res_sq = residual**2;
proc arima data = res_LogChina;
identify var = res_sq nlag = 12 stationarity = (adf=4);
ods select ChiSqAuto SeriesCorrPanel;
run;
/*Model : AR(5)*/

title "Log Net Income of China";
proc arima data = Flight_adj;
identify var = net_logchina nlag = 15 stationarity = (adf=4) ;
estimate p = 5 ml;
forecast  id = term out = net_logchina_pred lead = 7 ;
run;
/*Stationary*/

/*篴 EVA*/
title "Fit Model for Log Income of EVA";
proc arima data = Flight_adj;
identify var = logeva(1) nlag = 15 stationarity = (adf=4);
estimate p = 5 method = ml;
ods select ChiSqAuto StationarityTests SeriesCorrPanel ChiSqAuto ResidualCorrPanel  ModelDescription ARPolynomial  Forecasts;
ods output ResidualCorrPanel = res_LogEva;
forecast  id = term out = logeva_pred lead = 7;
run;
data res_LogEva;
set res_LogEva(keep = residual);
res_sq = residual**2;
proc arima data = res_LogEva;
identify var = res_sq nlag = 12 stationarity = (adf=4);
ods select ChiSqAuto SeriesCorrPanel;
run;
/*Model : AR(5)*/

title "Log Net Income of EVA";
proc arima data = Flight_adj;
identify var = net_logeva nlag = 15 stationarity = (adf=4) ;
estimate p = 5 method = ml;
ods output ResidualCorrPanel = res_netLogEva;
ods select ChiSqAuto StationarityTests SeriesCorrPanel ChiSqAuto ResidualCorrPanel  ModelDescription ARPolynomial Forecasts;
forecast  id = term out = net_logeva_pred lead = 7 ;
run;
data res_netLogEva;
set res_netLogEva(keep = residual);
res_sq = residual**2;
proc arima data = res_netLogEva;
identify var = res_sq nlag = 12 stationarity = (adf=4);
ods select ChiSqAuto SeriesCorrPanel;
run;
/*Model : AR(5)*/
/*------------------------------------------------------------------------------------------------------------------*/
/*VAR model Predict*/
data temp_VarIncome;
set var_log_pred;
if logchina = .;
rename
	for1 = Var_China
	for2 = Var_Eva;
keep for1 for2;
data temp_VarxNet;
set varx_netlog_pred;
if net_logchina = .;
rename
	for1= Varx_NetChina
	for2 = Varx_NetEva;
keep for1 for2;

/*AR model Predict*/
data temp_ARChina;
set logchina_pred;
if LogChina = .;
rename forecast = AR_China;
keep forecast;
data temp_AREva;
set logeva_pred;
if LogEva = .;
rename forecast = AR_Eva;
keep forecast;
data temp_ARNetChina;
set net_logchina_pred;
if net_logchina = .;
rename forecast = AR_NetChina;
keep forecast;
data temp_ARNetEva;
set net_logeva_pred;
if net_logeva = .;
rename forecast = AR_NetEva;
keep forecast;


data Flight_pred;
merge temp_VarIncome temp_VarxNet
	temp_ARChina temp_AREva temp_ARNetChina temp_ARNetEva;
input season $ @@;
cards;
	2019Q1 2019Q2 2019Q3 2019Q4
	2020Q1 2020Q2 2019Q3
;
proc datasets lib = work nolist;
    modify Flight_pred;
		label
			Var_China = "VAR 地犁Μ箇代 (China Income pred)"
			Var_Eva = "VAR 篴犁Μ箇代 (EVA Income pred)"
			Varx_NetChina = "VARX 地を箇代 (China Net Income pred)"
			Varx_NetEva = "VARX 篴を箇代 (EVA Net Income pred)"
			AR_China = "AR 地犁Μ箇代 (China Income pred)"
			AR_Eva = "AR 篴犁Μ箇代 (EVA Income pred)"
			AR_NetChina = "AR 地を箇代 (China Net Income pred)"
			AR_NetEva = "AR 篴を箇代 (EVA Net Income pred)"
		;
proc print label; run;

data Flight_Valid;
merge Flight_pred test;
if _n_ <= 3;
proc print data = Flight_Valid; run;


/*Validation Plot for Income*/
proc sgplot data = flight_valid;
title height = 20pt "Prediction and Validation Plot for Income of China Air";
series x = season y = logchina/ lineattrs = (color=blue thickness=3);
series x = season y = var_china/ lineattrs = (color=red thickness=3);
series x = season y = AR_china / lineattrs = (color=green thickness=3);
/*series x = time y =  logoil / lineattrs = (color=red thickness=3);*/
yaxis label = "Log Transformed Data" labelattrs = (size=15) valueattrs = (size=10) values = (17.45 to 17.75 by 0.05);
xaxis label = "Season" labelattrs = (size=15);
run;
proc sgplot data = flight_valid;
title height = 20pt "Prediction and Validation Plot for Income of EVA Air";
series x = season y = logeva/ lineattrs = (color=blue thickness=3);
series x = season y = var_eva/ lineattrs = (color=red thickness=3);
series x = season y = AR_eva / lineattrs = (color=green thickness=3);
/*series x = time y =  logoil / lineattrs = (color=red thickness=3);*/
yaxis label = "Log Transformed Data" labelattrs = (size=15) valueattrs = (size=10) values = (17.45 to 17.75 by 0.05);
xaxis label = "Season" labelattrs = (size=15);
run;

/*Validation Plot for Net Income*/
proc sgplot data = flight_valid;
title height = 20pt "Prediction and Validation Plot for Net Income of China Air";
series x = season y = net_logchina/ lineattrs = (color=blue thickness=3);
series x = season y = varx_netchina/ lineattrs = (color=red thickness=3);
series x = season y = AR_netchina / lineattrs = (color=green thickness=3);
/*series x = time y =  logoil / lineattrs = (color=red thickness=3);*/
yaxis label = "Log Transformed Data" labelattrs = (size=15) valueattrs = (size=10) values = (15.2 to 16 by 0.1);
xaxis label = "Season" labelattrs = (size=15);
run;
proc sgplot data = flight_valid;
title height = 20pt "Prediction and Validation Plot for Net Income of EVAAir";
series x = season y = net_logeva/ lineattrs = (color=blue thickness=3);
series x = season y = varx_neteva/ lineattrs = (color=red thickness=3);
series x = season y = AR_neteva / lineattrs = (color=green thickness=3);
/*series x = time y =  logoil / lineattrs = (color=red thickness=3);*/
yaxis label = "Log Transformed Data" labelattrs = (size=15) valueattrs = (size=10) values = (15.2 to 16 by 0.1);
xaxis label = "Season" labelattrs = (size=15);
run;

/*------------------------------------------------------------------------------------------------------------------*/
/*Output as pdf*/
ods pdf close;
/*------------------------------------------------------------------------------------------------------------------*/
