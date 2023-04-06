--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: sourcemodule
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE sourcemodule ADD CONSTRAINT PRIMARY KEY (
source_code
) CONSTRAINT pk_sourcemodule;
