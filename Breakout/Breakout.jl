using Colors

#---------------From hand_server.jl-------------
#Seems like the Gamezero framework prevents usage of include....
#include("hand_control/hand_server.jl")
using Sockets

hand_control_socket = nothing
function spawn_hand_control_server()
	#t = Threads.@spawn 
    create_hand_server()
	#rm("data.txt")
	#wait(t)
end

function create_hand_server()
    #write("data.txt", "ok, started")
	port = 50000
	server = listen(port)

    global hand_control_socket
    hand_control_socket = accept(server)
    println("Hand control Client connected.")
end
#---------------end From hand_server.jl-------------

WIDTH = 600
HEIGHT = 600
BACKGROUND = colorant"black"
#BALL_SIZE = 10
MARGIN = 50

#[oferw]: Number of bricks on the screen
BRICKS_X = 10
BRICKS_Y = 5

#[oferw]: Single brick sizes
BRICK_W = (WIDTH - 2 * MARGIN) ÷ BRICKS_X
BRICK_H = 25

#[oferw]: For future use
#struct Bat
#    rect::Rect
#end

mutable struct Player
    points::Int32
    color::Colorant
    #bat::Bat   #for future use once bat becomes a srtuct
end

function make_player(color = colorant"pink")
    points = 0
    return Player(points, color)
end

mutable struct Ball
    circ::Circle
    velocity::Tuple{Float32, Float32}
    color::Colorant
    is_main::Bool
end

function make_ball(color = colorant"white", is_main = true)
    BALL_SIZE = 10
    x_loc = rand(0:WIDTH)
    y_loc = HEIGHT / 2
    return Ball(Circle(x_loc, y_loc, BALL_SIZE/2), (rand(-200:200), 400), color, is_main)
end

function get_points_actor(player::Player)
    return TextActor("Points: " * string(player.points), actors_font, color = Int[255,255,255,255], font_size = 15, x = 3, y = 3)
end

@enum game_winlose_modes begin
    game_mode_play = 0
    game_mode_lose = 1
    game_mode_win = 2
end

mutable struct game_mode
    winlose::game_winlose_modes
    show_score::Bool
end

ball_arr = Ball[]
push!(ball_arr, make_ball())

players_arr = Player[]
push!(players_arr, make_player())

bat = Rect(WIDTH / 2, HEIGHT - 50, 120, 12)

#[the_duke]: The Actor constructor looks for the "images" directory in the current run location. If the game is ran using a runner julia script (to avoid manual REPL commands), then it will use the terminal's director, and not the game's directory, and so the images won't be found, this cd to the game's dir makes the images available.
cd(@__DIR__)
actors_font = "2k4sregular-r1ob"

#[the_duke]: Suggestion: These should be grouped into some win actors struct.
win_pic = Actor("hands_holding_champions_cup.png", position = Rect(100, 50, 400, 400))
win_text = TextActor("Victory!", actors_font, color = Int[255,255,0,255], font_size = 80, x = 160, y = 430)
win_text_any_key = TextActor("Press key 'A' to play again.", actors_font, color = Int[255,0,255,255], font_size = 20, x = 180, y = 550)

@enum vert_modes begin
    vert_off = 0
    vert_immediate = 1
    vert_sliding = 2
end

bat_vert_mode = vert_off
is_hand_control = false

curr_game_modes::game_mode = game_mode(game_mode_play, false)

bricks = []

struct Brick
    brick::Rect
    brick_color::Colorant
    highlight_color::Colorant
    points_value::Int32
end

function reset()
    deleteat!(bricks, 1:length(bricks))
    for x in 1:BRICKS_X
        for y in 1:BRICKS_Y
            hue = (x + y - 2) / BRICKS_X
            saturation = ( (y-1) / BRICKS_Y) * 0.5 + 0.5
            brick_color = HSV(hue*360, saturation, 0.8)
            highlight_color = HSV(hue*360, saturation * 0.7, 1.0)
            #[duke]: feature suggestion: points should be upgraded to be different per color, and be shown when the brick is hit
            points_value = 5
            brick = Brick( Rect(
                ((x-1) * BRICK_W + MARGIN, (y-1) * BRICK_H + MARGIN),
                (BRICK_W - 1, BRICK_H - 1)
            ), brick_color, highlight_color, points_value)
            push!(bricks, brick)
        end
    end

    global ball_arr
    empty!(ball_arr)
    push!(ball_arr, make_ball())

    global players_arr
    players_arr[1].points = 0

    #i = 1
    #ball_arr[i].circ.center = (WIDTH / 2, HEIGHT / 3)
    #ball_arr[i].velocity = (rand(-200:200), 400)

    #ball = (WIDTH / 2, HEIGHT / 3)  #should be centre
    #ball_vel = (rand(-200:200), 400)
    
    #[the_duke]: DEBUG override
    #ball.center = (100, 0)
    #global ball_vel = (200, 400)
