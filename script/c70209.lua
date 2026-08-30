--Flower Spirit-Iris on target
local s,id=GetID()

function s.initial_effect(c)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

function s.hdfilter(c)
	return c:IsSetCard(0x702) and c:IsType(TYPE_SPELL)
end
function s.gyfilter(c)
	return c:IsSetCard(0x702) and c:IsType(TYPE_SPELL) and c:IsAbleToRemoveAsCost()
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.hdfilter,tp,LOCATION_HAND+LOCATION_DECK,0,1,nil)
			or Duel.IsExistingMatchingCard(s.gyfilter,tp,LOCATION_GRAVE,0,1,nil)
	end
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local op=0
	local canop1=Duel.IsExistingMatchingCard(s.hdfilter,tp,LOCATION_HAND+LOCATION_DECK,0,1,nil)
	local canop2=Duel.IsExistingMatchingCard(s.gyfilter,tp,LOCATION_GRAVE,0,1,nil)
	if canop1 and canop2 then
		op=Duel.SelectOption(tp,aux.Stringid(id,0),aux.Stringid(id,1))
	elseif canop2 then
		op=1
	elseif not canop1 then
		return
	end
	if op==0 then
		--Send any number of "Flower Spirit" Spells with different names from hand/Deck to GY
		local g=Duel.SelectMatchingCard(tp,s.hdfilter,tp,LOCATION_HAND+LOCATION_DECK,0,1,99,nil)
		if g:GetCount()>0 then
			Duel.SendtoGrave(g,REASON_EFFECT)
			local sentct=Duel.GetOperatedGroup():GetCount()
			if sentct>0 and Duel.IsExistingTarget(Card.IsAbleToGrave,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,sentct,nil) then
				local tg=Duel.SelectTarget(tp,Card.IsAbleToGrave,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,sentct,sentct,nil)
				Duel.SendtoGrave(tg,REASON_EFFECT)
			end
		end
	else
		--Banish any number of "Flower Spirit" Spells from GY, negate targeted cards'
		--effects until the end of this turn
		local g=Duel.SelectMatchingCard(tp,s.gyfilter,tp,LOCATION_GRAVE,0,1,99,nil)
		local ct=g:GetCount()
		if ct>0 then
			Duel.Remove(g,POS_FACEUP,REASON_EFFECT)
			if Duel.IsExistingTarget(aux.TRUE,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,ct,nil) then
				local tg=Duel.SelectTarget(tp,aux.TRUE,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,ct,ct,nil)
				for tc in aux.Next(tg) do
					local le=Effect.CreateEffect(e:GetHandler())
					le:SetType(EFFECT_TYPE_SINGLE)
					le:SetCode(EFFECT_DISABLE)
					le:SetReset(RESET_PHASE+PHASE_END,1)
					tc:RegisterEffect(le)
				end
			end
		end
	end
end
