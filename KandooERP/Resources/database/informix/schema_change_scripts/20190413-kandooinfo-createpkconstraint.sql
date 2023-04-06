--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: kandooinfo
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE kandooinfo ADD CONSTRAINT PRIMARY KEY (
licensed_user_text
) CONSTRAINT pk_kandooinfo;
