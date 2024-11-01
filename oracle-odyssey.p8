-- Game states
game_states = {
    splash = 1,
    game = 2,
    gameover = 3
}

-- Initial state
state = game_states.splash

-- Player variables
player = {
    x = 16,
    y = 64,
    width = 8,
    height = 8,
    dy = 0,
    jump_strength = -3,
    gravity = 0.2
}

-- Obstacle variables
obstacles = {}
obstacle_timer = 0
obstacle_interval = 60

-- Game variables
score = 0
game_over = false

function _init()
    cls()
    state = game_states.splash
end

function _update()
    if state == game_states.splash then   
        update_splash()
    elseif state == game_states.game then
        update_game() 
    elseif state == game_states.gameover then
        update_gameover()
    end
end

function _draw()
    cls()
    if state == game_states.splash then   
        draw_splash()
    elseif state == game_states.game then
        draw_game()
    elseif state == game_states.gameover then
        draw_gameover()
    end
end

-- SPLASH

function update_splash()
    if btnp(4) then 
        change_state(game_states.game)
    end
end

function draw_splash() 
    rectfill(0, 0, SCREEN_SIZE, SCREEN_SIZE, 11)
    local text = "Press Z to Start"
    write(text, text_x_pos(text), 52, 7)
end

-- GAME

function update_game()
    if not game_over then
        handle_player_input()
        apply_gravity()
        update_obstacles()
        check_collisions()
    else
        if btnp(4) then
            _init()
        end
    end
end

function draw_game()
    draw_player()
    draw_obstacles()
    draw_score()
end

function handle_player_input()
    if btnp(4) and player.y == 64 then
        player.dy = player.jump_strength
    end
end

function apply_gravity()
    player.dy = player.dy + player.gravity
    player.y = player.y + player.dy

    if player.y > 64 then
        player.y = 64
        player.dy = 0
    end
end

function update_obstacles()
    obstacle_timer = obstacle_timer + 1
    if obstacle_timer > obstacle_interval then
        add(obstacles, {x = 128, y = 64, width = 8, height = 8})
        obstacle_timer = 0
    end

    for obstacle in all(obstacles) do
        obstacle.x = obstacle.x - 2
        if obstacle.x < -8 then
            del(obstacles, obstacle)
            score = score + 1
        end
    end
end

function check_collisions()
    for obstacle in all(obstacles) do
        if player.x < obstacle.x + obstacle.width and
           player.x + player.width > obstacle.x and
           player.y < obstacle.y + obstacle.height and
           player.y + player.height > obstacle.y then
            game_over = true
            change_state(game_states.gameover)
        end
    end
end

function draw_player()
    rectfill(player.x, player.y, player.x + player.width, player.y + player.height, 7)
end

function draw_obstacles()
    for obstacle in all(obstacles) do
        rectfill(obstacle.x, obstacle.y, obstacle.x + obstacle.width, obstacle.y + obstacle.height, 9)
    end
end

function draw_score()
    print("score: "..score, 1, 1, 7)
end

-- GAME OVER

function update_gameover()
    if btnp(4) then
        change_state(game_states.splash)
    end
end

function draw_gameover()
    print("Game Over!", 48, 20, 8)
    print("Press Z to Restart", 32, 30, 8)
end

-- Utils

-- Change this if you use a different resolution like 64x64
SCREEN_SIZE = 128

-- Calculate center position in X axis
-- This is assuming the text uses the system font which is 4px wide
function text_x_pos(text)
    local letter_width = 4

    -- First calculate how wide is the text
    local width = #text * letter_width
    
    -- If it's wider than the screen then it's multiple lines so we return 0 
    if width > SCREEN_SIZE then 
        return 0 
    end 

    return SCREEN_SIZE / 2 - flr(width / 2)
end

-- Prints black bordered text
function write(text, x, y, color) 
    for i = 0, 2 do
        for j = 0, 2 do
            print(text, x + i, y + j, 0)
        end
    end
    print(text, x + 1, y + 1, color)
end 

-- Returns if module of a/b == 0. Equals to a % b == 0 in other languages
function mod_zero(a, b)
   return a - flr(a / b) * b == 0
end

-- Change state function
function change_state(new_state)
    state = new_state
    if state == game_states.game then
        _init_game()
    end
end

-- Initialize game state
function _init_game()
    player.y = 64
    player.dy = 0
    obstacles = {}
    score = 0
    game_over = false
end
