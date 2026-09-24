-- ============================================================
-- Card Name: Genericus Monstrum the Ritual
-- Passcode : 192500004
-- Type     : Monster / Ritual / Effect
-- Attribute: LIGHT
-- Level    : 10
-- ATK/DEF  : ? / ?
-- Race     : Fiend
-- Archetype: Genericus Monstrum (0x785)
-- ============================================================
-- You can Ritual Summon this card with any Ritual Spell, ignoring its
-- Summoning conditions. Must first be Ritual Summoned, or Special
-- Summoned by a "Genericus Monstrum" card effect. If this card is Special
-- Summoned by the effect of a "Genericus Monstrum" monster, its original
-- ATK / DEF become 3000 (if it was Special Summoned by the effect of a
-- "Genericus Monstrum" Link Monster, this card's Attributes also become
-- DIVINE, DARK, LIGHT, WATER, FIRE, WIND, and EARTH). This card can be
-- treated as any Type required for a Ritual Summon.
-- ① This card gains the original Attribute(s), Type(s), ATK, and DEF of
--    the monsters Tributed for its Ritual Summon.
-- ② You can banish 1 Ritual Monster face-down from your hand or GY; add
--    this card from your Deck to your hand.
-- ③ If a monster(s) leaves the Extra Deck (except during the Damage Step):
--    You can negate the effects of all other face-up monsters currently on
--    the field until the end of this turn.
-- ④ (Quick Effect): You can Tribute 1 monster you control; Tribute 1 monster
--    your opponent controls (if this card was Special Summoned by the
--    effect of a "Genericus Monstrum" Link Monster, you can Tribute up to
--    2 monsters your opponent controls instead).
-- ⑤ If this card is Tributed: You can add 1 Ritual Monster or 1 Ritual Spell
--    from your Deck to your hand, then Special Summon this card (from where
--    it is), ignoring its Summoning conditions.
-- ⑥ If this face-up card in its owner's possession leaves the field because
--    of an opponent's card effect: Return this card to the Deck, and if you
--    do, Special Summon 1 non-Ritual "Genericus Monstrum" monster from your
--    Deck or Extra Deck, ignoring its Summoning conditions.
-- You can only use each effect of "Genericus Monstrum the Ritual" once per turn.
-- ============================================================

local s,id=GetID()
Duel.LoadScript("constants.lua")

function s.initial_effect(c)
	c:EnableReviveLimit()

	-- ============================================================
	-- Summon Procedures & Constraints
	-- ============================================================
	-- Must first be Ritual Summoned or Special Summoned by a "Genericus Monstrum" card effect
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_SPSUMMON_CONDITION)
	e0:SetValue(s.splimit)
	c:RegisterEffect(e0)

	-- Treated as any Type required for a Ritual Summon
	local e_race=Effect.CreateEffect(c)
	e_race:SetType(EFFECT_TYPE_SINGLE)
	e_race:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e_race:SetCode(EFFECT_ADD_RACE)
	e_race:SetRange(LOCATION_HAND|LOCATION_MZONE|LOCATION_GRAVE)
	e_race:SetValue(RACE_ALL)
	c:RegisterEffect(e_race)

	-- ============================================================
	-- Continuous & Inherent Effects
	-- ============================================================
	-- Special Summoned by "Genericus Monstrum" monster effect
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetOperation(s.gen_spop)
	c:RegisterEffect(e1)

	-- Effect 1: Gain original Attributes, Types, ATK, and DEF of tributed monsters
	local e_mat=Effect.CreateEffect(c)
	e_mat:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e_mat:SetCode(EVENT_SPSUMMON_SUCCESS)
	e_mat:SetOperation(s.matop)
	c:RegisterEffect(e_mat)

	-- ============================================================
	-- Activated Effects
	-- ============================================================
	-- Effect 2: Banish 1 Ritual Monster face-down from hand/GY; add this card from Deck to hand
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_DECK)
	e2:SetCountLimit(1,id)
	e2:SetCost(s.cost2)
	e2:SetTarget(s.tg2)
	e2:SetOperation(s.op2)
	c:RegisterEffect(e2)

	-- Effect 3: Monster leaves Extra Deck -> negate effects of all other face-up monsters
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_DISABLE)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_MOVE)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,{id,1})
	e3:SetCondition(s.discon)
	e3:SetTarget(s.distg)
	e3:SetOperation(s.disop)
	c:RegisterEffect(e3)

	-- Effect 4: (Quick Effect) Tribute 1 monster you control; Tribute 1 (or up to 2) monster(s) opponent controls
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,2))
	e4:SetCategory(CATEGORY_RELEASE)
	e4:SetType(EFFECT_TYPE_QUICK_O)
	e4:SetCode(EVENT_FREE_CHAIN)
	e4:SetRange(LOCATION_MZONE)
	e4:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E|TIMING_MAIN_END)
	e4:SetCountLimit(1,{id,2})
	e4:SetCost(s.cost4)
	e4:SetTarget(s.tg4)
	e4:SetOperation(s.op4)
	c:RegisterEffect(e4)

	-- Effect 5: If Tributed -> add 1 Ritual Monster or Spell from Deck to hand, then Special Summon this card
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,3))
	e5:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_SPECIAL_SUMMON)
	e5:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e5:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_DAMAGE_STEP)
	e5:SetCode(EVENT_RELEASE)
	e5:SetCountLimit(1,{id,3})
	e5:SetTarget(s.sptg5)
	e5:SetOperation(s.spop5)
	c:RegisterEffect(e5)

	-- Effect 6: Face-up leaves field by opponent's card effect -> return to Deck, Special Summon 1 non-Ritual
	local e6=Effect.CreateEffect(c)
	e6:SetDescription(aux.Stringid(id,4))
	e6:SetCategory(CATEGORY_TODECK+CATEGORY_SPECIAL_SUMMON)
	e6:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e6:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_DAMAGE_STEP)
	e6:SetCode(EVENT_LEAVE_FIELD)
	e6:SetCountLimit(1,{id,4})
	e6:SetCondition(s.spcon6)
	e6:SetTarget(s.sptg6)
	e6:SetOperation(s.spop6)
	c:RegisterEffect(e6)
