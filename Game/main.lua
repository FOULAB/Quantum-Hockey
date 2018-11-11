local windowed = false
local paused = true
--local projector = true
local displayMenu = true

local winWidth = 1280
local winHeight = 720
local playHeight = 524.5
local goalSize = playHeight * 0.286
local friction = 0.985

local speed = 10
local maxLife = 4 --(seconds after immobility)
local ballObject = {x = 0, y = 0, vx = speed, vy = speed, mass=1, prob = 100, life = maxLife}
local ballProbs = {}
local explosions = {}
local count = 0
local ballSize = 20
local playerSize = 34
local loop = true
local lowestProb = 2
local roundWinner = -1

local newBall = false
local ballIntro = playHeight/4

local joysticks = love.joystick.getJoysticks()
local joy1 = joysticks[1]
if joy1 and not joy1:isGamepad() then
    local guid = joy1:getGUID()
    love.joystick.setGamepadMapping(guid, 'leftx', 'axis', 1)
    love.joystick.setGamepadMapping(guid, 'lefty', 'axis', 2)
    love.joystick.setGamepadMapping(guid, 'rightx', 'axis', 3)
    love.joystick.setGamepadMapping(guid, 'righty', 'axis', 4)
end


function variance()
	return love.math.random(-10, 10) / 80
end

local scoreLeft = 0
local scoreRight = 0
local prevScoreLeft = 0
local prevScoreRight = 0
local totalProb = 100
local p1={x =0, y=0, prevX=0, prevY=0, vx=0, vy=0, mass = 1.1}
local p2={x =0, y=0, prevX=0, prevY=0, vx=0, vy=0, mass = 1.1}

function round(n, mult)
    mult = mult or 1
    return math.floor((n + mult/2)/mult) * mult
end

function ballObject:new (o)
  o = o or {}   -- create object if user does not provide one
  setmetatable(o, self)
  self.__index = self
  return o
end

------------------------------ MENU -----------------------
function toggleMenu()
    paused = not paused
    displayMenu = not displayMenu
end

function reset()
    love.load()
end

function quit()
    love.event.quit()
end

local menuItem = { x = 0, y = 0, completion = 0, active = false, action = toggleMenu, text = ''}

function menuItem:new (o)
  o = o or {}   -- create object if user does not provide one
  setmetatable(o, self)
  self.__index = self
  return o
end

local menuCircles = {}
menuCircles[1] = menuItem:new{text = 'MENU'}
menuCircles[2] = menuItem:new{text = 'MENU'}

local menu = {}
menu[1] = menuItem:new{action = reset, text = 'RESET'}
menu[2] = menuItem:new{action = resume, text = 'RESUME'}
menu[3] = menuItem:new{action = reset, text = 'RESET'}
menu[4] = menuItem:new{action = resume, text = 'RESUME'}

local startMenu = {}
startMenu[1] = menuItem:new{action = resume, text = 'START!'}
startMenu[2] = menuItem:new{action = resume, text = 'START!'}





------------------- COLLISIONS --------------------
function checkCollision(ball, player)
    local dist = (ball.x - player.x)^2 + (ball.y - player.y)^2
    return dist <= (ballSize + playerSize)^2
end

function collide(i, ball, player)
	ball.life = maxLife;

	local vxTotal = ball.vx - player.vx
    local vyTotal = ball.vy - player.vy

    local newVelX = (ball.vx * (ball.mass - player.mass) + (2 * player.mass * player.vx)) / (ball.mass + player.mass)
    local newVelY = (ball.vy * (ball.mass - player.mass) + (2 * player.mass * player.vy)) / (ball.mass + player.mass)

     --fix for immobile player
	if player.vx == 0 then newVelX = (ball.vx * (ball.mass - 100) + (2 * 100 * player.vx)) / (ball.mass + 100) end
	if player.vy == 0 then newVelY = (ball.vy * (ball.mass - 100) + (2 * 100 * player.vy)) / (ball.mass + 100) end

    -- Move the circles so that they don't overlap
    local collPointX = ((ball.x * playerSize) + (player.x * ballSize))/(ballSize + playerSize)
	local collPointY = ((ball.y * playerSize) + (player.y * ballSize))/(ballSize + playerSize)
    local dist = math.sqrt((ball.x - player.x)^2 + (ball.y - player.y)^2)
    ball.x = collPointX + (ballSize * (ball.x - player.x)/dist)*1.1
    ball.y = collPointY + (ballSize * (ball.y - player.y)/dist)*1.1
     
    -- Update the velocities
    ball.vx = newVelX
    ball.vy = newVelY
	split(i)
end

