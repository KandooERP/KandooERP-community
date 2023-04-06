############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl"
DEFINE contact_channel_pky_array DYNAMIC ARRAY OF RECORD #@g00002 
	cc_id LIKE contact_channel.cc_id, # VARCHAR(64) #@g00002 
	cc_channel LIKE contact_channel.cc_channel # CHAR(6) #@g00003 
END RECORD #@g00004 

DEFINE contact_channel_sr_array DYNAMIC ARRAY OF RECORD #@g00006 
	cc_channel LIKE contact_channel.valid_to, # CHAR(6) #@g00006 
	cc_id LIKE contact_channel.valid_to, # VARCHAR(64) #@g00006 
	valid_from LIKE contact_channel.valid_to, # DATE #@g00006 
	valid_to LIKE contact_channel.valid_to # DATE #@g00007 
END RECORD #@g00008 

DEFINE contact_channel_status_array DYNAMIC ARRAY OF SMALLINT #@g00010 

DEFINE tbl_contact_channel RECORD #@g00012 
	contact_seed LIKE contact_channel.contact_seed, # BIGINT #@g00012 
	cc_id LIKE contact_channel.cc_id, # VARCHAR(64) #@g00012 
	cc_channel LIKE contact_channel.cc_channel, # CHAR(6) #@g00012 
	valid_from LIKE contact_channel.valid_from, # DATE #@g00012 
	valid_to LIKE contact_channel.valid_to # DATE #@g00013 
END RECORD #@g00014 

FUNCTION init_cursor_test2_contact_channel () #@g00016 
	DEFINE query_text CHAR(1024) #@g00017 
	# Prepare the CURSOR TO display the contact_channel array		                                                               	#@G00018
	# using foreign key pointing TO contact		                                                                                 	#@G00019

	LET query_text = "SELECT contact_channel.cc_id,contact_channel.cc_channel ,", #@g00021 
	"contact_channel.cc_channel,", #@g00022 
	"contact_channel.cc_id,", #@g00023 
	"contact_channel.valid_from,", #@g00024 
	"contact_channel.valid_to", #@g00025 
	#@G00026
	#@G00027
	" AND contact_seed = ? ", #@g00028 
	" ORDER BY contact_channel.cc_id,contact_channel.cc_channel " #@g00029 
	PREPARE pr_child_contact_channel FROM query_text #@g00030 
	DECLARE crs_child_contact_channel CURSOR FOR pr_child_contact_channel #@g00031 

	# PREPARE INSERT statement		                                                                                              	#@G00033
	LET query_text = #@g00034 
	"INSERT INTO contact_channel ( contact_seed,cc_id,cc_channel,valid_from,valid_to )", #@g00035 
	" VALUES ( ?,?,?,?,? )" #@g00036 
	PREPARE pr_ins_contact_channel FROM query_text #@g00037 

	# PREPARE UPDATE statement		                                                                                              	#@G00039
	LET query_text= #@g00040 
	"UPDATE contact_channel ", #@g00041 
	"SET ( contact_seed,valid_from,valid_to )", #@g00042 
	" = ( ?,?,? )", #@g00043 
	" WHERE cc_id = ? 
	AND cc_channel = ? " #@G00045 
	PREPARE pr_upd_contact_channel FROM query_text #@g00046 

	# PREPARE DELETE statement		                                                                                              	#@G00048
	LET query_text= "DELETE FROM contact_channel ", #@g00049 
	" WHERE cc_id = ? 
	AND cc_channel = ? " #@G00051 
	PREPARE pr_del_contact_channel FROM query_text #@g00052 

END FUNCTION #@g00054 

