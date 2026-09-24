-- ============================================================
-- Card Name: Genericus Monstrum the Link
-- Passcode : 192500002
-- Type     : Monster / Link / Effect
-- Attribute: LIGHT
-- Link Rating: 5
-- Link Arrows: Top-Left, Top-Right, Left, Right, Bottom
-- ATK      : ?
-- Race     : Cyberse
-- Archetype: Genericus Monstrum (0x785)
-- ============================================================
-- Materials: 1+ monsters
-- If this card is Special Summoned by the effect of a "Genericus Monstrum"
-- monster: Its original ATK becomes 3000, also you can declare 1
-- Attribute; this card becomes that Attribute.
-- ① Gains the original Attributes, Types, ATK, and DEF of the monsters
--    used as material for its Link Summon.
-- ② Cannot be targeted by the effects of monsters with the same Attribute
--    as this card.
-- ③ (Quick Effect): You can shuffle both this card and 1 card on the field
--    into the Deck/Extra Deck; Special Summon 1 non-Link "Genericus
--    Monstrum" monster from your Deck or Extra Deck.
-- ④ If this card in its owner's possession leaves the field because of an
--    opponent's card effect: Return this card to the Extra Deck, and if you
--    do, Special Summon 1 non-Link "Genericus Monstrum" monster from your
--    Deck or Extra Deck, ignoring its Summoning conditions.
-- You can only use each effect of "Genericus Monstrum the Link" once per turn.
-- ============================================================

local s,id=GetID()
Duel.LoadScript("constants.lua")

function s.initial_effect(c)
	c:EnableReviveLimit()

	-- ============================================================
	-- Summon Procedures & Constraints
	-- ============================================================
	-- Link Materials: 1+ monsters
	Link.AddProcedure(c,nil,1,5)

	-- ============================================================
	-- Continuous & Inherent Effects
	-- ============================================================
	-- Special Summoned by "Genericus Monstrum" monster effect
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCondition(s.gen_spcon)
	e1:SetOperation(s.gen_spop)
	c:RegisterEffect(e1)

	-- ============================================================
	-- Effect 1: Material Stat/Attribute/Race Gain
	-- ============================================================
	local e_mat=Effect.CreateEffect(c)
	e_mat:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e_mat:SetCode(EVENT_SPSUMMON_SUCCESS)
	e_mat:SetOperation(s.matop)
	c:RegisterEffect(e_mat)

	-- ============================================================
	-- Effect 2: Cannot be targeted by same Attribute monster effect
	-- ============================================================
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e2:SetRange(LOCATION_MZONE)
	e2:SetValue(s.tgval2)
	c:RegisterEffect(e2)

	-- ============================================================
	-- Effect 3: (Quick Effect) Shuffle this card and 1 card on field
	-- ============================================================
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetCategory(CATEGORY_TODECK+CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetRange(LOCATION_MZONE)
	e3:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E|TIMING_MAIN_END)
	e3:SetCountLimit(1,id)
	e3:SetCost(s.cost3)
	e3:SetTarget(s.tg3)
	e3:SetOperation(s.op3)
	c:RegisterEffect(e3)

	-- ============================================================
	-- Effect 4: Leaves Field Floating Effect
	-- ============================================================
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,1))
	e4:SetCategory(CATEGORY_TOEXTRA+CATEGORY_SPECIAL_SUMMON)
	e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e4:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_DAMAGE_STEP)
	e4:SetCode(EVENT_LEAVE_FIELD)
	e4:SetCountLimit(1,{id,1})
	e4:SetCondition(s.spcon4)
	e4:SetTarget(s.sptg4)
	e4:SetOperation(s.spop4)
	c:RegisterEffect(e4)
end
s.listed_series={SET_GENERICUS_MONSTRUM}

-- ============================================================
-- Genericus Special Summon Enhancements
-- ============================================================
function s.gen_spcon(e,tp,eg,ep,ev,re,r,rp)
	if not re then return false end
	local rc=re:GetHandler()
	return rc and rc:IsSetCard(SET_GENERICUS_MONSTRUM) and rc:IsMonster()
end
function s.gen_spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_SET_BASE_ATTACK)
	e1:SetValue(3000)
	e1:SetReset(RESET_EVENT|RESETS_STANDARD)
	c:RegisterEffect(e1)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATTRIBUTE)
	local att=Duel.AnnounceAttribute(tp,1,ATTRIBUTE_ALL)
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_CHANGE_ATTRIBUTE)
	e2:SetValue(att)
	e2:SetReset(RESET_EVENT|RESETS_STANDARD)
	c:RegisterEffect(e2)
end

