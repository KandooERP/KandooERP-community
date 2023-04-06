--# description: this script handles changes in the ToolBar of A62 and A6P programs
--# dependencies:
--# tables list:  qxt_toolbar
--# author: Alex Bondar
--# date: 2021-05-28
--# Ticket: KD-2773
delete from qxt_toolbar
where 
tb_proj_id   = "kandoo" and 
tb_module_id = "A62"  and 
tb_menu_id   = "inp-arr-tentbankhead" and 
tb_action    = "ACCEPT";

delete from qxt_toolbar
where 
tb_proj_id   = "kandoo" and 
tb_module_id = "A6P"  and 
tb_menu_id   = "menu-pos-bank-deposit" and 
tb_action    = "Generate";