#######################################################################		                                                  	#@G00056
FUNCTION open_crs_contact_channel_sr_array(fky) #@g00057 
	#######################################################################		                                                  	#@G00058
	DEFINE lsql_ok INTEGER #@g00059 
	DEFINE fky RECORD #@g00060 
		contact_seed LIKE contact_channel.contact_seed # BIGINT #@g00061 
	END RECORD #@g00062 

	WHENEVER ERROR CONTINUE #@g00064 
	OPEN crs_child_contact_channel USING fky.* #@g00065 

	WHENEVER ERROR CALL error_mngmt #@g00067 
	CASE #@g00068 
		WHEN sqlca.sqlcode = 100 #@g00069 
			LET lsql_ok = 0 #@g00070 
		WHEN sqlca.sqlcode < 0 #@g00071 
			LET lsql_ok = -1 #@g00072 
		OTHERWISE #@g00073 
			LET lsql_ok = 1 #@g00074 
	END CASE #@g00075 
	RETURN lsql_ok #@g00076 
END FUNCTION #@g00077 

########################################################################		                                                 	#@G00079
## INSERT in table contact_channel 		                                                                                      	#@G00080
########################################################################		                                                 	#@G00081
FUNCTION sql_add_contact_channel(lr_contact_channel) #@g00082 
	DEFINE lr_contact_channel RECORD #@g00083 
		contact_seed LIKE contact_channel.contact_seed, # BIGINT #@g00083 
		cc_id LIKE contact_channel.cc_id, # VARCHAR(64) #@g00083 
		cc_channel LIKE contact_channel.cc_channel, # CHAR(6) #@g00083 
		valid_from LIKE contact_channel.valid_from, # DATE #@g00083 
		valid_to LIKE contact_channel.valid_to # DATE #@g00084 
	END RECORD #@g00085 

	DEFINE lsql_stmt_status INTEGER #@g00087 
	DEFINE lookup_status INTEGER #@g00088 
	DEFINE nb_deleted_rows INTEGER #@g00089 

	WHENEVER ERROR CONTINUE #@g00091 
	EXECUTE pr_ins_contact_channel #@g00092 
	USING lr_contact_channel.contact_seed, #@g00092 
	lr_contact_channel.cc_id, #@g00092 
	lr_contact_channel.cc_channel, #@g00092 
	lr_contact_channel.valid_from, #@g00092 
	lr_contact_channel.valid_to # #@g00093 
	WHENEVER ERROR CALL error_mngmt #@g00094 

	CASE #@g00096 
		WHEN sqlca.sqlcode = 0 #@g00097 
			LET lsql_stmt_status = 0 #@g00098 
		WHEN sqlca.sqlcode < 0 #@g00099 
			CALL display_eric_error("Add contact_channel:failed ") #@g00100 
			LET lsql_stmt_status = -1 #@g00101 
	END CASE #@g00102 
	RETURN lsql_stmt_status #@g00103 
END FUNCTION #@g00104 

########################################################################		                                                 	#@G00106
## SqlModify_contact_channel :UPDATE current contact_channel record		                                                      	#@G00107
########################################################################		                                                 	#@G00108
FUNCTION sql_modify_contact_channel(pky,lr_contact_channel) #@g00109 
	DEFINE lr_contact_channel RECORD #@g00110 
		contact_seed LIKE contact_channel.contact_seed, # BIGINT #@g00110 
		cc_id LIKE contact_channel.cc_id, # VARCHAR(64) #@g00110 
		cc_channel LIKE contact_channel.cc_channel, # CHAR(6) #@g00110 
		valid_from LIKE contact_channel.valid_from, # DATE #@g00110 
		valid_to LIKE contact_channel.valid_to # DATE #@g00111 
	END RECORD #@g00112 
	DEFINE lsql_stmt_status INTEGER #@g00113 
	DEFINE nb_modified_rows INTEGER #@g00114 
	DEFINE pky RECORD #@g00115 
		cc_id LIKE contact_channel.cc_id, # VARCHAR(64) #@g00115 
		cc_channel LIKE contact_channel.cc_channel # CHAR(6) #@g00116 
	END RECORD #@g00117 

	WHENEVER ERROR CONTINUE #@g00119 
	EXECUTE pr_upd_contact_channel #@g00120 
	USING lr_contact_channel.contact_seed, #@g00120 
	lr_contact_channel.valid_from, #@g00120 
	lr_contact_channel.valid_to , #@g00121 
	pky.* #@g00122 

	WHENEVER ERROR CALL error_mngmt #@g00124 
	CASE #@g00125 
		WHEN sqlca.sqlcode = 0 #@g00126 
			LET lsql_stmt_status = 0 #@g00127 
			LET nb_modified_rows = sqlca.sqlerrd[3] #@g00128 
		WHEN sqlca.sqlcode < 0 #@g00129 
			CALL display_eric_error("Modify contact_channel:failed ") #@g00130 
			LET lsql_stmt_status = -1 #@g00131 
			LET nb_modified_rows = 0 #@g00132 
	END CASE #@g00133 
	RETURN lsql_stmt_status,nb_modified_rows #@g00134 
