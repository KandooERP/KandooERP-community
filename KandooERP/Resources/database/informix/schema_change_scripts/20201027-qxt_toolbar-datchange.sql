--# description: this script handles changes in the ToolBar of AZH programm
--# dependencies:
--# tables list:  qxt_toolbar
--# author: Alex Bondar
--# date: 2020-10-27
--# Ticket: KD-2151
update qxt_toolbar set
tb_label    = "Delete",
tb_icon     = "ic_delete_24px.svg",
tb_position = 12,
tb_static   = 0,
tb_tooltip  = "Delete Record",
tb_type     = 0,
tb_scope    = 0,
tb_hide     = 0,
tb_key      = NULL,
tb_category = "0011 - 0029 Edit",
tb_mod_user = "AnBl",
tb_mod_date = "2020-10-27 14:23:01"
where
tb_proj_id   = "kandoo" and
tb_module_id = "AZH" and
tb_menu_id   = "inp-arr-holdreas" and
tb_action    = "DELETE";
