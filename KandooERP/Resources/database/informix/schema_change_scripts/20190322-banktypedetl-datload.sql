--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: banktypedetl
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/banktypedetl.unl SELECT * FROM banktypedetl;
drop table banktypedetl;


create table "informix".banktypedetl 
(
type_code nvarchar(8),
cr_dr_ind nchar(2),
bank_ref_code nvarchar(10),
max_ref_code nchar(3),
desc_text nvarchar(30)
);


LOAD FROM unl20190322/banktypedetl.unl INSERT INTO banktypedetl;
