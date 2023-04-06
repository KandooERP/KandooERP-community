--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: term
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/term.unl SELECT * FROM term;
drop table term;

create table "informix".term 
(
cmpy_code char(2),
term_code nchar(3),
desc_text nvarchar(40),
day_date_ind nchar(1),
due_day_num smallint,
disc_day_num smallint,
disc_per decimal(6,3)
);

LOAD FROM unl20190322/term.unl INSERT INTO term;
