--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: stnd_custgrp
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/stnd_custgrp.unl SELECT * FROM stnd_custgrp;
drop table stnd_custgrp;


create table "informix".stnd_custgrp 
(
cmpy_code char(2),
cust_code nvarchar(8),
group_code nchar(2),
attn_text nvarchar(40)
);
LOAD FROM unl20190322/stnd_custgrp.unl INSERT INTO stnd_custgrp;
