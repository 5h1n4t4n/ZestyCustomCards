-- Rise Motor Contractor
-- ID: 888700003
local s,id=GetID()

local SET_RISING_UNIT = 0xa63
local SET_RISING_HERO = 0xff8

s.listed_series={SET_RISING_UNIT, SET_RISING_HERO}

function s.initial_effect(c)
	-- Quy tắc: Luôn được coi là lá "Rising Unit" (0xa63)
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_ADD_SETCODE)
	e0:SetValue(SET_RISING_UNIT)
	c:RegisterEffect(e0)

	-- Quick Effect: Bỏ bài từ tay xuống GY để Vô hiệu hóa hiệu ứng
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DISABLE)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_CHAINING)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id) -- [HOPT] 1 lần mỗi lượt
	e1:SetCondition(s.negcon)
	e1:SetCost(s.negcost)
	e1:SetTarget(s.negtg)
	e1:SetOperation(s.negop)
	c:RegisterEffect(e1)
end

--------------------------------------------------------------------------------
-- NEGATE LOGIC
--------------------------------------------------------------------------------
function s.cfilter(c)
	-- Kiểm tra người chơi có đang điều khiển quái thú "Rising HERO" (0xff8) trên sân
	return c:IsFaceup() and c:IsSetCard(SET_RISING_HERO)
end

function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsChainDisablable(ev)
		and Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_MZONE,0,1,nil)
end

function s.negcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsAbleToGraveAsCost() end
	Duel.SendtoGrave(c,REASON_COST)
end

function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_DISABLE,eg,1,0,0)
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)
	Duel.NegateEffect(ev)
end