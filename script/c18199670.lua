-- Nahida, Genshin the Premature Philosopher
local s,id=GetID()
function s.initial_effect(c)
	-- Special Summon from hand/GY
	c:SetSPSummonOnce(id)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetRange(LOCATION_HAND+LOCATION_GRAVE)
	e1:SetCondition(s.spcon)
	c:RegisterEffect(e1)
	-- Inherit effect
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EVENT_BE_MATERIAL)
	e2:SetCondition(s.efcon)
	e2:SetOperation(s.efop)
	c:RegisterEffect(e2)
end
s.listed_series={0x369}
function s.filter(c)
	return c:IsFaceup() and c:IsSetCard(0x369)
end
function s.spcon(e,c)
	if c==nil then return true end
	return Duel.GetLocationCount(c:GetControler(),LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.filter,c:GetControler(),LOCATION_MZONE,0,1,nil)
end
function s.efcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return r==REASON_RITUAL or r==REASON_FUSION or r==REASON_SYNCHRO or r==REASON_XYZ or r==REASON_LINK
end
function s.efop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local rc=c:GetReasonCard()
	if not rc then return end
	if rc:IsSetCard(0x369) and rc:GetMaterialCount()>=2 and c:IsPreviousLocation(LOCATION_ONFIELD) then
		local e2=Effect.CreateEffect(rc)
		e2:SetDescription(aux.Stringid(id,0))
		e2:SetType(EFFECT_TYPE_FIELD)
		e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT)
		e2:SetCode(EFFECT_CANNOT_ACTIVATE)
		e2:SetRange(LOCATION_MZONE)
		e2:SetTargetRange(0,1)
		e2:SetValue(1)
		e2:SetCondition(s.armcon)
		e2:SetReset(RESET_EVENT+RESETS_STANDARD)
		rc:RegisterEffect(e2,true)
		if not rc:IsType(TYPE_EFFECT) then
			local e3=Effect.CreateEffect(c)
			e3:SetType(EFFECT_TYPE_SINGLE)
			e3:SetCode(EFFECT_ADD_TYPE)
			e3:SetValue(TYPE_EFFECT)
			e3:SetReset(RESET_EVENT+RESETS_STANDARD)
			rc:RegisterEffect(e3,true)
		end
	end
end
function s.armcon(e)
	local c=e:GetHandler()
	return Duel.GetAttacker()==c or Duel.GetAttackTarget()==c
end
