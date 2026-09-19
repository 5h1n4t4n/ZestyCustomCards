-- Sayaka the Magica Mahou Shoujo
-- ID: 999900009
local s,id=GetID()

local SET_MAGICA		  = 0x654
local SET_SOULGEM		 = 0xc7d
local CARD_SAYAKA_STUDENT = 999900008
local CARD_OKTAVIA		= 999900010
local COUNTER_NOTE		= 0x1655

s.listed_series={SET_MAGICA, SET_SOULGEM}
s.listed_names={CARD_SAYAKA_STUDENT, CARD_OKTAVIA}

function s.initial_effect(c)
	c:EnableReviveLimit()
	c:EnableCounterPermit(COUNTER_NOTE)

	-- Luôn được tính là lá bài "Magica"
	local e0_set=Effect.CreateEffect(c)
	e0_set:SetType(EFFECT_TYPE_SINGLE)
	e0_set:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0_set:SetCode(EFFECT_ADD_SETCODE)
	e0_set:SetValue(SET_MAGICA)
	c:RegisterEffect(e0_set)

	-- ĐIỀU KIỆN SUMMON: Bắt buộc gọi bằng hiệu ứng của Sayaka Student
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_SPSUMMON_CONDITION)
	e0:SetValue(s.splimit)
	c:RegisterEffect(e0)

	-- 1. Tự đặt Note Counter khi Magica summoned hoặc bài/hiệu ứng kích hoạt
	local e1a=Effect.CreateEffect(c)
	e1a:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1a:SetCode(EVENT_SUMMON_SUCCESS)
	e1a:SetRange(LOCATION_MZONE)
	e1a:SetOperation(s.ctop1)
	c:RegisterEffect(e1a)

	local e1b=e1a:Clone()
	e1b:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e1b)

	local e1c=e1a:Clone()
	e1c:SetCode(EVENT_FLIP_SUMMON_SUCCESS)
	c:RegisterEffect(e1c)

	local e1d=Effect.CreateEffect(c)
	e1d:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1d:SetCode(EVENT_CHAINING)
	e1d:SetRange(LOCATION_MZONE)
	e1d:SetOperation(s.ctop2)
	c:RegisterEffect(e1d)

	-- 2. Quick Effect: Trừ 2 Counter -> Chuyển tư thế & Negate (HOPT)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_POSITION+CATEGORY_DISABLE)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetRange(LOCATION_MZONE)
	e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E+TIMING_MAIN_END)
	e2:SetCountLimit(1,id)
	e2:SetCost(s.poscost)
	e2:SetTarget(s.postg)
	e2:SetOperation(s.posop)
	c:RegisterEffect(e2)

	-- 3. Quick Effect trên tay trong lượt mình: Reveal -> 4 Counters -> Return Deck -> SS Magica (OPD)
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_TODECK+CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetRange(LOCATION_HAND)
	e3:SetHintTiming(0,TIMING_MAIN_END)
	e3:SetCountLimit(1,id+100,EFFECT_COUNT_CODE_DUEL)
	e3:SetCondition(s.handcon)
	e3:SetCost(s.handcost)
	e3:SetTarget(s.handtg)
	e3:SetOperation(s.handop)
	c:RegisterEffect(e3)

	-- 4. Quick Effect: Gửi vào GY -> Special Summon Oktavia -> Transfer Counters -> Return to hand (HOPT)
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,2))
	e4:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOHAND)
	e4:SetType(EFFECT_TYPE_QUICK_O)
	e4:SetCode(EVENT_FREE_CHAIN)
	e4:SetRange(LOCATION_MZONE)
	e4:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E+TIMING_MAIN_END)
	e4:SetCountLimit(1,id+200)
	e4:SetCost(s.oktcost)
	e4:SetTarget(s.okttg)
	e4:SetOperation(s.oktop)
	c:RegisterEffect(e4)
end

function s.splimit(e,se,sp,st)
	return se and se:GetHandler() and se:GetHandler():IsCode(CARD_SAYAKA_STUDENT)
end

--------------------------------------------------------------------------------
-- EFFECT 1: ADD COUNTER ON EVENT
--------------------------------------------------------------------------------
function s.ctfilter(c)
	return c:IsFaceup() and c:IsSetCard(SET_MAGICA)
end

function s.ctop1(e,tp,eg,ep,ev,re,r,rp)
	if eg:IsExists(s.ctfilter,1,nil) then
		e:GetHandler():AddCounter(COUNTER_NOTE,1)
	end
end

function s.ctop2(e,tp,eg,ep,ev,re,r,rp)
	e:GetHandler():AddCounter(COUNTER_NOTE,1)
end

--------------------------------------------------------------------------------
-- EFFECT 2: CHANGE POSITION & NEGATE
--------------------------------------------------------------------------------
function s.poscost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsCanRemoveCounter(tp,LOCATION_ONFIELD,LOCATION_ONFIELD,COUNTER_NOTE,2,REASON_COST) end
	Duel.RemoveCounter(tp,LOCATION_ONFIELD,LOCATION_ONFIELD,COUNTER_NOTE,2,REASON_COST)
end

