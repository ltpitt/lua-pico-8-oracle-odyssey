pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
game = {
    states = {
        splash = 1,
        game = 2,
        gameover = 3
    },
    state = 1,
    score = 0,
    game_over = false,
    obstacle_count = 0,
    obstacle_timer = 0,
    obstacle_interval = 60,
    debug = true
}

player = {
    x = 16,
    y = 88,
    width = 8,
    height = 8,
    dy = 0,
    jump_strength = -3,
    gravity = 0.2,
    jump_count = 0,
    max_jumps = 1,
    double_jump_enabled = false,
    double_jump_timer = 0,
    double_jump_duration = 300,
    sprite = 1,
    anim_timer = 0,
    anim_speed = 0.2,
    anim_frames = {0,1,2,3,4},
    jump_frames = {5},
    state = "walking"
}

obstacles = {}
power_ups = {}
screen_size = 128
ground_offset = 0

function _init()
    cls()
    game.state = game.states.splash
end

function _init_game()
    player.y = 88
    player.dy = 0
    player.jump_count = 0
    obstacles = {}
    game.score = 0
    game.game_over = false
    player.double_jump_enabled = false
    player.double_jump_timer = 0
    player.max_jumps = 1
    game.obstacle_count = 0
end

function _update60()
    if game.state == game.states.splash then   
        update_splash()
    elseif game.state == game.states.game then
        update_game() 
    elseif game.state == game.states.gameover then
        update_gameover()
    end
end

function _draw()
    cls()
    if game.debug then
        draw_border()
        draw_debug_info()
    end
    if game.state == game.states.splash then   
        draw_splash()
    elseif game.state == game.states.game then
        draw_game()
        if game.debug then
            draw_debug_info()
        end
    elseif game.state == game.states.gameover then
        draw_gameover()
    end
end

function add_obstacle()
    local obstacle_y = 88
    local obstacle_height = 8
    local obstacle_width = 8
    local obstacle_dy = 0

    local random_value = rnd(1)
    local level = get_current_level()

    if level == 1 then
        obstacle_height = 8
        obstacle_width = 8
    elseif level == 2 then
        if random_value < 0.1 then
            obstacle_height = 16
        elseif random_value < 0.2 then
            obstacle_width = 16
        end
    elseif level == 3 then
        if random_value < 0.1 then
            obstacle_height = 16
            obstacle_width = 16
        elseif random_value < 0.3 then
            obstacle_height = 16
        elseif random_value < 0.5 then
            obstacle_width = 16
        end
    elseif level == 4 then
        if random_value < 0.1 then
            obstacle_height = 16
            obstacle_width = 16
        elseif random_value < 0.3 then
            obstacle_height = 16
        elseif random_value < 0.5 then
            obstacle_width = 16
        end
    elseif level == 5 then
        obstacle_dy = 0.7
        local starting_height = flr(rnd(2)) + 1
        if(starting_height) == 1 then
            obstacle_y = 80
        else
            obstacle_y = 60
        end 
        if random_value < 0.5 then
            obstacle_height = 16
        end
    else
        if random_value < 0.05 then
            obstacle_height = 16
            obstacle_width = 16
        elseif random_value < 0.25 then
            obstacle_height = 16
        elseif random_value < 0.45 then
            obstacle_width = 16
        end
    end

    add(obstacles, {x = 128, y = obstacle_y - obstacle_height + 8, width = obstacle_width, height = obstacle_height, dy = obstacle_dy})
    game.obstacle_count = game.obstacle_count + 1
end

function add_power_up()
    local power_up_y = 70 - rnd(10)
    add(power_ups, {x = 128, y = power_up_y, width = 8, height = 8})
end

function update_game()
    if not game.game_over then
        update_player()
        update_obstacles()
        update_power_ups()
        check_collisions()
        update_ground()
    else
        if btnp(4) then
            _init()
        end
    end
end

function update_splash()
    if btnp(4) then 
        change_state(game.states.game)
    end
end

function update_player()
    if btnp(4) and player.jump_count < player.max_jumps then
        player.dy = player.jump_strength
        player.jump_count = player.jump_count + 1
        player.state = "jumping"
        player.anim_timer = 0
    end

    player.dy = player.dy + player.gravity
    player.y = player.y + player.dy

    if player.y > 88 then
        player.y = 88
        player.dy = 0
        player.jump_count = 0
        player.state = "walking"
        -- do not reset anim_timer here
    end
end

function update_obstacles()
    game.obstacle_timer = game.obstacle_timer + 1
    if game.obstacle_timer > game.obstacle_interval then
        add_obstacle()
        if rnd(1) < 0.1 then
            add_power_up()
        end
        game.obstacle_timer = 0
        game.obstacle_interval = 30 + rnd(60)
    end

    for obstacle in all(obstacles) do
        obstacle.x = obstacle.x - 2
        if get_current_level() == 5 then
            obstacle.y = obstacle.y + obstacle.dy
            if obstacle.y < 50 or obstacle.y > 88 then
                obstacle.dy = -obstacle.dy
            end
        end
        if obstacle.x < -8 then
            del(obstacles, obstacle)
            game.score = game.score + 1
        end
    end
end

