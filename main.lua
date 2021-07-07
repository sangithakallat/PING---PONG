push = require 'push'
Class = require 'class'
require 'Paddle'
require 'Ball'

WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720

VIRTUAL_WIDTH = 432
VIRTUAL_HEIGHT = 243

-- speed at which we will move our paddle; multiplied by dt in update
PADDLE_SPEED = 200

function love.load()
    
    love.graphics.setDefaultFilter('nearest', 'nearest')
    love.window.setTitle('Pong')
    math.randomseed(os.time())
    smallFont = love.graphics.newFont('retro.ttf', 8)
    fpsFont = love.graphics.newFont('retro.ttf', 8)
    largeFont = love.graphics.newFont('retro.ttf', 16)
    scoreFont = love.graphics.newFont('font.ttf', 32)

    love.graphics.setFont(smallFont)
    sounds = {
        ['paddle_hit'] = love.audio.newSource('sounds/ping.mp3', 'static' ),
        ['score'] = love.audio.newSource('sounds/score.wav', 'static'),
        ['wall_hit'] =  love.audio.newSource('sounds/bounce.mp3', 'static')
    }-- called either by sounds.score or sounds['score'] to execute sounds.score:play()
    push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
        fullscreen = true,
        resizable = false,
        vsync = true
    })
    player1Score = 0
    player2Score = 0

    servingPlayer = 1

    player1 = Paddle(10, 30, 5, 30)
    player2 = Paddle(VIRTUAL_WIDTH - 10, VIRTUAL_HEIGHT - 30, 5, 30)
    ball = Ball(VIRTUAL_WIDTH / 2 - 2, VIRTUAL_HEIGHT / 2 - 2, 4, 4)

    gameState = 'start'
    love.graphics.setBackgroundColor(0, 1, 0)
end

function love.resize(w, h)
	push:resize(w,h)
end

function love.update(dt)
    if gameState == 'serve' then
        love.graphics.setBackgroundColor(0, 1, 0)
        -- before switching to play, initialize ball's velocity based
        -- on player who last scored
        ball.dy = math.random(-50, 50)
        if servingPlayer == 1 then
            ball.dx = math.random(140, 200)
        else
            ball.dx = -math.random(140, 200)
        end
    elseif gameState == 'play' then
        love.graphics.setBackgroundColor(0, 1, 0)
        -- detect ball collision with paddles, reversing dx if true and
        -- slightly increasing it, then altering the dy based on the position of collision
        if ball:collides(player1) then
            sounds.paddle_hit:play()
            ball.dx = -ball.dx * 1.03
            ball.x = player1.x + 5

            -- keep velocity going in the same direction, but randomize it
            if ball.dy < 0 then
                ball.dy = -math.random(10, 150)
            else
                ball.dy = math.random(10, 150)
            end
        end
        if ball:collides(player2) then
            sounds.paddle_hit:play()
            ball.dx = -ball.dx * 1.03
            ball.x = player2.x - 4

            -- keep velocity going in the same direction, but randomize it
            if ball.dy < 0 then
                ball.dy = -math.random(10, 150)
            else
                ball.dy = math.random(10, 150)
            end
        end

        -- detect upper and lower screen boundary collision and reverse if collided
        if ball.y <= 0 then
            sounds.wall_hit:play()
            ball.y = 0
            ball.dy = -ball.dy
        end

        -- -4 to account for the ball's size
        if ball.y >= VIRTUAL_HEIGHT - 4 then
            sounds.wall_hit:play()
            ball.y = VIRTUAL_HEIGHT - 4
            ball.dy = -ball.dy
        end
        if ball.x < 0 then
        	sounds.score:play()
            servingPlayer = 1
            player2Score = player2Score + 1

            if player2Score == 10 then 
                winningPlayer = 2
                gameState = 'done'
            
            else
                gameState = 'serve'
                ball:reset()
            end
        end  
        if ball.x > VIRTUAL_WIDTH then
        	sounds.score:play()
            servingPlayer = 2
            player1Score = player1Score + 1
            
            if player1Score == 10 then
                winningPlayer = 1
                gameState = 'done'
            else
                gameState = 'serve'
                ball:reset()
            end
        end
    end
    

    -- if we reach the left or right edge of the screen, 
    -- go back to start and update the score
    

    -- player 1 movement
    if love.keyboard.isDown('w') then
        player1.dy = -PADDLE_SPEED
    elseif love.keyboard.isDown('s') then
        player1.dy = PADDLE_SPEED
    else
        player1.dy = 0
    end

    -- player 2 movement
    if love.keyboard.isDown('up') then
        player2.dy = -PADDLE_SPEED
    elseif love.keyboard.isDown('down') then
        player2.dy = PADDLE_SPEED
    else
        player2.dy = 0
    end

    -- update our ball based on its DX and DY only if we're in play state;
    -- scale the velocity by dt so movement is framerate-independent
    if gameState == 'play' then
        ball:update(dt)
    end

    player1:update(dt)
    player2:update(dt)