END FUNCTION #@g00135 

########################################################################		                                                 	#@G00137
## delete_contact_channel :delete Selected row in table contact_channel 		                                                 	#@G00138
########################################################################		                                                 	#@G00139
FUNCTION sql_suppress_contact_channel(pky) #@g00140 
	DEFINE lsql_stmt_status SMALLINT #@g00141 
	DEFINE nb_deleted_rows INTEGER #@g00142 
	DEFINE pky RECORD #@g00143 
		cc_id LIKE contact_channel.cc_id, # VARCHAR(64) #@g00143 
		cc_channel LIKE contact_channel.cc_channel # CHAR(6) #@g00144 
	END RECORD #@g00145 

	WHENEVER ERROR CONTINUE #@g00147 
	EXECUTE pr_del_contact_channel USING pky.* #@g00148 

	WHENEVER ERROR CALL error_mngmt #@g00150 
	CASE #@g00151 
		WHEN sqlca.sqlcode = 0 #@g00152 
			LET lsql_stmt_status=0 #@g00153 
			LET nb_deleted_rows = sqlca.sqlerrd[3] #@g00154 
		WHEN sqlca.sqlcode < 0 #@g00155 
			CALL display_eric_error("Suppress contact_channel:failed ") #@g00156 
			LET lsql_stmt_status = -1 #@g00157 
	END CASE #@g00158 

	RETURN lsql_stmt_status,nb_deleted_rows #@g00160 
END FUNCTION #@g00161 

################################################################################		                                         	#@G00163
#   status_pk_contact_channel : Check if primary key exists		                                                              	#@G00164
################################################################################		                                         	#@G00165
FUNCTION status_pk_contact_channel(pky) #@g00166 
	# Check primary key		                                                                                                      	#@G00167
	# inbound parameter : record of primary key		                                                                              	#@G00168
	# outbound parameter:  STATUS > 0  if exists, 0 if no record, < 0 if error		                                               	#@G00169
	DEFINE pky RECORD #@g00170 
		cc_id LIKE contact_channel.cc_id, # VARCHAR(64) #@g00170 
		cc_channel LIKE contact_channel.cc_channel # CHAR(6) #@g00171 
	END RECORD #@g00172 
	DEFINE pk_status INTEGER #@g00173 

	WHENEVER ERROR CONTINUE #@g00175 
	OPEN crs_pky_mcontact USING pky.* #@g00176 
	FETCH crs_pky_mcontact #@g00177 
	WHENEVER ERROR CALL error_mngmt #@g00178 

	CASE sqlca.sqlcode #@g00180 
		WHEN 0 #@g00181 
			LET pk_status = 1 #@g00182 
		WHEN 100 #@g00183 
			LET pk_status = 0 #@g00184 
		WHEN sqlca.sqlerrd[2] = 104 #@g00185 
			LET pk_status = -1 # RECORD locked #@g00186 
		WHEN sqlca.sqlcode < 0 #@g00187 
			LET pk_status = sqlca.sqlcode #@g00188 
	END CASE #@g00189 
	RETURN pk_status #@g00190 
END FUNCTION #@g00191 

#@G00193

#######################################################################		                                                  	#@G00195
FUNCTION initialize_array_contact_channel() #@g00196 
	#######################################################################		                                                  	#@G00197
	# INITIALIZEs arrays		                                                                                                    	#@G00198
	CALL contact_channel_sr_array.clear() #@g00199 
	CALL contact_channel_pky_array.clear() #@g00200 
	CALL contact_channel_status_array.clear() #@g00201 
