--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: carrier
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/carrier.unl SELECT * FROM carrier;
drop table carrier;

create table "informix".carrier 
(
cmpy_code char(2),
carrier_code nchar(3),
name_text nvarchar(30),
addr1_text nvarchar(30),
addr2_text nvarchar(30),
city_text nvarchar(20),
state_code nvarchar(6),
post_code nvarchar(10),
country_code nchar(3),
next_manifest integer,
next_consign nvarchar(15),
last_consign nvarchar(15),
charge_ind nchar(1),
format_ind decimal(2,0)
);


LOAD FROM unl20190322/carrier.unl INSERT INTO carrier;
