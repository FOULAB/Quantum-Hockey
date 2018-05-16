local winWidth = 600
local winHeight = 800

local speed = 1
local maxLife = 300
local ball = {x = 0, y = 0, vx = speed, vy = speed, mass=1, prob = 100, life = maxLife}
local ballProbs = {}
local count = 1
local ballSize = 20
local playerSize = 30
local loop = true --try replacing this with returns in the love.update() function
local lowestProb = 2

local newBall = false
local ballIntro = winWidth/4

function variance()
	return love.math.random(-10, 10) / 80
end

local scoreTop = 0
local scoreBottom = 0
local totalProb = 100
local p1={x =0, y=0, prevX=0, prevY=0, vx=0, vy=0, mass = 1.1}

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

function love.load()
    love.window.setMode(winWidth, winHeight, {resizable=false, vsync=true, msaa = 4})
    ballProbs = {}
    scoreTop = 0
    scoreBottom = 0
    ballProbs[1] = ball:new{}
    totalProb = 100
    count = 1
    font = love.graphics.setNewFont(18)
    love.graphics.setLineWidth(2)
end
	
function love.update()
	if love.keyboard.isDown('r') then love.load() end

	--Get player position and velocity
	p1.prevX = p1.x
	p1.prevY = p1.y
	p1.x = love.mouse.getX() - winWidth/2
	p1.y = love.mouse.getY() - winHeight/2
	p1.vx = p1.x - p1.prevX
	p1.vy = p1.y - p1.prevY

	--OPTIMIZATION: modify this to change only when the total probability changes (goal, ball degrades)
	totalProb = 0
	for i = 1, #ballProbs do
		totalProb = totalProb + ballProbs[i].prob
	end

	if totalProb < 40 then

		--Move this into its own function
		newBall = true
		ballIntro = ballIntro - (winWidth/1.5)/ ballIntro

		if ballIntro <= ballSize then
			count = count + 1
			ballProbs[count] = ball:new{vx = speed * (round(love.math.random(0,1)) * 2 -1), vy = speed * (round(love.math.random(0,1)) * 2 -1)}
			newBall = false
			ballIntro = winWidth/4
		end
	end
	for i=#ballProbs,1,-1 do
		ballProbs[i].x = ballProbs[i].x + ballProbs[i].vx
		ballProbs[i].y = ballProbs[i].y + ballProbs[i].vy


		--Deceleration (friction)
		ballProbs[i].vx = ballProbs[i].vx * 0.985
		ballProbs[i].vy = ballProbs[i].vy * 0.985

		--Degradation
		if ballProbs[i].prob < lowestProb and math.abs(ballProbs[i].vx) <= 0.05 and math.abs(ballProbs[i].vy) <= 0.05 then
			ballProbs[i].life = ballProbs[i].life -1
			if ballProbs[i].life <= 0 then
				table.remove(ballProbs, i)
				count = #ballProbs
				loop = false
			end
		end

		--Player interaction
		if loop and checkCollision(ballProbs[i], p1) then

			ballProbs[i].life = maxLife;

			local vxTotal = ballProbs[i].vx - p1.vx
	        local vyTotal = ballProbs[i].vy - p1.vy

	        local newVelX = (ballProbs[i].vx * (ballProbs[i].mass - p1.mass) + (2 * p1.mass * p1.vx)) / (ballProbs[i].mass + p1.mass)
	        local newVelY = (ballProbs[i].vy * (ballProbs[i].mass - p1.mass) + (2 * p1.mass * p1.vy)) / (ballProbs[i].mass + p1.mass)
      
	         --fix for immobile player
			if p1.vx == 0 then newVelX = (ballProbs[i].vx * (ballProbs[i].mass - 100) + (2 * 100 * p1.vx)) / (ballProbs[i].mass + 100) end
			if p1.vy == 0 then newVelY = (ballProbs[i].vy * (ballProbs[i].mass - 100) + (2 * 100 * p1.vy)) / (ballProbs[i].mass + 100) end

	        -- Move the circles so that they don't overlap
	        local collPointX = ((ballProbs[i].x * playerSize) + (p1.x * ballSize))/(ballSize + playerSize)
			local collPointY = ((ballProbs[i].y * playerSize) + (p1.y * ballSize))/(ballSize + playerSize)
	        local dist = math.sqrt((ballProbs[i].x - p1.x)^2 + (ballProbs[i].y - p1.y)^2)
	        ballProbs[i].x = collPointX + (ballSize * (ballProbs[i].x - p1.x)/dist)*1.1
	        ballProbs[i].y = collPointY + (ballSize * (ballProbs[i].y - p1.y)/dist)*1.1
	         
	        -- Update the velocities
	        ballProbs[i].vx = newVelX
	        ballProbs[i].vy = newVelY
			split(i)		
		end
		--Wall interaction
		--Wall X
		if loop and math.abs(ballProbs[i].x) >= (winWidth / 2 - ballSize) then 
			if ballProbs[i].x > (winWidth / 2 - ballSize) then ballProbs[i].x = (winWidth / 2 - ballSize - 1) end
			if ballProbs[i].x < (-winWidth / 2 + ballSize) then ballProbs[i].x = (-winWidth / 2 + ballSize + 1) end
			reflectX(i)
		end
		--Wall Y
		if loop and math.abs(ballProbs[i].y) >= (winHeight / 2 - ballSize - 15) and math.abs(ballProbs[i].x) > (winWidth / 6) then
			if ballProbs[i].y > (winHeight / 2 - ballSize - 15) then ballProbs[i].y = (winHeight / 2 - ballSize - 16) end
			if ballProbs[i].y < (-winHeight / 2 + ballSize + 15) then ballProbs[i].y = (-winHeight / 2 + ballSize + 16) end
			reflectY(i)
		end
		if loop and ballProbs[i].y >= (winHeight / 2) and math.abs(ballProbs[i].x) <= (winWidth / 6) then
			scoreBottom = scoreBottom + ballProbs[i].prob / 100
			table.remove(ballProbs, i)
			count = #ballProbs
			loop = false
		end
		if loop and ballProbs[i].y <= (-winHeight / 2) and math.abs(ballProbs[i].x) <= (winWidth / 6) then
			scoreTop = scoreTop + ballProbs[i].prob / 100
			table.remove(ballProbs, i)
			count = #ballProbs
			loop = false
		end
		loop = true
	end
