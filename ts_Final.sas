%let dir=D:\丁计だ猂\Final_project\data;
%let file_japan=nominal_GDP_Japan.xlsx;
%let file_taiwan=nominal_GDP_Taiwan.xlsx;
%let file_china=nominal_GDP_China.xlsx;

proc import datafile = "&dir\&file_japan" out = Japan
dbms = xlsx replace;
datarow = 4;
getnames = no;
data Japan;
set japan;
rename
	A = time
	B = GDP
	C = pred;
lGDP = log(B);
proc sort;
by time;
proc print; run;

proc import datafile = "&dir\&file_taiwan" out = Taiwan
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

proc import datafile = "&dir\&file_china" out = China
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

/*
data Japan;
infile "&dir\&file_japan" firstobs = 4 delimiter = ",";
input year $1-4 month $6-7 GDP 10-18 @20 pred $;
lGDP = log(GDP);                                             *  log磷计筁;
year_and_month =  cat(cat(year, "/"), month);  * for ploting;

label 
	year = ""
	month = "る"
	pred = "箇代";

proc sort;
by year month;
proc print label; run;

data Taiwan;
infile "&dir\&file_taiwan" firstobs = 4 delimiter = ",";
input year $1-4 month $6-7 GDP pred $;
lGDP = log(GDP);                                             * log磷计筁;
year_and_month =  cat(cat(year, "/"), month);  * for ploting;

label 
	year = ""
	month = "る"
	pred = "箇代"
;
proc sort;
by year month;
proc print label; run;
*/
/*Taiwan Time Series Analysis*/
*plot the time series;

proc gplot data = taiwan;
title "Time Series data for Taiwan";
plot lgdp * time;
symbol c = red i = spline v = dot;
run;
proc gplot data = japan;
title "Time Series data for Japan";
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
proc arima data = taiwan;
identify var = lgdp(1, 4) nlag = 15;
estimate p = 4 q = 0 method = ml;
run;

/*Japan Time Series Analysis*/
proc gplot data = japan;
title "Time Series data for Japn";
plot lgdp * year_and_month;
symbol c = red i = spline v = dot;
run;

/*ARIMA Analysis for Japan*/
proc arima data = japan;
identify var = lgdp nlag = 15 stationarity = (adf=0);
run;

proc arima data = japan;
identify var = lgdp(1) nlag = 15 stationarity = (adf=0) outcov = out_cov;
run;
proc print data = out_cov; run;

proc timeseries data = japan plots = corr outcorr = corr_pvals;
*id year_and_month interval = year;
var lgdp;
corr lag n acf pacf acfstd acfprob pacfprob / nlag = 15;
run;

proc arima data = japan;
identify var = lgdp(1) nlag = 15;
estimate p = 3 q = 0 method = ml;
run;

proc arima data = china;
identify var = lgdp nlag = 15 stationarity = (adf=0); *test stationarity by agument dickey-fuller test;
run;
proc arima data = china;
identify var = lgdp(1) nlag = 15 stationarity = (adf=0);
run;
proc arima data = china;
identify var = lgdp(1, 4) nlag = 15 stationarity = (adf=0);
run;
