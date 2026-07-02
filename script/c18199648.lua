-- Genshin Execution - Holy Lyre Ringing
local s,id=GetID()
function s.initial_effect(c)
	-- Activate
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_TODECK+CATEGORY_DRAW)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.target)
	e1:SetOperation(s.operation)
	c:RegisterEffect(e1)
end
s.listed_series={0x369}
function s.tdfilter1(c)
	return c:IsSetCard(0x369) and c:IsAbleToDeck()
end
function s.tdfilter2(c)
	return c:IsFaceup() and c:IsSetCard(0x369) and c:IsAbleToDeck()
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		if e:GetLabel()==1 then
			return chkc:IsLocation(LOCATION_GRAVE) and chkc:IsControler(tp) and s.tdfilter1(chkc)
		else
			return chkc:IsLocation(LOCATION_REMOVED) and chkc:IsControler(tp) and s.tdfilter2(chkc)
		end
	end
	local g1=Duel.GetMatchingGroup(s.tdfilter1,tp,LOCATION_GRAVE,0,nil)
	local b1=g1:GetClassCount(Card.GetCode)>=5 and Duel.IsPlayerCanDraw(tp,2)
	local g2=Duel.GetMatchingGroup(s.tdfilter2,tp,LOCATION_REMOVED,0,nil)
	local b2=g2:GetClassCount(Card.GetCode)>=3 and Duel.IsPlayerCanDraw(tp,1)
	if chk==0 then return b1 or b2 end
	local op=0
	if b1 and b2 then
		op=Duel.SelectOption(tp,aux.Stringid(id,0),aux.Stringid(id,1))+1
	elseif b1 then
		op=Duel.SelectOption(tp,aux.Stringid(id,0))+1
	else
		op=Duel.SelectOption(tp,aux.Stringid(id,1))+2
	end
	e:SetLabel(op)
	local sg=Group.CreateGroup()
	if op==1 then
		e:SetCategory(CATEGORY_TODECK+CATEGORY_DRAW)
		for i=1,5 do
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
			local tc=g1:Select(tp,1,1,nil):GetFirst()
			sg:AddCard(tc)
			g1:Remove(Card.IsCode,nil,tc:GetCode())
		end
		Duel.SetTargetCard(sg)
		Duel.SetOperationInfo(0,CATEGORY_TODECK,sg,5,0,0)
		Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,2)
	else
		e:SetCategory(CATEGORY_TODECK+CATEGORY_DRAW)
		for i=1,3 do
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
			local tc=g2:Select(tp,1,1,nil):GetFirst()
			sg:AddCard(tc)
			g2:Remove(Card.IsCode,nil,tc:GetCode())
		end
		Duel.SetTargetCard(sg)
		Duel.SetOperationInfo(0,CATEGORY_TODECK,sg,3,0,0)
		Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,1)
	end
end
function s.operation(e,tp,eg,ep,ev,re,r,rp)
	local tg=Duel.GetTargetCards(e)
	if #tg==0 then return end
	Duel.SendtoDeck(tg,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
	local g=Duel.GetOperatedGroup()
	if g:IsExists(Card.IsLocation,1,nil,LOCATION_DECK+LOCATION_EXTRA) then
		if g:IsExists(Card.IsLocation,1,nil,LOCATION_DECK) then Duel.ShuffleDeck(tp) end
		local ct = e:GetLabel()==1 and 2 or 1
		Duel.BreakEffect()
		Duel.Draw(tp,ct,REASON_EFFECT)
	end
end
