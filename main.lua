local windowed = false

local winWidth = 1024
local winHeight = 768
local playHeight = 524.5
local goalSize = playHeight * 0.286

local speed = 1
local maxLife = 300
local ball = {x = 0, y = 0, vx = speed, vy = speed, mass=1, prob = 100, life = maxLife}
local ballProbs = {}
local count = 1
local ballSize = 20
local playerSize = 34
local loop = true
local lowestProb = 2

local newBall = false
local ballIntro = playHeight/4

local joysticks = love.joystick.getJoysticks()
local joy1 = joysticks[1]



function variance()
	return love.math.random(-10, 10) / 80
end

local scoreTop = 0
local scoreBottom = 0
local totalProb = 100
local p1={x =0, y=0, prevX=0, prevY=0, vx=0, vy=0, mass = 1.1}
local p2={x =0, y=0, prevX=0, prevY=0, vx=0, vy=0, mass = 1.1}

function round(n, mult)
    mult = mult or 1
    return math.floor((n + mult/2)/mult) * mult
end

function ball:new (o)
  o = o or {}   -- create object if user does not provide one
  setmetatable(o, self)
  self.__index = self
  return o
end

function checkCollision(ball, player)
    local dist = (ball.x - player.x)^2 + (ball.y - player.y)^2
    return dist <= (ballSize + playerSize)^2
end

function collide(i, ball, player)
	ballProbs[i].life = maxLife;

	local vxTotal = ball.vx - player.vx
    local vyTotal = ball.vy - player.vy

    local newVelX = (ball.vx * (ballProbs[i].mass - player.mass) + (2 * player.mass * player.vx)) / (ballProbs[i].mass + player.mass)
    local newVelY = (ball.vy * (ballProbs[i].mass - player.mass) + (2 * player.mass * player.vy)) / (ballProbs[i].mass + player.mass)

     --fix for immobile player
	if player.vx == 0 then newVelX = (ball.vx * (ballProbs[i].mass - 100) + (2 * 100 * player.vx)) / (ballProbs[i].mass + 100) end
	if player.vy == 0 then newVelY = (ball.vy * (ballProbs[i].mass - 100) + (2 * 100 * player.vy)) / (ballProbs[i].mass + 100) end

    -- Move the circles so that they don't overlap
    local collPointX = ((ball.x * playerSize) + (player.x * ballSize))/(ballSize + playerSize)
	local collPointY = ((ball.y * playerSize) + (player.y * ballSize))/(ballSize + playerSize)
    local dist = math.sqrt((ball.x - player.x)^2 + (ball.y - player.y)^2)
    ballProbs[i].x = collPointX + (ballSize * (ball.x - player.x)/dist)*1.1
    ballProbs[i].y = collPointY + (ballSize * (ball.y - player.y)/dist)*1.1
     
    -- Update the velocities
    ballProbs[i].vx = newVelX
    ballProbs[i].vy = newVelY
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
	if ballProbs[i].prob > lowestProb then
		ballProbs[i].prob = ballProbs[i].prob / 2
		count = count +1
		ballProbs[count] = ball:new{prob = ballProbs[i].prob}
		ballProbs[count].vx = ballProbs[i].vx + variance()
		ballProbs[count].vy = ballProbs[i].vy + variance()
		
		ballProbs[count].x = ballProbs[i].x
		ballProbs[count].y = ballProbs[i].y
	end
end

function removeBall(i)
	table.remove(ballProbs, i)
	count = #ballProbs
	loop = false
end

function love.load()
    love.window.setMode(winWidth, winHeight, {resizable=false, vsync=true})
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


    ballProbs = {}
    scoreTop = 0
    scoreBottom = 0
    ballProbs[1] = ball:new{}
    totalProb = 100
    count = 1
    font = love.graphics.setNewFont(18)
    love.graphics.setLineWidth(2)

    --Check for Joysticks
    if joysticks and next(joysticks) == nil then joysticks = false end
end
	