-- ============================================================
-- Material Gain Callback
-- ============================================================
function s.matop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsLinkSummoned() then return end
	local mg=c:GetMaterial()
	if not mg or #mg==0 then return end
	local att=0
	local race=0
	local atk=0
	for tc in mg:Iter() do
		att=att|tc:GetOriginalAttribute()
		race=race|tc:GetOriginalRace()
		local tatk=tc:GetTextAttack()
		local tdef=tc:GetTextDefense()
		if tatk>0 then atk=atk+tatk end
		if tdef>0 then atk=atk+tdef end
	end
	if att~=0 then
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_ADD_ATTRIBUTE)
		e1:SetValue(att)
		e1:SetReset(RESET_EVENT|RESETS_STANDARD)
		c:RegisterEffect(e1)
	end
	if race~=0 then
		local e2=Effect.CreateEffect(c)
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetCode(EFFECT_ADD_RACE)
		e2:SetValue(race)
		e2:SetReset(RESET_EVENT|RESETS_STANDARD)
		c:RegisterEffect(e2)
	end
	if atk>0 then
		local e3=Effect.CreateEffect(c)
		e3:SetType(EFFECT_TYPE_SINGLE)
		e3:SetCode(EFFECT_UPDATE_ATTACK)
		e3:SetValue(atk)
		e3:SetReset(RESET_EVENT|RESETS_STANDARD)
		c:RegisterEffect(e3)
	end
end

-- ============================================================
-- Effect 2 Callbacks
-- ============================================================
function s.tgval2(e,te)
	return te:IsActiveType(TYPE_MONSTER)
		and (te:GetHandler():GetAttribute() & e:GetHandler():GetAttribute() ~= 0)
end

-- ============================================================
-- Effect 3 Callbacks
-- ============================================================
function s.cfilter3(c)
	return c:IsAbleToDeckOrExtraAsCost()
end
function s.spfilter3(c,e,tp,hc)
	return c:IsSetCard(SET_GENERICUS_MONSTRUM) and not c:IsType(TYPE_LINK) and c:IsMonster()
		and c:IsCanBeSpecialSummoned(e,0,tp,true,false)
		and ((c:IsLocation(LOCATION_DECK) and Duel.GetMZoneCount(tp,hc)>0)
			or (c:IsLocation(LOCATION_EXTRA) and Duel.GetLocationCountFromEx(tp,tp,hc,c)>0))
end
function s.cost3(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsAbleToExtraAsCost()
		and Duel.IsExistingMatchingCard(s.cfilter3,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,c) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	local g=Duel.SelectMatchingCard(tp,s.cfilter3,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,1,c)
	g:AddCard(c)
	Duel.SendtoDeck(g,nil,SEQ_DECKSHUFFLE,REASON_COST)
end
function s.tg3(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return Duel.IsExistingMatchingCard(s.spfilter3,tp,LOCATION_DECK|LOCATION_EXTRA,0,1,nil,e,tp,c) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK|LOCATION_EXTRA)
end
function s.spfilter3_op(c,e,tp)
	return c:IsSetCard(SET_GENERICUS_MONSTRUM) and not c:IsType(TYPE_LINK) and c:IsMonster()
		and c:IsCanBeSpecialSummoned(e,0,tp,true,false)
		and ((c:IsLocation(LOCATION_DECK) and Duel.GetLocationCount(tp,LOCATION_MZONE)>0)
			or (c:IsLocation(LOCATION_EXTRA) and Duel.GetLocationCountFromEx(tp,tp,nil,c)>0))
end
function s.op3(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spfilter3_op,tp,LOCATION_DECK|LOCATION_EXTRA,0,1,1,nil,e,tp)
	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,true,false,POS_FACEUP)
	end
end

-- ============================================================
-- Effect 4 Callbacks
-- ============================================================
function s.spcon4(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsPreviousLocation(LOCATION_ONFIELD) and c:IsPreviousControler(tp)
		and c:GetReasonPlayer()==1-tp and c:IsReason(REASON_EFFECT)
end
function s.spfilter4(c,e,tp)
	return c:IsSetCard(SET_GENERICUS_MONSTRUM) and not c:IsType(TYPE_LINK) and c:IsMonster()
		and c:IsCanBeSpecialSummoned(e,0,tp,true,false)
		and ((c:IsLocation(LOCATION_DECK) and Duel.GetLocationCount(tp,LOCATION_MZONE)>0)
			or (c:IsLocation(LOCATION_EXTRA) and Duel.GetLocationCountFromEx(tp,tp,nil,c)>0))
end
function s.sptg4(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsAbleToExtra()
		and Duel.IsExistingMatchingCard(s.spfilter4,tp,LOCATION_DECK|LOCATION_EXTRA,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_TOEXTRA,c,1,tp,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK|LOCATION_EXTRA)
end
function s.spop4(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) and Duel.SendtoDeck(c,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)>0
		and c:IsLocation(LOCATION_EXTRA) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local g=Duel.SelectMatchingCard(tp,s.spfilter4,tp,LOCATION_DECK|LOCATION_EXTRA,0,1,1,nil,e,tp)
		if #g>0 then
			Duel.SpecialSummon(g,0,tp,tp,true,false,POS_FACEUP)
		end
	end
end
