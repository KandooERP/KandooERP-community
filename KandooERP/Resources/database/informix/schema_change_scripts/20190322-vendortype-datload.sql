--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: vendortype
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/vendortype.unl SELECT * FROM vendortype;
drop table vendortype;

create table "informix".vendortype 
(
cmpy_code char(2),
type_code nchar(3),
type_text nvarchar(20),
pay_acct_code nvarchar(18),
freight_acct_code nvarchar(18),
salestax_acct_code nvarchar(18),
disc_acct_code nvarchar(18),
exch_acct_code nvarchar(18),
withhold_tax_ind nchar(1),
tax_vend_code nvarchar(8)
);



LOAD FROM unl20190322/vendortype.unl INSERT INTO vendortype;
