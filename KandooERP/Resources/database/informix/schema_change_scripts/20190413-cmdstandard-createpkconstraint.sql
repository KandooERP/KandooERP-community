--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: cmdstandard
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE cmdstandard ADD CONSTRAINT PRIMARY KEY (
language_code,
ref_code
) CONSTRAINT pk_cmdstandard;
