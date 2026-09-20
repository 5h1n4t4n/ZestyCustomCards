local s,id=GetID()
function s.initial_effect(c)

	-- Equip
	aux.AddEquipProcedure(c,nil,aux.FilterBoolFunction(Card.IsFaceup))

	-- ATK +300
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_EQUIP)
	e1:SetCode(EFFECT_UPDATE_ATTACK)
	e1:SetValue(300)
	c:RegisterEffect(e1)

	-- GY trigger (Đã sửa Category sang CATEGORY_DISABLE)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_DISABLE+CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e2:SetCode(EVENT_TO_GRAVE)
	e2:SetCountLimit(1,id)
	e2:SetCondition(s.thcon)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
end

-- CONDITION (2 NHÁNH RIÊNG)
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	-- 🔹 Nhánh 1: discard từ tay (bất kỳ effect nào)
	if c:IsPreviousLocation(LOCATION_HAND) 
		and (r&(REASON_EFFECT|REASON_COST|REASON_DISCARD))~=0 then
		return true
	end

	-- 🔹 Nhánh 2: đang equip và bị Desire Hero gửi
	if c:IsPreviousLocation(LOCATION_SZONE)
		and re and re:GetHandler()
		and re:GetHandler():IsSetCard(0x927)
		and (r&(REASON_EFFECT|REASON_COST))~=0 then
		return true
	end

	return false
end

-- FILTER DISABLE
function s.negfilter(c)
	return c:IsFaceup()
		and c:IsSetCard(0x927)
		and not c:IsDisabled()
end

-- TARGET
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(tp) and s.negfilter(chkc) end
	if chk==0 then
		return e:GetHandler():IsAbleToHand()
			and Duel.IsExistingTarget(s.negfilter,tp,LOCATION_MZONE,0,1,nil)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
	Duel.SelectTarget(tp,s.negfilter,tp,LOCATION_MZONE,0,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_DISABLE,nil,1,tp,LOCATION_MZONE)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,e:GetHandler(),1,0,0)
end

-- OPERATION
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()

	-- Vô hiệu hóa quái thú trên sân chuẩn quy cách EDOPro
	if tc and tc:IsFaceup() and tc:IsRelateToEffect(e) and not tc:IsDisabled() then
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

	-- Đưa lá Equip từ Mộ về tay
	if c:IsRelateToEffect(e) then
		Duel.BreakEffect()
		Duel.SendtoHand(c,nil,REASON_EFFECT)
	end
end