-- P.L Start!
local s,id=GetID()
function s.initial_effect(c)
	-- Activate
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_TODECK+CATEGORY_HANDES)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetHintTiming(0,TIMING_BATTLE_START+TIMING_BATTLE_END)
	e1:SetCost(s.cost)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end
s.listed_series={0x317}
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckLPCost(tp,1000) end
	Duel.PayLPCost(tp,1000)
end
function s.thfilter(c)
	return c:IsSetCard(0x317) and c:IsMonster() and c:IsAbleToHand()
end
function s.revfilter(c)
	return c:IsSetCard(0x317) and c:IsMonster()
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	local g=Duel.GetMatchingGroup(s.thfilter,tp,LOCATION_DECK,0,nil)
	local b1 = g:GetClassCount(Card.GetAttribute)>=2 and Duel.GetFlagEffect(tp,id)==0
	
	local hg=Duel.GetMatchingGroup(s.revfilter,tp,LOCATION_HAND,0,nil)
	local b2 = hg:GetClassCount(Card.GetAttribute)>=2 and Duel.GetFieldGroupCount(tp,0,LOCATION_HAND)>0 and Duel.GetFlagEffect(tp,id+1)==0
	
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
		Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,2,tp,LOCATION_DECK)
		if not (Duel.GetCurrentPhase()>=PHASE_BATTLE_START and Duel.GetCurrentPhase()<=PHASE_BATTLE) then
			Duel.SetOperationInfo(0,CATEGORY_HANDES,nil,1,tp,1)
		end
	else
		Duel.RegisterFlagEffect(tp,id+1,RESET_PHASE+PHASE_END,0,1)
		Duel.SetOperationInfo(0,CATEGORY_TODECK,nil,1,1-tp,LOCATION_ONFIELD+LOCATION_HAND)
	end
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local op=e:GetLabel()
	local is_bp = (Duel.GetCurrentPhase()>=PHASE_BATTLE_START and Duel.GetCurrentPhase()<=PHASE_BATTLE)
	if op==0 then
		local g=Duel.GetMatchingGroup(s.thfilter,tp,LOCATION_DECK,0,nil)
		if g:GetClassCount(Card.GetAttribute)>=2 then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
			local g1=g:Select(tp,1,1,nil)
			if #g1>0 then
				local tc1=g1:GetFirst()
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
				local g2=g:FilterSelect(tp,function(c,attr) return c:GetAttribute()~=attr end,1,1,tc1,tc1:GetAttribute())
				g1:Merge(g2)
				if #g1==2 then
					Duel.SendtoHand(g1,nil,REASON_EFFECT)
					Duel.ConfirmCards(1-tp,g1)
					if not is_bp then
						Duel.BreakEffect()
						Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DISCARD)
						local dg=Duel.SelectMatchingCard(tp,aux.TRUE,tp,LOCATION_HAND,0,1,1,nil)
						if #dg>0 then
							Duel.SendtoGrave(dg,REASON_EFFECT+REASON_DISCARD)
						end
					end
				end
			end
		end
	else
		local hg=Duel.GetMatchingGroup(s.revfilter,tp,LOCATION_HAND,0,nil)
		if hg:GetClassCount(Card.GetAttribute)>=2 and Duel.GetFieldGroupCount(tp,0,LOCATION_HAND)>0 then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONFIRM)
			local g1=hg:Select(tp,1,1,nil)
			if #g1>0 then
				local tc1=g1:GetFirst()
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONFIRM)
				local g2=hg:FilterSelect(tp,function(c,attr) return c:GetAttribute()~=attr end,1,1,tc1,tc1:GetAttribute())
				g1:Merge(g2)
				if #g1==2 then
					Duel.ConfirmCards(1-tp,g1)
					local opp_hand=Duel.GetFieldGroup(tp,0,LOCATION_HAND)
					Duel.ConfirmCards(tp,opp_hand)
					local shuf_g = Duel.GetMatchingGroup(nil,tp,0,LOCATION_ONFIELD,nil)
					if is_bp then
						shuf_g:Merge(opp_hand)
					end
					if #shuf_g>0 and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
						Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
						local to_deck = shuf_g:Select(tp,1,2,nil)
						Duel.SendtoDeck(to_deck,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
					end
					Duel.ShuffleHand(1-tp)
				end
			end
		end
	end
end
