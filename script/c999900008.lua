-- Sayaka Miki The Magica Student
-- ID: 999900008
local s,id=GetID()

local SET_MAGICA		= 0x654
local SET_SOULGEM	   = 0xc7d
local CARD_SAYAKA_MAHOU = 999900009
local COUNTER_NOTE	  = 0x1655 -- Mã Counter cho Note Counter

s.listed_series={SET_MAGICA, SET_SOULGEM}
s.listed_names={CARD_SAYAKA_MAHOU}

function s.initial_effect(c)
	-- Bật tính năng chứa Note Counter cho lá bài này
	c:EnableCounterPermit(COUNTER_NOTE)

	-- 1. Normal/Special Summoned: Add 1 "Soulgem" -> Magica SS Restriction
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SUMMON_SUCCESS)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)

	local e1b=e1:Clone()
	e1b:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e1b)

	-- 2. Special Summon from Hand if control "Magica" -> Gain 1000 LP
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_RECOVER)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_HAND)
	e2:SetCondition(s.spcon)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)

	-- 3. Quick Effect: Discard "Soulgem" -> Ritual SS Sayaka Mahou -> Transfer Counters -> Return to Hand
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOHAND)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetRange(LOCATION_MZONE)
	e3:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_CANNOT_NEGATE)
	e3:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E+TIMING_MAIN_END)
	e3:SetCost(s.effcost)
	e3:SetTarget(s.efftg)
	e3:SetOperation(s.effop)
	c:RegisterEffect(e3)
end

--------------------------------------------------------------------------------
-- EFFECT 1: SEARCH SOULGEM & RESTRICTION
--------------------------------------------------------------------------------
function s.thfilter(c)
	return c:IsSetCard(SET_SOULGEM) and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then 
		return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end

	-- Khóa Special Summon chỉ gọi được "Magica" cho đến HẾT TRANH ĐẤU
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT)
	e1:SetDescription(aux.Stringid(id,3))
	e1:SetTargetRange(1,0)
	e1:SetTarget(s.splimit)
	Duel.RegisterEffect(e1,tp)
end

function s.splimit(e,c,sump,sumtype,sumpos,targetp,se)
	return not c:IsSetCard(SET_MAGICA)
end

--------------------------------------------------------------------------------
-- EFFECT 2: SPECIAL SUMMON FROM HAND & GAIN LP
--------------------------------------------------------------------------------
function s.cfilter(c)
	return c:IsFaceup() and c:IsSetCard(SET_MAGICA)
end

function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_MZONE,0,1,nil)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then 
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and c:IsCanBeSpecialSummoned(e,0,tp,false,false) 
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_RECOVER,nil,0,tp,1000)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) and Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)>0 then
		Duel.BreakEffect()
		Duel.Recover(tp,1000,REASON_EFFECT)
	end
end

--------------------------------------------------------------------------------
-- EFFECT 3: QUICK EFFECT (RITUAL SS, COUNTER TRANSFER, BOUNCE)
--------------------------------------------------------------------------------
function s.costfilter(c)
	return c:IsSetCard(SET_SOULGEM) and c:IsDiscardable()
end

function s.effcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.costfilter,tp,LOCATION_HAND,0,1,nil) end
	Duel.DiscardHand(tp,s.costfilter,1,1,REASON_COST+REASON_DISCARD)
end

function s.spfilter(c,e,tp)
	return c:IsCode(CARD_SAYAKA_MAHOU) 
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_RITUAL,tp,true,false)
		and (c:IsLocation(LOCATION_HAND+LOCATION_DECK) or c:IsFaceup())
end

function s.chainlm(re,rp,tp)
	return false
end

function s.efftg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then 
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_REMOVED,0,1,nil,e,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_REMOVED)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,c,1,0,0)
	
	-- Không ai có thể kích hoạt hiệu ứng phản hồi lại
	Duel.SetChainLimit(s.chainlm)
end

function s.effop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_REMOVED,0,1,1,nil,e,tp)
	local tc=g:GetFirst()

	if tc then
		if Duel.SpecialSummonStep(tc,SUMMON_TYPE_RITUAL,tp,tp,true,false,POS_FACEUP) then
			tc:CompleteProcedure()
			Duel.SpecialSummonComplete()

			-- Chuyển toàn bộ Note Counter sang cho quái thú mới được gọi ra
			if c:IsRelateToEffect(e) and c:IsFaceup() then
				local ct=c:GetCounter(COUNTER_NOTE)
				if ct>0 then
					c:RemoveCounter(tp,COUNTER_NOTE,ct,0)
					tc:AddCounter(COUNTER_NOTE,ct)
				end
				-- Trả lá bài này về tay
				Duel.BreakEffect()
				Duel.SendtoHand(c,nil,REASON_EFFECT)
			end
		end
	end
end
