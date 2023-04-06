--# description: this script handles changes in the ToolBar of GZL programm
--# dependencies: put in unl directory any .unl file if the script loads data
--# tables list:  qxt_toolbar
--# author: Alex Bondar
--# date: 2020-04-03
--# Ticket: KD-1290
--# more comments: 
--# set constraints all deferred is necessary because qxt_menu_item has another relationship with qxt_log_run
-- set constraints all deferred;
delete from qxt_toolbar where tb_proj_id = "kandoo" and tb_module_id = "GZA" and tb_menu_id = "fiscalYearQuery";
load from unl/20200403_qxt_toolbar.unl insert into qxt_toolbar;