function reflectX(i)
	ballProbs[i].vx = -ballProbs[i].vx + variance()
	ballProbs[i].vy = ballProbs[i].vy + variance()
	
	split(i)
end

function reflectY(i)
	ballProbs[i].vx = ballProbs[i].vx + variance()
	ballProbs[i].vy = -ballProbs[i].vy + variance()

	split(i)
end
	
function split(i)
	local ball = ballProbs[i]
	if ball.prob > lowestProb then
		ball.prob = ball.prob / 2
		count = count +1
		ballProbs[count] = ballObject:new{x= ball.x, y = ball.y, vx = ball.vx + variance(), vy = ball.vy + variance(), prob = ball.prob}
	end
end

function removeBall(i)
	table.remove(ballProbs, i)
	count = #ballProbs
	loop = false
end

function explode(ball, left)
    explosions[#explosions + 1] = ballObject:new{x= ball.x, y = ball.y, left = left, size = ballSize, prob = ball.prob}
end



---------------------------------------------------
------------------ LOVE LOAD -------------------
-------------------------------------------------
function love.load()
    love.window.setMode(winWidth, winWidth * 0.512, {resizable=false, vsync=true, msaa=4})
    if not windowed then
    	local fullscreen = love.window.setFullscreen(true)
    	love.mouse.setVisible(false)
	end

	winWidth, winHeight = love.graphics.getDimensions()
	playHeight = winWidth * 0.512 --ratio based on real dimensions
	goalSize = playHeight * 0.286 /2
	ballIntro = playHeight/4
	ballSize = winWidth * 0.038 /2
	playerSize = winWidth * 0.066 /2

    -- place menu proportionately to screen size
    menuCircles[1].x = -winWidth/2.5
    menuCircles[1].y = playHeight/3
    menuCircles[2].x = winWidth/2.5
    menuCircles[2].y = -playHeight/3
    menu[1].x = winWidth/3
    menu[1].y = playHeight/4
    menu[2].x = menu[1].x
    menu[2].y = -menu[1].y
    menu[3].x = -menu[1].x
    menu[3].y = menu[1].y
    menu[4].x = -menu[1].x
    menu[4].y = -menu[1].y
    startMenu[1].x = menu[1].x
    startMenu[2].x = -startMenu[1].x

    ballProbs = {}
    scoreLeft = 0
    scoreRight = 0
    roundWinner = round(love.math.random(0,1)) * 2 -1 --randomize starting player
    totalProb = 0
    count = 0
    scoreFont = love.graphics.setNewFont('uni0553-webfont.ttf', 54)
    infoFont = love.graphics.setNewFont('uni0553-webfont.ttf', 18)
    love.graphics.setLineWidth(2)
    

    --Check for Joysticks
    if joysticks and next(joysticks) == nil then joysticks = false end
    
    --animation
    animation = newAnimation(love.graphics.newImage("qh_logo_sprite.png"), 200, 200, 1)
    
end

function addPuck()
    if scoreLeft - prevScoreLeft > scoreRight - prevScoreRight then
        roundWinner = 1 --left won the round
    else if count > 0 then --fix for first puck
        roundWinner = -1 -- right won the round
        end
    end
    
    newBall = true
    ballIntro = ballIntro - (playHeight/1.5)/ ballIntro

    if ballIntro <= ballSize then
        count = count + 1
        ballProbs[count] = ballObject:new{vx = speed * roundWinner, vy = love.math.random(0,1) * speed / 2 + (round(love.math.random(0,1)) * 2 -1)}
        newBall = false
        ballIntro = playHeight/4
        
        prevScoreLeft = scoreLeft
        prevScoreRight = scoreRight
    end
end




function love.update(dt)
	function love.keypressed(key, unicode)
		if key == 'w' then
			windowed = true
			winWidth = 1280
			winHeight = 720
			love.load()
		end

		if key == 'p' then
			paused = not paused
		end
        
        if key == 'q' then
			quit()
		end
        
        if key == 'r' then
			reset()
		end
        
        if key == 'escape' then
            toggleMenu()
        end
        
	end
    

	--Get player position and velocity
	p1.prevX = p1.x
	p1.prevY = p1.y
	p2.prevX = p2.x
	p2.prevY = p2.y
	
	if joysticks then
        p1.x = joy1:getGamepadAxis("leftx") * winWidth/2
        p1.y = -joy1:getGamepadAxis("lefty") * 0.75 * winWidth/2 --0.75 is the ratio of the Wiimote resolution (768/1024)
        p2.x = joy1:getGamepadAxis("rightx") * winWidth/2
        p2.y = -joy1:getGamepadAxis("righty") * 0.75 * winWidth/2
        
        
        --Hopefully fixes the wiimote's glitch when it loses an IR point.
        if math.abs(p1.x - p2.x) < 10 and math.abs(p1.y - p2.y) < 10 then
            if math.abs(p1.prevX - p1.x) > 200 then --completely arbitrary number
                p1.x = p1.prevX
                p1.y = p1.prevY
            else
                p2.x = p2.prevX
                p2.y = p2.prevY
            end
        end
	else
        p1.x = love.mouse.getX() - winWidth/2
        p1.y = love.mouse.getY() - playHeight/2
	end
	p1.vx = p1.x - p1.prevX
	p1.vy = p1.y - p1.prevY
	p2.vx = p2.x - p2.prevX
	p2.vy = p2.y - p2.prevY
    
    if displayMenu then
        --animation
        animation.currentTime = animation.currentTime + dt
        if animation.currentTime >= animation.duration then
            animation.currentTime = animation.currentTime - animation.duration
        end
        
        if count == 0 then
            currentMenu = startMenu
        else
            currentMenu = menu
        end
    else
        currentMenu = menuCircles
    end
    for i, option in ipairs(currentMenu) do
        if checkCollision(option, p1) then
            option.active = true
            option.completion = option.completion + dt*5
            if option.completion >= 10 then
                option.active = false
                option.completion = 0
                option.action()
            end
        elseif option.active then
            option.active = false
            option.completion = 0
        end
    end
    
    if paused then return end
    
	--OPTIMIZATION: maybe modify this to change only when the total probability changes (ball removed, new ball)
	totalProb = 0
	for i = 1, #ballProbs do
		totalProb = totalProb + ballProbs[i].prob
	end

	if totalProb < 40 then

		addPuck();
		
	end
    
    
    
	for i, ball in ipairs(ballProbs) do

		--Move balls before calculating next event
		ball.x = ball.x + ball.vx
		ball.y = ball.y + ball.vy

		--Deceleration (friction)
		ball.vx = ball.vx - ball.vx * friction * dt
		ball.vy = ball.vy - ball.vy * friction * dt

		--Degradation
		if ball.prob < lowestProb and math.abs(ball.vx) <= 0.05 and math.abs(ball.vy) <= 0.05 then
			ball.life = ball.life -1 * dt
			if ball.life <= 0 then
				removeBall(i)
			end
		end

		--Player interaction
		if loop and checkCollision(ball, p1) then
				collide(i, ball, p1)
		end

		if loop and joysticks and checkCollision(ball, p2) then
				collide(i, ball, p2)
		end

		--Wall interaction
		--Wall X
		if loop and math.abs(ball.x) >= (winWidth / 2 - ballSize) and math.abs(ball.y) > (goalSize) then 
			if ball.x > 0 then ball.x = (winWidth / 2 - ballSize - 1) end
			if ball.x < 0 then ball.x = (-winWidth / 2 + ballSize + 1) end
			reflectX(i)
		end
		--Wall Y
		if loop and math.abs(ball.y) >= (playHeight / 2 - ballSize) then
			if ball.y > 0 then ball.y = (playHeight / 2 - ballSize - 16) end
			if ball.y < 0 then ball.y = (-playHeight / 2 + ballSize + 16) end
			reflectY(i)
		end
		--SCORE!
		if loop and ball.x >= (winWidth / 2) and math.abs(ball.y) <= (goalSize) then
			scoreLeft = scoreLeft + ball.prob / 100
            explode(ball, false)
			removeBall(i)
		end
		if loop and ball.x <= (-winWidth / 2) and math.abs(ball.y) <= (goalSize) then
			scoreRight = scoreRight + ball.prob / 100
            explode(ball, true)
			removeBall(i)
		end
		loop = true
	end
    
    for i, explosion in ipairs(explosions) do
        explosion.size = explosion.size + (ballSize * 10)/explosion.size * 60 * dt
        if explosion.size > ballSize * 5 then
            table.remove(explosions, i)
        end
    end
end

--GRAPHICS

function newAnimation(image, width, height, duration)
    local animation = {}
    animation.spriteSheet = image
    animation.quads = {}
    image:setFilter('nearest', 'nearest')
    
    for y = 0, image:getHeight() - height, height do
        for x = 0, image:getWidth() - width, width do
            table.insert(animation.quads, love.graphics.newQuad(x,y, width,height, image:getDimensions()))
        end
    end
    
    animation.duration = duration or 1
    animation.currentTime = 0
    
    return animation
end

function drawBG()
    love.graphics.setColor(1, 1, 1)
	love.graphics.rectangle("fill", -winWidth/2, -playHeight/2, winWidth, playHeight)
	love.graphics.setColor(1,0.14,0.34, 0.2)
	love.graphics.circle("line", 0, 0, playHeight/4)
	love.graphics.circle("line", winWidth/2, 0, goalSize)
	love.graphics.circle("line", -winWidth/2, 0, goalSize)
	love.graphics.setColor(0, 0.2, 0.8, 0.2)
	love.graphics.line(0, -playHeight/2, 0, playHeight/2)
end


function love.draw()
	love.graphics.translate(winWidth/2, winHeight/2)
	
    --Background
    --if projector then
        love.graphics.setColor(1, 1, 1)
        love.graphics.setLineWidth(5)
        love.graphics.rectangle("line", -winWidth/2 + 1, -playHeight/2 +1, winWidth -2, playHeight -2)
    love.graphics.setLineWidth(1)
--    else
--        drawBG()
--    end
    
    
    --Score
    love.graphics.setFont(scoreFont)
    love.graphics.setColor(1, 0.25, 0.25)
	love.graphics.printf(scoreLeft, -winWidth/2, -playHeight/2 + 20, winWidth/2, "center")
    love.graphics.setColor(0.25, 0.47, 1)
	love.graphics.printf(scoreRight, 0, -playHeight/2 + 20, winWidth/2, "center")
    love.graphics.setFont(infoFont)
	love.graphics.printf("TOTAL PROB: " .. totalProb .. "%", -winWidth/2, playHeight/2 - 40, winWidth/2, "center")
	love.graphics.printf(count .. " PUCKS", 0, playHeight/2 - 40, winWidth/2, "center")
	love.graphics.printf(winWidth .. 'x' .. winHeight, -winWidth/4, playHeight/2 - 40, winWidth/2, "center")
    
    
    --New puck animation
	if newBall then
        if roundWinner < 0 then
            love.graphics.setColor(1,0.25,0.25, (playHeight/4)/ballIntro - 1)
        else
            love.graphics.setColor(0.25,0.47,1, (playHeight/4)/ballIntro - 1)
        end
		love.graphics.circle("fill", 0, 0, ballIntro)
	end

    --Player position
	love.graphics.setColor(1, 0.25, 0.25)
	love.graphics.circle("line", p1.x, p1.y, playerSize)
	if joysticks then
        love.graphics.setColor(0.25,0.47,1)
        love.graphics.circle("line", p2.x, p2.y, playerSize)
    end
    
    --Explosions (goal)
    for i, explosion in ipairs(explosions) do
        if explosion.left then
            love.graphics.setColor(1,0.25,0.25, (1 - (100 - explosion.prob)/110) *(ballSize * 5 -explosion.size)/(ballSize*5))
        else
            love.graphics.setColor(0.25,0.47,1, (1 - (100 - explosion.prob)/110) *(ballSize * 5 -explosion.size)/(ballSize*5))
        end
        love.graphics.circle("fill", explosion.x, explosion.y, explosion.size)
    end

    --Pucks
	for i, puck in ipairs(ballProbs)  do
		love.graphics.setColor(1,1,1,  1 - (100 - puck.prob)/105)
		if puck.life < maxLife then love.graphics.setColor(0.5,0.14, 1, 0.02) end
		love.graphics.circle("fill", puck.x, puck.y, ballSize)
	end
    
    if displayMenu then
        love.graphics.setColor(0,0,0,0.5)
        love.graphics.rectangle("fill", -winWidth/2, -playHeight/2, winWidth, playHeight)
        love.graphics.setColor(1,1,1,1)
        --animated logo
        local spriteNum = math.floor(animation.currentTime / animation.duration * #animation.quads) + 1
        love.graphics.draw(animation.spriteSheet, animation.quads[spriteNum], -200, -200, 0, 2)
    end
    
    --Menu circles
    for i, option in ipairs(currentMenu) do
        love.graphics.setColor(1,1,1, 0.3)
        love.graphics.setLineWidth(1)
        love.graphics.circle("line", option.x, option.y, playerSize)
        love.graphics.setLineWidth(14)
        love.graphics.setColor(1,1,1)
        if option.x < 0 then
            love.graphics.printf(option.text, option.x + playerSize/3, option.y - playerSize, playerSize*2, "center", math.pi/2)
            love.graphics.setColor(1, 0.25, 0.25)
        else
            love.graphics.printf(option.text, option.x -playerSize/3, option.y + playerSize, playerSize*2, "center", -math.pi/2)
            love.graphics.setColor(0.25, 0.47, 1)
        end
        
        love.graphics.arc("line", "open", option.x, option.y, playerSize +7, 0, math.pi * 0.2 * option.completion)
    end
    love.graphics.setLineWidth(1)
	
end