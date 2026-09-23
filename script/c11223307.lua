-- ============================================================
-- Card Name: Maverick Analyzer - Rico
-- Passcode : 11223307
-- Type     : Monster / Tuner / Effect
-- Attribute: LIGHT
-- Level    : 4
-- ATK/DEF  : 1000 / 1800
-- Race     : Machine
-- Archetype: Maverick Analyzer (0x305)
-- ============================================================
-- Effect 1: If this card is Normal Summoned: You can Special
--           Summon 1 "Maverick Hunter" monster from your Deck,
--           but negate its effects.
-- Effect 2: If this card is in your GY: You can banish both this
--           card and 1 "Maverick Hunter" monster you control or
--           in your GY; Special Summon 1 "Maverick Hunter" Synchro
--           Monster from your Extra Deck whose Level is equal to
--           the combined Level of the banished monsters (This is
--           treated as a Synchro Summon).
-- You can only use 1 effect of "Maverick Analyzer - Rico" once per turn.
-- ============================================================

Duel.LoadScript("constants.lua")
local s,id=GetID()

function s.initial_effect(c)
	-- ============================================================
	-- Effect 1 — Trigger on Normal Summon: Special Summon from Deck
	-- ============================================================
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SUMMON_SUCCESS)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.sptg1)
	e1:SetOperation(s.spop1)
	c:RegisterEffect(e1)

	-- ============================================================
	-- Effect 2 — Ignition from GY: Banish materials to pseudo-Synchro Summon
	-- ============================================================
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,id)
	e2:SetCost(s.spcost2)
	e2:SetTarget(s.sptg2)
	e2:SetOperation(s.spop2)
	c:RegisterEffect(e2)
end

s.listed_series={SET_MAVERICK_HUNTER,SET_MAVERICK_ANALYZER}

-- ============================================================
-- Effect 1 Logic
-- ============================================================
function s.spfilter1(c,e,tp)
	return c:IsSetCard(SET_MAVERICK_HUNTER) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.sptg1(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.spfilter1,tp,LOCATION_DECK,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK)
end

function s.spop1(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spfilter1,tp,LOCATION_DECK,0,1,1,nil,e,tp)
	local tc=g:GetFirst()
	if tc and Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)>0 then
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_DISABLE)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		tc:RegisterEffect(e1)
		local e2=Effect.CreateEffect(e:GetHandler())
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetCode(EFFECT_DISABLE_EFFECT)
		e2:SetReset(RESET_EVENT+RESETS_STANDARD)
		tc:RegisterEffect(e2)
	end
end

-- ============================================================
-- Effect 2 Logic
-- ============================================================
function s.synfilter(c,e,tp,lv,mc)
	return c:IsSetCard(SET_MAVERICK_HUNTER) and c:IsType(TYPE_SYNCHRO) and c:GetLevel()==lv
		and Duel.GetLocationCountFromEx(tp,tp,mc,c)>0
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_SYNCHRO,tp,false,false)
end

function s.matfilter(c,e,tp)
	if not (c:IsSetCard(SET_MAVERICK_HUNTER) and c:IsAbleToRemoveAsCost() and c:HasLevel()) then return false end
	local lv=c:GetLevel()+4
	return Duel.IsExistingMatchingCard(s.synfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp,lv,c)
end

function s.spcost2(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsAbleToRemoveAsCost()
		and Duel.IsExistingMatchingCard(s.matfilter,tp,LOCATION_MZONE+LOCATION_GRAVE,0,1,c,e,tp) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectMatchingCard(tp,s.matfilter,tp,LOCATION_MZONE+LOCATION_GRAVE,0,1,1,c,e,tp)
	local tc=g:GetFirst()
	e:SetLabel(tc:GetLevel()+4)
	g:AddCard(c)
	Duel.Remove(g,POS_FACEUP,REASON_COST)
end

function s.sptg2(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

function s.synspfilter(c,e,tp,lv)
	return c:IsSetCard(SET_MAVERICK_HUNTER) and c:IsType(TYPE_SYNCHRO) and c:GetLevel()==lv
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_SYNCHRO,tp,false,false)
end

function s.spop2(e,tp,eg,ep,ev,re,r,rp)
	local lv=e:GetLabel()
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.synspfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp,lv)
	local tc=g:GetFirst()
	if tc and Duel.SpecialSummon(tc,SUMMON_TYPE_SYNCHRO,tp,tp,false,false,POS_FACEUP)>0 then
		tc:CompleteProcedure()
	end
end
