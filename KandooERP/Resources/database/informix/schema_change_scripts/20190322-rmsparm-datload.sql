--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: rmsparm
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/rmsparm.unl SELECT * FROM rmsparm;
drop table rmsparm;

create table "informix".rmsparm 
(
cmpy_code char(2),
order_hold_flag char(1),
order_print_text nvarchar(20),
inv_hold_flag char(1),
inv_print_text nvarchar(20),
inv_print_qty smallint,
next_report_num integer,
rw_print_text nchar(2)
);

LOAD FROM unl20190322/rmsparm.unl INSERT INTO rmsparm;
