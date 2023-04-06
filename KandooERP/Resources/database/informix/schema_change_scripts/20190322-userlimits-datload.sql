--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: userlimits
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/userlimits.unl SELECT * FROM userlimits;
drop table userlimits;

create table "informix".userlimits 
(
cmpy_code char(2),
sign_on_code nvarchar(8),
price_high_per decimal(6,3),
price_low_per decimal(6,3),
cart_high_per decimal(6,3),
cart_low_per decimal(6,3),
other_high_per decimal(6,3),
other_low_per decimal(6,3),
price_auth_ind nchar(1)
);

LOAD FROM unl20190322/userlimits.unl INSERT INTO userlimits;
