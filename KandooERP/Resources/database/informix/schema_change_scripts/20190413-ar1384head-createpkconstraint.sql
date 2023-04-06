--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: ar1384head
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE ar1384head ADD CONSTRAINT PRIMARY KEY (
jour_code,
jour_num,
cmpy_code
) CONSTRAINT pk_ar1384head;

