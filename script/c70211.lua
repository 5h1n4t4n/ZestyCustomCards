--Flower Spirit-Rose no more Thorns
local s,id=GetID()
local banished_card2=nil

function s.initial_effect(c)
	--Send 1 Spell Card from your hand to the GY (you can also send 1 "Flower Spirit"
	--Spell from your Deck to the GY), set 1 "Flower Spirit" Spell from your Deck
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id)
	e1:SetCost(s.cost)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
	--(Quick Effect): banish this card and 1 "Flower Spirit" card from your GY; apply 1 of
	--the other banished card's effects
	--NOTE: reusing an arbitrary banished card's effect is implementation-specific; this
	--reuses the banished card's own registered activation effect where possible. Please
	--test carefully.
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,id+1)
	e2:SetCost(s.reusecost)
	e2:SetTarget(s.reusetg)
	e2:SetOperation(s.reuseop)
	c:RegisterEffect(e2)
end

--Send 1 Spell from hand to GY (mandatory cost); optionally also send 1 "Flower Spirit"
--Spell from the Deck to the GY
function s.handfilter(c)
	return c:IsType(TYPE_SPELL) and c:IsAbleToGraveAsCost()
end
function s.deckspellfilter(c)
	return c:IsSetCard(0x702) and c:IsType(TYPE_SPELL) and c:IsAbleToGraveAsCost()
end
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.handfilter,tp,LOCATION_HAND,0,1,nil) end
	local g=Duel.SelectMatchingCard(tp,s.handfilter,tp,LOCATION_HAND,0,1,1,nil)
	Duel.SendtoGrave(g,REASON_COST)
	if Duel.IsExistingMatchingCard(s.deckspellfilter,tp,LOCATION_DECK,0,1,nil)
		and Duel.SelectYesNo(tp,aux.Stringid(id,1)) then
		local g2=Duel.SelectMatchingCard(tp,s.deckspellfilter,tp,LOCATION_DECK,0,1,1,nil)
		if g2:GetCount()>0 then Duel.SendtoGrave(g2,REASON_COST) end
	end
end

--Set 1 "Flower Spirit" Spell from the Deck
function s.setfilter(c)
	return c:IsSetCard(0x702) and c:IsType(TYPE_SPELL) and c:IsSSetable()
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOFIELD,nil,1,tp,0)
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	if Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_DECK,0,1,nil) then
		local g=Duel.SelectMatchingCard(tp,s.setfilter,tp,LOCATION_DECK,0,1,1,nil)
		if g:GetCount()>0 then Duel.SSet(tp,g) end
	end
end

--Quick Effect: banish this card (from GY) + 1 "Flower Spirit" card from GY; reuse 1 of
--the other banished card's effects
function s.gy2filter(c)
	return c:IsSetCard(0x702) and c:IsAbleToRemoveAsCost()
end
function s.reusecost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsAbleToRemoveAsCost() and Duel.IsExistingMatchingCard(s.gy2filter,tp,LOCATION_GRAVE,0,1,c) end
	local g=Duel.SelectMatchingCard(tp,s.gy2filter,tp,LOCATION_GRAVE,0,1,1,c)
	banished_card2=g:GetFirst()
	Duel.Remove(c,POS_FACEUP,REASON_COST)
	Duel.Remove(g,POS_FACEUP,REASON_COST)
end
function s.reusetg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
end
function s.reuseop(e,tp,eg,ep,ev,re,r,rp)
	local bc=banished_card2
	banished_card2=nil
	if not bc then return end
	local ae=bc:IsHasEffect(EFFECT_TYPE_ACTIVATE) and bc:GetActivateEffect and bc:GetActivateEffect() or nil
	if ae then
		local op=ae:GetOperation()
		if op then op(ae,tp,eg,ep,ev,re,r,rp) end
	end
end