end

reset()

function draw(g::Game)
    clear()
    global curr_game_modes

    if curr_game_modes.winlose == game_mode_win
        draw(win_pic)
        draw(win_text)
        draw(win_text_any_key)
    else
        for b in bricks
            draw(b.brick, b.brick_color, fill = true)
            draw(Line(b.brick.bottomleft, b.brick.topleft), b.highlight_color)
            draw(Line(b.brick.topleft, b.brick.topright), b.highlight_color)
        end

        global players_arr

        draw(bat, players_arr[1].color, fill = true)

        for ball in ball_arr
            draw(ball.circ, ball.color, fill = true)
        end

        if curr_game_modes.show_score
            draw(get_points_actor(players_arr[1]))
        end
    end
end

speed = 1
hand_data = nothing
function update(g::Game)
    global curr_game_modes

    if curr_game_modes.winlose == game_mode_win
        #println("win!")
        #win_pic.x = 10
    else
        global ball_arr
        global players_arr
        # When you have fast moving objects, like the ball, a good trick
        # is to run the update step several times per frame with tiny time steps.
        # This makes it more likely that collisions will be handled correctly.
        for _ in 1:3
            update_step(1 / 180, ball_arr, players_arr)
        end 
        
        #--slowed down version for debug--
        # global speed = (speed + 1) % 2
        # if speed == 1
            # update_step(1 / 180)
        # end
        #-------------------------

        global hand_control_socket
        if !isnothing(hand_control_socket)
            #read(hand_control_socket, String)
            
            global hand_data
            #println(hand_data)
            println() #Strangely enough, if this println() is taken off, the socket reading won't work. Stanger: print() won't make it work.
            if isnothing(hand_data)
                @async hand_data = readline(hand_control_socket)
                hand_data = "waiting" #Reading request was ativated, Waiting for hand data reading
            elseif hand_data != "waiting"
                hand_float = parse(Float64, hand_data)
                pixels_to_move = round(WIDTH * hand_float)
                #println(string(bat.centerx) *" + "* string(pixels_to_move))

                #The first hand appearance gives a shocking number, reducing it.
                if pixels_to_move < WIDTH
                    move_bat_by(pixels_to_move, 0) 
                end
                hand_data = nothing #Preparing to send a reading request
            end
                
                #print("["* string(hand_data) *"]\n")
        end
        
        update_bat_vx()
    end
end

