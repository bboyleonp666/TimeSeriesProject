%macro datasets_dir;
%local fr rc cwd;
%let rc = %sysfunc(filename(fr,.));
%let cwd = %sysfunc(pathname(&fr));
%let rc = %sysfunc(filename(fr));

%let data = data;
%let datasets_dir = &cwd\data;
&datasets_dir
%mend datasets_dir;

/*%let dir=D:\時間數列分析\Final_project\data;*/
%let file_US = nominal_GDP_US_2010_2019.xlsx;
%let file_taiwan = nominal_GDP_Taiwan_2010_2019.xlsx;
%let file_china = nominal_GDP_China_2010_2019.xlsx;

proc import datafile = "%datasets_dir\&file_US" out = US
dbms = xlsx replace;
datarow = 4;
getnames = no;
data US;
set us;
rename
	A = time
	B = GDP
	C = pred;
lGDP = log(B);
proc sort;
by time;
proc print; run;

proc import datafile = "%datasets_dir\&file_taiwan" out = Taiwan
dbms = xlsx replace;
datarow = 4;
getnames = no;
data Taiwan;
set taiwan;
rename
	A = time
	B = GDP
	C = pred;
lGDP = log(B);
proc sort;
by time;
proc print; run;

proc import datafile = "%datasets_dir\&file_china" out = China
dbms = xlsx replace;
datarow = 4;
getnames = no;
data China;
set china;
rename
	A = time
	B = GDP
	C = pred;
lGDP = log(B);
proc sort;
by time;
proc print; run;

/*Taiwan Time Series Analysis*/
*plot the time series;
proc gplot data = taiwan;
title "Time Series data for Taiwan";
plot lgdp * time;
symbol c = red i = spline v = dot;
run;
proc gplot data = us;
title "Time Series data for United States";
plot lgdp * time;
symbol c = red i = spline v = dot;
run;
proc gplot data = china;
title "Time Series data for China";
plot lgdp * time;
symbol c = red i = spline v = dot;
run;

/*ARIMA Analysis for Taiwan*/
proc arima data = taiwan;
identify var = lgdp nlag = 15 stationarity = (adf=0); *test stationarity by agument dickey-fuller test;
run;

/*
zero mean -- H0: non-stationary
single mean -- H0: non-stationary
*/
proc arima data = taiwan;
identify var = lgdp(1) nlag = 15 stationarity = (adf=0);
run;
proc arima data = taiwan;
identify var = lgdp(1, 4) nlag = 15 stationarity = (adf=0);
run;

/*After differentialized, found a AR(4) model*/
/*proc arima data = taiwan;
identify var = lgdp(1, 4) nlag = 15;
estimate p = 4 q = 0 method = ml;
run;*/

/*ARIMA Analysis for Japan*/
proc arima data = us;
identify var = lgdp nlag = 15 stationarity = (adf=0);
run;

proc arima data = us;
identify var = lgdp(1) nlag = 15 stationarity = (adf=0) outcov = out_cov;
run;
proc print data = out_cov; run;
/*
proc timeseries data = us plots = corr outcorr = corr_pvals;
*id year_and_month interval = year;
var lgdp;
corr lag n acf pacf acfstd acfprob pacfprob / nlag = 15;
run;
*/

proc arima data = china;
identify var = lgdp nlag = 15 stationarity = (adf=0); *test stationarity by agument dickey-fuller test;
run;
proc arima data = china;
identify var = lgdp(1) nlag = 15 stationarity = (adf=0);
run;
proc arima data = china;
identify var = lgdp(1, 4) nlag = 15 stationarity = (adf=0);
run;
proc arima data = china;
identify var = lgdp(1, 4) nlag = 15 stationarity = (adf=0);
estimate p = 2 method = ml;
run;
