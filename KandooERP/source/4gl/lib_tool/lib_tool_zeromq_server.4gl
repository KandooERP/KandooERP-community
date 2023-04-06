FUNCTION send_msg_zmq_to_server(p_type,p_message) 
	DEFINE p_type STRING 
	DEFINE p_message STRING 

	DEFINE context zmq.context 
	DEFINE requester zmq.socket 
	DEFINE request, reply STRING 
	DEFINE requestnbr int 

	# Socket TO talk TO server
	DISPLAY "Connecting TO hello world server..." 

	LET requester = context.Socket("ZMQ.REQ") 
	CALL requester.connect("tcp://localhost:5556") 

	FOR requestnbr = 0 TO 10 
		LET request = "Hello" 
		DISPLAY "Sending Hello ", requestnbr 
		CALL requester.send(request) 

		LET reply = requester.recv() 
		DISPLAY "Received ", reply clipped, " ", requestnbr 
	END FOR 

	CALL requester.close() 
	CALL context.term() 

END FUNCTION 