function s.postg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsControler(1-tp) and chkc:IsLocation(LOCATION_MZONE) and chkc:IsCanChangePosition() end
	if chk==0 then return Duel.IsExistingTarget(Card.IsCanChangePosition,tp,0,LOCATION_MZONE,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_POSCHANGE)
	local g=Duel.SelectTarget(tp,Card.IsCanChangePosition,tp,0,LOCATION_MZONE,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_POSITION,g,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_DISABLE,g,1,0,0)
end

function s.posop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		if Duel.ChangePosition(tc,POS_FACEUP_DEFENSE,POS_FACEDOWN_DEFENSE,POS_FACEUP_ATTACK,POS_FACEUP_ATTACK)>0 then
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
	end
end

--------------------------------------------------------------------------------
-- EFFECT 3: IN-HAND QUICK EFFECT (OPD)
--------------------------------------------------------------------------------
function s.handcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetTurnPlayer()==tp
end

function s.handcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return not c:IsPublic() end
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_PUBLIC)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD-RESET_TOHAND+RESET_PHASE+PHASE_END)
	c:RegisterEffect(e1)
end

function s.ctmfilter(c)
	return c:IsFaceup() and c:IsSetCard(SET_MAGICA) and c:IsCanAddCounter(COUNTER_NOTE,4)
end

function s.tdmfilter(c)
	return c:IsSetCard(SET_MAGICA) and c:IsAbleToDeck()
		and (c:IsLocation(LOCATION_HAND) or c:IsLocation(LOCATION_GRAVE))
end

function s.spmfilter(c,e,tp)
	return c:IsSetCard(SET_MAGICA) and c:IsCanBeSpecialSummoned(e,0,tp,true,true)
end

function s.handtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.ctmfilter,tp,LOCATION_MZONE,0,1,nil)
			and Duel.IsExistingMatchingCard(s.tdmfilter,tp,LOCATION_HAND+LOCATION_GRAVE,0,1,c)
			and Duel.GetMZoneCount(tp)>0
			and Duel.IsExistingMatchingCard(s.spmfilter,tp,LOCATION_DECK,0,1,nil,e,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_TODECK,nil,1,tp,LOCATION_HAND+LOCATION_GRAVE)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK)
end

function s.handop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_COUNTER)
	local cg=Duel.SelectMatchingCard(tp,s.ctmfilter,tp,LOCATION_MZONE,0,1,1,nil)
	if #cg>0 and cg:GetFirst():AddCounter(COUNTER_NOTE,4) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
		local tdg=Duel.SelectMatchingCard(tp,s.tdmfilter,tp,LOCATION_HAND+LOCATION_GRAVE,0,1,1,e:GetHandler())
		if #tdg>0 and Duel.SendtoDeck(tdg,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)>0 then
			if Duel.GetLocationCount(tp,LOCATION_MZONE)>0 then
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
				local spg=Duel.SelectMatchingCard(tp,s.spmfilter,tp,LOCATION_DECK,0,1,1,nil,e,tp)
				if #spg>0 then
					local sc=spg:GetFirst()
					if Duel.SpecialSummon(sc,0,tp,tp,true,true,POS_FACEUP)>0 then
						sc:CompleteProcedure()
					end
				end
			end
		end
	end

	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CANNOT_ATTACK_ANNOUNCE)
	e1:SetProperty(EFFECT_FLAG_OATH)
	e1:SetTargetRange(LOCATION_MZONE,0)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
end

--------------------------------------------------------------------------------
-- EFFECT 4: TRANSFORM INTO OKTAVIA (MAIN DECK MONSTER)
--------------------------------------------------------------------------------
function s.oktfilter(c,e,tp)
	return c:IsCode(CARD_OKTAVIA) and c:IsCanBeSpecialSummoned(e,0,tp,true,true)
end

function s.oktcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsAbleToGraveAsCost() end
	local ct=c:GetCounter(COUNTER_NOTE)
	e:SetLabel(ct)
	Duel.SendtoGrave(c,REASON_COST)
end

function s.okttg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		local ft=c:IsLocation(LOCATION_MZONE) and Duel.GetMZoneCount(tp,c) or Duel.GetLocationCount(tp,LOCATION_MZONE)
		return ft>0 and Duel.IsExistingMatchingCard(s.oktfilter,tp,LOCATION_HAND+LOCATION_DECK,0,1,nil,e,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_DECK)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,c,1,0,0)
end

function s.oktop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.oktfilter,tp,LOCATION_HAND+LOCATION_DECK,0,1,1,nil,e,tp)
	local tc=g:GetFirst()

	if tc and Duel.SpecialSummon(tc,0,tp,tp,true,true,POS_FACEUP)>0 then
		tc:CompleteProcedure()

		local field_ct=Duel.GetCounter(tp,LOCATION_ONFIELD,LOCATION_ONFIELD,COUNTER_NOTE)
		if field_ct>0 then
			Duel.RemoveCounter(tp,LOCATION_ONFIELD,LOCATION_ONFIELD,COUNTER_NOTE,field_ct,REASON_EFFECT)
		end
		local total_ct=field_ct+e:GetLabel()
		if total_ct>0 then
			tc:AddCounter(COUNTER_NOTE,total_ct)
		end

		if c:IsLocation(LOCATION_GRAVE) and c:IsAbleToHand() then
			Duel.BreakEffect()
			Duel.SendtoHand(c,nil,REASON_EFFECT)
		end
	end
end