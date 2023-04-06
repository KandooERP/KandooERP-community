--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: cont_mail
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE cont_mail ADD CONSTRAINT PRIMARY KEY (
cmpy_code,
cont_code,
mail_code
) CONSTRAINT pk_cont_mail;
