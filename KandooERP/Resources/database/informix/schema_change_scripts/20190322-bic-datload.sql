--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: bic
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/bic.unl SELECT * FROM bic;
drop table bic;

create table "informix".bic 
(
bic_code char(11),
desc_text nvarchar(30,0),
post_code nvarchar(10),
bank_ref nvarchar(8),
primary key (bic_code) 
);

LOAD FROM unl20190322/bic.unl INSERT INTO bic;
