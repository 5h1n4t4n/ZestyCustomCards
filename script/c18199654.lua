-- Ayato, Genshin the Head Commissioner
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	-- Special Summon procedure
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetRange(LOCATION_HAND)
	e1:SetCondition(s.spcon)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)
	-- Choose 1 of 2 effects
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,id)
	e2:SetTarget(s.efftg)
	e2:SetOperation(s.effop)
	c:RegisterEffect(e2)
end
s.listed_series={0x369}
function s.spfilter(c)
	return c:IsSetCard(0x369) and c:IsMonster() and c:IsAbleToRemoveAsCost()
end
function s.spcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	local rg=Duel.GetMatchingGroup(s.spfilter,tp,LOCATION_GRAVE,0,nil)
	return Duel.GetLocationCount(tp,LOCATION_MZONE)>0 and rg:GetClassCount(Card.GetCode)>=2
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,c)
	local rg=Duel.GetMatchingGroup(s.spfilter,tp,LOCATION_GRAVE,0,nil)
	local g=aux.SelectUnselectGroup(rg,e,tp,2,2,aux.dncheck,1,tp,HINTMSG_REMOVE,nil,nil,true)
	if #g>0 then
		g:KeepAlive()
		e:SetLabelObject(g)
		return true
	end
	return false
end
function s.spop(e,tp,eg,ep,ev,re,r,rp,c)
	local g=e:GetLabelObject()
	if g then
		Duel.Remove(g,POS_FACEUP,REASON_COST)
		g:DeleteGroup()
	end
end
function s.rtfilter(c)
	return c:IsAbleToHand()
end
function s.stfilter(c)
	return c:IsSetCard(0x369) and c:IsSpellTrap() and c:IsFaceup()
end
function s.efftg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return false end
	local b1=Duel.IsExistingMatchingCard(s.rtfilter,tp,LOCATION_ONFIELD,0,1,e:GetHandler())
		and Duel.IsExistingMatchingCard(nil,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,e:GetHandler())
	local b2=Duel.IsExistingTarget(s.stfilter,tp,LOCATION_REMOVED,0,1,nil)
	if chk==0 then return b1 or b2 end
	local op=0
	if b1 and b2 then op=Duel.SelectOption(tp,aux.Stringid(id,1),aux.Stringid(id,2))
	elseif b1 then op=Duel.SelectOption(tp,aux.Stringid(id,1))
	else op=Duel.SelectOption(tp,aux.Stringid(id,2))+1 end
	e:SetLabel(op)
	if op==0 then
		e:SetProperty(0)
		e:SetCategory(CATEGORY_TOHAND+CATEGORY_DESTROY)
		Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_ONFIELD)
		Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,1,LOCATION_ONFIELD,LOCATION_ONFIELD)
		Duel.SetChainLimit(s.chainlm)
	else
		e:SetProperty(EFFECT_FLAG_CARD_TARGET)
		e:SetCategory(CATEGORY_TOGRAVE)
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
		local g=Duel.SelectTarget(tp,s.stfilter,tp,LOCATION_REMOVED,0,1,1,nil)
		Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,g,1,0,0)
	end
end
function s.chainlm(e,rp,tp)
	return tp==rp
end
function s.effop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if e:GetLabel()==0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RTOHAND)
		local hg=Duel.SelectMatchingCard(tp,s.rtfilter,tp,LOCATION_ONFIELD,0,1,1,c)
		if #hg>0 and Duel.SendtoHand(hg,nil,REASON_EFFECT)>0 then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
			local dg=Duel.SelectMatchingCard(tp,nil,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,1,nil)
			if #dg>0 then
				Duel.Destroy(dg,REASON_EFFECT)
			end
		end
	else
		local tc=Duel.GetFirstTarget()
		if tc and tc:IsRelateToEffect(e) and Duel.SendtoGrave(tc,REASON_EFFECT+REASON_RETURN)>0 then
			if c:IsRelateToEffect(e) then
				local e1=Effect.CreateEffect(c)
				e1:SetType(EFFECT_TYPE_SINGLE)
				e1:SetCode(EFFECT_EXTRA_ATTACK_MONSTER)
				e1:SetValue(2)
				e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_BATTLE)
				c:RegisterEffect(e1)
			end
		end
	end
end
