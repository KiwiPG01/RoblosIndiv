--[[
	Created by iMod999 in September 2020
	Open sourced 10/1/2021
]]



--\\ module variables
local gunClient = {}

local inputService = game:GetService("UserInputService")

local player = game:GetService("Players").LocalPlayer
local mouse = player:GetMouse()

local bulletModule = require(player.PlayerScripts:WaitForChild("bulletRender"))
local gunGui = script:WaitForChild("gunGui")

local totalFired = 0

local CameraSystem = require(player.PlayerScripts:WaitForChild("CameraManager"))

--\\ module functions
function gunClient.init(tool)
	print("gunClient init")
	repeat wait() until player.Character and player.Character.Parent == workspace; wait(.25)
	
	local character = player.Character
	local humanoid = character:WaitForChild("Humanoid")
	local root = character:WaitForChild("HumanoidRootPart")

	local emptySound = tool:WaitForChild("Handle"):WaitForChild("emptySound")
	local reloadSound = tool:WaitForChild("Handle"):WaitForChild("reloadSound")
	
	local bulletStorage = workspace:WaitForChild("bulletStorage")
	local gunStorage = game:GetService("ReplicatedStorage"):WaitForChild("gunStorage")
	local gunEvents = gunStorage:WaitForChild("events")
	local fireEvent = gunEvents:WaitForChild("fire")
	local reloadEvent = gunEvents:WaitForChild("reload")
	local posVerifier = gunEvents:WaitForChild("positionVerifier")
	
	local config = tool:WaitForChild("config")
	local animations = config:WaitForChild("animations")
	local mainConfigs = config:WaitForChild("main")
	local miscConfgs = config:WaitForChild("misc")
	local modeConfigs = config:WaitForChild("mode")

	local shotgun = mainConfigs.shotgun.Value
	local pellets = mainConfigs.shotgun.pellets.Value
	local rpm = mainConfigs.rpm.Value
	local spread = mainConfigs:WaitForChild("spread").Value
	local ammo = tool:WaitForChild("ammo")
	
	local equipAnim = humanoid:LoadAnimation(animations:WaitForChild("equipAnim"))
	local holsterAnim = humanoid:LoadAnimation(animations:WaitForChild("holsterAnim"))
	local crouchAnim = humanoid:LoadAnimation(animations:WaitForChild("crouchAnim"))
	local reloadAnim = humanoid:LoadAnimation(animations:WaitForChild("reloadAnim"))
	local recoilAnim = humanoid:LoadAnimation(animations:WaitForChild("recoilAnim"))
	local idleAnim = humanoid:LoadAnimation(animations:WaitForChild("idleAnim"))
	--local swapRAnim = nil --left to right
	--local swapLAnim = nil -- right to left
	
	local hAnim = false
	local canFire = true
	local equipped = false
	local mouseDown = false
	local holstering = false
	local crouching = false
	local reloading = false
	local canRespond = false
	local gunMode

	--// Camera Settings //--
	local CameraSettings = {

		DefaultShoulder = {
			FieldOfView = 70,
			Offset = Vector3.new(2, 2, 4),
			Sensitivity = 3,
			LerpSpeed = 0.5
		},

		ZoomedShoulder = {
			FieldOfView = 30,
			Offset = Vector3.new(2, 2, 4),
			Sensitivity = 1.5,
			LerpSpeed = 0.5
		}

	}
	
	--\\ initialization
	for _,v in pairs(modeConfigs:GetChildren()) do
		if v.Value then
			gunMode = v.Name
		end
	end

	mouse.TargetFilter = workspace.bulletStorage

	equipAnim.Priority = Enum.AnimationPriority.Action4
	holsterAnim.Priority = Enum.AnimationPriority.Action
	crouchAnim.Priority = Enum.AnimationPriority.Action
	recoilAnim.Priority = Enum.AnimationPriority.Action
	reloadAnim.Priority = Enum.AnimationPriority.Action
	idleAnim.Priority = Enum.AnimationPriority.Action4
