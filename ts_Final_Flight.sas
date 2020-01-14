%let dir = D:\時間數列分析\Final_project\data;
%let file = Flight_2005_2019.csv;

data temp;
infile "&dir\&file" firstobs = 2 delimiter = ",";
input Company ShortName $ time $ NetIncome;
proc transpose data = temp out = FlightWide prefix = NetIncome;
by time;
id company;
var netincome;
data Flight;
set flightwide(drop = _name_);
rename
	netincome2610 = hua
	netincome2612 = cho
	netincome2618 = chan;
label
	time = "年月"
	netincome2610 = "華航"
	netincome2612 = "中航"
	netincome2618 = "長榮";
proc print data = flight label;
run;

proc gplot data = flight;
title "Time Series data for Taiwan";
plot cho * time;
symbol c = red i = spline v = dot;
run;
proc arima data = flight;
identify var = cho nlag = 15 stationarity = (adf=0); *test stationarity by agument dickey-fuller test;
run;
proc arima data = flight;
identify var = cho(1) nlag = 15 stationarity = (adf=0); *test stationarity by agument dickey-fuller test;
run;
proc arima data = flight;
identify var = cho(1) nlag = 15 stationarity = (adf=0); *test stationarity by agument dickey-fuller test;
estimate p = 4 method = ml;
run;

proc arima data = flight;
identify var = hua nlag = 15 stationarity = (adf=0); *test stationarity by agument dickey-fuller test;
run;
proc arima data = flight;
identify var = hua(1) nlag = 15 stationarity = (adf=0); *test stationarity by agument dickey-fuller test;
run;
proc arima data = flight;
identify var = hua(1) nlag = 15 stationarity = (adf=0); *test stationarity by agument dickey-fuller test;
estimate p = 3 method = ml;
run;

proc arima data = flight;
identify var = chan nlag = 15 stationarity = (adf=0); *test stationarity by agument dickey-fuller test;
run;
proc arima data = flight;
identify var = hua nlag = 15 stationarity = (adf=0); *test stationarity by agument dickey-fuller test;
estimate p = 5 method = ml;
run;
