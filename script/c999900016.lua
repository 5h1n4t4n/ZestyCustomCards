-- Magica: TIRO FINALE
-- ID: 999900016
local s,id=GetID()

local SET_MAGICA		  = 0x654
local CARD_MAMI_STUDENT   = 999900013
local CARD_MAMI_MAHOU	 = 999900014
local CARD_MAMI_WITCH	 = 999900015

s.listed_series={SET_MAGICA}
s.listed_names={CARD_MAMI_STUDENT, CARD_MAMI_MAHOU, CARD_MAMI_WITCH}

function s.initial_effect(c)
	-- Activate
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_POSITION+CATEGORY_ATKCHANGE+CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

--------------------------------------------------------------------------------
-- FILTER HELPER FUNCTIONS
--------------------------------------------------------------------------------
function s.mamifilter(c)
	return c:IsFaceup() and c:IsCode(CARD_MAMI_STUDENT, CARD_MAMI_MAHOU, CARD_MAMI_WITCH)
end

function s.witchfilter(c)
	return c:IsFaceup() and c:IsCode(CARD_MAMI_WITCH)
end

function s.desfilter(c,atk)
	return c:IsFaceup() and c:GetAttack()>=0 and c:GetAttack()<=atk
end

--------------------------------------------------------------------------------
-- TARGET & OPERATION
--------------------------------------------------------------------------------
function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(tp) and s.mamifilter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.mamifilter,tp,LOCATION_MZONE,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	local g=Duel.SelectTarget(tp,s.mamifilter,tp,LOCATION_MZONE,0,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_POSITION,g,1,0,0)

	-- Nếu điều khiển "Mami the Magica Puella Witch": Không cho phép đối phương chèn Chain
	if Duel.IsExistingMatchingCard(s.witchfilter,tp,LOCATION_MZONE,0,1,nil) then
		Duel.SetChainLimit(s.chainlm)
	end
end

function s.chainlm(e,rp,tp)
	return false
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) and tc:IsFaceup() then
		-- Chuyển sang thế Tấn công nếu đang ở thế Phòng thủ
		if tc:IsDefensePos() then
			Duel.ChangePosition(tc,POS_FACEUP_ATTACK)
		end

		-- ATK trở thành 6000 cho đến hết lượt
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_SET_ATTACK_FINAL)
		e1:SetValue(6000)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		tc:RegisterEffect(e1)

		-- Phá hủy toàn bộ card đối phương có ATK <= ATK hiện tại của target
		local atk=tc:GetAttack()
		local dg=Duel.GetMatchingGroup(s.desfilter,tp,0,LOCATION_ONFIELD,nil,atk)
		if #dg>0 then
			Duel.BreakEffect()
			Duel.Destroy(dg,REASON_EFFECT)
		end
	end
end
