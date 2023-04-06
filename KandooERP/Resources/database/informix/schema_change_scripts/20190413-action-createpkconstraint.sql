--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: action
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE action ADD CONSTRAINT PRIMARY KEY (
action_grp
) CONSTRAINT pk_action;
