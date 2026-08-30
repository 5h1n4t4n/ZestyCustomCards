--Flower Spirit-Called of the Spring
local s,id=GetID()

function s.initial_effect(c)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
	--If your opponent banishes a card(s): shuffle 1 of those cards into the Deck, then
	--each player adds 1 banished card to their hand (works while this card sits in the GY)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_REMOVE)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCondition(s.gybancon)
	e2:SetTarget(s.gybantg)
	e2:SetOperation(s.gybanop)
	c:RegisterEffect(e2)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local fieldcount=Duel.GetFieldGroupCount(tp,LOCATION_ONFIELD,0)
	local gycount=Duel.GetFieldGroupCount(tp,LOCATION_GRAVE,0)
	local shufflecount=0
	local zones={LOCATION_ONFIELD,LOCATION_HAND,LOCATION_GRAVE,LOCATION_REMOVED}
	for _,loc in ipairs(zones) do
		local g=Duel.GetMatchingGroup(Card.IsAbleToDeckAsCost,tp,loc,0,nil)
		if g:GetCount()>0 then
			shufflecount=shufflecount+g:GetCount()
			Duel.SendtoDeck(g,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
		end
	end
	Duel.BreakEffect()
	if shufflecount>0 then Duel.Draw(tp,shufflecount,REASON_EFFECT) end
	--Set as many cards from hand as possible, up to the number of cards you controlled
	local sc=math.min(fieldcount,Duel.GetFieldGroupCount(tp,LOCATION_HAND,0))
	if sc>0 and Duel.IsExistingMatchingCard(Card.IsSSetable,tp,LOCATION_HAND,0,1,nil) then
		local setcount=math.min(sc,Duel.GetMatchingGroupCount(Card.IsSSetable,tp,LOCATION_HAND,0,nil))
		if setcount>0 then
			local sg=Duel.SelectMatchingCard(tp,Card.IsSSetable,tp,LOCATION_HAND,0,setcount,setcount,nil)
			if sg:GetCount()>0 then Duel.SSet(tp,sg) end
		end
	end
	--Send cards from hand to the GY equal to the number that were in your GY before
	local dc=math.min(gycount,Duel.GetFieldGroupCount(tp,LOCATION_HAND,0))
	if dc>0 then
		local dg=Duel.SelectMatchingCard(tp,aux.TRUE,tp,LOCATION_HAND,0,dc,dc,nil)
		if dg:GetCount()>0 then Duel.SendtoGrave(dg,REASON_EFFECT) end
	end
	--Banish all cards remaining in your hand
	local finalhand=Duel.GetFieldGroup(tp,LOCATION_HAND,0)
	if finalhand:GetCount()>0 then
		Duel.Remove(finalhand,POS_FACEUP,REASON_EFFECT)
	end
end

function s.gybancon(e,tp,eg,ep,ev,re,r,rp)
	return rp==1-tp
end
function s.gybantg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return eg:IsExists(Card.IsAbleToDeckAsCost,1,nil) end
	local g=eg:FilterSelect(tp,Card.IsAbleToDeckAsCost,1,1,nil)
	Duel.SetTargetCard(g)
	Duel.SetOperationInfo(0,CATEGORY_TODECK,g,1,0,0)
end
function s.gybanop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) and tc:IsAbleToDeckAsCost() then
		Duel.SendtoDeck(tc,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
	end
	if Duel.IsExistingMatchingCard(Card.IsAbleToHand,tp,LOCATION_REMOVED,0,1,nil) then
		local g1=Duel.SelectMatchingCard(tp,Card.IsAbleToHand,tp,LOCATION_REMOVED,0,1,1,nil)
		if g1:GetCount()>0 then Duel.SendtoHand(g1,nil,REASON_EFFECT) Duel.ConfirmCards(1-tp,g1) end
	end
	if Duel.IsExistingMatchingCard(Card.IsAbleToHand,1-tp,LOCATION_REMOVED,0,1,nil) then
		local g2=Duel.SelectMatchingCard(1-tp,Card.IsAbleToHand,1-tp,LOCATION_REMOVED,0,1,1,nil)
		if g2:GetCount()>0 then Duel.SendtoHand(g2,nil,REASON_EFFECT) Duel.ConfirmCards(tp,g2) end
	end
end
