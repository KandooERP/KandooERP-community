--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: kandoomenu
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE kandoomenu ADD CONSTRAINT PRIMARY KEY (
profile_code,
language_code,
select_code,
cmpy_code
) CONSTRAINT pk_kandoomenu;
