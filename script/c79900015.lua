-- ============================================================
-- Card Name: Retfihs Noisnemid
-- Passcode : 79900015
-- Type     : Monster / Effect
-- Attribute: LIGHT
-- Level    : 6
-- ATK      : 2200
-- DEF      : 1200
-- Race     : Spellcaster
-- Archetype: Generic (None)
-- ============================================================
-- Effect 1: If a card(s) is in either GY or banishment
--           (Quick Effect): You can banish this card from your
--           hand; until the end of the next turn, any card
--           banished, except from the GY, is sent to the GY
--           instead, also your opponent takes 100 damage for
--           each card sent to the GY that way.
-- ============================================================

local s,id=GetID()

function s.initial_effect(c)
	--Quick Effect from hand: banish to apply replacement effect
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DAMAGE)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_HAND)
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_MAIN_END)
	e1:SetCondition(s.condition)
	e1:SetCost(s.cost)
	e1:SetOperation(s.operation)
	c:RegisterEffect(e1)
end

--Điều kiện: Có ít nhất 1 lá trong GY hoặc Banishment của bất kỳ người chơi nào
function s.condition(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetFieldGroupCount(tp,LOCATION_GRAVE+LOCATION_REMOVED,LOCATION_GRAVE+LOCATION_REMOVED)>0
end

--Cost: Banish lá này từ tay
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsAbleToRemoveAsCost() end
	Duel.Remove(c,POS_FACEUP,REASON_COST)
end

function s.operation(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	--Hiệu ứng thay thế chuyển sang Mộ: EFFECT_TO_GRAVE_REDIRECT
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_SET_AVAILABLE+EFFECT_FLAG_IGNORE_RANGE+EFFECT_FLAG_IGNORE_IMMUNE)
	e1:SetCode(EFFECT_TO_GRAVE_REDIRECT)
	e1:SetTargetRange(0xff,0xff)
	e1:SetValue(LOCATION_GRAVE)
	e1:SetTarget(s.rmtarget)
	e1:SetReset(RESET_PHASE+PHASE_END,2)
	Duel.RegisterEffect(e1,tp)

	--Ghi nhận sát thương đốt máu: 100 LP mỗi lá
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EVENT_TO_GRAVE)
	e2:SetReset(RESET_PHASE+PHASE_END,2)
	e2:SetOperation(s.damop)
	Duel.RegisterEffect(e2,tp)
end

--Target lọc: Thay thế các hành động gửi bài sang Banishment (LOCATION_REMOVED) NGOẠI TRỪ từ Mộ (LOCATION_GRAVE)
function s.rmtarget(e,c)
	return not c:IsLocation(LOCATION_GRAVE) and c:GetDestination()==LOCATION_REMOVED
end

--Thực thi gây sát thương: Đếm số lượng lá kích hoạt cờ chuyển vào Mộ
function s.damfilter(c)
	return c:IsReason(REASON_REDIRECT) and not c:IsPreviousLocation(LOCATION_GRAVE)
end

function s.damop(e,tp,eg,ep,ev,re,r,rp)
	local ct=eg:FilterCount(s.damfilter,nil)
	if ct>0 then
		Duel.Damage(1-tp,ct*100,REASON_EFFECT)
	end
end