--# description: This script populates the 'rptpos' table with data
--# tables list: rptpos
--# author: albo
--# date: 2019-10-16
--# Ticket # : 	
--# more comments:

begin work;
delete from rptpos where 1=1;
insert into rptpos values ('C','Centred');
insert into rptpos values ('L','Left Justified');
insert into rptpos values ('R','Right Justified');
commit work;

