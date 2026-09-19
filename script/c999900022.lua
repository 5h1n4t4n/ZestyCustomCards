-- Magica: LAW OF CYCLES
-- ID: 999900022
local s,id=GetID()

local SET_MAGICA		  = 0x654
local CARD_MADOKA_DIVINE  = 999900003

s.listed_series={SET_MAGICA}
s.listed_names={
	-- Homura monsters
	999900019, -- Homura Akemi the Magica Student
	999900020, -- Homura the Magica Mahou Shoujo
	999900023, -- Homulily the Magica Puella Witch
	999900024, -- Endstage: Walpurgisnacht the Magica Puella Witch
	-- Madoka monsters
	999900001, -- Madoka Kaname the Magica Student
	999900002, -- Madoka the Magica Mahou Shoujo
	CARD_MADOKA_DIVINE
}

function s.initial_effect(c)
	-- Kích hoạt: Negate + Destroy + Banish GY đối thủ face-down
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY+CATEGORY_REMOVE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_CHAINING)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetCondition(s.condition)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)

	-- Hiệu ứng kích hoạt trực tiếp từ trên tay
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_TRAP_ACT_IN_HAND)
	e2:SetCondition(s.handcon)
	c:RegisterEffect(e2)
end

--------------------------------------------------------------------------------
-- CONDITION & HAND ACTIVATION LOGIC
--------------------------------------------------------------------------------
function s.reqfilter(c)
	if not (c:IsFaceup() and c:IsSetCard(SET_MAGICA)) then return false end
	local type=c:GetType()
	return (type&TYPE_RITUAL)~=0 or (type&TYPE_XYZ)~=0 or (type&TYPE_LINK)~=0 or c:IsCode(CARD_MADOKA_DIVINE)
end

function s.condition(e,tp,eg,ep,ev,re,r,rp)
	if rp==tp or not Duel.IsChainNegatable(ev) then return false end
	return Duel.IsExistingMatchingCard(s.reqfilter,tp,LOCATION_MZONE,0,1,nil)
end

function s.homura_or_madoka_filter(c)
	return c:IsFaceup() and c:IsCode(
		999900019, 999900020, 999900023, 999900024, -- Homura IDs
		999900001, 999900002, 999900003  -- Madoka IDs
	)
end

function s.handcon(e)
	return Duel.IsExistingMatchingCard(s.homura_or_madoka_filter,e:GetHandlerPlayer(),LOCATION_MZONE,0,1,nil)
end

--------------------------------------------------------------------------------
-- TARGET & OPERATION LOGIC
--------------------------------------------------------------------------------
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
	if re:GetHandler():IsRelateToEffect(re) and re:GetHandler():IsDestructable() then
		Duel.SetOperationInfo(0,CATEGORY_DESTROY,eg,1,0,0)
	end
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,1,1-tp,LOCATION_GRAVE)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local ec=re:GetHandler()
	if Duel.NegateActivation(ev) and ec:IsRelateToEffect(re) and Duel.Destroy(ec,REASON_EFFECT)>0 then
		local g=Duel.GetMatchingGroup(Card.IsAbleToRemove,tp,0,LOCATION_GRAVE,nil,tp,POS_FACEDOWN)
		if #g>0 and Duel.SelectYesNo(tp,aux.Stringid(id,0)) then
			Duel.BreakEffect()
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
			local sg=g:Select(tp,1,1,nil)
			Duel.Remove(sg,POS_FACEDOWN,REASON_EFFECT)
		end
	end
end