end


function love.keypressed(key)

    if key == 'escape' then
        love.event.quit()
    -- if we press enter during either the start or serve phase, it should
    -- transition to the next appropriate state
    elseif key == 'enter' or key == 'return' then
        love.graphics.setBackgroundColor(0, 1, 0)
        if gameState == 'start' then
            gameState = 'serve'
        elseif gameState == 'serve' then
            gameState = 'play'
        elseif gameState == 'done' then 
            gameState = 'serve' 
            -- may be we can increase the level            ball:reset
            -- by changing here 

            player1Score = 0
            player2Score = 0

            if winningPlayer == 1 then 
                servingPlayer = 2
            else
                servingPlayer = 1
            end
        end
    end
end


function love.draw()

    push:apply('start')

    love.graphics.setFont(smallFont)

    displayScore()

    if gameState == 'start' then
        love.graphics.setBackgroundColor(0, 1, 0)
        love.graphics.setFont(smallFont)
        love.graphics.printf('Welcome to Pong!', 0, 10, VIRTUAL_WIDTH, 'center')
        love.graphics.printf('Press Enter to begin!', 0, 20, VIRTUAL_WIDTH, 'center')
    elseif gameState == 'serve' then
        love.graphics.setBackgroundColor(0, 1, 0)
        love.graphics.setFont(smallFont)
        love.graphics.printf('Player ' .. tostring(servingPlayer) .. "'s serve!", 
            0, 10, VIRTUAL_WIDTH, 'center')
        love.graphics.printf('Press Enter to serve!', 0, 20, VIRTUAL_WIDTH, 'center')
    elseif gameState == 'play' then
        love.graphics.setBackgroundColor(0, 1, 0)

    elseif gameState == 'done' then 
        love.graphics.setBackgroundColor(1, 0, 0)
        love.graphics.setFont(largeFont)
        love.graphics.setColor(0, 1, 0)
        love.graphics.printf('Player --' .. tostring(winningPlayer) .. '--wins!!', 0, 10, VIRTUAL_WIDTH, 'center')
        love.graphics.setFont(smallFont)
        love.graphics.printf('Press enter to restart', 0, 50, VIRTUAL_WIDTH, 'center')
    end

    player1:render()
    player2:render()
    ball:render()

    displayFPS()

    push:apply('end')
end

function displayFPS()
    
    love.graphics.setFont(fpsFont)
    love.graphics.print('FPS: ' .. tostring(love.timer.getFPS()), 10, 10)
end


function displayScore()

    love.graphics.setFont(scoreFont)
    love.graphics.print(tostring(player1Score), VIRTUAL_WIDTH / 2 - 50, 
        VIRTUAL_HEIGHT / 3)
    love.graphics.print(tostring(player2Score), VIRTUAL_WIDTH / 2 + 30,
        VIRTUAL_HEIGHT / 3)
end
