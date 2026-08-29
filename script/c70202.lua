--Flower Spirit Fall Down
local s,id=GetID()

function s.initial_effect(c)
	--Activate: banish your hand, Special Summon 1 "Flower Spirit" monster from your Extra Deck
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.condition)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
	--If this card is banished from the GY: shuffle 3 cards from your GY into the Deck,
	--then draw 2 cards. If you do not draw a "Flower Spirit" card, banish your entire hand.
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetType(EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_REMOVE)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCondition(s.gcon)
	e2:SetTarget(s.gtg)
	e2:SetOperation(s.gop)
	c:RegisterEffect(e2)
end

--Main activation: 3+ cards in hand required, banish hand, Special Summon from Extra Deck
function s.condition(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetFieldGroupCount(tp,LOCATION_HAND,0)>=3
end
function s.filter(c)
	return c:IsSetCard(0x702) and c:IsType(TYPE_MONSTER)
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.filter,tp,LOCATION_EXTRA,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,0,tp,LOCATION_EXTRA)
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local hg=Duel.GetFieldGroup(tp,LOCATION_HAND,0)
	if hg:GetCount()>0 then
		Duel.Remove(hg,POS_FACEUP,REASON_EFFECT)
	end
	if Duel.IsExistingMatchingCard(s.filter,tp,LOCATION_EXTRA,0,1,nil) then
		local g=Duel.SelectMatchingCard(tp,s.filter,tp,LOCATION_EXTRA,0,1,1,nil)
		if g:GetCount()>0 then
			Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
		end
	end
end

--Trigger from GY: this card itself must be the card banished
function s.gcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsContains(e:GetHandler())
end
function s.gyfilter(c)
	return c:IsAbleToDeckAsCost()
end
function s.spiritfilter(c)
	return c:IsSetCard(0x702)
end
function s.gtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
end
function s.gop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.IsExistingMatchingCard(s.gyfilter,tp,LOCATION_GRAVE,0,1,nil) then
		local g=Duel.SelectMatchingCard(tp,s.gyfilter,tp,LOCATION_GRAVE,0,1,3,nil)
		if g:GetCount()>0 then
			Duel.SendtoDeck(g,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
		end
	end
	Duel.BreakEffect()
	Duel.Draw(tp,2,REASON_EFFECT)
	local dg=Duel.GetOperatedGroup()
	if not dg:IsExists(s.spiritfilter,1,nil) then
		local hg=Duel.GetFieldGroup(tp,LOCATION_HAND,0)
		if hg:GetCount()>0 then
			Duel.Remove(hg,POS_FACEUP,REASON_EFFECT)
		end
	end
end
