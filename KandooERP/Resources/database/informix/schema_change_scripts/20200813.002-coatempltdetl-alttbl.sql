--# description: this script adds columns to coatempltdetl
--# tables list: coatempltdetl
--# dependencies: 
--# author: ericv
--# date: 2020-08-13
--# Ticket #  KD-2239	
--# Comments: parent: parent code of this code 
--# is_max_level: this code is at the bottom of the hierarchy (is a nominal code) 
alter table coatempltdetl modify (acct_code nchar(18));
update coatempltdetl set tree_level = "10" where tree_level = "X" ;
alter table coatempltdetl modify (tree_level smallint);
alter table coatempltdetl add (parent nchar(18),is_max_level smallint);