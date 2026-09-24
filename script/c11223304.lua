-- ============================================================
-- Card Name: Maverick Hunter - Black Zero
-- Passcode : 11223304
-- Type     : Monster / Xyz / Effect
-- Attribute: DARK
-- Rank     : 4
-- ATK/DEF  : 2000 / 1600
-- Race     : Machine
-- Archetype: Maverick Hunter (0x303), Zero (0x306)
-- Materials: 2 Level 4 Machine monsters
-- ============================================================
-- Effect 1: If this card is Xyz Summoned: You can add 1 "Maverick
--           Boost" Quick-Play Spell Card from your Deck to your hand.
-- Effect 2: If this card is Xyz Summoned using at least 1 "Zero"
--           monster as material, it gains these effects:
--           ● Gains 1000 ATK.
--           ● Neither player can activate cards or effects in response
--             to this card's effect activations.
-- Effect 3: (Quick Effect): You can detach 1 material from this card;
--           this card is unaffected by your opponent's card effects
--           until the end of the next turn.
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
	-- Effect 1 — Trigger on Xyz Summon: Search Quick-Play Spell
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
	-- Effect 2 — Continuous: Material check (at least 1 "Zero" monster)
	-- ============================================================
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetCondition(s.matcon)
	e2:SetOperation(s.matop)
	c:RegisterEffect(e2)

	-- ============================================================
	-- Effect 3 — Quick Effect: Detach 1 material; unaffected
	-- ============================================================
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,{id,1})
	e3:SetCost(s.immcost)
	e3:SetOperation(s.immop)
	c:RegisterEffect(e3)
end

s.listed_series={SET_MAVERICK_HUNTER,SET_ZERO,SET_MAVERICK_BOOST}

-- ============================================================
-- Effect 1 Logic
-- ============================================================
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_XYZ)
end

function s.thfilter(c)
	return c:IsSetCard(SET_MAVERICK_BOOST) and c:IsType(TYPE_QUICKPLAY) and c:IsAbleToHand()
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
function s.zerofilter(c)
	return c:IsSetCard(SET_ZERO)
end

function s.matcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local mg=c:GetMaterial()
	return c:IsSummonType(SUMMON_TYPE_XYZ) and mg:IsExists(s.zerofilter,1,nil)
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
	-- Neither player can activate card or effect in response to its effects
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EVENT_CHAINING)
	e2:SetRange(LOCATION_MZONE)
	e2:SetOperation(s.chainop)
	e2:SetReset(RESET_EVENT+RESETS_STANDARD)
	c:RegisterEffect(e2)
end

function s.chainop(e,tp,eg,ep,ev,re,r,rp)
	if re:GetHandler()==e:GetHandler() then
		Duel.SetChainLimit(s.chainlimit)
	end
end

function s.chainlimit(e,rp,tp)
	return false
end

-- ============================================================
-- Effect 3 Logic
-- ============================================================
function s.immcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():CheckRemoveOverlayCard(tp,1,REASON_COST) end
	e:GetHandler():RemoveOverlayCard(tp,1,1,REASON_COST)
end

function s.immop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) and c:IsFaceup() then
		local e1=Effect.CreateEffect(c)
		e1:SetDescription(3110)
		e1:SetProperty(EFFECT_FLAG_CLIENT_HINT)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_IMMUNE_EFFECT)
		e1:SetValue(s.efilter)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END,2)
		c:RegisterEffect(e1)
	end
end

function s.efilter(e,re)
	return e:GetOwnerPlayer()~=re:GetOwnerPlayer()
end
