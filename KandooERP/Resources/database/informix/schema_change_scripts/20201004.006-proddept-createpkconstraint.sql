--# description: this script redefines the primary key constraint from a unique index
--# dependencies: n/a
--# tables list: proddept
--# author: spokey/eric
--# date: 2020-10-04
--# Ticket # : 4
--# 
alter table proddept drop constraint pk_proddept;
drop index if exists pk_proddept;
create unique index pk_proddept on proddept (dept_code,cmpy_code);
ALTER TABLE proddept ADD CONSTRAINT PRIMARY KEY (dept_code,cmpy_code) CONSTRAINT pk_proddept;