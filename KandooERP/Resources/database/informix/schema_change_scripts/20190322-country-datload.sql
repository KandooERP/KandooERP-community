--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: country
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/country.unl SELECT * FROM country;
drop table country;


create table "informix".country 
(
country_code nchar(3),
country_text nvarchar(60), /* was too short*/
language_code nchar(3),
post_code_text nvarchar(20),
post_code_min_num smallint,
post_code_max_num smallint,
state_code_text nvarchar(20),
state_code_min_num smallint,
state_code_max_num smallint,
bank_acc_format smallint
);

LOAD FROM unl20190322/country.unl INSERT INTO country;
