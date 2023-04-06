--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: customership
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/customership.unl SELECT * FROM customership;
drop table customership;

create table "informix".customership 
(
cmpy_code char(2),
cust_code nvarchar(8),
ship_code nvarchar(8),
name_text nvarchar(30),
addr_text nvarchar(30),
addr2_text nvarchar(30),
city_text nvarchar(30),
state_text nvarchar(20),
post_code nvarchar(10),
country_text nvarchar(40),
contact_text nvarchar(30),
tele_text nvarchar(20),
ware_code nchar(3),
tax_code nchar(3),
ship1_text nvarchar(60),
ship2_text nvarchar(60),
contract_text nvarchar(10),
cat_code nchar(3),
run_text nchar(3),
note_text nvarchar(40),
carrier_code nchar(3),
freight_ind nchar(1),
country_code nchar(3)
);


LOAD FROM unl20190322/customership.unl INSERT INTO customership;
