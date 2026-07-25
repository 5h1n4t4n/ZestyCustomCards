-- Papyrus the Skeleton Warrior
local s,id=GetID()
function s.initial_effect(c)
	-- Special Summon from hand
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetRange(LOCATION_HAND)
	e1:SetCondition(s.spcon)
	c:RegisterEffect(e1)
	-- Excavate 5 cards on opponent's Deck and place 2 at bottom
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TODECK)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_BE_MATERIAL)
	e2:SetCountLimit(1,id)
	e2:SetCondition(s.excon)
	e2:SetTarget(s.extg)
	e2:SetOperation(s.exop)
	c:RegisterEffect(e2)
	-- Banish trigger: Return to Deck and Bounce 2 cards
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_TOHAND+CATEGORY_TODECK)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e3:SetCode(EVENT_REMOVE)
	e3:SetRange(LOCATION_GRAVE)
	e3:SetCountLimit(1,{id,1})
	e3:SetCondition(s.thcon)
	e3:SetCost(s.thcost)
	e3:SetTarget(s.thtg)
	e3:SetOperation(s.thop)
	c:RegisterEffect(e3)
end
s.listed_series={0x366}
function s.spfilter(c)
	return c:IsFaceup() and c:IsSetCard(0x366)
end
function s.spcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_MZONE,0,2,nil)
end
function s.excon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsLocation(LOCATION_GRAVE) and (r&REASON_FUSION~=0 or r&REASON_SYNCHRO~=0)
end
function s.extg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetFieldGroupCount(tp,0,LOCATION_DECK)>0 end
end
function s.exop(e,tp,eg,ep,ev,re,r,rp)
	local count=Duel.GetFieldGroupCount(tp,0,LOCATION_DECK)
	if count>0 then
		local exc=math.min(5,count)
		Duel.ConfirmDecktop(1-tp,exc)
		local g=Duel.GetDecktopGroup(1-tp,exc)
		if #g>=2 then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
			local sg=g:Select(tp,2,2,nil)
			Duel.SendtoDeck(sg,nil,SEQ_DECKBOTTOM,REASON_EFFECT)
		elseif #g>0 then
			Duel.SendtoDeck(g,nil,SEQ_DECKBOTTOM,REASON_EFFECT)
		end
	end
end
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	return not eg:IsContains(e:GetHandler())
end
function s.thcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsAbleToDeckAsCost() end
	Duel.SendtoDeck(e:GetHandler(),nil,SEQ_DECKSHUFFLE,REASON_COST)
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return false end
	if chk==0 then return Duel.IsExistingTarget(Card.IsAbleToHand,tp,LOCATION_ONFIELD,0,1,nil)
		and Duel.IsExistingTarget(Card.IsAbleToHand,tp,0,LOCATION_ONFIELD,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RTOHAND)
	local g1=Duel.SelectTarget(tp,Card.IsAbleToHand,tp,LOCATION_ONFIELD,0,1,1,nil)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RTOHAND)
	local g2=Duel.SelectTarget(tp,Card.IsAbleToHand,tp,0,LOCATION_ONFIELD,1,1,nil)
	g1:Merge(g2)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,g1,2,0,0)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetTargetCards(e)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
	end
end
