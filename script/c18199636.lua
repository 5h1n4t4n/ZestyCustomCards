-- Arataki Itto - Genshin the Descendant of the Crimson Oni
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_ATKCHANGE+CATEGORY_DEFCHANGE+CATEGORY_DAMAGE)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.condition)
	e1:SetTarget(s.target)
	e1:SetOperation(s.operation)
	c:RegisterEffect(e1)
end
function s.condition(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetCurrentPhase()==PHASE_MAIN1
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetFieldGroupCount(1-tp,LOCATION_DECK,0)>=5 end
end
function s.operation(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if Duel.GetFieldGroupCount(1-tp,LOCATION_DECK,0)<5 then return end
	local g=Duel.GetDecktopGroup(1-tp,5)
	Duel.ConfirmCards(tp,g)
	Duel.SortDecktop(tp,1-tp,5)
	local ct1=g:FilterCount(Card.IsType,nil,TYPE_MONSTER)
	local ct2=g:FilterCount(Card.IsType,nil,TYPE_SPELL+TYPE_TRAP)
	if ct1>0 and c:IsRelateToEffect(e) and c:IsFaceup() then
		local mg=g:Filter(Card.IsType,nil,TYPE_MONSTER)
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
		local sg=mg:Select(tp,1,1,nil)
		local val=sg:GetFirst():GetAttack()
		if val>0 then
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_UPDATE_ATTACK)
			e1:SetValue(val)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END,2)
			c:RegisterEffect(e1)
			local e2=e1:Clone()
			e2:SetCode(EFFECT_UPDATE_DEFENSE)
			c:RegisterEffect(e2)
		end
		-- other monsters cannot attack
		local e3=Effect.CreateEffect(c)
		e3:SetType(EFFECT_TYPE_FIELD)
		e3:SetCode(EFFECT_CANNOT_ATTACK)
		e3:SetTargetRange(LOCATION_MZONE,0)
		e3:SetTarget(s.ftarget)
		e3:SetLabel(c:GetFieldID())
		e3:SetReset(RESET_PHASE+PHASE_END)
		Duel.RegisterEffect(e3,tp)
	end
	if ct2>0 then
		Duel.Damage(1-tp,ct2*800,REASON_EFFECT)
	end
end
function s.ftarget(e,c)
	return e:GetLabel()~=c:GetFieldID()
end
