-- Genshin Superpower - Raging Betrayal
local s,id=GetID()
function s.initial_effect(c)
	c:SetUniqueOnField(1,0,id)
	-- Activate
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_CONTROL)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
	-- Negate target's effects
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_DISABLE)
	e2:SetRange(LOCATION_SZONE)
	e2:SetTargetRange(LOCATION_MZONE,LOCATION_MZONE)
	e2:SetTarget(s.distg)
	c:RegisterEffect(e2)
	-- Return control when this card leaves the field
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_CONTINUOUS+EFFECT_TYPE_SINGLE)
	e3:SetCode(EVENT_LEAVE_FIELD)
	e3:SetOperation(s.leaveop)
	c:RegisterEffect(e3)
	-- Target leaves field -> damage and destroy
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e4:SetCode(EVENT_LEAVE_FIELD)
	e4:SetRange(LOCATION_SZONE)
	e4:SetOperation(s.desop)
	c:RegisterEffect(e4)
end
s.listed_series={0x369}
function s.filter(c)
	return c:IsFaceup() and c:IsSetCard(0x369) and c:IsControlerCanBeChanged()
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(tp) and s.filter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.filter,tp,LOCATION_MZONE,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONTROL)
	local g=Duel.SelectTarget(tp,s.filter,tp,LOCATION_MZONE,0,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_CONTROL,g,1,0,0)
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if c:IsRelateToEffect(e) and tc and tc:IsRelateToEffect(e) and tc:IsFaceup() then
		c:SetCardTarget(tc)
		Duel.GetControl(tc,1-tp)
		-- Destroy during opponent's 3rd End Phase
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		e1:SetCode(EVENT_PHASE+PHASE_END)
		e1:SetCountLimit(1)
		e1:SetCondition(s.descon)
		e1:SetOperation(s.desop2)
		e1:SetReset(RESET_PHASE+PHASE_END+RESET_OPPO_TURN,3)
		Duel.RegisterEffect(e1,tp)
		c:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD,0,1,0)
	end
end
function s.descon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetTurnPlayer()==1-tp
end
function s.desop2(e,tp,eg,ep,ev,re,r,rp)
	local ct=e:GetLabel()+1
	e:SetLabel(ct)
	if ct>=3 then
		Duel.Destroy(e:GetOwner(),REASON_EFFECT)
	end
end
function s.distg(e,c)
	return e:GetHandler():IsHasCardTarget(c)
end
function s.leaveop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local g=c:GetCardTarget()
	for tc in g:Iter() do
		if tc:IsLocation(LOCATION_MZONE) then
			Duel.GetControl(tc,tc:GetOwner())
		end
	end
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local g=c:GetCardTarget()
	for tc in eg:Iter() do
		if g:IsContains(tc) then
			local atk=math.max(0,tc:GetPreviousAttackOnField())
			local def=math.max(0,tc:GetPreviousDefenseOnField())
			Duel.Damage(1-tp,atk+def,REASON_EFFECT)
			Duel.Destroy(c,REASON_EFFECT)
			break
		end
	end
end
