--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: vendorinvs
--# author: spokey
--# date: 2020-03-16
--# Ticket # : 4
--# 

ALTER TABLE vendorinvs DROP CONSTRAINT pk_vendorinvs;
drop index if exists u_vendorinvs ;
create unique index u_vendorinvs on vendorinvs (vouch_code, cmpy_code) using btree;
ALTER TABLE vendorinvs ADD CONSTRAINT PRIMARY KEY (vouch_code,cmpy_code) CONSTRAINT pk_vendorinvs;