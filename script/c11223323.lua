-- ============================================================
-- Card Name: Maverick Hunter - White Axl
-- Passcode : 11223323
-- Type     : Monster / Xyz / Effect
-- Attribute: LIGHT
-- Rank     : 4
-- ATK/DEF  : 1500 / 1500
-- Race     : Machine
-- Archetype: Maverick Hunter (0x303), Axl (0x308)
-- Materials: 2 Level 4 Machine monsters
-- ============================================================
-- Effect 1: If this card is Xyz Summoned: You can add 1 "Maverick
--           Boost" Equip Spell Card from your Deck to your hand.
-- Effect 2: If this card is Xyz Summoned using at least 1 "Axl"
--           monster as material, it gains these effects:
--           ● Gains 1000 ATK.
--           ● Cannot be destroyed by card effects.
-- Effect 3: (Quick Effect): You can detach 1 material from this card;
--           equip 1 "Maverick Boost" Equip Spell Card from your Deck
--           to an appropriate monster on the field.
-- You can only use this effect of "Maverick Hunter - White Axl" once per turn.
-- ============================================================

Duel.LoadScript("constants.lua")
local s,id=GetID()

function s.initial_effect(c)
	c:EnableReviveLimit()

	-- ============================================================
	-- Summon Procedure — Xyz: 2 Level 4 Machine monsters
	-- ============================================================
	Xyz.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsRace,RACE_MACHINE),4,2)

	-- ============================================================
	-- Effect 1 — Trigger on Xyz Summon: Search "Maverick Boost" Equip Spell
	-- ============================================================
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.thcon)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)

	-- ============================================================
	-- Effect 2 — Continuous: Material check (at least 1 "Axl" monster)
	-- ============================================================
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetCondition(s.matcon)
	e2:SetOperation(s.matop)
	c:RegisterEffect(e2)

	-- ============================================================
	-- Effect 3 — Quick Effect: Detach 1; equip 1 Boost Equip from Deck
	-- ============================================================
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_EQUIP)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetRange(LOCATION_MZONE)
	e3:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E+TIMING_MAIN_END)
	e3:SetCountLimit(1,{id,1})
	e3:SetCost(s.eqcost)
	e3:SetTarget(s.eqtg)
	e3:SetOperation(s.eqop)
	c:RegisterEffect(e3)
end

s.listed_series={SET_MAVERICK_HUNTER,SET_AXL,SET_MAVERICK_BOOST}

-- ============================================================
-- Effect 1 Logic
-- ============================================================
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_XYZ)
end

function s.thfilter(c)
	return c:IsSetCard(SET_MAVERICK_BOOST) and c:IsType(TYPE_EQUIP) and c:IsAbleToHand()
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
-- Effect 2 Logic
-- ============================================================
function s.axlfilter(c)
	return c:IsSetCard(SET_AXL)
end

function s.matcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local mg=c:GetMaterial()
	return c:IsSummonType(SUMMON_TYPE_XYZ) and mg:IsExists(s.axlfilter,1,nil)
end

function s.matop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	-- Gain 1000 ATK
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_UPDATE_ATTACK)
	e1:SetValue(1000)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD)
	c:RegisterEffect(e1)
	-- Cannot be destroyed by card effects
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetValue(1)
	e2:SetReset(RESET_EVENT+RESETS_STANDARD)
	c:RegisterEffect(e2)
end

-- ============================================================
-- Effect 3 Logic
-- ============================================================
function s.eqcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():CheckRemoveOverlayCard(tp,1,REASON_COST) end
	e:GetHandler():RemoveOverlayCard(tp,1,1,REASON_COST)
end

function s.eqdeckfilter(c,tp)
	return c:IsSetCard(SET_MAVERICK_BOOST) and c:IsType(TYPE_EQUIP)
		and Duel.IsExistingMatchingCard(s.eqtargetfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil,c)
end

function s.eqtargetfilter(c,ec)
	return c:IsFaceup() and ec:CheckEquipTarget(c)
end

function s.eqtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
		and Duel.IsExistingMatchingCard(s.eqdeckfilter,tp,LOCATION_DECK,0,1,nil,tp) end
	Duel.SetOperationInfo(0,CATEGORY_EQUIP,nil,1,tp,LOCATION_DECK)
end

function s.eqop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_EQUIP)
	local ec=Duel.SelectMatchingCard(tp,s.eqdeckfilter,tp,LOCATION_DECK,0,1,1,nil,tp):GetFirst()
	if not ec then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
	local tc=Duel.SelectMatchingCard(tp,s.eqtargetfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,1,nil,ec):GetFirst()
	if tc then
		Duel.Equip(tp,ec,tc)
	end
end
