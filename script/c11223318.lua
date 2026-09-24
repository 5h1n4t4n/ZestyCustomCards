-- ============================================================
-- Card Name: Maverick Boost - Virus Affect
-- Passcode : 11223318
-- Type     : Spell / Normal
-- Archetype: Maverick Boost (0x304)
-- ============================================================
-- Effect 1: Send 1 "Zero" monster from your hand or face-up field
--           to the GY; Special Summon 1 "Dark Maverick Hunter -
--           Zero Virus" from your Extra Deck.
-- Effect 2: You can banish this card from the GY; add 1 "Maverick
--           Hunter - Zero" from your GY to your hand.
-- You can only use each effect of "Maverick Boost - Virus Affect" once per turn.
-- ============================================================

Duel.LoadScript("constants.lua")
local s,id=GetID()

function s.initial_effect(c)
	-- ============================================================
	-- Effect 1 — Activation: Send "Zero" monster to summon "Zero Virus"
	-- ============================================================
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id)
	e1:SetCost(s.cost)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)

	-- ============================================================
	-- Effect 2 — Ignition from GY: Banish to recover "Maverick Hunter - Zero"
	-- ============================================================
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,{id,1})
	e2:SetCost(aux.bfgcost)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
end

s.listed_names={11223312,11223325}
s.listed_series={SET_ZERO,SET_MAVERICK_BOOST,SET_MAVERICK_HUNTER}

-- ============================================================
-- Effect 1 Logic
-- ============================================================
function s.cfilter(c,e,tp)
	return (c:IsLocation(LOCATION_HAND) or c:IsFaceup()) and c:IsSetCard(SET_ZERO) and c:IsAbleToGraveAsCost()
		and Duel.GetLocationCountFromEx(tp,tp,c,TYPE_FUSION)>0
end

function s.spfilter(c,e,tp)
	return c:IsCode(11223325) and c:IsCanBeSpecialSummoned(e,0,tp,true,false)
end

function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_HAND+LOCATION_MZONE,0,1,nil,e,tp) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g=Duel.SelectMatchingCard(tp,s.cfilter,tp,LOCATION_HAND+LOCATION_MZONE,0,1,1,nil,e,tp)
	Duel.SendtoGrave(g,REASON_COST)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCountFromEx(tp,tp,nil,TYPE_FUSION)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp)
	if #g>0 and Duel.SpecialSummon(g,0,tp,tp,true,false,POS_FACEUP)>0 then
		g:GetFirst():CompleteProcedure()
	end
end

-- ============================================================
-- Effect 2 Logic
-- ============================================================
function s.thfilter(c)
	return c:IsCode(11223312) and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_GRAVE,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_GRAVE)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_GRAVE,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end
