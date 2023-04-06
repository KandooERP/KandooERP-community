--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: conddisc
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/conddisc.unl SELECT * FROM conddisc;
drop table conddisc;

create table "informix".conddisc 
(
cmpy_code char(2),
cond_code nchar(3),
reqd_amt decimal(16,2),
bonus_check_per decimal(5,2),
disc_check_per decimal(5,2),
disc_per decimal(5,2)
);

LOAD FROM unl20190322/conddisc.unl INSERT INTO conddisc;
