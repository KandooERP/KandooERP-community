--# description: This script populates the 'rndcode' table with data
--# tables list: rndcode
--# author: albo
--# date: 2019-10-16
--# Ticket # : 	
--# more comments:

begin work;
delete from rndcode where 1=1;
insert into rndcode values('WHOLE','Rounded to the nearest dollar',1);
insert into rndcode values('100','Rounded to the nearest $100.00',100);
insert into rndcode values('1000','Rounded to the nearest $1,000.00',1000);
insert into rndcode values('10000','Rounded to the nearest $10,000.00',10000);
insert into rndcode values('HUNDT','Rounded to the nearest $100,000.00',100000);
commit work;

