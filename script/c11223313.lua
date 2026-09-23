-- ============================================================
-- Card Name: Maverick Boost - Counter Smash
-- Passcode : 11223313
-- Type     : Trap / Counter
-- Archetype: Maverick Boost (0x304)
-- ============================================================
-- Effect 1: When a Spell/Trap Card, or monster effect, is activated
--           while you control a "Maverick Hunter" monster Special
--           Summoned from the Extra Deck: Negate the activation,
--           and if you control a "Zero" monster, banish that card.
-- You can only activate 1 "Maverick Boost - Counter Smash" once per turn.
-- ============================================================

Duel.LoadScript("constants.lua")
local s,id=GetID()

function s.initial_effect(c)
	-- ============================================================
	-- Effect 1 — Activation: Negate activation and optionally banish
	-- ============================================================
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_NEGATE+CATEGORY_REMOVE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_CHAINING)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetCondition(s.condition)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

s.listed_series={SET_MAVERICK_HUNTER,SET_ZERO,SET_MAVERICK_BOOST}

-- ============================================================
-- Effect 1 Logic
-- ============================================================
function s.cfilter(c)
	return c:IsFaceup() and c:IsSetCard(SET_MAVERICK_HUNTER) and c:IsSummonLocation(LOCATION_EXTRA)
end

function s.condition(e,tp,eg,ep,ev,re,r,rp)
	if not Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_MZONE,0,1,nil) then return false end
	return (re:IsActiveType(TYPE_MONSTER) or re:IsHasType(EFFECT_TYPE_ACTIVATE)) and Duel.IsChainNegatable(ev)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
	if Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsSetCard,SET_ZERO),tp,LOCATION_MZONE,0,1,nil)
		and re:GetHandler():IsRelateToEffect(re) and re:GetHandler():IsAbleToRemove() then
		Duel.SetOperationInfo(0,CATEGORY_REMOVE,eg,1,0,0)
	end
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local rc=re:GetHandler()
	if Duel.NegateActivation(ev) and rc:IsRelateToEffect(re)
		and Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsSetCard,SET_ZERO),tp,LOCATION_MZONE,0,1,nil) then
		Duel.Remove(eg,POS_FACEUP,REASON_EFFECT)
	end
end