END FUNCTION #@g00202 

#######################################################################		                                                  	#@G00204
FUNCTION display_array_contact_channel (fky,browse) #@g00205 
	#######################################################################		                                                  	#@G00206
	DEFINE elem_num,choice,xpos,ypos INTEGER #@g00207 
	DEFINE arrcurr,srcline INTEGER #@g00208 
	DEFINE sql_ok INTEGER #@g00209 
	DEFINE qbe_stmt CHAR(1000) #@g00210 
	DEFINE browse boolean #@g00211 
	DEFINE where_clause CHAR(64) #@g00212 
	DEFINE fky RECORD #@g00213 
		contact_seed LIKE contact_channel.contact_seed # BIGINT #@g00214 
	END RECORD #@g00215 
	DEFINE sql_stmt_status INTEGER #@g00216 

	CALL initialize_array_contact_channel() #@g00218 
	# Display empty array		                                                                                                   	#@G00219
	CALL set_count(100) #@g00220 
	INPUT ARRAY contact_channel_sr_array WITHOUT DEFAULTS #@g00221 
	FROM sr_contact_channel.* #@g00222 
		BEFORE INPUT #@g00223 
			CALL fgl_dialog_setkeylabel ("accept","","") #@g00224 
		BEFORE ROW #@g00225 
			# display array AND exits immediately		                                                                                  	#@G00226
			EXIT INPUT #@g00227 
	END INPUT #@g00228 

	# opening array CURSOR		                                                                                                  	#@G00230
	LET sql_ok = open_crs_contact_channel_sr_array(fky.*) #@g00231 

	LET elem_num = 1 #@g00233 
	FOREACH crs_child_contact_channel INTO contact_channel_pky_array[elem_num].*,contact_channel_sr_array[elem_num].* #@g00234 
		LET contact_channel_status_array[elem_num] = 0 # elements exists #@g00235 
		LET elem_num = elem_num + 1 #@g00236 
	END FOREACH #@g00237 
	LET elem_num = elem_num - 1 #@g00238 

	INPUT ARRAY contact_channel_sr_array WITHOUT DEFAULTS #@g00240 
	FROM sr_contact_channel.* #@g00241 
		BEFORE INPUT #@g00242 
			CALL fgl_dialog_setkeylabel ("INSERT","","") #@g00243 
			CALL fgl_dialog_setkeylabel ("delete","","") #@g00244 
			--CALL fgl_dialog_setkeylabel ("help","","")		                                                                             	#@G00245
			CALL fgl_dialog_setkeylabel ("append","","") #@g00246 
			CALL fgl_dialog_setkeylabel ("cancel","","") #@g00247 
			CALL fgl_dialog_setkeylabel ("find","","") #@g00248 

			IF browse = false THEN #@g00250 
				CALL fgl_dialog_setkeylabel ("accept","","") #@g00251 
				# display array AND exits immediately		                                                                                 	#@G00252
				EXIT INPUT #@g00253 
			END IF #@g00254 

		BEFORE ROW #@g00256 

	END INPUT #@g00258 
	RETURN elem_num #@g00259 

END FUNCTION #@g00261 

