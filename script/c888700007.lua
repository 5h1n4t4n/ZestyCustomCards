-- Rising Search
-- ID: 888700007
local s,id=GetID()

local SET_RISING_HERO = 0xff8

s.listed_series={SET_RISING_HERO}

function s.initial_effect(c)
	-- Activate: Gửi 1 quái LIGHT Warrior có 1000 DEF từ tay xuống GY -> Rút 2 lá
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DRAW)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCost(s.cost)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

--------------------------------------------------------------------------------
-- DRAW & RESTRICTION LOGIC
--------------------------------------------------------------------------------
function s.cfilter(c)
	return c:IsAttribute(ATTRIBUTE_LIGHT) 
		and c:IsRace(RACE_WARRIOR) 
		and c:IsDefense(1000) 
		and c:IsAbleToGraveAsCost()
end

function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_HAND,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g=Duel.SelectMatchingCard(tp,s.cfilter,tp,LOCATION_HAND,0,1,1,nil)
	Duel.SendtoGrave(g,REASON_COST)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsPlayerCanDraw(tp,2) end
	Duel.SetTargetPlayer(tp)
	Duel.SetTargetParam(2)
	Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,2)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local p,d=Duel.GetChainInfo(0,CHAININFO_TARGET_PLAYER,CHAININFO_TARGET_PARAM)
	if Duel.Draw(p,d,REASON_EFFECT)>0 then
		-- Giới hạn: Trong lượt này chỉ quái LIGHT Warrior mới được tuyên bố tấn công
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_FIELD)
		e1:SetCode(EFFECT_CANNOT_ATTACK_ANNOUNCE)
		e1:SetTargetRange(LOCATION_MZONE,0)
		e1:SetTarget(s.atktg)
		e1:SetReset(RESET_PHASE+PHASE_END)
		Duel.RegisterEffect(e1,tp)
	end
end

function s.atktg(e,c)
	-- Khóa tấn công đối với quái KHÔNG PHẢI LIGHT Warrior
	return not (c:IsAttribute(ATTRIBUTE_LIGHT) and c:IsRace(RACE_WARRIOR))
end
