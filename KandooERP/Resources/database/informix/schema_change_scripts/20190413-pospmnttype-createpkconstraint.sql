--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: pospmnttype
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE pospmnttype ADD CONSTRAINT PRIMARY KEY (
pmnt_type_code,
cmpy_code
) CONSTRAINT pk_pospmnttype;
