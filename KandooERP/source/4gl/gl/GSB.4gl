{
###########################################################################
# This program IS free software; you can redistribute it AND/OR modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 2 of the License, OR (at your
# option) any later version.
#
# This program IS distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License FOR more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; IF NOT, write TO the Free Software Foundation, Inc.,
# 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
#
###########################################################################

	Source code beautified by beautify.pl on 2020-01-03 14:28:52	$Id: $
}



#Program GSB allows the user TO check subsidiary vs GL accounts


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" 

GLOBALS 
END GLOBALS 

############################################################
# MODULE Scope Variables
############################################################
DEFINE modu_conv_qty LIKE invoicehead.conv_qty
DEFINE modu_ans CHAR(1)
DEFINE modu_period_numb SMALLINT
DEFINE modu_year_numb SMALLINT
DEFINE modu_line_item_tot money(16,2) 
DEFINE modu_totaller1 money(16,2)
DEFINE modu_totaller2 money(16,2)
DEFINE modu_totaller3 money(16,2)

############################################################
# MAIN
#
#
############################################################
MAIN 

	CALL setModuleId("GSB") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_g_gl() #init g/gl general ledger module 


	OPEN WINDOW wg164 with FORM "G164"
	CALL windecoration_g("G164") 


	LET modu_ans = "Y" 
	WHILE modu_ans = "Y" 

		CALL query() 

	END WHILE 

END MAIN 


