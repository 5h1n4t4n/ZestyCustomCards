-- ============================================================
-- Card Name: Maverick Analyzer - Alia
-- Passcode : 11223305
-- Type     : Monster / Effect
-- Attribute: LIGHT
-- Level    : 4
-- ATK/DEF  : 1000 / 1800
-- Race     : Machine
-- Archetype: Maverick Analyzer (0x305)
-- ============================================================
-- Effect 1: If you control a "Maverick Hunter" monster, you can
--           Special Summon this card from your hand. You can only
--           Special Summon "Maverick Analyzer - Alia" once per turn this way.
-- Effect 2: You can discard 1 card; Special Summon 1 "Maverick Hunter"
--           monster from your Deck, and if it is an "X" monster, your
--           "Maverick" monsters' Special Summon cannot be negated for
--           the rest of this turn. You can only use this effect of
--           "Maverick Analyzer - Alia" once per turn.
-- ============================================================

Duel.LoadScript("constants.lua")
local s,id=GetID()

function s.initial_effect(c)
	-- ============================================================
	-- Effect 1 — Special Summon procedure from hand
	-- ============================================================
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetCondition(s.spcon)
	c:RegisterEffect(e1)

	-- ============================================================
	-- Effect 2 — Ignition: Discard 1 card; Special Summon from Deck
	-- ============================================================
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,{id,1})
	e2:SetCost(s.spcost)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)
end

s.listed_series={SET_MAVERICK_HUNTER,SET_MAVERICK_ANALYZER,SET_MAVERICK_BOOST,SET_X}

-- ============================================================
-- Effect 1 Logic
-- ============================================================
function s.mhfilter(c)
	return c:IsFaceup() and c:IsSetCard(SET_MAVERICK_HUNTER)
end

function s.spcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.mhfilter,tp,LOCATION_MZONE,0,1,nil)
end

-- ============================================================
-- Effect 2 Logic
-- ============================================================
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(Card.IsDiscardable,tp,LOCATION_HAND,0,1,nil) end
	Duel.DiscardHand(tp,Card.IsDiscardable,1,1,REASON_COST+REASON_DISCARD)
end

function s.spdeckfilter(c,e,tp)
	return c:IsSetCard(SET_MAVERICK_HUNTER) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.spdeckfilter,tp,LOCATION_DECK,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK)
end

function s.distg(e,c)
	return c:IsSetCard(SET_MAVERICK_HUNTER) or c:IsSetCard(SET_MAVERICK_BOOST) or c:IsSetCard(SET_MAVERICK_ANALYZER)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spdeckfilter,tp,LOCATION_DECK,0,1,1,nil,e,tp)
	local tc=g:GetFirst()
	if tc and Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)>0 then
		if tc:IsSetCard(SET_X) then
			-- Maverick monsters' Special Summon cannot be negated for the rest of this turn
			local e1=Effect.CreateEffect(e:GetHandler())
			e1:SetType(EFFECT_TYPE_FIELD)
			e1:SetCode(EFFECT_CANNOT_DISABLE_SPSUMMON)
			e1:SetProperty(EFFECT_FLAG_IGNORE_RANGE+EFFECT_FLAG_SET_AVAILABLE)
			e1:SetTargetRange(1,0)
			e1:SetTarget(s.distg)
			e1:SetReset(RESET_PHASE+PHASE_END)
			Duel.RegisterEffect(e1,tp)
		end
	end
end
