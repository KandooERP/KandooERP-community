--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: suburbarea
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE suburbarea ADD CONSTRAINT PRIMARY KEY (
suburb_code,
waregrp_code,
cmpy_code
) CONSTRAINT pk_suburbarea;