function update_step(dt, ball_arr, players_arr)
    for (ball_i, ball) in enumerate(ball_arr)
        #get ball properties
        x, y = ball.circ.center  #should be centre
        vx, vy = ball.velocity
        
        #check game over
        if ball.circ.top > HEIGHT
            if ball.is_main
                reset()
            else
                deleteat!(ball_arr, ball_i)
            end

            return
        end
        
        #perform step
        x += vx * dt
        y += vy * dt
        ball.circ.center = (x, y)  #should be centre
        
        # ==check velocity changes==
        
        #side border collisions
        if ball.circ.left < 0
            vx = -vx
            ball.circ.left = -ball.circ.left
        elseif ball.circ.right > WIDTH
            vx = -vx
            ball.circ.right += -(2 * (ball.circ.right - WIDTH))
        end

        #top border collision
        if ball.circ.top < 0
            vy = -vy
            ball.circ.top = ball.circ.top * -1
        end
        
        if collide(ball.circ, bat)
            vy = -abs(vy)
            vx += 170 * bat_vx
            
            #Excessive speed protection
            if(abs(vx) > 200)
                vx = sign(vx) * 200
            end
        else
            collisions = [collide(ball.circ, b.brick) for b in bricks]
            idx = findfirst(x->x == true, collisions)
            
            if idx ≠ nothing
                b = bricks[idx]
                
                #[the_duke]: This bug was fixed around 2022, but there is no strong case to change back the code. Anyway Leaving this comment as a historical reference: note, rect's centerx gives the middle between topright x and (0,0), which is not really the rect center. bottomleft is also not aligned with the other rect corners, and does not give the absolute coordinates, but rather the coordinates relative to topleft. These seem to be bugs in gamezero.
                #println("topleft"* string(b.brick.topleft) *", topright:"* string(b.brick.topright) *", bottomleft:"* string(b.brick.bottomleft) *", boottomright:"* string(b.brick.bottomright) *", width: "* string(BRICK_W) *", height: "* string(BRICK_H) *", centerx:"* string(b.brick.centerx))
                # println("if abs("* string(ball_arr[i].circ.centerx) *" - ("* string(b.brick.topleft[1]) *" + "* string(b.brick.centerx) *")) < "* string(BRICK_W/2))
                # println("if abs("* string(ball_arr[i].circ.centerx) *" - "* string(b.brick.topleft[1] + b.brick.centerx) *") < "* string(BRICK_W/2))
                # println("if abs("* string(ball_arr[i].circ.centerx - (b.brick.topleft[1] + b.brick.centerx)) *") < "* string(BRICK_W/2))
                if ball.circ.centerx >= b.brick.topleft[1] && ball.circ.centerx <= b.brick.topright[1]
                    vy = -vy
                else
                    vx = -vx
                end
                
                #points frozen when not shown
                if curr_game_modes.show_score
                    players_arr[1].points += b.points_value
                end

                deleteat!(bricks, idx)

                if length(bricks) == 0
                    global curr_game_modes.winlose = game_mode_win
                end
            end
        end
        #println("vx after "* string(vx))
        ball.velocity = (vx, vy)
    end
end

bat_recent_vxs = []
bat_vx = 0
bat_prev_centerx = bat.centerx

function update_bat_vx()
    global bat_prev_centerx
    dx = bat.centerx - bat_prev_centerx
    bat_prev_centerx = bat.centerx
    
    global bat_recent_vxs
    
    if length(bat_recent_vxs) >= 5
        popfirst!(bat_recent_vxs)
    end
    push!(bat_recent_vxs, dx)
    vx = sum(bat_recent_vxs) / length(bat_recent_vxs)
    
    #Limiting the bat fraction power on the ball
    global bat_vx = min(10, max(-10, vx))
end

function on_key_down(g::Game, key)
    global bat_vert_mode
    global curr_game_modes

    if curr_game_modes.winlose == game_mode_play

        #[the_duke]: for victory mode debugging
        #if key == GameZero.Keys.I
        #    game_mode.winlose = game_mode_win
        #end
        
        #Flying bar cheat
        if key == GameZero.Keys.UP
            bat_vert_mode = vert_immediate
        elseif key == GameZero.Keys.DOWN
            bat_vert_mode = vert_off
        elseif key == GameZero.Keys.W
            widen_by::Int32 = 5
            global bat = Rect(bat.left - widen_by, bat.top, bat.w + widen_by*2, 12)
        elseif key == GameZero.Keys.Q
            unwiden_by::Int32 = 3
            global bat = Rect(bat.left + unwiden_by, bat.top, bat.w - unwiden_by*2, 12)
        elseif key == GameZero.Keys.S
            curr_game_modes.show_score = !curr_game_modes.show_score
        elseif key == GameZero.Keys.H
            global is_hand_control
            if !is_hand_control
                println("EASTER EGG: Hand control activated.")
                curr_path = pwd()
                #Running the hand client first since it takes time before failing
                run(`cmd /k py $curr_path/hand_control/hand_control.py`, wait=false)
                create_hand_server()
                is_hand_control = true
            end
        elseif key == GameZero.Keys.B
            global ball_arr
            push!(ball_arr, make_ball(colorant"yellow", false))
        end
    elseif curr_game_modes.winlose == game_mode_win && key == GameZero.Keys.A
        reset()
        curr_game_modes.winlose = game_mode_play
    end
end

function on_mouse_move(g::Game, pos)
    x, y = pos
    bat.centerx = x

    move_bat_to(x, y)
end

function move_bat_by(x, y)
    move_bat_to(bat.centerx + x, bat.centery + y)
end

function move_bat_to(x, y)
    global bat_vert_mode

    bat.centerx = x

    if bat_vert_mode == vert_immediate
        bat.centery = y
    end

    if bat.left < 0
        bat.left = 0
    elseif bat.right > WIDTH
        bat.right = WIDTH
    end
end