--Flower Spirit Veiler
local s,id=GetID()
local banished_card=nil

function s.initial_effect(c)
	c:SetSpsummonOnce(id)
	--Synchro Summon: 1 Tuner + 1 non-Tuner monster
	aux.AddSynchroProcedure(c,aux.TRUE,aux.TRUE,1,1)
	--If this card is Special Summoned: add 1 "Flower Spirit" Spell from GY/banishment to hand
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCondition(s.adcon)
	e1:SetTarget(s.adtg)
	e1:SetOperation(s.adop)
	c:RegisterEffect(e1)
	--Once per turn, when you activate a Spell Card: banish 1 "Flower Spirit" Spell from GY;
	--the activated Spell's effect becomes that of the banished card
	--NOTE: dynamically swapping a resolving Spell Card's effect for a different named
	--card's effect is a very advanced/unusual mechanic. This implementation stores the
	--banished card and reuses its own registered activation effect where possible.
	--This is the most experimental part of this card - please test carefully.
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_CHAINING)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,id)
	e2:SetCondition(s.chcon)
	e2:SetCost(s.chcost)
	e2:SetTarget(s.chtg)
	e2:SetOperation(s.chop)
	c:RegisterEffect(e2)
end

function s.adcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsContains(e:GetHandler())
end
function s.adfilter(c)
	return c:IsSetCard(0x702) and c:IsType(TYPE_SPELL) and c:IsAbleToHand()
end
function s.adtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.adfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,0)
end
function s.adop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.IsExistingMatchingCard(s.adfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,nil) then
		local g=Duel.SelectMatchingCard(tp,s.adfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,1,nil)
		if g:GetCount()>0 then
			Duel.SendtoHand(g,nil,REASON_EFFECT)
			Duel.ConfirmCards(1-tp,g)
		end
	end
end

function s.chcon(e,tp,eg,ep,ev,re,r,rp)
	return re:IsActivated() and re:GetHandler():GetType()&TYPE_SPELL==TYPE_SPELL and re:GetHandlerPlayer()==tp
end
function s.gybanfilter(c)
	return c:IsSetCard(0x702) and c:IsType(TYPE_SPELL) and c:IsAbleToRemoveAsCost()
end
function s.chcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.gybanfilter,tp,LOCATION_GRAVE,0,1,nil) end
	local g=Duel.SelectMatchingCard(tp,s.gybanfilter,tp,LOCATION_GRAVE,0,1,1,nil)
	banished_card=g:GetFirst()
	Duel.ConfirmCards(1-tp,g)
	Duel.Remove(g,POS_FACEUP,REASON_COST)
end
function s.chtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
end
function s.chop(e,tp,eg,ep,ev,re,r,rp)
	local bc=banished_card
	banished_card=nil
	if not bc then return end
	local ae=bc:IsHasEffect(EFFECT_TYPE_ACTIVATE) and bc:GetActivateEffect and bc:GetActivateEffect() or nil
	if ae then
		Duel.ChangeChainOperation(ev,ae:GetOperation())
	end
end