--	swapRAnim.Priority = Enum.AnimationPriority.Action
--	swapLAnim.Priority = Enum.AnimationPriority.Action

	
	
	--\\ equip functions
	local ammoListen
	tool.Equipped:Connect(function()
		equipAnim:Play()
		task.wait(equipAnim.length)
		idleAnim:AdjustWeight(0.1)
		idleAnim:Play()
		mouse.Icon = "rbxassetid://"..config.misc.crosshair.Value
		equipped = true --stupud ass thsedoiguvhebnwsale;iokdjgnv
	
		if humanoid.WalkSpeed >16 then
			holster(true)
		end
		
		local gunGuiClone = gunGui:Clone()
		gunGuiClone.Parent = player.PlayerGui

		gunGuiClone.infoFrame.gunName.Text = tool.Name
		gunGuiClone.infoFrame.gunAmmo.Text = tostring(ammo.Value).." / "..tostring(mainConfigs.ammo.Value)
		ammoListen = ammo.Changed:Connect(function()
			gunGuiClone.infoFrame.gunAmmo.Text = tostring(ammo.Value).." / "..tostring(mainConfigs.ammo.Value)
		end)
	end)
	
	
	tool.Unequipped:Connect(function()
		holsterAnim:Stop()
		equipAnim:Stop()
		crouchAnim:Stop()
		reloadAnim:Stop()
		recoilAnim:Stop()
		idleAnim:Stop()
		

		local gunGuiClone = player.PlayerGui:FindFirstChild("gunGui")
		if gunGuiClone then
			gunGuiClone:Destroy()
		end
		if ammoListen then
			ammoListen:Disconnect()
		end
		
		if crouching then
			humanoid.WalkSpeed = 16
		end
		
		equipped = false
		mouseDown = false
		reloading = false
		holstering = false
		crouching = false
		mouse.Icon = ""
	end)

	
	
	--\\ functions
	function holster(arg)
		if arg then
			holstering = true
			holsterAnim:Play()
			humanoid.WalkSpeed = miscConfgs.runSpeed.Value
		else
			holstering = false
			holsterAnim:Stop()
			humanoid.WalkSpeed = 16
		end
	end
	
	
	local function crouch(arg)
		if arg then
			crouching = true
			crouchAnim:Play()
			humanoid.WalkSpeed = miscConfgs.crouchSpeed.Value
		else
			crouching = false
			crouchAnim:Stop()
			humanoid.WalkSpeed = 16
		end
	end
	
	
	local function reload()
		if not reloading and ammo.Value < mainConfigs.ammo.Value then
			reloading = true
			reloadAnim:Play(.1, 1, reloadAnim.Length / mainConfigs.reloadTime.Value)
			reloadEvent:FireServer(tool.Name)

			local canStop = true
			local unequipListen
			unequipListen = tool.Unequipped:Connect(function()
				unequipListen:Disconnect()
				canStop = false
			end)

			wait(mainConfigs.reloadTime.Value)

			unequipListen:Disconnect()
			if canStop then
				reloading = false
			end
		end
	end
	
	
	local function fire()
		print("fired")
		if equipped and canFire and humanoid.Health >0 and not reloading then
			if holstering then
				holster(false)
			end
			--idleAnim:Stop()

			if ammo.Value >0 then
				-- Check if player is aiming (OTS camera system)
				local isAiming = player:FindFirstChild("IsAiming") and player.IsAiming.Value
				print(isAiming)
				-- Adjust spread based on aiming state
				local currentSpread = isAiming and (spread * 0.3) or spread -- Reduced spread when aiming
				
				local ray = Ray.new(root.CFrame.p, (tool.barrel.CFrame.p - root.CFrame.p).unit * (root.Position - tool.barrel.Position).magnitude)
				local part = workspace:FindPartOnRayWithIgnoreList(ray, {character, bulletStorage}, false, true)
				
				if not part or part.Parent:FindFirstChildOfClass("Humanoid") or part.Parent.Parent:FindFirstChildOfClass("Humanoid") then
					if shotgun then
						spawn(function()
							for i = 1, pellets, 1 do
								local ray = Ray.new(root.CFrame.p, (isAiming and workspace.CurrentCamera.CFrame.LookVector or (mouse.hit.p - root.CFrame.p).unit) * 999)
								local part,endPos = workspace:FindPartOnRayWithIgnoreList(ray, {bulletStorage, character}, false, true)
								local spreadCalculation = currentSpread * (endPos - tool.barrel.Position).magnitude
								endPos += Vector3.new(math.random(-spreadCalculation,spreadCalculation)/100, math.random(-spreadCalculation,spreadCalculation)/100, math.random(-spreadCalculation,spreadCalculation)/100)

								bulletModule.renderBullet(player, tool.Name, endPos)

								if i >= pellets then
									fireEvent:FireServer(tool.Name, endPos, true)
								else
									fireEvent:FireServer(tool.Name, endPos, false)
									totalFired += 1
								end
							end
						end)
					else
						local ray = Ray.new(root.CFrame.p, (isAiming and workspace.CurrentCamera.CFrame.LookVector or (mouse.hit.p - root.CFrame.p).unit) * 999)
						local part,endPos = workspace:FindPartOnRayWithIgnoreList(ray, {bulletStorage, character}, false, true)
						local spreadCalculation = currentSpread * (endPos - tool.barrel.Position).magnitude
						endPos += Vector3.new(math.random(-spreadCalculation,spreadCalculation)/100, math.random(-spreadCalculation,spreadCalculation)/100, math.random(-spreadCalculation,spreadCalculation)/100)

						fireEvent:FireServer(tool.Name, endPos)
						totalFired += 1
						
						bulletModule.renderBullet(player, tool.Name, endPos)
					end
					
					local totalWhenFired = totalFired
					
					canFire = false
					delay(60 / mainConfigs.rpm.Value, function()
						canFire = true
					end)

					local canRespond = true
					posVerifier.OnClientInvoke=function()
						if canRespond then
							canRespond = false
							local response=player.UserId;response*=player.UserId;response-=player.UserId
							local players=game:GetService("Players")response+=#players:GetPlayers()
							return response,totalWhenFired
						end
					end
					recoilAnim:Play()
					print("recoil")
				end
			else
				emptySound:Play()
			end
		end
	end
	
	
	local function mouseBegan()
		if gunMode == "auto" then
			while mouseDown and equipped do
				if canFire then
					fire()
				end
				wait(60 / mainConfigs.rpm.Value)
			end
		elseif gunMode == "semi" then
			if canFire and equipped then
				fire()
			end
		end
	end

	
	
	--\\ interaction
	inputService.InputBegan:Connect(function(input, gpe)
		print("")
		if equipped and not gpe then
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				mouseDown = true
				mouseBegan()
				print("Mouse Begain")
			elseif input.UserInputType == Enum.UserInputType.Keyboard then
				if input.KeyCode == Enum.KeyCode.LeftShift then
					if not holstering and not crouching and not mouseDown then
						holster(true)
					end
				elseif input.KeyCode == Enum.KeyCode.C then
					if not crouching and not holstering then
						crouch(true)
					elseif not holstering then
						crouch(false)
					end
				elseif input.KeyCode == Enum.KeyCode.R then
					if not reloading then
						reload()
					end
				elseif input.KeyCode == Enum.KeyCode.F then
					if not holstering then
						if not hAnim then
							hAnim = true
							holsterAnim:Play()
						else
							hAnim = false
							holsterAnim:Stop()
						end
					end
				end
			end
		end
	end)
	
	
	inputService.InputEnded:Connect(function(input, gpe)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			mouseDown = false
		elseif input.UserInputType == Enum.UserInputType.Keyboard then
			if input.KeyCode == Enum.KeyCode.LeftShift then
				if not mouseDown and not crouching then
					holster(false)
				end
			end
		end
	end)
end



--\\ returning gun client
return gunClient
