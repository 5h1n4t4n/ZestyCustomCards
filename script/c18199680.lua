-- Nilou - Genshin Lotuslight Dancer
local s,id=GetID()
function s.initial_effect(c)
	-- Xyz Summon
	Xyz.AddProcedure(c,s.matfilter,4,2,nil,nil,Xyz.InfiniteMats)
	c:EnableReviveLimit()
	-- Attack while in defense
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_DEFENSE_ATTACK)
	e1:SetValue(1)
	c:RegisterEffect(e1)
	-- Attach during End Phase
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetCode(EVENT_PHASE+PHASE_END)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,id)
	e2:SetTarget(s.attg)
	e2:SetOperation(s.atop)
	c:RegisterEffect(e2)
	-- Quick Effect
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetRange(LOCATION_MZONE)
	e3:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_MAIN_END)
	e3:SetCountLimit(1,{id,1})
	e3:SetCost(s.qcost)
	e3:SetTarget(s.qtg)
	e3:SetOperation(s.qop)
	c:RegisterEffect(e3,false,REGISTER_FLAG_DETACH_XMAT)
end
s.listed_series={0x369}
function s.matfilter(c,scard,sumtype,tp)
	return c:IsSetCard(0x369,scard,sumtype,tp)
end
function s.atfilter(c)
	return c:IsFaceup() and c:IsSetCard(0x369)
end
function s.attg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_REMOVED) and chkc:IsControler(tp) and s.atfilter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.atfilter,tp,LOCATION_REMOVED,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_XMATERIAL)
	local g=Duel.SelectTarget(tp,s.atfilter,tp,LOCATION_REMOVED,0,1,1,nil)
end
function s.atop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if c:IsRelateToEffect(e) and c:IsFaceup() and tc and tc:IsRelateToEffect(e) then
		Duel.Overlay(c,tc)
	end
end
function s.posfilter(c)
	return c:IsFaceup() and c:IsCanTurnSet()
end
function s.ctrlfilter(c)
	return c:IsControlerCanBeChanged()
end
function s.qcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	local b1=c:CheckRemoveOverlayCard(tp,1,REASON_COST) and Duel.IsExistingTarget(s.posfilter,tp,0,LOCATION_MZONE,1,nil)
	local b2=c:CheckRemoveOverlayCard(tp,2,REASON_COST) and Duel.IsExistingTarget(s.ctrlfilter,tp,0,LOCATION_MZONE,1,nil)
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
		if e:GetLabel()==1 then return chkc:IsControler(1-tp) and chkc:IsLocation(LOCATION_MZONE) and s.posfilter(chkc)
		else return chkc:IsControler(1-tp) and chkc:IsLocation(LOCATION_MZONE) and s.ctrlfilter(chkc) end
	end
	if chk==0 then return true end
	local op=e:GetLabel()
	if op==1 then
		e:SetCategory(CATEGORY_POSITION)
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_POSCHANGE)
		local g=Duel.SelectTarget(tp,s.posfilter,tp,0,LOCATION_MZONE,1,1,nil)
		Duel.SetOperationInfo(0,CATEGORY_POSITION,g,1,0,0)
	else
		e:SetCategory(CATEGORY_CONTROL)
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONTROL)
		local g=Duel.SelectTarget(tp,s.ctrlfilter,tp,0,LOCATION_MZONE,1,1,nil)
		Duel.SetOperationInfo(0,CATEGORY_CONTROL,g,1,0,0)
	end
end
function s.qop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if not (tc and tc:IsRelateToEffect(e)) then return end
	local op=e:GetLabel()
	if op==1 then
		Duel.ChangePosition(tc,POS_FACEDOWN_DEFENSE)
	else
		Duel.GetControl(tc,tp,PHASE_END,2)
	end
end
