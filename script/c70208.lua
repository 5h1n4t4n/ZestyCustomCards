--Flower Spirit-Called of the Spring
local s,id=GetID()

function s.initial_effect(c)
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_TODECK+CATEGORY_DRAW+CATEGORY_TOGRAVE+CATEGORY_REMOVE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id+EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
	--Trigger from GY when opponent banishes card
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_TODECK+CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_REMOVE)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,id+100)
	e2:SetCost(aux.bfgcost)
	e2:SetCondition(s.gybancon)
	e2:SetTarget(s.gybantg)
	e2:SetOperation(s.gybanop)
	c:RegisterEffect(e2)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_TODECK,nil,1,tp,LOCATION_ONFIELD+LOCATION_HAND+LOCATION_GRAVE+LOCATION_REMOVED)
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local field_count=Duel.GetFieldGroupCount(tp,LOCATION_ONFIELD,0)
	if c:IsRelateToEffect(e) then field_count=field_count-1 end
	local gy_count=Duel.GetFieldGroupCount(tp,LOCATION_GRAVE,0)
	local g=Duel.GetFieldGroup(tp,LOCATION_ONFIELD+LOCATION_HAND+LOCATION_GRAVE+LOCATION_REMOVED,0)
	if c:IsRelateToEffect(e) then g:RemoveCard(c) end
	if #g==0 then return end
	local shuffled=Duel.SendtoDeck(g,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
	if shuffled>0 then
		Duel.BreakEffect()
		if Duel.Draw(tp,shuffled,REASON_EFFECT)>0 then
			local hand=Duel.GetFieldGroup(tp,LOCATION_HAND,0)
			local set_max=math.min(field_count,#hand)
			if set_max>0 then
				local sset_g=hand:Filter(Card.IsSSetable,nil)
				if #sset_g>0 then
					Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
					local sg=sset_g:Select(tp,0,set_max,nil)
					if #sg>0 then
						Duel.SSet(tp,sg)
					end
				end
			end
			hand=Duel.GetFieldGroup(tp,LOCATION_HAND,0)
			local to_grave_count=math.min(gy_count,#hand)
			if to_grave_count>0 then
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
				local tg=hand:Select(tp,to_grave_count,to_grave_count,nil)
				Duel.SendtoGrave(tg,REASON_EFFECT)
			end
			hand=Duel.GetFieldGroup(tp,LOCATION_HAND,0)
			if #hand>0 then
				Duel.Remove(hand,POS_FACEUP,REASON_EFFECT)
			end
		end
	end
end

function s.gybancon(e,tp,eg,ep,ev,re,r,rp)
	return rp==1-tp
end
function s.gybantg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return eg:IsExists(Card.IsAbleToDeck,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TODECK,eg,1,0,0)
end
function s.gybanop(e,tp,eg,ep,ev,re,r,rp)
	local g=eg:Filter(Card.IsAbleToDeck,nil)
	if #g>0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
		local tc=g:Select(tp,1,1,nil):GetFirst()
		if tc and Duel.SendtoDeck(tc,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)>0 then
			Duel.BreakEffect()
			local hg1=Duel.GetMatchingGroup(Card.IsAbleToHand,tp,LOCATION_REMOVED,0,nil)
			local hg2=Duel.GetMatchingGroup(Card.IsAbleToHand,1-tp,LOCATION_REMOVED,0,nil)
			if #hg1>0 then
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
				local sc1=hg1:Select(tp,1,1,nil)
				Duel.SendtoHand(sc1,nil,REASON_EFFECT)
				Duel.ConfirmCards(1-tp,sc1)
			end
			if #hg2>0 then
				Duel.Hint(HINT_SELECTMSG,1-tp,HINTMSG_ATOHAND)
				local sc2=hg2:Select(1-tp,1,1,nil)
				Duel.SendtoHand(sc2,nil,REASON_EFFECT)
				Duel.ConfirmCards(tp,sc2)
			end
		end
	end
end
