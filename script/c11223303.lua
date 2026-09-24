-- ============================================================
-- Card Name: Maverick Boost - Z Saber
-- Passcode : 11223303
-- Type     : Spell / Equip
-- Archetype: Maverick Boost (0x304)
-- ============================================================
-- Effect 1: Equip only to a "Maverick Hunter" monster.
-- Effect 2: The equipped monster can make a second attack during
--           each Battle Phase.
-- Effect 3: If the equipped monster is a "Zero" monster: It gains 500 ATK.
-- Effect 4: If this card is discarded: You can Special Summon 1
--           "Maverick Hunter - Zero" from your hand or GY.
-- You can only use each effect of "Maverick Boost - Z Saber" once per turn.
-- ============================================================

Duel.LoadScript("constants.lua")
local s,id=GetID()

function s.initial_effect(c)
	-- ============================================================
	-- Equip Procedure: Equip only to a "Maverick Hunter" monster
	-- ============================================================
	aux.AddEquipProcedure(c,0,s.eqfilter)

	-- ============================================================
	-- Effect 1 — Continuous: Second attack during each Battle Phase
	-- ============================================================
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_EQUIP)
	e1:SetCode(EFFECT_EXTRA_ATTACK)
	e1:SetValue(1)
	c:RegisterEffect(e1)

	-- ============================================================
	-- Effect 2 — Continuous: Gain 500 ATK if equipped to "Zero" monster
	-- ============================================================
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_EQUIP)
	e2:SetCode(EFFECT_UPDATE_ATTACK)
	e2:SetCondition(s.atkcon)
	e2:SetValue(500)
	c:RegisterEffect(e2)

	-- ============================================================
	-- Effect 3 — Trigger on Discard: Special Summon "Maverick Hunter - Zero"
	-- ============================================================
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_TO_GRAVE)
	e3:SetCountLimit(1,id)
	e3:SetCondition(s.spcon)
	e3:SetTarget(s.sptg)
	e3:SetOperation(s.spop)
	c:RegisterEffect(e3)
end

s.listed_names={11223312}
s.listed_series={SET_MAVERICK_HUNTER,SET_ZERO,SET_MAVERICK_BOOST}

-- ============================================================
-- Equip Procedure Filter
-- ============================================================
function s.eqfilter(c)
	return c:IsFaceup() and c:IsSetCard(SET_MAVERICK_HUNTER)
end

-- ============================================================
-- Effect 2 Logic
-- ============================================================
function s.atkcon(e)
	local ec=e:GetHandler():GetEquipTarget()
	return ec and ec:IsSetCard(SET_ZERO)
end

-- ============================================================
-- Effect 3 Logic
-- ============================================================
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsReason(REASON_DISCARD)
end

function s.spfilter(c,e,tp)
	return c:IsCode(11223312) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_HAND+LOCATION_GRAVE,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_GRAVE)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.spfilter),tp,LOCATION_HAND+LOCATION_GRAVE,0,1,1,nil,e,tp)
	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
	end
end
