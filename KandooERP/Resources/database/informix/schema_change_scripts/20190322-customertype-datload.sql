--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: customertype
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/customertype.unl SELECT * FROM customertype;
drop table customertype;



create table "informix".customertype 
(
cmpy_code char(2),
type_code nchar(3),
type_text nvarchar(30),
ar_acct_code nvarchar(18),
freight_acct_code nvarchar(18),
tax_acct_code nvarchar(18),
disc_acct_code nvarchar(18),
exch_acct_code nvarchar(18),
lab_acct_code nvarchar(18),
acct_mask_code nvarchar(18)
);




LOAD FROM unl20190322/customertype.unl INSERT INTO customertype;
