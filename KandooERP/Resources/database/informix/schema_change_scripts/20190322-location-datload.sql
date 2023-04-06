--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: location
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/location.unl SELECT * FROM location;
drop table location;

create table "informix".location 
(
cmpy_code char(2),
locn_code nchar(3),
desc_text nvarchar(40,0),
addr1_text nvarchar(40,0),
addr2_text nvarchar(40,0),
city_text nvarchar(40,0),
state_code nvarchar(6,0),
post_code nvarchar(10,0),
country_code nchar(3),
contact_text nvarchar(40,0),
tele_text nvarchar(20),
fax_text nvarchar(20),
ware_code nchar(3),
price_high_per decimal(6,3),
price_low_per decimal(6,3),
cart_high_per decimal(6,3),
cart_low_per decimal(6,3),
other_high_per decimal(6,3),
other_low_per decimal(6,3),
price_auth_ind nchar(1),
pallet_charge_ind nchar(1),
bank_code nvarchar(9),
days_to_del smallint,
ol_hold_code nchar(3),
tt_hold_code nchar(3),
oltt_hold_code nchar(3),
excess_day_num smallint,
excess_limit_per smallint,
price_round_ind nchar(1),
disp_locn_ind nchar(1),
stocktake_ind nchar(1),
def_labour_class nvarchar(8),
desc2_text nvarchar(60,0),
comp_date date,
approval_flag char(1),
summ_cfwd_flag char(1),
edit_km_flag char(1),
min_cartage_ind nchar(1),
head_info_flag char(1),
def_int_cust nvarchar(8,0)
);



LOAD FROM unl20190322/location.unl INSERT INTO location;
