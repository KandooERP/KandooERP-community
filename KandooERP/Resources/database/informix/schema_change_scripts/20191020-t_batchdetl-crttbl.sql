--# description: this script creates the t_batchdetl table which now becomes a permanent table
--# dependencies: 
--# tables list: t_batchdetl
--# author: eric vercelletto
--# date: 2019-10-20
--# Ticket # :
--# more comments: 
create table "informix".t_batchdetl 
  (
    cmpy_code nchar(2),
    jour_code nchar(3),
    jour_num integer,
    seq_num integer,
    tran_type_ind nchar(3),
    analysis_text nchar(16),
    tran_date date,
    ref_text nchar(10),
    ref_num integer,
    acct_code nchar(18),
    desc_text nchar(30),
    debit_amt decimal(16,2),
    credit_amt decimal(16,2),
    currency_code nchar(3),
    conv_qty float,
    for_debit_amt decimal(16,2),
    for_credit_amt decimal(16,2),
    stats_qty float,
    username nchar(8)
  );

create unique index u_t_batchdetl on t_batchdetl (username,jour_num,seq_num,jour_code,cmpy_code) using btree ;


