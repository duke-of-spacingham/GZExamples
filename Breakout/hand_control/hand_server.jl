using Sockets

function spawn_hand_control_server(sock, bat)
	t = Threads.@spawn create_hand_srver(sock, bat)
	#rm("data.txt")
	#wait(t)
end

function create_hand_server(sock, bat)
	port = 50000
	server = listen(port)
	while true
		sock = accept(server)
		while isopen(sock)
			m = readline(sock)
			if(m != "")
				#print("["* string(m) *"]\n")
				write("data.txt", string(bat.centerx) *" + "* string(m))
				#bat.centerx = bat.centerx + m
			end
		end
	end
end