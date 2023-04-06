--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: vouchpayee
--# author: ericv
--# date: 2019-05-07
--# Ticket # : 4
--# 

create unique index u_vouchpayee on vouchpayee(vouch_code,vend_code,cmpy_code);
ALTER TABLE vouchpayee ADD CONSTRAINT PRIMARY KEY ( vouch_code,vend_code,cmpy_code)
CONSTRAINT pk_vouchpayee;
