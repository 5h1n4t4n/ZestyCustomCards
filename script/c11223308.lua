-- ============================================================
-- Card Name: Reploid Angel - Cinnamon
-- Passcode : 11223308
-- Type     : Monster / Link / Effect
-- Attribute: LIGHT
-- Link     : 2 (Bottom-Left, Bottom-Right)
-- ATK      : 1800
-- Race     : Machine
-- Archetype: Maverick Analyzer (0x305)
-- Materials: 2 "Maverick" monsters
-- ============================================================
-- Effect 1: If this card is Link Summoned: You can send from
--           your Deck 1 "Maverick Analyzer" or "Maverick Boost"
--           card to the GY.
-- Effect 2: During opponent's Main Phase (Quick Effect): You can
--           return this card to the Extra Deck; target 1 face-up
--           card your opponent controls; negate its effects.
-- You can only use each effect of "Reploid Angel - Cinnamon" once per turn.
-- ============================================================

Duel.LoadScript("constants.lua")
local s,id=GetID()

function s.initial_effect(c)
	c:EnableReviveLimit()

	-- ============================================================
	-- Summon Procedure — Link: 2 "Maverick" monsters
	-- ============================================================
	Link.AddProcedure(c,s.matfilter,2,2)

	-- ============================================================
	-- Effect 1 — Trigger on Link Summon: Send 1 Analyzer/Boost card to GY
	-- ============================================================
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOGRAVE)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.tgcon)
	e1:SetTarget(s.tgtg)
	e1:SetOperation(s.tgop)
	c:RegisterEffect(e1)

	-- ============================================================
	-- Effect 2 — Quick Effect (Opponent's Main Phase): Return to Extra; negate
	-- ============================================================
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_DISABLE)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,{id,1})
	e2:SetCondition(s.discon)
	e2:SetCost(s.discost)
	e2:SetTarget(s.distg)
	e2:SetOperation(s.disop)
	c:RegisterEffect(e2)
end

s.listed_series={SET_MAVERICK_HUNTER,SET_MAVERICK_BOOST,SET_MAVERICK_ANALYZER}

-- ============================================================
-- Summon Procedure / Material Filters
-- ============================================================
function s.matfilter(c,lc,sumtype,tp)
	return (c:IsSetCard(SET_MAVERICK_HUNTER) or c:IsSetCard(SET_MAVERICK_BOOST) or c:IsSetCard(SET_MAVERICK_ANALYZER))
		and c:IsType(TYPE_MONSTER)
end

-- ============================================================
-- Effect 1 Logic
-- ============================================================
function s.tgcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_LINK)
end

function s.tgfilter(c)
	return (c:IsSetCard(SET_MAVERICK_ANALYZER) or c:IsSetCard(SET_MAVERICK_BOOST)) and c:IsAbleToGrave()
end

function s.tgtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.tgfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_DECK)
end

function s.tgop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g=Duel.SelectMatchingCard(tp,s.tgfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoGrave(g,REASON_EFFECT)
	end
end

-- ============================================================
-- Effect 2 Logic
-- ============================================================
function s.discon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetTurnPlayer()~=tp and Duel.IsMainPhase()
end

function s.discost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsAbleToExtraAsCost() end
	Duel.SendtoDeck(c,nil,SEQ_DECKSHUFFLE,REASON_COST)
end

function s.distg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsControler(1-tp) and chkc:IsOnField() and chkc:IsFaceup() and not chkc:IsDisabled() end
	if chk==0 then return Duel.IsExistingTarget(aux.FaceupFilter(aux.NOT(Card.IsDisabled)),tp,0,LOCATION_ONFIELD,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_NEGATE)
	local g=Duel.SelectTarget(tp,aux.FaceupFilter(aux.NOT(Card.IsDisabled)),tp,0,LOCATION_ONFIELD,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_DISABLE,g,1,0,0)
end

function s.disop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsFaceup() and tc:IsRelateToEffect(e) and not tc:IsDisabled() then
		Duel.NegateRelatedChain(tc,RESET_TURN_SET)
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_DISABLE)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		tc:RegisterEffect(e1)
		local e2=Effect.CreateEffect(e:GetHandler())
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetCode(EFFECT_DISABLE_EFFECT)
		e2:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		tc:RegisterEffect(e2)
	end
end
