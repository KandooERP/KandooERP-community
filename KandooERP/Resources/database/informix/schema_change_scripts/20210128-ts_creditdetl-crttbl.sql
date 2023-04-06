--# description: this script create the ts_creditdetl table as a static table , which is replacing t_creditdetl (temporary)
--# dependencies: 
--# tables list: ts_creditdetl
--# author: erve
--# date: 2021-01-28
--# Ticket # : 	KD-2541
create table ts_creditdetl
  (
    cmpy_code nchar(2),
    cust_code nchar(8),
    cred_num integer,
    line_num smallint,
    part_code nchar(15),
    ware_code nchar(3),
    cat_code nchar(3),
    ship_qty float,
    ser_ind nchar(1),
    line_text nchar(40),
    uom_code nchar(4),
    unit_cost_amt decimal(16,4),
    ext_cost_amt decimal(16,2),
    disc_amt decimal(16,2),
    unit_sales_amt decimal(16,4),
    ext_sales_amt decimal(16,2),
    unit_tax_amt decimal(16,4),
    ext_tax_amt decimal(16,2),
    line_total_amt decimal(16,2),
    seq_num integer,
    line_acct_code nchar(18),
    job_code nchar(8),
    level_code nchar(1),
    comm_amt decimal(16,2),
    tax_code nchar(3),
    reason_code nchar(3),
    received_qty float,
    invoice_num integer,
    inv_line_num integer,
    var_code smallint,
    activity_code nchar(8),
    jobledger_seq_num integer,
    price_uom_code nchar(4),
    km_qty float,
    prodgrp_code nchar(3),
    maingrp_code nchar(3),
    proddept_code nchar(3),
    list_amt decimal(16,4),
    username nchar(8),
    program_id char(32)
  );

create unique index pk_ts_creditdetl on ts_creditdetl (cust_code,cred_num,line_num,cmpy_code) using btree ;
create index ts_creditdetl_username on ts_creditdetl(username,program_id);
