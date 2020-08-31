SWEP.Base = "bobs_gun_base"
SWEP.Slot = 4

SWEP.Primary.SpreadZoomed = .001

SWEP.ScopeCD = 0
SWEP.ScopeScale = 0.5
SWEP.ReticleScale = 0.5
SWEP.NextReloadTime = 0

function SWEP:Initialize()
	self:SetHoldType(self.HoldType)
	self.OurIndex = self:EntIndex()
	self:SetNWInt("ScopeState",0)

	if SERVER and game.SinglePlayer() then -- In singleplayer we need to force the weapon to be equipped after spawning
		timer.Simple(0,function()
			if not IsValid(self) or not IsValid(self.Owner) then return end -- We need to abort when the owner already had the weapon!
			self.Owner:SelectWeapon(self:GetClass())
		end)
	end

	if CLIENT then
		self.WepSelectIcon = surface.GetTextureID(string.gsub("vgui/hud/name","name",self:GetClass()))

		if self.Owner == LocalPlayer() then
			self:SendWeaponAnim(ACT_VM_IDLE)

			if self.Owner:GetActiveWeapon() == self then -- Compat/Bugfix
				self:Equip()
				self:Deploy()
			end
		end

		local iScreenWidth = ScrW()
		local iScreenHeight = ScrH()

		self.ScopeTable = {}
		self.ScopeTable.l = iScreenHeight * self.ScopeScale
		self.ScopeTable.x1 = 0.5 * (iScreenWidth + self.ScopeTable.l)
		self.ScopeTable.y1 = 0.5 * (iScreenHeight - self.ScopeTable.l)
		self.ScopeTable.x2 = self.ScopeTable.x1
		self.ScopeTable.y2 = 0.5 * (iScreenHeight + self.ScopeTable.l)
		self.ScopeTable.x3 = 0.5 * (iScreenWidth - self.ScopeTable.l)
		self.ScopeTable.y3 = self.ScopeTable.y2
		self.ScopeTable.x4 = self.ScopeTable.x3
		self.ScopeTable.y4 = self.ScopeTable.y1
		self.ScopeTable.l = (iScreenHeight + 1) * self.ScopeScale
		self.QuadTable = {}
		self.QuadTable.x1 = 0
		self.QuadTable.y1 = 0
		self.QuadTable.w1 = iScreenWidth
		self.QuadTable.h1 = 0.5 * iScreenHeight - self.ScopeTable.l
		self.QuadTable.x2 = 0
		self.QuadTable.y2 = 0.5 * iScreenHeight + self.ScopeTable.l
		self.QuadTable.w2 = self.QuadTable.w1
		self.QuadTable.h2 = self.QuadTable.h1
		self.QuadTable.x3 = 0
		self.QuadTable.y3 = 0
		self.QuadTable.w3 = 0.5 * iScreenWidth - self.ScopeTable.l
		self.QuadTable.h3 = iScreenHeight
		self.QuadTable.x4 = 0.5 * iScreenWidth + self.ScopeTable.l
		self.QuadTable.y4 = 0
		self.QuadTable.w4 = self.QuadTable.w3
		self.QuadTable.h4 = self.QuadTable.h3
		self.LensTable = {}
		self.LensTable.x = self.QuadTable.w3
		self.LensTable.y = self.QuadTable.h1
		self.LensTable.w = 2 * self.ScopeTable.l
		self.LensTable.h = 2 * self.ScopeTable.l
		self.ReticleTable = {}
		self.ReticleTable.wdivider = 3.125
		self.ReticleTable.hdivider = 1.7579 / self.ReticleScale
		self.ReticleTable.x = (iScreenWidth / 2) - ((iScreenHeight / self.ReticleTable.hdivider) / 2)
		self.ReticleTable.y = (iScreenHeight / 2) - ((iScreenHeight / self.ReticleTable.hdivider) / 2)
		self.ReticleTable.w = iScreenHeight / self.ReticleTable.hdivider
		self.ReticleTable.h = iScreenHeight / self.ReticleTable.hdivider
	end
end

function SWEP:Think()
	if self:GetNWInt("ScopeState") > 0 and self.Owner:GetVelocity():Length() < 100 then
		self.Primary.Spread = self.Primary.SpreadZoomed
	else
		self.Primary.Spread = self.Primary.SpreadBefore
	end
end

function SWEP:Holster()
	if not SERVER and self.Owner ~= LocalPlayer() then return end

	timer.Remove("m9k_resetscope_" .. self.OurIndex)
	self.Owner:DrawViewModel(true)
	self:SetNWInt("ScopeState",0)
	return true
end

function SWEP:AdjustMouseSensitivity()
	local Scope = self:GetNWInt("ScopeState")

	if Scope == 0 then
		return 1
	elseif Scope == 1 then
		return 0.75
	elseif Scope == 2 then
		return 0.35
	elseif Scope == 3 then
		return 0.1
	end
end

function SWEP:SecondaryAttack()
	if self.ScopeCD > CurTime() or self.Owner:GetViewEntity() ~= self.Owner then return false end
	local Scope = self:GetNWInt("ScopeState")

	Scope = Scope  + 1
	if Scope > 3 then
		Scope = 0
	end
	self.ScopeCD = CurTime() + 0.2

	if Scope == 0 then
		self.Owner:SetFOV(0,0.1)
	elseif Scope == 1 then
		self.Owner:SetFOV(50,0.1)
	elseif Scope == 2 then
		self.Owner:SetFOV(25,0.1)
	elseif Scope == 3 then
		self.Owner:SetFOV(10,0.1)
	end

	self:SetNWInt("ScopeState",Scope)
	self.Owner:EmitSound("weapons/zoom.wav")
end

function SWEP:Reload()
	if SERVER and game.SinglePlayer() then self:CallOnClient("Reload") end -- Make sure that it runs on the CLIENT!

	if self:GetNWInt("ScopeState") > 0 then
		self.Owner:SetFOV(0,0.1)
		self:SetNWInt("ScopeState",0)
		self.ScopeCD = CurTime() + 0.2
		self.Owner:EmitSound("weapons/zoom.wav")
		self.NextReloadTime = CurTime() + 0.5
	end

	if self.CanReload and self.NextReloadTime < CurTime() and self.Owner:GetAmmoCount(self.Primary.Ammo) >= 1 and self:Clip1() < self:GetMaxClip1() then
		self:DefaultReload(ACT_VM_RELOAD)
		self.Owner:SetAnimation(PLAYER_RELOAD)
	end
end

if CLIENT then
	local effectData = EffectData()

	function SWEP:FireAnimationEvent(_,_,event)
		if event == 5001 or event == 5011 or event == 5021 or event == 5031 then
			if self.Owner:GetViewEntity() ~= self.Owner or self:GetNWInt("ScopeState") > 0 then return true end
			local vm = self.Owner:GetViewModel()
			if not IsValid(vm) then return end

			local vmAttachment = vm:GetAttachment("1")

			effectData:SetAttachment(1)
			effectData:SetEntity(vm)
			effectData:SetScale(1)
			effectData:SetMagnitude(1)
			effectData:SetOrigin(vmAttachment.Pos)
			effectData:SetAngles(vmAttachment.Ang)
			util.Effect("CS_MuzzleFlash",effectData)

			return true
		end
	end
end