function update_power_ups()
    for power_up in all(power_ups) do
        power_up.x = power_up.x - 2
        if power_up.x < -8 then
            del(power_ups, power_up)
        elseif player.x < power_up.x + power_up.width and
               player.x + player.width > power_up.x and
               player.y < power_up.y + power_up.height and
               player.y + player.height > power_up.y then
            collect_power_up()
            del(power_ups, power_up)
        end
    end
    decrease_power_up_timer()
end

function update_ground()
    ground_offset = (ground_offset - 2) % screen_size
end

function update_gameover()
    if btnp(4) then
        change_state(game.states.splash)
    end
end

function draw_game()
    draw_ground()
    draw_player()
    draw_obstacles()
    draw_power_ups()
    draw_score()
    draw_power_up_timer()
end

function draw_ground()
    for i = 0, screen_size / 8 do
        local x = (i * 8 + ground_offset) % screen_size
        line(x, 97, x + 4, 97, 5)
    end
end

function draw_player()
    player.anim_timer = player.anim_timer + player.anim_speed
    local frames = player.anim_frames

    if player.state == "jumping" then
        frames = player.jump_frames
    end

    if player.anim_timer >= #frames then
        player.anim_timer = 0
    end

    player.sprite = frames[flr(player.anim_timer) + 1]
    spr(player.sprite, player.x, player.y)
end

function draw_obstacles()
    for obstacle in all(obstacles) do
        rectfill(obstacle.x, obstacle.y, obstacle.x + obstacle.width, obstacle.y + obstacle.height, 9)
    end
end

function draw_power_ups()
    for power_up in all(power_ups) do
        spr(16, power_up.x, power_up.y)
    end
end

function draw_score()
    print("score: "..game.score, 1, 1, 7)
end

function draw_power_up_timer()
    if player.double_jump_enabled then
        local timer_text = "double jump: " ..convert_frames_to_seconds(player.double_jump_timer)
        print(timer_text, screen_size - (#timer_text * 4) - 1, 1, 12)
    end
end

function draw_gameover()
    print("game over!", 48, 20, 8)
    print("press z to continue", 32, 30, 8)
end

function draw_splash() 
    rectfill(0, 0, screen_size, screen_size, 11)
    local text = "press z to start"
    write(text, text_x_pos(text), 52, 7)
end

function draw_border()
    rect(0, 0, screen_size - 1, screen_size - 1, 8)
end

function draw_debug_info()
    print("level: "..get_current_level(), 1, 10, 11)
end

function handle_player_input()
    if btnp(4) and player.jump_count < player.max_jumps then
        player.dy = player.jump_strength
        player.jump_count = player.jump_count + 1
        player.state = "jumping"
        player.anim_timer = 0
   end
end

function apply_gravity()
    player.dy = player.dy + player.gravity
    player.y = player.y + player.dy

    if player.y > 88 then
        player.y = 88
        player.dy = 0
        player.jump_count = 0
        player.state = "walking"
        player.anim_timer = 0
    end
end

function check_collisions()
    for obstacle in all(obstacles) do
        if player.x < obstacle.x + obstacle.width and
           player.x + player.width > obstacle.x and
           player.y < obstacle.y + obstacle.height and
           player.y + player.height > obstacle.y then
            game.game_over = true
            change_state(game.states.gameover)
        end
    end
end

function get_current_level()
    if game.obstacle_count < 5 then
        return 1
    elseif game.obstacle_count < 15 then
        return 2
    elseif game.obstacle_count < 30 then
        return 3
    elseif game.obstacle_count < 50 then
        return 4
    elseif game.obstacle_count < 75 then
        return 5
    else
        return 6
    end
end

function collect_power_up()
    player.double_jump_enabled = true
    player.double_jump_timer = player.double_jump_duration
    player.max_jumps = 2
end

function decrease_power_up_timer()
    if player.double_jump_enabled then
        draw_power_up_timer()
        player.double_jump_timer = player.double_jump_timer - 1
        if player.double_jump_timer <= 0 then
            player.double_jump_enabled = false
            player.max_jumps = 1
        end
    end
end

function change_state(new_state)
    game.state = new_state
    if game.state == game.states.game then
        _init_game()
    end
end

function convert_frames_to_seconds(frames)
    return ceil(frames / 60)
end

function text_x_pos(text)
    local letter_width = 4
    local width = #text * letter_width
    if width > screen_size then 
        return 0 
    end 
    return screen_size / 2 - flr(width / 2)
end

function write(text, x, y, color) 
    for i = 0, 2 do
        for j = 0, 2 do
            print(text, x + i, y + j, 0)
        end
    end
    print(text, x + 1, y + 1, color)
end 

function mod_zero(a, b)
   return a - flr(a / b) * b == 0
end
__gfx__
00000000000000000088888000888880000000000088888000000000000000000000000000000000000000000000000000000000000000000000000000000000
00888880008888800844444008444440008888800844444000000000000000000000000000000000000000000000000000000000000000000000000000000000
08444440084444400841441008414410084444408041441000000000000000000000000000000000000000000000000000000000000000000000000000000000
08414410084144100824442088244420084144108024442000000000000000000000000000000000000000000000000000000000000000000000000000000000
08244420082444208002220000022200082444200002220000000000000000000000000000000000000000000000000000000000000000000000000000000000
00022200000222000009994000499900800222000049994000000000000000000000000000000000000000000000000000000000000000000000000000000000
00099900000999400040000000000040004999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00040400000400000000000000000000000000400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00042000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00666d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000dd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0066dd00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
061111d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6888222d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
62222225000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0d555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
