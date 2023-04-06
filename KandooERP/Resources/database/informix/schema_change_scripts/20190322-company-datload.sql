--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: company
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/company.unl SELECT * FROM company;
drop table company;


create table "informix".company 
(
cmpy_code char(2),
name_text nvarchar(40),
addr1_text nvarchar(30),
addr2_text nvarchar(30),
city_text nvarchar(30),
state_code nvarchar(6),
post_code nvarchar(10),
country_text nvarchar(40),
country_code nchar(3),
language_code nchar(3),
fax_text nvarchar(20),
tax_text nvarchar(30),
telex_text nvarchar(30),
com1_text nvarchar(50),
com2_text nvarchar(50),
tele_text nvarchar(20),
curr_code nchar(3),
module_text nvarchar(26),
abn_text nvarchar(11),
abn_div_text nchar(3)
);


LOAD FROM unl20190322/company.unl INSERT INTO company;