end
s.listed_series={SET_GENERICUS_MONSTRUM}

-- ============================================================
-- Summon Procedures & Constraints
-- ============================================================
function s.splimit(e,se,sp,st)
	return (st&SUMMON_TYPE_RITUAL)==SUMMON_TYPE_RITUAL or (se and se:GetHandler():IsSetCard(SET_GENERICUS_MONSTRUM))
end

-- ============================================================
-- Genericus Special Summon Enhancements
-- ============================================================
function s.gen_spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not re then return end
	local rc=re:GetHandler()
	if not (rc and rc:IsSetCard(SET_GENERICUS_MONSTRUM) and rc:IsMonster()) then return end
	if rc:IsType(TYPE_LINK) then
		c:RegisterFlagEffect(id,RESET_EVENT|RESETS_STANDARD,0,1)
	end
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_SET_BASE_ATTACK)
	e1:SetValue(3000)
	e1:SetReset(RESET_EVENT|RESETS_STANDARD)
	c:RegisterEffect(e1)
	local e2=e1:Clone()
	e2:SetCode(EFFECT_SET_BASE_DEFENSE)
	c:RegisterEffect(e2)
	if rc:IsType(TYPE_LINK) then
		local e3=Effect.CreateEffect(c)
		e3:SetType(EFFECT_TYPE_SINGLE)
		e3:SetCode(EFFECT_ADD_ATTRIBUTE)
		e3:SetValue(ATTRIBUTE_ALL)
		e3:SetReset(RESET_EVENT|RESETS_STANDARD)
		c:RegisterEffect(e3)
	end
end

-- ============================================================
-- Material Gain Callback
-- ============================================================
function s.matop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRitualSummoned() then return end
	local mg=c:GetMaterial()
	if not mg or #mg==0 then return end
	local att=0
	local race=0
	local atk=0
	local def=0
	for tc in mg:Iter() do
		att=att|tc:GetOriginalAttribute()
		race=race|tc:GetOriginalRace()
		local tatk=tc:GetTextAttack()
		local tdef=tc:GetTextDefense()
		if tatk>0 then atk=atk+tatk end
		if tdef>0 then def=def+tdef end
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
	if def>0 then
		local e4=Effect.CreateEffect(c)
		e4:SetType(EFFECT_TYPE_SINGLE)
		e4:SetCode(EFFECT_UPDATE_DEFENSE)
		e4:SetValue(def)
		e4:SetReset(RESET_EVENT|RESETS_STANDARD)
		c:RegisterEffect(e4)
	end
end

-- ============================================================
-- Effect 2 Callbacks
-- ============================================================
function s.cfilter2(c)
	return c:IsType(TYPE_RITUAL) and c:IsMonster() and c:IsAbleToRemoveAsCost(POS_FACEDOWN)