FUNCTION edit_array_contact_channel (pky_contact) #@g00263 
	DEFINE srcline INTEGER #@g00264 
	DEFINE arrcurr INTEGER #@g00265 
	DEFINE bulk_update_status SMALLINT #@g00266 
	DEFINE nbr_edited_rows INTEGER #@g00267 
	DEFINE sql_action SMALLINT #@g00268 
	DEFINE i SMALLINT #@g00269 
	DEFINE pky_contact RECORD #@g00270 
		contact_seed LIKE contact.contact_seed # BIGSERIAL #@g00271 
	END RECORD #@g00272 

	BEGIN WORK #@g00273 
		#@G00273
		WHILE true #@g00274 
			CALL input_array_contact_channel (pky_contact.*) RETURNING nbr_edited_rows,sql_action #@g00274 
			#@G00274
			IF nbr_edited_rows > 0 THEN #@g00275 
				CASE #@g00276 
					WHEN sql_action = 2 #@g00277 
						LET bulk_update_status = array_bulk_update_contact_channel () #@g00278 
						IF bulk_update_status < 0 THEN #@g00279 
							ROLLBACK WORK #@g00279 
							#@G00279
							ERROR "input_array_ failed" #@g00280 
						ELSE #@g00281 
							ERROR "input_array_ Successful operation" #@g00282 
						COMMIT WORK #@g00282 
						#@G00282
						EXIT WHILE #@g00283 
					END IF #@g00284 
					WHEN sql_action = 1 #@g00285 
						# No		                                                                                                                 	#@G00286
						ERROR "Please INPUT ARRAY AGAIN" #@g00287 
					WHEN sql_action = 0 #@g00288 
						# Cancel		                                                                                                             	#@G00289
						MESSAGE "Cancelled, EXIT INPUT ARRAY" #@g00290 
						EXIT WHILE #@g00291 
				END CASE #@g00292 
			ELSE #@g00293 
				# Nothing		                                                                                                             	#@G00294
				MESSAGE "Nothing has been changed" #@g00295 
				EXIT WHILE #@g00296 
			END IF #@g00297 
		END WHILE #@g00298 

END FUNCTION #@g00300 

