-- ============================================================
-- Card Name: Maverick Analyzer - Layer
-- Passcode : 11223301
-- Type     : Monster / Effect
-- Attribute: LIGHT
-- Level    : 4
-- ATK/DEF  : 1000 / 1800
-- Race     : Machine
-- Archetype: Maverick Analyzer (0x305)
-- ============================================================
-- Effect 1: If you control a "Maverick Hunter" monster (Quick Effect):
--           You can Special Summon this card from your hand, then if
--           you control a "Zero" monster when this card is Summoned;
--           You can target 1 face-up card your opponent controls or
--           in their GY, until the end of this turn, its effects are negated.
-- You can only use this effect of "Maverick Analyzer - Layer" once per turn.
-- ============================================================

Duel.LoadScript("constants.lua")
local s,id=GetID()

function s.initial_effect(c)
	-- ============================================================
	-- Effect 1 — Quick Effect: Special Summon from hand + optional negate
	-- ============================================================
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_DISABLE)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.spcon)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)
end

s.listed_series={SET_MAVERICK_HUNTER,SET_MAVERICK_ANALYZER,SET_ZERO}

-- ============================================================
-- Effect 1 Logic
-- ============================================================
function s.mhfilter(c)
	return c:IsFaceup() and c:IsSetCard(SET_MAVERICK_HUNTER)
end

function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(s.mhfilter,tp,LOCATION_MZONE,0,1,nil)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end

function s.zerofilter(c)
	return c:IsFaceup() and c:IsSetCard(SET_ZERO)
end

function s.negfilter(c)
	if c:IsLocation(LOCATION_ONFIELD) then
		return c:IsFaceup() and not c:IsDisabled()
	else
		return aux.NecroValleyFilter()(c)
	end
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) or Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)<=0 then return end
	if Duel.IsExistingMatchingCard(s.zerofilter,tp,LOCATION_MZONE,0,1,nil)
		and Duel.IsExistingMatchingCard(s.negfilter,tp,0,LOCATION_ONFIELD+LOCATION_GRAVE,1,nil)
		and Duel.SelectYesNo(tp,aux.Stringid(id,1)) then
		Duel.BreakEffect()
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_NEGATE)
		local g=Duel.SelectMatchingCard(tp,s.negfilter,tp,0,LOCATION_ONFIELD+LOCATION_GRAVE,1,1,nil)
		local tc=g:GetFirst()
		if tc then
			Duel.HintSelection(g)
			if tc:IsLocation(LOCATION_ONFIELD) then
				Duel.NegateRelatedChain(tc,RESET_TURN_SET)
				local e1=Effect.CreateEffect(c)
				e1:SetType(EFFECT_TYPE_SINGLE)
				e1:SetCode(EFFECT_DISABLE)
				e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
				tc:RegisterEffect(e1)
				local e2=Effect.CreateEffect(c)
				e2:SetType(EFFECT_TYPE_SINGLE)
				e2:SetCode(EFFECT_DISABLE_EFFECT)
				e2:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
				tc:RegisterEffect(e2)
			else
				local e1=Effect.CreateEffect(c)
				e1:SetType(EFFECT_TYPE_SINGLE)
				e1:SetCode(EFFECT_DISABLE)
				e1:SetReset(RESET_EVENT+RESETS_STANDARD_EXC_GRAVE+RESET_PHASE+PHASE_END)
				tc:RegisterEffect(e1)
				local e2=Effect.CreateEffect(c)
				e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
				e2:SetCode(EVENT_CHAIN_SOLVING)
				e2:SetRange(LOCATION_GRAVE)
				e2:SetOperation(s.disop)
				e2:SetReset(RESET_EVENT+RESETS_STANDARD_EXC_GRAVE+RESET_PHASE+PHASE_END)
				tc:RegisterEffect(e2)
			end
		end
	end
end

function s.disop(e,tp,eg,ep,ev,re,r,rp)
	if re:GetHandler()==e:GetHandler() then
		Duel.NegateEffect(ev)
	end
end
