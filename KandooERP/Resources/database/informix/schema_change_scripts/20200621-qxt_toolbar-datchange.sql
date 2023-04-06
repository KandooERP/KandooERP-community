--# description: this script handles changes in the ToolBar of GZT programm
--# dependencies:
--# tables list:  qxt_toolbar
--# author: Alex Bondar
--# date: 2020-06-21
--# Ticket: KD-2121
update qxt_toolbar set
tb_label    = "Delete",
tb_icon     = "ic_delete_24px.svg",
tb_position = 13,
tb_static   = 0,
tb_tooltip  = "Delete Record",
tb_type     = 0,
tb_scope    = 0,
tb_hide     = 0,
tb_key      = NULL,
tb_category = "0011 - 0019 Edit",
tb_mod_user = "AnBl",
tb_mod_date = "2020-06-16 11:41:49"
where
tb_proj_id   = "kandoo" and
tb_module_id = "GZT" and
tb_menu_id   = "bankTypeList" and
tb_action    = "DELETE";

update qxt_toolbar set
tb_label    = "Transaction",
tb_icon     = "ic_code_24px.svg",
tb_position = 60,
tb_static   = 0,
tb_tooltip  = "Account Transaction Codes",
tb_type     = 0,
tb_scope    = 0,
tb_hide     = 0,
tb_key      = NULL,
tb_category = NULL,
tb_mod_user = "AnBl",
tb_mod_date = "2020-06-16 11:41:49"
where
tb_proj_id   = "kandoo" and
tb_module_id = "GZT" and
tb_menu_id   = "bankTypeEdit" and
tb_action    = "F10";

update qxt_toolbar set
tb_label    = "---Divider-Edit---",
tb_icon     = NULL,
tb_position = 5,
tb_static   = 0,
tb_tooltip  = NULL,
tb_type     = 1,
tb_scope    = 0,
tb_hide     = 0,
tb_key      = NULL,
tb_category = "0011 - 0019 Edit",
tb_mod_user = "AnBl",
tb_mod_date = "2020-06-16 11:41:49"
where
tb_proj_id   = "kandoo" and
tb_module_id = "GZT" and
tb_menu_id   = "bankTypeDetlList" and
tb_action    = "---Divider-Edit---";

update qxt_toolbar set
tb_label    = "Add",
tb_icon     = "ic_add_box_24px.svg",
tb_position = 10,
tb_static   = 0,
tb_tooltip  = "Append/Create New Record",
tb_type     = 0,
tb_scope    = 0,
tb_hide     = 0,
tb_key      = NULL,
tb_category = NULL,
tb_mod_user = "AnBl",
tb_mod_date = "2020-06-16 11:41:49"
where
tb_proj_id   = "kandoo" and
tb_module_id = "GZT" and
tb_menu_id   = "bankTypeDetlList" and
tb_action    = "APPEND";

update qxt_toolbar set tb_position = 1
where
tb_proj_id   = "kandoo" and
tb_module_id = "GZT" and
tb_menu_id   = "bankTypeEdit" and
tb_action    = "CANCEL";

update qxt_toolbar set tb_position = 10
where
tb_proj_id   = "kandoo" and
tb_module_id = "GZT" and
tb_menu_id   = "bankTypeEdit" and
tb_action    = "ACCEPT";

update qxt_toolbar set tb_position = 1
where
tb_proj_id   = "kandoo" and
tb_module_id = "GZT" and
tb_menu_id   = "bankTypeNew" and
tb_action    = "CANCEL";

update qxt_toolbar set tb_position = 10
where
tb_proj_id   = "kandoo" and
tb_module_id = "GZT" and
tb_menu_id   = "bankTypeNew" and
tb_action    = "ACCEPT";

delete from qxt_toolbar
where 
tb_proj_id   = "kandoo" and
tb_module_id = "GZT" and
tb_menu_id   = "bankTypeNew" and
tb_action    = "F10";

insert into qxt_toolbar values
(
"kandoo",
"GZT",
"bankTypeNew",
"F10",
"Transaction",
"ic_code_24px.svg",
60,
0,
"Account Transaction Codes",
0,
0,
0,
NULL,
NULL,
"AnBl",
"2020-06-16 11:41:49"
);

