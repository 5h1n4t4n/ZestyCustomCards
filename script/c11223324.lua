-- ============================================================
-- Card Name: Maverick Hunter - X
-- Passcode : 11223324
-- Type     : Monster / Effect
-- Attribute: LIGHT
-- Level    : 4
-- ATK/DEF  : 1800 / 1400
-- Race     : Machine
-- Archetype: Maverick Hunter (0x303), X (0x307)
-- ============================================================
-- Effect 1: If this card is Summoned: You can add 1 "Maverick Boost"
--           card from your Deck to your hand.
-- Effect 2: If a "Maverick Boost" card is activated while you control
--           this face-up card (Quick Effect): You can target 1 face-up
--           card your opponent controls; negate its effects.
-- You can only use each effect of "Maverick Hunter - X" once per turn.
-- ============================================================

Duel.LoadScript("constants.lua")
local s,id=GetID()

function s.initial_effect(c)
	-- ============================================================
	-- Effect 1 — Trigger on Summon: Search 1 "Maverick Boost" card
	-- ============================================================
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SUMMON_SUCCESS)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)
	local e2=e1:Clone()
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e2)

	-- ============================================================
	-- Effect 2 — Quick Effect: Negate face-up card on "Maverick Boost" activation
	-- ============================================================
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_DISABLE)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_CHAINING)
	e3:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,{id,1})
	e3:SetCondition(s.discon)
	e3:SetTarget(s.distg)
	e3:SetOperation(s.disop)
	c:RegisterEffect(e3)
end

s.listed_series={SET_MAVERICK_HUNTER,SET_X,SET_MAVERICK_BOOST}

-- ============================================================
-- Effect 1 Logic
-- ============================================================
function s.thfilter(c)
	return c:IsSetCard(SET_MAVERICK_BOOST) and c:IsAbleToHand()
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
function s.discon(e,tp,eg,ep,ev,re,r,rp)
	return re:GetHandler():IsSetCard(SET_MAVERICK_BOOST)
end

function s.distg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_ONFIELD) and chkc:IsControler(1-tp)
		and chkc:IsFaceup() and chkc:IsCanBeDisabledByEffect(e) end
	if chk==0 then return Duel.IsExistingTarget(Card.IsCanBeDisabledByEffect,tp,0,LOCATION_ONFIELD,1,nil,e) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_NEGATE)
	local g=Duel.SelectTarget(tp,Card.IsCanBeDisabledByEffect,tp,0,LOCATION_ONFIELD,1,1,nil,e)
	Duel.SetOperationInfo(0,CATEGORY_DISABLE,g,1,0,0)
end

function s.disop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsFaceup() and tc:IsRelateToEffect(e) then
		tc:NegateEffects(c,RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
	end
end
