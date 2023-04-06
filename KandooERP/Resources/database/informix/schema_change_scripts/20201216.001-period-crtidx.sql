--# description: this script creates a new index on period 
--# dependencies: 
--# tables list: period 
--# author: eric
--# date: 2020-12-16
--# Ticket # : 
--# 

create index d_period_dates on period (start_date,end_date,year_num,period_num,cmpy_code) using btree ;
update statistics high for table period;

SET CONSTRAINTS ALL DEFERRED;
update period
SET year_num =  2018 ,
period_num = 12
WHERE start_date = "01/03/2019";

update period
SET year_num =  2019 ,
period_num = 10
WHERE start_date = "01/01/2020";

update period
SET year_num =  2019 ,
period_num = 11
WHERE start_date = "01/02/2020";

update period
SET year_num =  2019 ,
period_num = 12
WHERE start_date = "01/03/2020";

update period
SET year_num =  2019 ,
period_num = 11
WHERE start_date = "01/02/2020";

update period
SET year_num =  2020 ,
period_num = 10
WHERE start_date = "01/01/2021";

update period
SET year_num =  2020 ,
period_num = 11
WHERE start_date = "01/02/2021";

update period
SET year_num =  2020 ,
period_num = 12
WHERE start_date = "01/03/2021";