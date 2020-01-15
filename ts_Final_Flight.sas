%macro datasets_dir;
%local fr rc cwd;
%let rc = %sysfunc(filename(fr,.));
%let cwd = %sysfunc(pathname(&fr));
%let rc = %sysfunc(filename(fr));

%let data = data;
%let datasets_dir = &cwd\data;
&datasets_dir
%mend datasets_dir;

%let NetIncome_file = Flight_Comany_NetIncome_2005_2019.csv;
%let Income_file = Flight_Comany_Income_2005_2019.csv;

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
	Netincome2610 = China_net
	Netincome2612 = AirChina_net
	Netincome2618 = Eva_net;
label
	time = "年月"
	Netincome2610 = "華航毛利"
	Netincome2612 = "中航毛利"
	Netincome2618 = "長榮毛利";
if time < 200803 then delete;
proc print data = flight_netincome label;
run;

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
	income2610 = China
	income2612 = AirChina
	income2618 = Eva;
label
	time = "年月"
	income2610 = "華航營收"
	income2612 = "中航營收"
	income2618 = "長榮營收";
if time < 200803 then delete;
proc print data = flight_income label;
run;

data Flight;
merge Flight_Income Flight_NetIncome ;
by time;
proc print; run;

/*Time Series Plots*/
/*淨營收*/
proc gplot data = Flight;
title "Time Series Plot for Income";
plot China * time AirChina*time Eva*time/overlay legend;
symbol1 interpol = join value = line c = blue v = dot; 
symbol2 interpol = join value = line c = green v = dot;
symbol3 interpol = join value = line c = red v = dot;
run;
/*淨毛利*/
proc gplot data = Flight;
title "Time Series Plot for Net Income";
plot China_net * time AirChina_net*time Eva_net*time/overlay legend;
symbol1 interpol = join value = line c = blue v = dot; 
symbol2 interpol = join value = line c = green v = dot;
symbol3 interpol = join value = line c = red v = dot;
run;

/*中國航空*/
proc arima data = Flight;
identify var = airchina_net nlag = 15 stationarity = (adf=4); *test stationarity by agument dickey-fuller test;
run;
proc arima data = Flight;
identify var = airchina_net(1) nlag = 15 stationarity = (adf=4); *test stationarity by agument dickey-fuller test;
run;
proc arima data = Flight;
identify var = airchina_net(1) nlag = 15 stationarity = (adf=4); *test stationarity by agument dickey-fuller test;
estimate p = 4 method = ml;
run;

/*長榮航空*/
proc arima data = Flight_Netincome;
identify var = eva_net nlag = 15 stationarity = (adf=4); *test stationarity by agument dickey-fuller test;
run;
proc arima data = Flight_Netincome;
identify var = eva_net(1) nlag = 15 stationarity = (adf=4); *test stationarity by agument dickey-fuller test;
run;
proc arima data = Flight_Netincome;
identify var = eva_net(1) nlag = 15 stationarity = (adf=4); *test stationarity by agument dickey-fuller test;
estimate p = 3 method = ml;
run;

/*中華航空*/
proc arima data = Flight_Netincome;
identify var = china_net nlag = 15 stationarity = (adf=4); *test stationarity by agument dickey-fuller test;
run;
proc arima data = Flight_Netincome;
identify var = china_net nlag = 15 stationarity = (adf=4); *test stationarity by agument dickey-fuller test;
estimate p = 5 method = ml;
run;



proc varmax data = Flight_Netincome;
id time interval=qtr;
model hua chan / p=1 noint lagmax=3 print=(estimates diagnose);
output out=for lead=5;
run;