############################################################		                                                             	#@G00302
FUNCTION input_array_contact_channel (pky_contact) #@g00303 
	############################################################		                                                             	#@G00304
	DEFINE arrcnt INTEGER #@g00305 
	DEFINE srcline INTEGER #@g00306 
	DEFINE arrcurr INTEGER #@g00307 
	DEFINE last_element INTEGER #@g00308 
	DEFINE lookup_status INTEGER #@g00309 
	DEFINE sql_stmt_status INTEGER #@g00310 
	DEFINE nbr_edited_rows INTEGER #@g00311 
	DEFINE sql_action SMALLINT #@g00312 
	DEFINE ins_key SMALLINT #@g00313 
	DEFINE pky_contact RECORD #@g00314 
		contact_seed LIKE contact.contact_seed # BIGSERIAL #@g00315 
	END RECORD #@g00316 
	DEFINE sav_contact_channel_sr_array RECORD #@g00317 
		cc_channel LIKE contact.sex_ind, # CHAR(6) #@g00317 
		cc_id LIKE contact.sex_ind, # VARCHAR(64) #@g00317 
		valid_from LIKE contact.sex_ind, # DATE #@g00317 
		valid_to LIKE contact.sex_ind # DATE #@g00318 
	END RECORD #@g00319 

	DEFINE sql_ok SMALLINT #@g00321 
	LET nbr_edited_rows = 0 #@g00322 

	#OPTIONS		                                                                                                                 	#@G00324
	#	accept key f17,		                                                                                                        	#@G00325
	#	DELETE KEY f16,		                                                                                                        	#@G00326
	#	INSERT KEY f15,		                                                                                                        	#@G00327
	#	previous key f14,		                                                                                                      	#@G00328
	#	next key f18		                                                                                                           	#@G00329

	LET int_flag = false #@g00331 
	LET ins_key = false #@g00332 

	INPUT ARRAY contact_channel_sr_array WITHOUT DEFAULTS #@g00334 
	FROM sr_contact_channel.* #@g00335 
	attribute(normal) #@g00336 
		ON KEY (INTERRUPT) #@g00337 
			# Cancel FROM input		                                                                                                    	#@G00338
			LET int_flag=false #@g00339 
			LET arrcurr = arr_curr() #@g00340 
			LET srcline = scr_line () #@g00341 
			LET contact_channel_sr_array[arrcurr].* = sav_contact_channel_sr_array.* #@g00342 
			DISPLAY contact_channel_sr_array[arrcurr].* TO sr_contact_channel[srcline].* #@g00343 
			MESSAGE "Quit with quit key Control-C" #@g00344 
			ROLLBACK WORK #@g00344 
			#@G00344
			EXIT INPUT #@g00345 

		BEFORE INSERT #@g00347 
			CALL contact_channel_pky_array.insert(arrcurr) #@g00348 
			CALL contact_channel_status_array.insert(arrcurr) #@g00349 
			LET contact_channel_status_array[arrcurr] = 1 # TO be INSERT #@g00350 

		AFTER DELETE #@g00352 
			IF contact_channel_status_array[arrcurr] IS NOT NULL THEN #@g00353 
				LET last_element = contact_channel_status_array.getsize() + 1 #@g00354 
				# copy contact_channel_pky_array TO the end of array AND create a contact_channel_status_array = -1		                   	#@G00355
				# Then delete contact_channel_pky_array,contact_channel_status_array for current element 		                             	#@G00356
				CALL contact_channel_sr_array.insert(last_element) #@g00357 
				CALL contact_channel_status_array.insert(last_element) #@g00358 
				LET contact_channel_status_array[last_element] = -1 # TO be deleted #@g00359 
				LET contact_channel_pky_array[last_element].* = contact_channel_pky_array[arrcurr].* #@g00360 
				# Delete current elements		                                                                                             	#@G00361
				CALL contact_channel_pky_array.delete(arrcurr) #@g00362 
				CALL contact_channel_pky_array.delete(arrcurr) #@g00363 
				LET nbr_edited_rows = nbr_edited_rows + 1 #@g00364 
			END IF #@g00365 

		BEFORE ROW #@g00367 
			LET srcline = scr_line() #@g00368 
			LET arrcurr = arr_curr() #@g00369 
			LET sav_contact_channel_sr_array.* = contact_channel_sr_array[arrcurr].* #@g00370 

			#@G00372

			#@G00373

		AFTER ROW #@g00375 
			IF field_touched (sr_contact_channel[srcline].*) THEN #@g00376 
				LET nbr_edited_rows = nbr_edited_rows + 1 #@g00377 
				CASE #@g00378 
					WHEN contact_channel_status_array[arrcurr] = 0 # existing #@g00379 
						LET contact_channel_status_array[arrcurr] = 2 # TO be modified #@g00380 
						LET contact_channel_pky_array[arrcurr].cc_channel = contact_channel_sr_array[arrcurr].cc_channel #@g00380 
						LET contact_channel_pky_array[arrcurr].cc_id = contact_channel_sr_array[arrcurr].cc_id #@g00380 
						#@G00381

					WHEN contact_channel_status_array[arrcurr] IS NULL # new #@g00383 
						LET contact_channel_status_array[arrcurr] = 1 # TO be inserted #@g00384 
						LET contact_channel_pky_array[arrcurr].cc_channel = contact_channel_sr_array[arrcurr].cc_channel #@g00384 
						LET contact_channel_pky_array[arrcurr].cc_id = contact_channel_sr_array[arrcurr].cc_id #@g00384 
						#@G00385
				END CASE #@g00386 
				IF status_pk_contact_channel(contact_channel_pky_array[arrcurr].cc_channel,contact_channel_pky_array[arrcurr].cc_id) THEN #@g00387 
					ERROR "contact_channel: already exists" #@g00388 
					NEXT FIELD valid_to #@g00389 
				END IF #@g00390 
				#@G00391
			END IF #@g00392 

		AFTER INPUT #@g00394 
			IF int_flag THEN #@g00395 
				LET int_flag = false #@g00396 
				ERROR " Cancel contact_channel" #@g00397 
				LET nbr_edited_rows = 0 #@g00398 
				LET sql_action = 0 #@g00399 
			ELSE #@g00400 
				LET sql_action = confirm_operation(5,10,"input_array_ ") #@g00401 
				IF sql_action = 1 THEN #@g00402 
					CONTINUE INPUT #@g00403 
				END IF #@g00404 
			END IF #@g00405 
	END INPUT #@g00406 
	RETURN nbr_edited_rows,sql_action #@g00407 
END FUNCTION #@g00408 

