--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: vendorgrp
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/vendorgrp.unl SELECT * FROM vendorgrp;
drop table vendorgrp;

create table "informix".vendorgrp 
(
cmpy_code char(2),
mast_vend_code nvarchar(8),
desc_text nvarchar(30),
vend_code nvarchar(8)
);


LOAD FROM unl20190322/vendorgrp.unl INSERT INTO vendorgrp;