end

function love.draw()
	love.graphics.clear(1, 1, 1)
	love.graphics.setColor(0, 0, 0, 0.4)
	love.graphics.translate(winWidth/2, winHeight/2)
	love.graphics.rectangle("fill", -winWidth/2, -winHeight/2, winWidth/3, 15)
	love.graphics.rectangle("fill", winWidth/2 - winWidth/3, -winHeight/2, winWidth/3, 15)
	love.graphics.rectangle("fill", -winWidth/2, winHeight/2 -15, winWidth/3, 15)
	love.graphics.rectangle("fill", winWidth/2 - winWidth/3, winHeight/2 -15, winWidth/3, 15)
	love.graphics.setColor(1,0.14,0.34, 0.2)
	love.graphics.circle("line", 0, 0, winWidth/4)
	love.graphics.setColor(0, 0.2, 0.8, 0.2)
	love.graphics.line(-winWidth/2, 0, winWidth/2, 0)

	if newBall then
		love.graphics.setColor(1,0.14,0.34, (winWidth/4)/ballIntro - 1)
		love.graphics.circle("fill", 0, 0, ballIntro)
	end

	love.graphics.setColor(0.3, 0.3, 0.3)
	love.graphics.circle("fill", p1.x, p1.y, playerSize)

	for i = #ballProbs, 1, -1  do
		love.graphics.setColor(1,0.14,0.34,  1 - (100 - ballProbs[i].prob)/102)
		if ballProbs[i].life < maxLife then love.graphics.setColor(0.5,0.14, 1, 0.02) end
		love.graphics.circle("fill", ballProbs[i].x, ballProbs[i].y, ballSize)
	end
	love.graphics.setColor(0, 0.2, 0.8, .2)
	love.graphics.printf(scoreTop, -winWidth/4, -winHeight/2 + 20, winWidth/2, "center")
	love.graphics.printf(scoreBottom, -winWidth/4, winHeight/2 - 40, winWidth/2, "center")
end