--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: period
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/period.unl SELECT * FROM period;
drop table period;

create table "informix".period 
(
cmpy_code char(2),
year_num smallint,
period_num smallint,
start_date date,
end_date date,
gl_flag char(1),
ar_flag char(1),
ap_flag char(1),
pu_flag char(1),
in_flag char(1),
jm_flag char(1),
oe_flag char(1)
);

LOAD FROM unl20190322/period.unl INSERT INTO period;