FUNCTION set_form_record_test2_sr_contact_channel(tbl_contents) #@g00410 
	DEFINE fgl_status SMALLINT #@g00411 
	DEFINE frm_contents RECORD #@g00412 
		cc_channel LIKE contact.sex_ind, # CHAR(6) #@g00412 
		cc_id LIKE contact.sex_ind, # VARCHAR(64) #@g00412 
		valid_from LIKE contact.sex_ind, # DATE #@g00412 
		valid_to LIKE contact.sex_ind # DATE #@g00413 
	END RECORD #@g00414 

	DEFINE tbl_contents RECORD #@g00416 
		contact_seed LIKE contact_channel.contact_seed, # BIGINT #@g00416 
		cc_id LIKE contact_channel.cc_id, # VARCHAR(64) #@g00416 
		cc_channel LIKE contact_channel.cc_channel, # CHAR(6) #@g00416 
		valid_from LIKE contact_channel.valid_from, # DATE #@g00416 
		valid_to LIKE contact_channel.valid_to # DATE #@g00417 
	END RECORD #@g00418 

	INITIALIZE frm_contents.* TO NULL #@g00420 
	LET frm_contents.cc_channel = tbl_contact_channel.cc_channel #@g00421 
	LET frm_contents.cc_id = tbl_contact_channel.cc_id #@g00422 
	LET frm_contents.valid_from = tbl_contact_channel.valid_from #@g00423 
	LET frm_contents.valid_to = tbl_contact_channel.valid_to #@g00424 
	#@G00425
	CASE #@g00426 
		WHEN status = 0 #@g00427 
			LET fgl_status = 1 #@g00428 
		WHEN status < 0 #@g00429 
			LET fgl_status = status #@g00430 
		OTHERWISE #@g00431 
			LET fgl_status = status #@g00432 
	END CASE #@g00433 
	RETURN fgl_status,frm_contents.* #@g00434 
END FUNCTION #@g00435 

FUNCTION set_table_record_test2_contact_channel(sql_op,pky,element_contents) #@g00437 
	DEFINE sql_op SMALLINT #@g00438 
	DEFINE fgl_status SMALLINT #@g00439 
	DEFINE element_contents RECORD #@g00440 
		cc_channel LIKE contact_channel.valid_to, # CHAR(6) #@g00440 
		cc_id LIKE contact_channel.valid_to, # VARCHAR(64) #@g00440 
		valid_from LIKE contact_channel.valid_to, # DATE #@g00440 
		valid_to LIKE contact_channel.valid_to # DATE #@g00441 
	END RECORD #@g00442 
	DEFINE pky RECORD #@g00443 
		cc_id LIKE contact_channel.cc_id, # VARCHAR(64) #@g00443 
		cc_channel LIKE contact_channel.cc_channel # CHAR(6) #@g00444 
	END RECORD #@g00445 
	DEFINE tbl_contents RECORD #@g00446 
		contact_seed LIKE contact_channel.contact_seed, # BIGINT #@g00446 
		cc_id LIKE contact_channel.cc_id, # VARCHAR(64) #@g00446 
		cc_channel LIKE contact_channel.cc_channel, # CHAR(6) #@g00446 
		valid_from LIKE contact_channel.valid_from, # DATE #@g00446 
		valid_to LIKE contact_channel.valid_to # DATE #@g00447 
	END RECORD #@g00448 

	WHENEVER ERROR CONTINUE #@g00450 
	INITIALIZE tbl_contents.* TO NULL #@g00451 
	# LET tbl_contents.contact_seed = your value		                                                                             	#@G00452
	IF sql_op = 1 THEN #@g00453 
		LET tbl_contents.cc_id = element_contents.cc_id #@g00454 
	END IF #@g00455 
	IF sql_op = 1 THEN #@g00456 
		LET tbl_contents.cc_channel = element_contents.cc_channel #@g00457 
	END IF #@g00458 
	LET tbl_contents.valid_from = element_contents.valid_from #@g00459 
	LET tbl_contents.valid_to = element_contents.valid_to #@g00460 
	#@G00461
	WHENEVER ERROR CALL error_mngmt #@g00462 
	CASE #@g00463 
		WHEN status = 0 #@g00464 
			LET fgl_status = 1 #@g00465 
		WHEN status < 0 #@g00466 
			LET fgl_status = status #@g00467 
		OTHERWISE #@g00468 
			LET fgl_status = status #@g00469 
	END CASE #@g00470 
	RETURN fgl_status,tbl_contents.* #@g00471 