end
function s.cost2(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.cfilter2,tp,LOCATION_HAND|LOCATION_GRAVE,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectMatchingCard(tp,s.cfilter2,tp,LOCATION_HAND|LOCATION_GRAVE,0,1,1,nil)
	Duel.Remove(g,POS_FACEDOWN,REASON_COST)
end
function s.tg2(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsAbleToHand() end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,c,1,tp,0)
end
function s.op2(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SendtoHand(c,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,c)
	end
end

-- ============================================================
-- Effect 3 Callbacks
-- ============================================================
function s.disfilter(c)
	return c:IsPreviousLocation(LOCATION_EXTRA) and c:IsMonster()
end
function s.discon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.disfilter,1,nil) and not eg:IsContains(e:GetHandler())
end
function s.distg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return Duel.IsExistingMatchingCard(function(tc) return tc:IsFaceup() and tc~=c end,
		tp,LOCATION_MZONE,LOCATION_MZONE,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_DISABLE,nil,1,0,LOCATION_MZONE)
end
function s.disop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local g=Duel.GetMatchingGroup(function(tc) return tc:IsFaceup() and tc~=c end,tp,LOCATION_MZONE,LOCATION_MZONE,nil)
	for tc in g:Iter() do
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_DISABLE)
		e1:SetReset(RESET_EVENT|RESETS_STANDARD|RESET_PHASE|PHASE_END)
		tc:RegisterEffect(e1)
		local e2=Effect.CreateEffect(c)
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetCode(EFFECT_DISABLE_EFFECT)
		e2:SetReset(RESET_EVENT|RESETS_STANDARD|RESET_PHASE|PHASE_END)
		tc:RegisterEffect(e2)
	end
end

-- ============================================================
-- Effect 4 Callbacks
-- ============================================================
function s.cost4(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckReleaseGroupCost(tp,nil,1,false,nil,nil) end
	local g=Duel.SelectReleaseGroupCost(tp,nil,1,1,false,nil,nil)
	Duel.Release(g,REASON_COST)
end
function s.tg4(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	local max_cnt=c:HasFlagEffect(id) and 2 or 1
	if chk==0 then return Duel.IsExistingMatchingCard(Card.IsReleasableByEffect,tp,0,LOCATION_MZONE,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_RELEASE,nil,1,1-tp,LOCATION_MZONE)
end
function s.op4(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local max_cnt=c:HasFlagEffect(id) and 2 or 1
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
	local g=Duel.SelectMatchingCard(tp,Card.IsReleasableByEffect,tp,0,LOCATION_MZONE,1,max_cnt,nil)
	if #g>0 then
		Duel.Release(g,REASON_EFFECT)
	end
end

-- ============================================================
-- Effect 5 Callbacks
-- ============================================================
function s.thfilter5(c)
	return ((c:IsType(TYPE_RITUAL) and c:IsMonster()) or c:IsRitualSpell()) and c:IsAbleToHand()
end
function s.sptg5(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter5,tp,LOCATION_DECK,0,1,nil)
		and c:IsCanBeSpecialSummoned(e,0,tp,true,false)
		and Duel.GetLocationCount(tp,LOCATION_MZONE)>0 end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,tp,0)
end
function s.spop5(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter5,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 and Duel.SendtoHand(g,nil,REASON_EFFECT)>0 and g:GetFirst():IsLocation(LOCATION_HAND) then
		Duel.ConfirmCards(1-tp,g)
		if c:IsRelateToEffect(e) and Duel.GetLocationCount(tp,LOCATION_MZONE)>0 then
			Duel.SpecialSummon(c,0,tp,tp,true,false,POS_FACEUP)
		end
	end
end

-- ============================================================
-- Effect 6 Callbacks
-- ============================================================
function s.spcon6(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsPreviousPosition(POS_FACEUP) and c:IsPreviousLocation(LOCATION_ONFIELD)
		and c:IsPreviousControler(tp) and c:GetReasonPlayer()==1-tp and c:IsReason(REASON_EFFECT)
end
function s.spfilter6(c,e,tp)
	return c:IsSetCard(SET_GENERICUS_MONSTRUM) and not c:IsType(TYPE_RITUAL) and c:IsMonster()
		and c:IsCanBeSpecialSummoned(e,0,tp,true,false)
		and ((c:IsLocation(LOCATION_DECK) and Duel.GetLocationCount(tp,LOCATION_MZONE)>0)
			or (c:IsLocation(LOCATION_EXTRA) and Duel.GetLocationCountFromEx(tp,tp,nil,c)>0))
end
function s.sptg6(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsAbleToDeck()
		and Duel.IsExistingMatchingCard(s.spfilter6,tp,LOCATION_DECK|LOCATION_EXTRA,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_TODECK,c,1,tp,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK|LOCATION_EXTRA)
end
function s.spop6(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) and Duel.SendtoDeck(c,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)>0
		and c:IsLocation(LOCATION_DECK) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local g=Duel.SelectMatchingCard(tp,s.spfilter6,tp,LOCATION_DECK|LOCATION_EXTRA,0,1,1,nil,e,tp)
		if #g>0 then
			Duel.SpecialSummon(g,0,tp,tp,true,false,POS_FACEUP)
		end
	end
end
