--Flower Spirit-Iris on target
local s,id=GetID()

function s.initial_effect(c)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetCountLimit(1,id+EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

function s.spfilter(c)
	return c:IsSetCard(0x702) and c:IsType(TYPE_SPELL)
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsOnField() end
	local b1=Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_HAND+LOCATION_DECK,0,1,nil)
		and Duel.IsExistingTarget(Card.IsAbleToGrave,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,e:GetHandler())
	local b2=Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_GRAVE,0,1,nil)
		and Duel.IsExistingTarget(aux.TRUE,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,e:GetHandler())
	if chk==0 then return b1 or b2 end
	local op=Duel.SelectEffect(tp,{b1,aux.Stringid(id,0)},{b2,aux.Stringid(id,1)})
	e:SetLabel(op)
	if op==1 then
		e:SetCategory(CATEGORY_TOGRAVE)
	else
		e:SetCategory(CATEGORY_REMOVE+CATEGORY_DISABLE)
	end
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local op=e:GetLabel()
	local c=e:GetHandler()
	if op==1 then
		local g=Duel.GetMatchingGroup(s.spfilter,tp,LOCATION_HAND+LOCATION_DECK,0,nil)
		if #g==0 then return end
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
		local sg=g:Select(tp,1,#g,nil)
		if #sg>0 and Duel.SendtoGrave(sg,REASON_EFFECT)>0 then
			local ct=#Duel.GetOperatedGroup()
			local tg=Duel.GetMatchingGroup(Card.IsAbleToGrave,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,c)
			if #tg>=ct then
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
				local dest=tg:Select(tp,ct,ct,nil)
				Duel.SendtoGrave(dest,REASON_EFFECT)
			end
		end
	elseif op==2 then
		local g=Duel.GetMatchingGroup(s.spfilter,tp,LOCATION_GRAVE,0,nil)
		if #g==0 then return end
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
		local sg=g:Select(tp,1,#g,nil)
		if #sg>0 and Duel.Remove(sg,POS_FACEUP,REASON_EFFECT)>0 then
			local ct=#Duel.GetOperatedGroup()
			local tg=Duel.GetMatchingGroup(Card.IsFaceup,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,c)
			if #tg>=ct then
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_NEGATE)
				local dest=tg:Select(tp,ct,ct,nil)
				for tc in aux.Next(dest) do
					local e1=Effect.CreateEffect(c)
					e1:SetType(EFFECT_TYPE_SINGLE)
					e1:SetCode(EFFECT_DISABLE)
					e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
					tc:RegisterEffect(e1)
					local e2=Effect.CreateEffect(c)
					e2:SetType(EFFECT_TYPE_SINGLE)
					e2:SetCode(EFFECT_DISABLE_EFFECT)
					e2:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
					tc:RegisterEffect(e2)
				end
			end
		end
	end
end
