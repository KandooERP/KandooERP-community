--# description: this script creates a stored procedure that checks debit_amnt and credit_amnt are equal  
--# dependencies: 
--# tables list: batchhead 
--# author: eric
--# date: 2020-12-09
--# Ticket # : KD-2499
--#  20201209.001-batchhead-dropckconstraint

drop procedure if exists batchhead_check_balance;
create procedure batchhead_check_balance(debit_amt DECIMAL (16,2),credit_amt DECIMAL (16,2),for_debit_amt DECIMAL (16,2),for_credit_amt DECIMAL (16,2));
IF debit_amt <> credit_amt OR for_debit_amt <> for_credit_amt THEN
        RAISE EXCEPTION -746, 0, 'batchead: debit <> credit or for_debit <> for_credit';
END IF
END PROCEDURE;
