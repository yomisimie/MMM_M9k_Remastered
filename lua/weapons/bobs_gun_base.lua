SWEP.Spawnable = false
SWEP.AdminSpawnable = false

SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false

SWEP.DrawAmmo = true
SWEP.DrawCrosshair = true
SWEP.DrawWeaponInfoBox = false
SWEP.BounceWeaponIcon = false

SWEP.ViewModelFOV = 65
SWEP.ViewModelFlip = true

SWEP.HoldType = "Pistol"

SWEP.Primary.Sound = ""
SWEP.Primary.Round = ""
SWEP.Primary.Cone = 0.2
SWEP.Primary.Recoil = 10
SWEP.Primary.Damage = 10
SWEP.Primary.Spread = .01
SWEP.Primary.NumShots = 1
SWEP.Primary.RPM = 0
SWEP.Primary.ClipSize = 0
SWEP.Primary.DefaultClip = 0
SWEP.Primary.KickUp = 0
SWEP.Primary.KickDown = 0
SWEP.Primary.KickHorizontal = 0
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "none"

SWEP.Secondary.DefaultClip = 0
SWEP.Secondary.Ammo = "none"

function SWEP:Initialize()
	util.PrecacheSound(self.Primary.Sound)
	util.PrecacheModel(self.ViewModel)
	util.PrecacheModel(self.WorldModel)

	self:SetHoldType(self.HoldType)
	self:SetWeaponHoldType(self.HoldType)
	self:SendWeaponAnim(ACT_VM_IDLE)

	if CLIENT then
		self.WepSelectIcon = surface.GetTextureID(string.gsub("vgui/hud/name","name",self:GetClass()))
	end
end

function SWEP:Equip()
	self:SetHoldType(self.HoldType)
	self:SetWeaponHoldType(self.HoldType)

	if not self.Owner:IsPlayer() then
		self:Remove()
		return
	end
end

function SWEP:Deploy()
	self:SetNextPrimaryFire(CurTime() + 1)
	self:SetNextSecondaryFire(CurTime() + 1)

	self:SetHoldType(self.HoldType)
	self:SetWeaponHoldType(self.HoldType)
	self:SendWeaponAnim(ACT_VM_DRAW)

	return true
end

function SWEP:PrimaryAttack()
	if self:CanPrimaryAttack() then
		local Spread = self.Primary.Spread
		local Class = self:GetClass()

		if not (Class == "m9k_m3" or Class == "m9k_browningauto5" or Class == "m9k_dbarrel" or Class == "m9k_ithacam37" or Class == "m9k_mossberg590" or Class == "m9k_jackhammer" or Class == "m9k_remington870" or Class == "m9k_spas12" or Class == "m9k_striker12" or Class == "m9k_1897winchester" or Class == "m9k_1887winchester") then
			if self.Owner:GetVelocity():Length() > 100 then
				Spread = self.Primary.Spread * 6
			elseif self.Owner:KeyDown(IN_DUCK) then
				Spread = self.Primary.Spread / 2
			end
		end

		self:SetNextPrimaryFire(CurTime() + 1 / (self.Primary.RPM / 60))
		self:TakePrimaryAmmo(1)
		self:ShootBullet((1 * self.Primary.Damage) * math.Rand(.85,1.3),self.Primary.Recoil,self.Primary.NumShots,Spread)
		self.Owner:SetAnimation(PLAYER_ATTACK1)
		self:EmitSound(self.Primary.Sound)
		self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
		self:MuzzleFlash() -- IDK if this is really needed tbh
	end
end

function SWEP:ShootBullet(damage,_,num_bullets,aimcone)
	num_bullets = num_bullets or 1
	aimcone = aimcone or 0

	local bullet = {
		Num = num_bullets,
		Src = self.Owner:GetShootPos(),
		Dir = self.Owner:GetAimVector(),
		Spread = Vector(aimcone,aimcone,0),
		Tracer = 3,
		TracerName = "Tracer",
		Force = damage * 0.3,
		Damage = damage
	}

	local KickUp = self.Primary.KickUp
	local KickDown = self.Primary.KickDown
	local KickHorizontal = self.Primary.KickHorizontal

	if self.Owner:KeyDown(IN_DUCK) then
		KickUp = self.Primary.KickUp / 2
		KickDown = self.Primary.KickDown / 2
		KickHorizontal = self.Primary.KickHorizontal / 2
	end

	local SharedRandom = Angle(math.Rand(-KickDown,-KickUp),math.Rand(-KickHorizontal,KickHorizontal),0)
	local eyes = self.Owner:EyeAngles()
	eyes:SetUnpacked(eyes.pitch + SharedRandom.pitch,eyes.yaw + SharedRandom.yaw,0)

	self.Owner:ViewPunch(SharedRandom)
	self.Owner:SetEyeAngles(eyes)

	self:ShootEffects()
	self.Owner:FireBullets(bullet) -- The bullet always comes out last! (Stop messing with simple logic pls.)
end

function SWEP:SecondaryAttack()
	return false
end

function SWEP:Reload()
	if self.Owner:GetAmmoCount(self.Primary.Ammo) >= 1 and self:Clip1() < self.Primary.ClipSize then
		self.Owner:SetAnimation(PLAYER_RELOAD)
		self:DefaultReload(ACT_VM_RELOAD)
	end
end

if CLIENT then
	function SWEP:FireAnimationEvent(_,_,event)
		if event == 20 or event == 5001 then return true end
	end

	function SWEP:DrawWorldModel()
		self:DrawModel()
	end
end