-- Rise Motor Emergent
-- ID: 888700005
local s,id=GetID()

local SET_RISING_UNIT = 0xa63
local SET_HERO		= 0x8

s.listed_series={SET_RISING_UNIT, SET_HERO}

function s.initial_effect(c)
	-- Quy tắc: Luôn được coi là lá "Rising Unit" (0xa63)
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_ADD_SETCODE)
	e0:SetValue(SET_RISING_UNIT)
	c:RegisterEffect(e0)

	-- Quick Effect: Discard từ tay -> Quái "HERO" (bao gồm Rising HERO) không bị phá hủy bởi hiệu ứng trong lượt này
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id) 
	e1:SetCost(s.indcost)
	e1:SetOperation(s.indop)
	c:RegisterEffect(e1)
end

--------------------------------------------------------------------------------
-- INDESTRUCTIBLE LOGIC
--------------------------------------------------------------------------------
function s.indcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsAbleToGraveAsCost() end
	Duel.SendtoGrave(c,REASON_COST)
end

function s.indtg(e,c)
	-- Bảo kê tất cả quái có mã HERO (0x8) - Tự động bao gồm cả Rising HERO (0xff8)
	return c:IsSetCard(SET_HERO)
end

function s.indop(e,tp,eg,ep,ev,re,r,rp)
	
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e1:SetTargetRange(LOCATION_MZONE,0)
	e1:SetTarget(s.indtg)
	e1:SetValue(1) 
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
end