function love.update()
	if love.keyboard.isDown('r') then love.load() end
	if love.keyboard.isDown('escape') then
		windowed = true
		winWidth = 1024
		winHeight = 768
		love.load()
	end

	--Get player position and velocity
	p1.prevX = p1.x
	p1.prevY = p1.y
	p2.prevX = p2.x
	p2.prevY = p2.y
	
	if joysticks then
	p1.x = joy1:getGamepadAxis("leftx")*winWidth/2 - winWidth/2
	p1.y = joy1:getGamepadAxis("lefty")*playHeight - playHeight/2
	p2.x = joy1:getGamepadAxis("rightx")*winWidth/2
	p2.y = joy1:getGamepadAxis("righty")*playHeight - playHeight/2
	else
	p1.x = love.mouse.getX() - winWidth/2
	p1.y = love.mouse.getY() - playHeight/2
	end
	p1.vx = p1.x - p1.prevX
	p1.vy = p1.y - p1.prevY
	p2.vx = p2.x - p2.prevX
	p2.vy = p2.y - p2.prevY

	--OPTIMIZATION: maybe modify this to change only when the total probability changes (ball removed, new ball)
	totalProb = 0
	for i = 1, #ballProbs do
		totalProb = totalProb + ballProbs[i].prob
	end

	if totalProb < 40 then

		--Move this into its own function
		newBall = true
		ballIntro = ballIntro - (playHeight/1.5)/ ballIntro

		if ballIntro <= ballSize then
			count = count + 1
			ballProbs[count] = ball:new{vx = speed * (round(love.math.random(0,1)) * 2 -1), vy = speed * (round(love.math.random(0,1)) * 2 -1)}
			newBall = false
			ballIntro = playHeight/4
		end
	end
	for i=#ballProbs,1,-1 do

		--OPTIMIZATION TO ADD! local ball = ballProbs[i]

		--Move balls before calculating next event
		ballProbs[i].x = ballProbs[i].x + ballProbs[i].vx
		ballProbs[i].y = ballProbs[i].y + ballProbs[i].vy

		--Deceleration (friction)
		ballProbs[i].vx = ballProbs[i].vx * 0.985
		ballProbs[i].vy = ballProbs[i].vy * 0.985

		--(Optimization)
		local ball = ballProbs[i]

		--Degradation
		if ballProbs[i].prob < lowestProb and math.abs(ball.vx) <= 0.05 and math.abs(ball.vy) <= 0.05 then
			ballProbs[i].life = ballProbs[i].life -1
			if ballProbs[i].life <= 0 then
				removeBall(i)
			end
		end

		--Player interaction
		if loop and checkCollision(ballProbs[i], p1) then
				collide(i, ball, p1)
		end

		if loop and joysticks and checkCollision(ballProbs[i], p2) then
				collide(i, ball, p2)
		end

		--Wall interaction
		--Wall X
		if loop and math.abs(ball.x) >= (winWidth / 2 - ballSize) and math.abs(ball.y) > (goalSize) then 
			if ball.x > 0 then ballProbs[i].x = (winWidth / 2 - ballSize - 1) end
			if ball.x < 0 then ballProbs[i].x = (-winWidth / 2 + ballSize + 1) end
			reflectX(i)
		end
		--Wall Y
		if loop and math.abs(ball.y) >= (playHeight / 2 - ballSize) then
			if ball.y > 0 then ballProbs[i].y = (playHeight / 2 - ballSize - 16) end
			if ball.y < 0 then ballProbs[i].y = (-playHeight / 2 + ballSize + 16) end
			reflectY(i)
		end
		--SCORE!
		if loop and ball.x >= (winWidth / 2) and math.abs(ball.y) <= (goalSize) then
			scoreBottom = scoreBottom + ballProbs[i].prob / 100
			removeBall(i)
		end
		if loop and ball.x <= (-winWidth / 2) and math.abs(ball.y) <= (goalSize) then
			scoreTop = scoreTop + ballProbs[i].prob / 100
			removeBall(i)
		end
		loop = true
	end
end

function love.draw()
	love.graphics.translate(winWidth/2, winHeight/2)
	love.graphics.setColor(1, 1, 1)
	love.graphics.rectangle("fill", -winWidth/2, -playHeight/2, winWidth, playHeight)
	love.graphics.setColor(1,0.14,0.34, 0.2)
	love.graphics.circle("line", 0, 0, playHeight/4)
	love.graphics.circle("line", winWidth/2, 0, goalSize)
	love.graphics.circle("line", -winWidth/2, 0, goalSize)
	love.graphics.setColor(0, 0.2, 0.8, 0.2)
	love.graphics.line(0, -playHeight/2, 0, playHeight/2)

	if newBall then
		love.graphics.setColor(1,0.14,0.34, (playHeight/4)/ballIntro - 1)
		love.graphics.circle("fill", 0, 0, ballIntro)
	end

	love.graphics.setColor(0.3, 0.3, 0.3)
	love.graphics.circle("fill", p1.x, p1.y, playerSize)
	if joysticks then love.graphics.circle("fill", p2.x, p2.y, playerSize) end

	for i = #ballProbs, 1, -1  do
		love.graphics.setColor(1,0.14,0.34,  1 - (100 - ballProbs[i].prob)/102)
		if ballProbs[i].life < maxLife then love.graphics.setColor(0.5,0.14, 1, 0.02) end
		love.graphics.circle("fill", ballProbs[i].x, ballProbs[i].y, ballSize)
	end
	love.graphics.setColor(0, 0.2, 0.8, .2)
	love.graphics.printf(scoreTop, -winWidth/4, -playHeight/2 + 20, winWidth/2, "center")
	love.graphics.printf(scoreBottom, -winWidth/4, playHeight/2 - 40, winWidth/2, "center")
	love.graphics.printf(totalProb .. "%", -winWidth/4, 0, winWidth/2, "center")
end