--# description: this script adds the column program_id for unicity purpose 
--# tables list: t_batchdetl
--# author: ericv
--# date: 2019-12-10
--# Ticket # : 	
--# more comments:
   alter table t_batchdetl add ( program_id CHAR(32));
