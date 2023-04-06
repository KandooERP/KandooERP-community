--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: comment
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE comment ADD CONSTRAINT PRIMARY KEY (
comment_line_id,
comment_id
) CONSTRAINT pk_comment;
