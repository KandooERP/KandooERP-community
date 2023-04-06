--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: kandooprofile
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/kandooprofile.unl SELECT * FROM kandooprofile;
drop table kandooprofile;


create table "informix".kandooprofile 
(
cmpy_code char(2),
profile_code nchar(3),
profile_text nvarchar(30),
access_ind nchar(1),
acct_mask_code nvarchar(18),
acct_access_code nvarchar(18),
quote_print_text nvarchar(20),
order_print_text nvarchar(20),
inv_print_text nvarchar(20),
chq_print_text nvarchar(20)
);

LOAD FROM unl20190322/kandooprofile.unl INSERT INTO kandooprofile;