END FUNCTION #@g00472 

FUNCTION array_bulk_update_contact_channel () #@g00474 
	DEFINE idx,arr_size INTEGER #@g00475 
	DEFINE updarr_status,fgl_status,global_status INTEGER #@g00476 
	DEFINE elements_contents RECORD #@g00477 
		cc_channel LIKE contact_channel.valid_to, # CHAR(6) #@g00477 
		cc_id LIKE contact_channel.valid_to, # VARCHAR(64) #@g00477 
		valid_from LIKE contact_channel.valid_to, # DATE #@g00477 
		valid_to LIKE contact_channel.valid_to # DATE #@g00478 
	END RECORD #@g00479 
	DEFINE l_contact_channel RECORD #@g00480 
		contact_seed LIKE contact_channel.contact_seed, # BIGINT #@g00480 
		cc_id LIKE contact_channel.cc_id, # VARCHAR(64) #@g00480 
		cc_channel LIKE contact_channel.cc_channel, # CHAR(6) #@g00480 
		valid_from LIKE contact_channel.valid_from, # DATE #@g00480 
		valid_to LIKE contact_channel.valid_to # DATE #@g00481 
	END RECORD #@g00482 
	LET global_status = 0 #@g00483 
	LET arr_size = contact_channel_sr_array.getsize() #@g00484 
	FOR idx = 1 TO arr_size #@g00485 
		IF contact_channel_status_array[idx] <> 0 THEN #@g00486 
			IF contact_channel_status_array[idx] > 0 THEN #@g00487 
				LET elements_contents.* = contact_channel_sr_array[idx].* #@g00488 
				CALL set_table_record_test2_contact_channel(contact_channel_status_array[idx],contact_channel_pky_array[idx].*,contact_channel_sr_array[idx].*) #@g00489 
				RETURNING fgl_status,l_contact_channel.* #@g00490 
			END IF #@g00491 
			LET updarr_status = update_one_element_contact_channel(idx,l_contact_channel.*) #@g00492 
			IF updarr_status < 0 THEN #@g00493 
				ERROR "Error on element # ",idx #@g00494 
				LET global_status = global_status + 1 #@g00495 
			END IF #@g00496 
		END IF #@g00497 
	END FOR #@g00498 
	RETURN global_status #@g00499 
END FUNCTION #@g00500 

FUNCTION update_one_element_contact_channel(idx,lr_contact_channel) #@g00502 
	DEFINE st SMALLINT #@g00503 
	DEFINE arrcnt SMALLINT #@g00504 
	DEFINE idx SMALLINT #@g00505 
	DEFINE statut SMALLINT #@g00506 
	DEFINE lr_contact_channel RECORD #@g00507 
		contact_seed LIKE contact_channel.contact_seed, # BIGINT #@g00507 
		cc_id LIKE contact_channel.cc_id, # VARCHAR(64) #@g00507 
		cc_channel LIKE contact_channel.cc_channel, # CHAR(6) #@g00507 
		valid_from LIKE contact_channel.valid_from, # DATE #@g00507 
		valid_to LIKE contact_channel.valid_to # DATE #@g00508 
	END RECORD #@g00509 
	LET st = 0 #@g00510 
	CASE contact_channel_status_array[idx] #@g00511 
		WHEN 2 # must be updated #@g00512 
			LET statut = sql_modify_contact_channel(contact_channel_pky_array[idx].*,lr_contact_channel.*) #@g00513 
		WHEN 1 #@g00514 
			LET statut = sql_add_contact_channel(lr_contact_channel.*) #@g00515 
		WHEN -1 #@g00516 
			LET statut = sql_suppress_contact_channel(contact_channel_pky_array[idx].*) #@g00517 
			#OTHERWISE		                                                                                                              	#@G00518
			#CONTINUE FOR		                                                                                                          	#@G00519
	END CASE #@g00520 
	RETURN statut #@g00521 
END FUNCTION #@g00522 


-----------------------------------------------------------------------------------------------------------------------------------------------------------------			#@G00525

