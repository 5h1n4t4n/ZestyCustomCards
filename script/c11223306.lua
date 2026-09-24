-- ============================================================
-- Card Name: Maverick Analyzer - Pallette
-- Passcode : 11223306
-- Type     : Monster / Effect
-- Attribute: LIGHT
-- Level    : 4
-- ATK/DEF  : 1000 / 1800
-- Race     : Machine
-- Archetype: Maverick Analyzer (0x305)
-- ============================================================
-- Effect 1: (Quick Effect): You can discard this card and 1 other
--           card; Special Summon 1 "Maverick Hunter" monster from
--           your GY, and if it is an "Axl" monster, you can add from
--           your Deck 1 "Maverick Boost" Equip Spell Card.
-- Effect 2: If this card is in the GY: You can target 1 of your
--           banished "Maverick Hunter" or "Maverick Boost" cards;
--           shuffle both this card and the targeted card into the Deck.
-- You can only use each effect of "Maverick Analyzer - Pallette" once per turn.
-- ============================================================

Duel.LoadScript("constants.lua")
local s,id=GetID()

function s.initial_effect(c)
	-- ============================================================
	-- Effect 1 — Quick Effect: Discard to Special Summon from GY
	-- ============================================================
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)
	e1:SetCost(s.spcost)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	-- ============================================================
	-- Effect 2 — Ignition from GY: Shuffle banished card and self to Deck
	-- ============================================================
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,2))
	e2:SetCategory(CATEGORY_TODECK)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,{id,1})
	e2:SetTarget(s.tdtg)
	e2:SetOperation(s.tdop)
	c:RegisterEffect(e2)
end

s.listed_series={SET_MAVERICK_HUNTER,SET_MAVERICK_BOOST,SET_MAVERICK_ANALYZER,SET_AXL}

-- ============================================================
-- Effect 1 Logic
-- ============================================================
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsDiscardable()
		and Duel.IsExistingMatchingCard(Card.IsDiscardable,tp,LOCATION_HAND,0,1,c) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DISCARD)
	local g=Duel.SelectMatchingCard(tp,Card.IsDiscardable,tp,LOCATION_HAND,0,1,1,c)
	g:AddCard(c)
	Duel.SendtoGrave(g,REASON_COST+REASON_DISCARD)
end

function s.spfilter(c,e,tp)
	return c:IsSetCard(SET_MAVERICK_HUNTER) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_GRAVE,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE)
end

function s.eqfilter(c)
	return c:IsSetCard(SET_MAVERICK_BOOST) and c:IsType(TYPE_EQUIP) and c:IsAbleToHand()
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.spfilter),tp,LOCATION_GRAVE,0,1,1,nil,e,tp)
	local tc=g:GetFirst()
	if tc and Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)>0 then
		if tc:IsSetCard(SET_AXL)
			and Duel.IsExistingMatchingCard(s.eqfilter,tp,LOCATION_DECK,0,1,nil)
			and Duel.SelectYesNo(tp,aux.Stringid(id,1)) then
			Duel.BreakEffect()
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
			local hg=Duel.SelectMatchingCard(tp,s.eqfilter,tp,LOCATION_DECK,0,1,1,nil)
			if #hg>0 then
				Duel.SendtoHand(hg,nil,REASON_EFFECT)
				Duel.ConfirmCards(1-tp,hg)
			end
		end
	end
end

-- ============================================================
-- Effect 2 Logic
-- ============================================================
function s.tdfilter(c)
	return (c:IsSetCard(SET_MAVERICK_HUNTER) or c:IsSetCard(SET_MAVERICK_BOOST)) and c:IsFaceup() and c:IsAbleToDeck()
end

function s.tdtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	local c=e:GetHandler()
	if chkc then return chkc:IsLocation(LOCATION_REMOVED) and chkc:IsControler(tp) and s.tdfilter(chkc) and chkc~=c end
	if chk==0 then return c:IsAbleToDeck()
		and Duel.IsExistingTarget(s.tdfilter,tp,LOCATION_REMOVED,0,1,c) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	local g=Duel.SelectTarget(tp,s.tdfilter,tp,LOCATION_REMOVED,0,1,1,c)
	g:AddCard(c)
	Duel.SetOperationInfo(0,CATEGORY_TODECK,g,2,0,0)
end

function s.tdop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if c:IsRelateToEffect(e) and tc and tc:IsRelateToEffect(e) then
		local g=Group.FromCards(c,tc)
		Duel.SendtoDeck(g,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
	end
end
