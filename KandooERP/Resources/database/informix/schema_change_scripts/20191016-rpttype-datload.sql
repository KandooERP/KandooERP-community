--# description: This script populates the 'rpttype' table with data
--# tables list: rpttype
--# author: albo
--# date: 2019-10-16
--# Ticket # : 	
--# more comments:

begin work;
delete from rpttype where 1=1;
insert into rpttype values('S','Standard');
insert into rpttype values('AD','Analysis Down');
insert into rpttype values('AC','Analysis Across');
commit work;

