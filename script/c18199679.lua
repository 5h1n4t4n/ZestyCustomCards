-- Cyno - Genshin General Mahamatra
local s,id=GetID()
function s.initial_effect(c)
	-- Xyz Summon
	Xyz.AddProcedure(c,s.matfilter,4,2,nil,nil,Xyz.InfiniteMats)
	c:EnableReviveLimit()
	-- Attach during End Phase
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetCode(EVENT_PHASE+PHASE_END)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.attg)
	e1:SetOperation(s.atop)
	c:RegisterEffect(e1)
	-- Quick Effect
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_MZONE)
	e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_MAIN_END)
	e2:SetCountLimit(1,{id,1})
	e2:SetCost(s.qcost)
	e2:SetTarget(s.qtg)
	e2:SetOperation(s.qop)
	c:RegisterEffect(e2,false,REGISTER_FLAG_DETACH_XMAT)
end
s.listed_series={0x369}
function s.matfilter(c,scard,sumtype,tp)
	return c:IsSetCard(0x369,scard,sumtype,tp)
end
function s.atfilter(c)
	return c:IsSetCard(0x369) and (c:IsLocation(LOCATION_GRAVE) or c:IsFaceup())
end
function s.attg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_GRAVE+LOCATION_REMOVED) and chkc:IsControler(tp) and s.atfilter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.atfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_XMATERIAL)
	local g=Duel.SelectTarget(tp,s.atfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,1,nil)
end
function s.atop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if c:IsRelateToEffect(e) and c:IsFaceup() and tc and tc:IsRelateToEffect(e) then
		Duel.Overlay(c,tc)
	end
end
function s.negfilter(c)
	return c:IsFaceup() and not c:IsDisabled()
end
function s.qcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	local b1=c:CheckRemoveOverlayCard(tp,1,REASON_COST) and Duel.IsExistingTarget(s.negfilter,tp,0,LOCATION_ONFIELD,1,nil)
	local b2=c:CheckRemoveOverlayCard(tp,2,REASON_COST) and Duel.IsExistingTarget(Card.IsAbleToChangeControler,tp,0,LOCATION_MZONE,1,nil)
	if chk==0 then return b1 or b2 end
	local op=0
	if b1 and b2 then
		op=Duel.SelectOption(tp,aux.Stringid(id,2),aux.Stringid(id,3))+1
	elseif b1 then
		op=Duel.SelectOption(tp,aux.Stringid(id,2))+1
	else
		op=Duel.SelectOption(tp,aux.Stringid(id,3))+2
	end
	e:SetLabel(op)
	c:RemoveOverlayCard(tp,op,op,REASON_COST)
end
function s.qtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		if e:GetLabel()==1 then return chkc:IsControler(1-tp) and chkc:IsOnField() and s.negfilter(chkc)
		else return chkc:IsControler(1-tp) and chkc:IsLocation(LOCATION_MZONE) end
	end
	if chk==0 then return true end
	local op=e:GetLabel()
	if op==1 then
		e:SetCategory(CATEGORY_DISABLE)
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_NEGATE)
		local g=Duel.SelectTarget(tp,s.negfilter,tp,0,LOCATION_ONFIELD,1,1,nil)
		Duel.SetOperationInfo(0,CATEGORY_DISABLE,g,1,0,0)
	else
		e:SetCategory(0)
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_XMATERIAL)
		local g=Duel.SelectTarget(tp,Card.IsAbleToChangeControler,tp,0,LOCATION_MZONE,1,1,nil)
	end
end
function s.qop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if not (tc and tc:IsRelateToEffect(e)) then return end
	local op=e:GetLabel()
	if op==1 then
		if tc:IsFaceup() and not tc:IsDisabled() then
			Duel.NegateRelatedChain(tc,RESET_TURN_SET)
			local e1=Effect.CreateEffect(e:GetHandler())
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_DISABLE)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
			tc:RegisterEffect(e1)
			local e2=Effect.CreateEffect(e:GetHandler())
			e2:SetType(EFFECT_TYPE_SINGLE)
			e2:SetCode(EFFECT_DISABLE_EFFECT)
			e2:SetValue(RESET_TURN_SET)
			e2:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
			tc:RegisterEffect(e2)
		end
	else
		local c=e:GetHandler()
		if c:IsRelateToEffect(e) and c:IsFaceup() and not tc:IsImmuneToEffect(e) then
			Duel.Overlay(c,tc)
		end
	end
end
