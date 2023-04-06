--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: vendorinvs
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 

create unique index u_vendorinvs on vendorinvs (vouch_code, vend_code, cmpy_code) using btree;
ALTER TABLE vendorinvs ADD CONSTRAINT PRIMARY KEY (vouch_code, vend_code, cmpy_code) CONSTRAINT pk_vendorinvs;
