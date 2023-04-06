--# description: this script handles changes in the ToolBar of PZ5 programm
--# dependencies:
--# tables list:  qxt_toolbar
--# author: Alex Bondar
--# date: 2020-07-02
--# Ticket: KD-2205
update qxt_toolbar set
tb_label    = "Delete",
tb_icon     = "ic_delete_24px.svg",
tb_position = 20,
tb_static   = 0,
tb_tooltip  = "Delete Record",
tb_type     = 0,
tb_scope    = 0,
tb_hide     = 0,
tb_key      = NULL,
tb_category = "0011 - 0029 Edit",
tb_mod_user = "AnBl",
tb_mod_date = "2020-07-02 15:59:50"
where
tb_proj_id   = "kandoo" and
tb_module_id = "PZ5" and
tb_menu_id   = "inp-arr-vendortype-1" and
tb_action    = "DELETE";
