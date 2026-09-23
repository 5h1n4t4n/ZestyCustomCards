-- Veidos's Erupting Egg of Extinction
local s,id=GetID()
Duel.LoadScript("constants.lua")

function s.initial_effect(c)
	-- Discard to add Veidos and send Ashened card
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_TOGRAVE)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_HAND)
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E+TIMING_MAIN_END)
	e1:SetCountLimit(1,{id,1})
	e1:SetCondition(s.quickcon)
	e1:SetCost(s.quickcost)
	e1:SetTarget(s.quicktg)
	e1:SetOperation(s.quickop)
	c:RegisterEffect(e1)

	-- Add this card to hand if Veidos leaves the field
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_LEAVE_FIELD)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,{id,2})
	e2:SetCondition(s.thcon)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
end

s.listed_names={78783557,id}
s.listed_series={SET_ASHENED,SET_VEIDOS}

function s.quickcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(nil,tp,LOCATION_FZONE,LOCATION_FZONE,1,nil)
end

function s.quickcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsDiscardable() end
	Duel.SendtoGrave(c,REASON_COST+REASON_DISCARD)
end

function s.vfilter(c)
	return c:IsPreviousPosition(POS_FACEUP) and c:IsPreviousCodeOnField(78783557)
end

function s.ashenedfilter(c)
	return c:IsSetCard(SET_ASHENED) and c:IsAbleToGrave()
end

function s.veidosfilter(c)
	return c:IsCode(78783557) and c:IsAbleToHand()
end

function s.quicktg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.veidosfilter,tp,LOCATION_DECK,0,1,nil)
			and Duel.IsExistingMatchingCard(s.ashenedfilter,tp,LOCATION_DECK,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_DECK)
end

function s.quickop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g1=Duel.SelectMatchingCard(tp,s.veidosfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g1>0 and Duel.SendtoHand(g1,nil,REASON_EFFECT)>0 and g1:GetFirst():IsLocation(LOCATION_HAND) then
		Duel.ConfirmCards(1-tp,g1)
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
		local g2=Duel.SelectMatchingCard(tp,s.ashenedfilter,tp,LOCATION_DECK,0,1,1,nil)
		if #g2>0 then
			Duel.BreakEffect()
			Duel.SendtoGrave(g2,REASON_EFFECT)
		end
	end
end

function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return eg:IsExists(s.vfilter,1,nil) and not eg:IsContains(c)
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsAbleToHand() end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,c,1,tp,0)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SendtoHand(c,nil,REASON_EFFECT)
	end
end
