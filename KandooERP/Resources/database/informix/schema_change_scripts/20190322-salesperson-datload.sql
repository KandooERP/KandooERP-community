--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: salesperson
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/salesperson.unl SELECT * FROM salesperson;
drop table salesperson;

create table "informix".salesperson 
(
cmpy_code char(2),
sale_code nvarchar(8),
name_text nvarchar(30),
comm_per decimal(6,3),
terri_code nvarchar(5),
ytds_amt decimal(16,2),
mtds_amt decimal(16,2),
mtdc_amt decimal(16,2),
ytdc_amt decimal(16,2),
comm_ind nchar(1),
sale_type_ind nchar(1),
addr1_text nvarchar(30),
addr2_text nvarchar(30),
city_text nvarchar(20),
state_code nvarchar(20),
post_code nvarchar(10),
country_code nchar(3),
language_code nchar(3),
fax_text nvarchar(20),
tele_text nvarchar(20),
alt_tele_text nvarchar(20),
com1_text nvarchar(30),
com2_text nvarchar(30),
ware_code nchar(3),
share_per decimal(2,0),
mgr_code nvarchar(8),
acct_mask_code char(18)
);

LOAD FROM unl20190322/salesperson.unl INSERT INTO salesperson;
