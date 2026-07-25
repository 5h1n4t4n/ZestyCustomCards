-- P.L Lunch
local s,id=GetID()
function s.initial_effect(c)
	-- Activate
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_RECOVER+CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_TODECK+CATEGORY_DRAW)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetHintTiming(0,TIMING_BATTLE_START+TIMING_BATTLE_END)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end
s.listed_series={0x317}
function s.thfilter(c)
	return c:IsSetCard(0x317) and c:IsAbleToHand()
end
function s.tdfilter(c)
	return c:IsSetCard(0x317) and c:IsAbleToDeck()
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	local hg=Duel.GetFieldGroup(tp,LOCATION_HAND,0)
	hg:RemoveCard(e:GetHandler())
	local b1 = #hg==0 and Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) and Duel.GetFlagEffect(tp,id)==0
	local b2 = Duel.IsExistingMatchingCard(s.tdfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,2,nil) and Duel.GetFlagEffect(tp,id+1)==0
	
	if chk==0 then return b1 or b2 end
	local op=0
	if b1 and b2 then
		op=Duel.SelectOption(tp,aux.Stringid(id,0),aux.Stringid(id,1))
	elseif b1 then
		op=0
	else
		op=1
	end
	e:SetLabel(op)
	if op==0 then
		Duel.RegisterFlagEffect(tp,id,RESET_PHASE+PHASE_END,0,1)
		Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
	else
		Duel.RegisterFlagEffect(tp,id+1,RESET_PHASE+PHASE_END,0,1)
		Duel.SetOperationInfo(0,CATEGORY_TODECK,nil,2,tp,LOCATION_GRAVE+LOCATION_REMOVED)
	end
	Duel.SetOperationInfo(0,CATEGORY_RECOVER,nil,0,tp,1000)
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	Duel.Recover(tp,1000,REASON_EFFECT)
	local op=e:GetLabel()
	local is_bp = (Duel.GetCurrentPhase()>=PHASE_BATTLE_START and Duel.GetCurrentPhase()<=PHASE_BATTLE)
	if op==0 then
		-- Effect 1
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
		if #g>0 and Duel.SendtoHand(g,nil,REASON_EFFECT)>0 then
			Duel.ConfirmCards(1-tp,g)
			if is_bp and Duel.IsPlayerCanDraw(tp,1) then
				Duel.BreakEffect()
				Duel.Draw(tp,1,REASON_EFFECT)
			end
		end
	else
		-- Effect 2
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
		local g=Duel.SelectMatchingCard(tp,s.tdfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,2,2,nil)
		if #g>0 then
			Duel.SendtoDeck(g,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
			if is_bp and Duel.IsPlayerCanDraw(tp,2) then
				Duel.BreakEffect()
				Duel.Draw(tp,2,REASON_EFFECT)
			end
		end
	end
end
