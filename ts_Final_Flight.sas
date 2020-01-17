%macro All_VARModel;
/*Variable Setting*/
%let variables = d:;

%do i = 1 %to 5;
    %VARModel(flight_std, &variables, &i);
%end;
data AllModel;
set InfoTable_&out:;
proc print data = AllModel; run;
%mend All_VARModel;
%All_VARModel;
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
	time = "年月"
	Netincome2610 = "華航毛利 (China)"
	Netincome2612 = "中航毛利 (Air China)"
	Netincome2618 = "長榮毛利 (EVA)";
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
	time = "年月"
	income2610 = "華航營收 (China)"
	income2612 = "中航營收 (Air China)"
	income2618 = "長榮營收 (EVA)";
if time < 200803 then delete;
proc print data = flight_income label;
run;
/*Data for Crude Oil*/
proc import datafile = "%datasets_dir\&Oil_file" out = temp 
	dbms = csv replace;
data Oil_Price;
set temp;
rename POILBREUSDM = Oil_Price;
label POILBREUSDM = "油價 (Oil Price)";
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
proc print label; run;

/*Merge Income and Net Income*/
data Flight;
merge Flight_Income Flight_NetIncome Oil_Price;
by time;
drop income_airchina net_airchina; *drop data related to Air China;
proc print; run;
/*Standardize the data*/
proc standard data = flight mean = 0 std = 1 out = Flight_Std;
var income: net: oil_price;
proc print data = flight_Std; run;

/*Time Series Plots*/
/*Income*/
ods graphics on / width = 1080px;
proc sgplot data = flight_std;
title height = 25pt "Time Series Plot for Income and Oil Price";
series x = time y = income_china / lineattrs = (color=blue thickness=3);
series x = time y = income_eva / lineattrs = (color=green thickness=3);
series x = time y =  oil_price / lineattrs = (color=red thickness=3);
yaxis label = "Normalized Data" labelattrs = (size=15) valueattrs = (size=10);
xaxis label = "Season" labelattrs = (size=15);
/*xaxis label = "Season" labelattrs = (size=15)  valuesrotate = diagnoal2;*/
run;
/*Net Income*/
proc sgplot data = flight_std;
title height = 25pt "Time Series Plot for Net Income and Oil Price";
series x = time y = net_china / lineattrs = (color=blue thickness=3);
series x = time y = net_eva / lineattrs = (color=green thickness=3);
series x = time y =  oil_price / lineattrs = (color=red thickness=3);
yaxis label = "Normalized Data" labelattrs = (size=15) valueattrs = (size=10);
xaxis label = "Season" labelattrs = (size=15);
/*xaxis label = "Season" labelattrs = (size=15)  valuesrotate = diagnoal2;*/
run;

/*長榮航空 EVA*/
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

   但 AR(3) 的係數不顯著
   所以 Final model:  ARIMA(5,1,0)-ARCH(2)
*/

/*中華航空 China*/
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

/*Fit VAR model of income*/
/*------------------------------------------------------------------------------------------------------------------*/
/*Analysis for Income*/
data flight_adj;
set flight;
/*Add min value to variables containing negative value
   Add 1 to avoid facing infinite while log transformation*/
net_China = net_China + 1098628 + 1;
net_Eva = net_Eva + 1652777 + 1;

/*log transformation*/
LogChina = log(income_china);
LogEva = log(income_eva);
net_LogChina = log(net_China);
net_LogEva = log(net_Eva);
LogOil = log(oil_price);
proc print; run;
/*Dickey-Fuller Test*/
/*From inspectation: There is trend, trend model picked*/
/*Non-stationary: log Oil_price 
   Stationary: log China, log Eva*/

%let dataset = flight_adj;                         *Name of dataset;
%let log_income = Log:;                         *Variables for all the log transformated income;
%let log_net = net_Log: LogOil;             *Variables for all the log transformated net income;
proc varmax data = flight_adj;
model &log_income / p = 1 dftest;
run;
/*first-differentiated*/
proc varmax data = flight_adj;
model &log_income / p = 1 dify = (1) dftest;
run;
/*All are Stationary!!!*/

/*------------------------------------------------------------------------------------------------------------------*/
/*Model Selection*/
%macro VARModel(dataset, var, P, DIF);
ods select none;
proc varmax data = &dataset;
model &var / p = &P dify = (&DIF);
ods output LogLikelihood = LLH;
ods output InfoCriteria = IC;
/*output out=for lead=5;*/
run;
data Info;
set LLH IC;
if _n_ in (1 4);
drop cvalue1;
if label1 = "對數概度" then label1 = "LogLike";
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
%macro All_VARModel(dataset, var, DIF);
%do i = 1 %to 5;
	%VARModel(&dataset, &var, &i, &DIF);
%end;
data AllModel;
set InfoTable_:;
proc print data = AllModel; run;
%mend All_VARModel;
/*------------------------------------------------------------------------------------------------------------------*/

/*Model selection for Operating Income*/
%All_VARModel(&dataset, &log_income, 1);
/*Pick the one with smallest AIC value: 2*/
/*Unit Root Test*/
proc varmax data = flight_adj;
model &log_income / p = 2 noint lagmax = 3 dify = (1)
									dftest cointtest=(johansen)
									print = (estimates diagnose);
run;
/*H0: non-stationary
   Some Reject H0 while some not*/

/*Granger Causality Test*/
proc varmax data = flight_adj plot = impulse;
model LogOil = logchina logeva / p = 2 difx = (1) dify = (1)
													  printform = univariate
													  print = (impulsx=(all) estimates);
run;
proc varmax data = flight_adj;
model logchina = logeva / p = 2 difx = (1) dify = (1)
										  print = (impulsx=(all) estimates);
run;

/*------------------------------------------------------------------------------------------------------------------*/
/*Analysis for Net Income*/
proc varmax data = flight_adj;
model &log_net / p = 1 dftest;
run;
/*Inspect Trend P-value
   Some are non-stationary some are stationary*/
proc varmax data = flight_adj;
model &log_net / p = 1 dify = (1) dftest;
run;
/*All are Stationary!!!*/

/*Model selection for Net income*/
%All_VARModel(&dataset, &log_net, 1);
/*Min AIC: p = 2*/
proc varmax data = flight_adj;
model &log_net / p = 2 noint lagmax = 3 dify = (1)
							dftest cointtest=(johansen)
							print = (estimates diagnose);
run;
proc varmax data = flight_adj plot = impulse;
model LogOil = dnet: / p = 2 dify = (1)
									printform = univariate
									print = (impulsx=(all) estimates);
run;
proc print data = flight_adj; run;
