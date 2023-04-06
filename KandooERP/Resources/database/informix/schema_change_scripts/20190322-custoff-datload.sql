--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: custoffer
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/custoffer.unl SELECT * FROM custoffer;
drop table custoffer;

create table "informix".custoffer 
(
cmpy_code char(2),
cust_code nvarchar(8),
offer_code nvarchar(6),
offer_start_date date,
effective_date date
);

LOAD FROM unl20190322/custoffer.unl INSERT INTO custoffer;
