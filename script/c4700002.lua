-- ============================================================
-- Card Name: Spirit of the Ice Barrier
-- Passcode : 4700002
-- Type     : Monster / Link / Effect
-- Attribute: WATER
-- Link     : 1 (Bottom)
-- ATK      : 1000
-- Race     : Aqua
-- Archetype: Ice Barrier (0x2f)
-- Materials: 1 Level 4 or lower "Ice Barrier" monster
-- ============================================================
-- Effect 1: If this card is Link Summoned: You can add 1 "Ice Barrier"
--           Spell/Trap from your Deck to your hand.
-- Effect 2: You can Tribute this card; Special Summon 1 "Ice Barrier"
--           Tuner from your hand or GY.
-- You can only use each effect of "Spirit of the Ice Barrier" once per turn.
-- ============================================================

local s,id=GetID()

function s.initial_effect(c)
	c:EnableReviveLimit()

	-- Link Summon Procedure: 1 Level 4 or lower "Ice Barrier" monster
	Link.AddProcedure(c,s.matfilter,1,1)

	-- Effect 1: Add 1 "Ice Barrier" Spell/Trap on Link Summon
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SEARCH+CATEGORY_TOHAND)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.thcon)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)

	-- Effect 2: Tribute this card; Special Summon 1 "Ice Barrier" Tuner from hand or GY
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,{id,1})
	e2:SetCost(Cost.SelfTribute)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)
end

s.listed_series={SET_ICE_BARRIER}

-- ============================================================
-- Link Material Filter
-- ============================================================
function s.matfilter(c,lc,sumtype,tp)
	return c:IsLevelBelow(4) and c:IsSetCard(SET_ICE_BARRIER,lc,sumtype,tp)
end

-- ============================================================
-- Effect 1 Logic: Search Spell/Trap on Link Summon
-- ============================================================
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_LINK)
end

function s.thfilter(c)
	return c:IsSetCard(SET_ICE_BARRIER) and c:IsSpellTrap() and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end

-- ============================================================
-- Effect 2 Logic: Tribute to Special Summon Tuner from hand or GY
-- ============================================================
function s.spfilter(c,e,tp)
	return c:IsSetCard(SET_ICE_BARRIER) and c:IsType(TYPE_TUNER) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
	if e:GetHandler():GetSequence()<5 then ft=ft+1 end
	if chk==0 then return ft>0 and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_HAND+LOCATION_GRAVE,0,1,nil,e,tp) end
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
