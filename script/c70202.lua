--Flower Spirit Fall Down
local s,id=GetID()

function s.initial_effect(c)
	--Activate: banish hand, Special Summon 1 "Flower Spirit" monster from Extra Deck
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.condition)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
	--If this card is banished from GY: shuffle 3 cards from GY into Deck, draw 2
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

function s.condition(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetFieldGroupCount(tp,LOCATION_HAND,0)>=2
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
	if #hg>0 then
		Duel.Remove(hg,POS_FACEUP,REASON_EFFECT)
	end
	if Duel.IsExistingMatchingCard(s.filter,tp,LOCATION_EXTRA,0,1,nil) then
		local g=Duel.SelectMatchingCard(tp,s.filter,tp,LOCATION_EXTRA,0,1,1,nil)
		if #g>0 then
			Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
		end
	end
end
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
		if #g>0 then
			Duel.SendtoDeck(g,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
		end
	end
	Duel.BreakEffect()
	Duel.Draw(tp,2,REASON_EFFECT)
	local dg=Duel.GetOperatedGroup()
	if not dg:IsExists(s.spiritfilter,1,nil) then
		local hg=Duel.GetFieldGroup(tp,LOCATION_HAND,0)
		if #hg>0 then
			Duel.Remove(hg,POS_FACEUP,REASON_EFFECT)
		end
	end
end
