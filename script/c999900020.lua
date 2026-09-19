-- Homura the Magica Mahou Shoujo
-- ID: 999900020
local s,id=GetID()

local SET_MAGICA			= 0x654
local SET_PUELLA_WITCH	  = 0x1654
local CARD_MADOKA_DIVINE	= 999900003
local CARD_FIELD_MITAKIHARA = 999900018
local CARD_HOMURA_STUDENT   = 999900019

s.listed_series={SET_MAGICA, SET_PUELLA_WITCH}
s.listed_names={
	999900001, -- Madoka Kaname The Magica Student
	999900008, -- Sayaka Miki The Magica Student
	999900013, -- Mami Tomoe The Magica Student
	999900019, -- Homura Akemi The Magica Student
	CARD_MADOKA_DIVINE,
	CARD_FIELD_MITAKIHARA
}

function s.initial_effect(c)
	c:EnableReviveLimit()

	-- Chỉ được điều khiển 1 "Homura the Magica Mahou Shoujo" trên sân
	c:SetUniqueOnField(1,0,id)

	-- ĐIỀU KIỆN SUMMON: Bắt buộc triệu hồi bởi hiệu ứng của "Homura Akemi the Magica Student"
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_SPSUMMON_CONDITION)
	e0:SetValue(s.splimit)
	c:RegisterEffect(e0)

	-- 1. Quick Effect (Main Phase): Negate hiệu ứng 1 lá bài ngửa của đối thủ đến cuối lượt
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DISABLE)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetRange(LOCATION_MZONE)
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E+TIMING_MAIN_END)
	e1:SetCondition(s.negcon)
	e1:SetTarget(s.negtg)
	e1:SetOperation(s.negop)
	c:RegisterEffect(e1)

	-- 2. Quick Effect: Gửi lá này (từ Tay/Sân) + 3 quái "Magica Student" từ Deck xuống GY 
	-- -> Special Summon 1 "Magica" Witch hoặc Divine + Đặt Field Spell "Mitakihara Town" vào Field Zone (HOPT)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_HAND+LOCATION_MZONE)
	e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E)
	e2:SetCountLimit(1,id)
	e2:SetCost(s.effcost)
	e2:SetTarget(s.efftg)
	e2:SetOperation(s.effop)
	c:RegisterEffect(e2)
end

function s.splimit(e,se,sp,st)
	return se and se:GetHandler():IsCode(CARD_HOMURA_STUDENT)
end

--------------------------------------------------------------------------------
-- 1. NEGATE EFFECT LOGIC
--------------------------------------------------------------------------------
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	local ph=Duel.GetCurrentPhase()
	return ph==PHASE_MAIN1 or ph==PHASE_MAIN2
end

function s.negfilter(c)
	return c:IsFaceup() and not c:IsDisabled()
end

function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsControler(1-tp) and chkc:IsOnField() and s.negfilter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.negfilter,tp,0,LOCATION_ONFIELD,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_NEGATE)
	local g=Duel.SelectTarget(tp,s.negfilter,tp,0,LOCATION_ONFIELD,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_DISABLE,g,1,0,0)
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) and tc:IsFaceup() and not tc:IsDisabled() then
		local c=e:GetHandler()
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_DISABLE)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		tc:RegisterEffect(e1)
		local e2=Effect.CreateEffect(c)
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetCode(EFFECT_DISABLE_EFFECT)
		e2:SetValue(RESET_TURN_SET)
		e2:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		tc:RegisterEffect(e2)
	end
end

--------------------------------------------------------------------------------
-- 2. SUMMON WITCH/DIVINE & PLACE FIELD SPELL LOGIC
--------------------------------------------------------------------------------
function s.studentfilter(c)
	return c:IsCode(999900001, 999900008, 999900013, 999900019) and c:IsAbleToGraveAsCost()
end

function s.effcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	local valid_hand_or_field = c:IsLocation(LOCATION_HAND) or c:IsFaceup()
	if chk==0 then 
		return valid_hand_or_field and c:IsAbleToGraveAsCost()
			and Duel.IsExistingMatchingCard(s.studentfilter,tp,LOCATION_DECK,0,3,nil)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g=Duel.SelectMatchingCard(tp,s.studentfilter,tp,LOCATION_DECK,0,3,3,nil)
	g:AddCard(c)
	Duel.SendtoGrave(g,REASON_COST)
end

function s.spfilter(c,e,tp)
	return (c:IsSetCard(SET_PUELLA_WITCH) or c:IsCode(CARD_MADOKA_DIVINE))
		and c:IsCanBeSpecialSummoned(e,0,tp,true,false)
end

function s.fieldfilter(c)
	return c:IsCode(CARD_FIELD_MITAKIHARA) and not c:IsForbidden()
end

function s.efftg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_EXTRA,0,1,nil,e,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_EXTRA)
end

function s.effop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_EXTRA,0,1,1,nil,e,tp)
	local tc=g:GetFirst()
	if tc and Duel.SpecialSummon(tc,0,tp,tp,true,false,POS_FACEUP)>0 then
		-- Đặt "Mitakihara Town - The City of Destiny" từ Deck hoặc GY vào Field Zone
		local fc=Duel.GetFirstMatchingCard(aux.NecroValleyFilter(s.fieldfilter),tp,LOCATION_DECK+LOCATION_GRAVE,0,nil)
		if fc then
			Duel.BreakEffect()
			Duel.MoveToField(fc,tp,tp,LOCATION_FZONE,POS_FACEUP,true)
		end
	end
end