-- Prophecy of the Ashened City
local s,id=GetID()
Duel.LoadScript("constants.lua")

function s.initial_effect(c)
	-- Add 1 "Veidos" card, then optional Ashened add & destroy Field Spell
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_DESTROY+CATEGORY_LEAVE_GRAVE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,{id,1})
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)

	-- Send 1 Pyro from Deck then destroy 1 card on field
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOGRAVE+CATEGORY_DESTROY)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,{id,2})
	e2:SetCondition(s.gycon)
	e2:SetCost(aux.bfgcost)
	e2:SetTarget(s.gytg)
	e2:SetOperation(s.gyop)
	c:RegisterEffect(e2)
end

s.listed_series={SET_ASHENED,SET_VEIDOS}

function s.veidosfilter(c)
	return (c:IsSetCard(SET_VEIDOS) or c:IsCode(78783557,30453613,8540986)) and c:IsAbleToHand()
end

function s.ashenedfilter(c)
	return c:IsSetCard(SET_ASHENED) and c:IsAbleToHand()
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.veidosfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
	Duel.SetPossibleOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
	Duel.SetPossibleOperationInfo(0,CATEGORY_DESTROY,nil,1,0,LOCATION_FZONE)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.veidosfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g==0 or Duel.SendtoHand(g,nil,REASON_EFFECT)==0 then return end
	Duel.ConfirmCards(1-tp,g)
	local fz=Duel.IsExistingMatchingCard(nil,tp,LOCATION_FZONE,LOCATION_FZONE,1,nil)
	local ash_avail=Duel.IsExistingMatchingCard(aux.NecroValleyFilter(s.ashenedfilter),
		tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil)
	local des_avail=Duel.IsExistingMatchingCard(Card.IsType,tp,LOCATION_FZONE,LOCATION_FZONE,1,nil,TYPE_FIELD)
	if fz and ash_avail and des_avail and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
		Duel.BreakEffect()
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local ag=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.ashenedfilter),
			tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil)
		if #ag>0 and Duel.SendtoHand(ag,nil,REASON_EFFECT)>0 then
			Duel.ConfirmCards(1-tp,ag)
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
			local dg=Duel.SelectMatchingCard(tp,Card.IsType,tp,LOCATION_FZONE,LOCATION_FZONE,1,1,nil,TYPE_FIELD)
			if #dg>0 then
				Duel.Destroy(dg,REASON_EFFECT)
			end
		end
	end
end

function s.gycon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsType,TYPE_FIELD),tp,LOCATION_FZONE,LOCATION_FZONE,1,nil)
end

function s.pyrofilter(c)
	return c:IsRace(RACE_PYRO) and c:IsAbleToGrave()
end

function s.gytg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.pyrofilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_DECK)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,1,0,LOCATION_ONFIELD)
end

function s.gyop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g=Duel.SelectMatchingCard(tp,s.pyrofilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 and Duel.SendtoGrave(g,REASON_EFFECT)>0 and g:GetFirst():IsLocation(LOCATION_GRAVE) then
		local dg=Duel.GetMatchingGroup(nil,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,nil)
		if #dg>0 then
			Duel.BreakEffect()
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
			local sg=dg:Select(tp,1,1,nil)
			Duel.HintSelection(sg)
			Duel.Destroy(sg,REASON_EFFECT)
		end
	end
end