############################################################
# FUNCTION query() 
#
#
############################################################
FUNCTION query() 

	INPUT modu_year_numb, modu_period_numb WITHOUT DEFAULTS 
	FROM year_numb, period_numb 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GSB","inp-period") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		EXIT PROGRAM 
	END IF 

	SELECT sum(total_amt / conv_qty) 
	INTO modu_totaller2 
	FROM invoicehead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND period_num = modu_period_numb 
	AND year_num = modu_year_numb 
	AND posted_flag = "Y" 

	LET modu_totaller1 = 0 
	DECLARE inv_curs CURSOR FOR 
	SELECT conv_qty, sum(line_total_amt) 
	INTO modu_conv_qty, modu_line_item_tot 
	FROM invoicehead, invoicedetl 
	WHERE invoicedetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND invoicehead.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND period_num = modu_period_numb 
	AND year_num = modu_year_numb 
	AND posted_flag = "Y" 
	AND line_total_amt < 0 
	AND invoicehead.inv_num = invoicedetl.inv_num 
	AND invoicehead.cust_code = invoicedetl.cust_code 
	GROUP BY conv_qty 

	FOREACH inv_curs 
		IF modu_line_item_tot IS NOT NULL THEN 
			LET modu_totaller1 = modu_totaller1 + (modu_line_item_tot / modu_conv_qty) 
		END IF 
	END FOREACH 
	IF modu_totaller2 IS NULL THEN LET modu_totaller2 = 0 END IF 
		LET modu_totaller1 = modu_totaller2 - modu_totaller1 + 0 

		DISPLAY modu_totaller1 TO sc_sub[1].totaller1 


		SELECT sum(batchdetl.credit_amt) 
		INTO modu_totaller2 
		FROM batchdetl, batchhead 
		WHERE batchhead.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND batchdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND batchhead.jour_num = batchdetl.jour_num 
		AND period_num = modu_period_numb 
		AND year_num = modu_year_numb 
		AND tran_type_ind = TRAN_TYPE_INVOICE_IN 

		IF modu_totaller2 IS NULL THEN LET modu_totaller2 = 0 END IF 
			DISPLAY modu_totaller2 TO sc_sub[1].totaller2 


			SELECT sum(credit_amt) 
			INTO modu_totaller3 
			FROM accountledger 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND period_num = modu_period_numb 
			AND year_num = modu_year_numb 
			AND tran_type_ind = TRAN_TYPE_INVOICE_IN 

			IF modu_totaller3 IS NULL THEN LET modu_totaller3 = 0 END IF 
				DISPLAY modu_totaller3 TO sc_sub[1].totaller3 


				SELECT sum(total_amt / conv_qty) 
				INTO modu_totaller2 
				FROM credithead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND period_num = modu_period_numb 
				AND year_num = modu_year_numb 
				AND posted_flag = "Y" 

				LET modu_totaller1 = 0 
				DECLARE cred_curs CURSOR FOR 
				SELECT conv_qty, sum(line_total_amt) 
				INTO modu_conv_qty, modu_line_item_tot 
				FROM credithead, creditdetl 
				WHERE creditdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND credithead.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND period_num = modu_period_numb 
				AND year_num = modu_year_numb 
				AND posted_flag = "Y" 
				AND line_total_amt < 0 
				AND credithead.cred_num = creditdetl.cred_num 
				AND credithead.cust_code = creditdetl.cust_code 
				GROUP BY conv_qty 

				FOREACH cred_curs 
					IF modu_line_item_tot IS NOT NULL THEN 
						LET modu_totaller1 = modu_totaller1 + (modu_line_item_tot / modu_conv_qty) 
					END IF 
				END FOREACH 
				IF modu_totaller2 IS NULL THEN LET modu_totaller2 = 0 END IF 
					LET modu_totaller1 = modu_totaller2 - modu_totaller1 + 0 

					DISPLAY modu_totaller1 TO sc_sub[2].totaller1 


					SELECT sum(batchdetl.debit_amt) 
					INTO modu_totaller2 
					FROM batchdetl, batchhead 
					WHERE batchhead.cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND batchdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND batchhead.jour_num = batchdetl.jour_num 
					AND period_num = modu_period_numb 
					AND year_num = modu_year_numb 
					AND tran_type_ind = TRAN_TYPE_CREDIT_CR 

					IF modu_totaller2 IS NULL THEN LET modu_totaller2 = 0 END IF 
						DISPLAY modu_totaller2 TO sc_sub[2].totaller2 


						SELECT sum(debit_amt) 
						INTO modu_totaller3 
						FROM accountledger 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND period_num = modu_period_numb 
						AND year_num = modu_year_numb 
						AND tran_type_ind = TRAN_TYPE_CREDIT_CR 

						IF modu_totaller3 IS NULL THEN LET modu_totaller3 = 0 END IF 
							DISPLAY modu_totaller3 TO sc_sub[2].totaller3 



							SELECT sum(cash_amt / conv_qty) 
							INTO modu_totaller1 
							FROM cashreceipt 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND period_num = modu_period_numb 
							AND year_num = modu_year_numb 
							AND posted_flag = "Y" 

							IF modu_totaller1 IS NULL THEN LET modu_totaller1 = 0 END IF 
								DISPLAY modu_totaller1 TO sc_sub[3].totaller1 


								SELECT sum(batchdetl.debit_amt) 
								INTO modu_totaller2 
								FROM batchdetl, batchhead 
								WHERE batchhead.cmpy_code = glob_rec_kandoouser.cmpy_code 
								AND batchdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
								AND batchhead.jour_num = batchdetl.jour_num 
								AND period_num = modu_period_numb 
								AND year_num = modu_year_numb 
								AND tran_type_ind = TRAN_TYPE_RECEIPT_CA 

								IF modu_totaller2 IS NULL THEN LET modu_totaller2 = 0 END IF 
									DISPLAY modu_totaller2 TO sc_sub[3].totaller2 


									SELECT sum(debit_amt) 
									INTO modu_totaller3 
									FROM accountledger 
									WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
									AND period_num = modu_period_numb 
									AND year_num = modu_year_numb 
									AND tran_type_ind = TRAN_TYPE_RECEIPT_CA 

									IF modu_totaller3 IS NULL THEN LET modu_totaller3 = 0 END IF 
										DISPLAY modu_totaller3 TO sc_sub[3].totaller3 



										SELECT sum(total_amt / conv_qty) 
										INTO modu_totaller1 
										FROM voucher 
										WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
										AND period_num = modu_period_numb 
										AND year_num = modu_year_numb 
										AND post_flag = "Y" 

										IF modu_totaller1 IS NULL THEN LET modu_totaller1 = 0 END IF 
											DISPLAY modu_totaller1 TO sc_sub[4].totaller1 


											SELECT sum(batchdetl.debit_amt) 
											INTO modu_totaller2 
											FROM batchdetl, batchhead 
											WHERE batchhead.cmpy_code = glob_rec_kandoouser.cmpy_code 
											AND batchdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
											AND batchhead.jour_num = batchdetl.jour_num 
											AND period_num = modu_period_numb 
											AND year_num = modu_year_numb 
											AND tran_type_ind = "VO" 

											IF modu_totaller2 IS NULL THEN LET modu_totaller2 = 0 END IF 
												DISPLAY modu_totaller2 TO sc_sub[4].totaller2 


												SELECT sum(debit_amt) 
												INTO modu_totaller3 
												FROM accountledger 
												WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
												AND period_num = modu_period_numb 
												AND year_num = modu_year_numb 
												AND tran_type_ind = "VO" 

												IF modu_totaller3 IS NULL THEN LET modu_totaller3 = 0 END IF 
													DISPLAY modu_totaller3 TO sc_sub[4].totaller3 



													SELECT sum(total_amt / conv_qty) 
													INTO modu_totaller1 
													FROM debithead 
													WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
													AND period_num = modu_period_numb 
													AND year_num = modu_year_numb 
													AND post_flag = "Y" 

													IF modu_totaller1 IS NULL THEN LET modu_totaller1 = 0 END IF 
														DISPLAY modu_totaller1 TO sc_sub[5].totaller1 


														SELECT sum(batchdetl.debit_amt) 
														INTO modu_totaller2 
														FROM batchdetl, batchhead 
														WHERE batchhead.cmpy_code = glob_rec_kandoouser.cmpy_code 
														AND batchdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
														AND batchhead.jour_num = batchdetl.jour_num 
														AND period_num = modu_period_numb 
														AND year_num = modu_year_numb 
														AND tran_type_ind = "DM" 

														IF modu_totaller2 IS NULL THEN LET modu_totaller2 = 0 END IF 
															DISPLAY modu_totaller2 TO sc_sub[5].totaller2 


															SELECT sum(debit_amt) 
															INTO modu_totaller3 
															FROM accountledger 
															WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
															AND period_num = modu_period_numb 
															AND year_num = modu_year_numb 
															AND tran_type_ind = "DM" 

															IF modu_totaller3 IS NULL THEN LET modu_totaller3 = 0 END IF 
																DISPLAY modu_totaller3 TO sc_sub[5].totaller3 



																SELECT sum(net_pay_amt / conv_qty) + sum(disc_amt / conv_qty) 
																INTO modu_totaller1 
																FROM cheque 
																WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
																AND period_num = modu_period_numb 
																AND year_num = modu_year_numb 
																AND post_flag = "Y" 

																IF modu_totaller1 IS NULL THEN LET modu_totaller1 = 0 END IF 
																	DISPLAY modu_totaller1 TO sc_sub[6].totaller1 


																	SELECT sum(batchdetl.credit_amt) 
																	INTO modu_totaller2 
																	FROM batchdetl, batchhead 
																	WHERE batchhead.cmpy_code = glob_rec_kandoouser.cmpy_code 
																	AND batchdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
																	AND batchhead.jour_num = batchdetl.jour_num 
																	AND period_num = modu_period_numb 
																	AND year_num = modu_year_numb 
																	AND tran_type_ind = "CH" 

																	IF modu_totaller2 IS NULL THEN LET modu_totaller2 = 0 END IF 
																		DISPLAY modu_totaller2 TO sc_sub[6].totaller2 


																		SELECT sum(credit_amt) 
																		INTO modu_totaller3 
																		FROM accountledger 
																		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
																		AND period_num = modu_period_numb 
																		AND year_num = modu_year_numb 
																		AND tran_type_ind = "CH" 

																		IF modu_totaller3 IS NULL THEN LET modu_totaller3 = 0 END IF 
																			DISPLAY modu_totaller3 TO sc_sub[6].totaller3 


																			RETURN 
END FUNCTION