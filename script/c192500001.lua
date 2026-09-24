-- ============================================================
-- Card Name: Genericus Monstrum the Fusion
-- Passcode : 192500001
-- Type     : Monster / Fusion / Effect
-- Attribute: LIGHT
-- Level    : 10
-- ATK/DEF  : ? / ?
-- Race     : Dragon
-- Archetype: Genericus Monstrum (0x785)
-- ============================================================
-- Materials: 2 monsters
-- Must first be either Fusion Summoned, or Special Summoned (from your
-- Extra Deck) by Tributing 2 monsters from either field (at least 1 from
-- your field). If this card is Special Summoned by the effect of a
-- "Genericus Monstrum" monster, its original ATK/DEF become 3000, also
-- its original Attribute(s) and Type(s) become the same as that monster's
-- (if it was Special Summoned by the effect of a "Genericus Monstrum"
-- Link Monster, this card's Attributes also become DIVINE, DARK, LIGHT,
-- WATER, FIRE, WIND, and EARTH). Cannot be destroyed by battle with a
-- monster with the same Attribute.
-- ① Gains the original Attributes, Types, ATK, and DEF of the materials
--    used for its Summon.
-- ② (Quick Effect): You can shuffle 1 card from your hand or field into the
--    Deck, then target 1 card your opponent controls or 1 card in their GY;
--    destroy it (if it was on the field) or banish it (if it was in the GY).
-- ③ You can shuffle 2 cards from your hand and/or field into the Deck;
--    banish 1 random card from your opponent's hand or Extra Deck. If this
--    card was Special Summoned by the effect of a "Genericus Monstrum" Link
--    Monster, this effect becomes a Quick Effect, and you only shuffle 1
--    card instead.
-- ④ If this card in its owner's possession leaves the field because of an
--    opponent's card effect: Return this card to the Extra Deck, and if you
--    do, Special Summon 1 non-Fusion "Genericus Monstrum" monster from your
--    Deck or Extra Deck, ignoring its Summoning conditions.
-- You can only use each effect of "Genericus Monstrum the Fusion" once per turn.
-- ============================================================

local s,id=GetID()
Duel.LoadScript("constants.lua")

function s.initial_effect(c)
	c:EnableReviveLimit()

	-- ============================================================
	-- Summon Procedures & Constraints
	-- ============================================================
	-- Fusion Material: 2 monsters
	Fusion.AddProcMixRep(c,true,true,aux.TRUE,2,2)

	-- Alternative Special Summon: Tribute 2 monsters from either field (at least 1 from your field)
	local e0=Effect.CreateEffect(c)
	e0:SetDescription(aux.Stringid(id,0))
	e0:SetType(EFFECT_TYPE_FIELD)
	e0:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_SPSUMMON_PROC)
	e0:SetRange(LOCATION_EXTRA)
	e0:SetCondition(s.spcon_alt)
	e0:SetTarget(s.sptg_alt)
	e0:SetOperation(s.spop_alt)
	c:RegisterEffect(e0)

	-- Must first be Fusion Summoned or Special Summoned by its own procedure
	local e00=Effect.CreateEffect(c)
	e00:SetType(EFFECT_TYPE_SINGLE)
	e00:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e00:SetCode(EFFECT_SPSUMMON_CONDITION)
	e00:SetValue(s.splimit)
	c:RegisterEffect(e00)

	-- ============================================================
	-- Continuous & Inherent Effects
	-- ============================================================
	-- Special Summoned by "Genericus Monstrum" monster effect
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetOperation(s.gen_spop)
	c:RegisterEffect(e1)

	-- Cannot be destroyed by battle with a monster with the same Attribute
	local e_indes=Effect.CreateEffect(c)
	e_indes:SetType(EFFECT_TYPE_SINGLE)
	e_indes:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
	e_indes:SetValue(s.batval)
	c:RegisterEffect(e_indes)

	-- ============================================================
	-- Effect 1: Material Stat/Attribute/Race Gain
	-- ============================================================
	local e_mat=Effect.CreateEffect(c)
	e_mat:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e_mat:SetCode(EVENT_SPSUMMON_SUCCESS)
	e_mat:SetOperation(s.matop)
	c:RegisterEffect(e_mat)

	-- ============================================================
	-- Effect 2: Quick Effect - Shuffle 1 card to Destroy or Banish
	-- ============================================================
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_DESTROY+CATEGORY_REMOVE+CATEGORY_TODECK)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetRange(LOCATION_MZONE)
	e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E|TIMING_MAIN_END)
	e2:SetCountLimit(1,id)
	e2:SetCost(s.cost2)
	e2:SetTarget(s.tg2)
	e2:SetOperation(s.op2)
	c:RegisterEffect(e2)

	-- ============================================================
	-- Effect 3: Shuffle to Banish Hand or Extra Deck
	-- ============================================================
	-- Standard (Ignition): Shuffle 2 cards
	local e3a=Effect.CreateEffect(c)
	e3a:SetDescription(aux.Stringid(id,2))
	e3a:SetCategory(CATEGORY_REMOVE+CATEGORY_TODECK)
	e3a:SetType(EFFECT_TYPE_IGNITION)
	e3a:SetRange(LOCATION_MZONE)
	e3a:SetCountLimit(1,{id,1})
	e3a:SetCondition(aux.NOT(s.linkcon))
	e3a:SetCost(s.cost3a)
	e3a:SetTarget(s.tg3)
	e3a:SetOperation(s.op3)
	c:RegisterEffect(e3a)

	-- Enhanced (Quick Effect if summoned by Genericus Link): Shuffle 1 card
	local e3b=Effect.CreateEffect(c)
	e3b:SetDescription(aux.Stringid(id,2))
	e3b:SetCategory(CATEGORY_REMOVE+CATEGORY_TODECK)
	e3b:SetType(EFFECT_TYPE_QUICK_O)
	e3b:SetCode(EVENT_FREE_CHAIN)
	e3b:SetRange(LOCATION_MZONE)
	e3b:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E|TIMING_MAIN_END)
	e3b:SetCountLimit(1,{id,1})
	e3b:SetCondition(s.linkcon)
	e3b:SetCost(s.cost3b)
	e3b:SetTarget(s.tg3)
	e3b:SetOperation(s.op3)
	c:RegisterEffect(e3b)

	-- ============================================================
	-- Effect 4: Leaves Field Floating Effect
	-- ============================================================
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,4))
	e4:SetCategory(CATEGORY_TOEXTRA+CATEGORY_SPECIAL_SUMMON)
	e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e4:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_DAMAGE_STEP)
	e4:SetCode(EVENT_LEAVE_FIELD)
	e4:SetCountLimit(1,{id,2})
	e4:SetCondition(s.spcon4)
	e4:SetTarget(s.sptg4)
	e4:SetOperation(s.spop4)
	c:RegisterEffect(e4)
end
s.listed_series={SET_GENERICUS_MONSTRUM}

-- ============================================================
-- Summon Procedures & Constraints
-- ============================================================
function s.splimit(e,se,sp,st)
	if e:GetHandler():GetLocation()~=LOCATION_EXTRA then return true end
	return (st&SUMMON_TYPE_FUSION)==SUMMON_TYPE_FUSION or (se and se:GetHandler():IsSetCard(SET_GENERICUS_MONSTRUM))
end

function s.spfilter_alt(c,tp)
	return c:IsMonster() and c:IsReleasable() and (c:IsControler(tp) or c:IsFaceup())
end
function s.rescon_alt(sg,e,tp,mg)
	return sg:IsExists(Card.IsControler,1,nil,tp) and Duel.GetLocationCountFromEx(tp,tp,sg,e:GetHandler())>0
end
function s.spcon_alt(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	local mg=Duel.GetMatchingGroup(s.spfilter_alt,tp,LOCATION_MZONE,LOCATION_MZONE,nil,tp)
	return aux.SelectUnselectGroup(mg,e,tp,2,2,s.rescon_alt,0)
end
function s.sptg_alt(e,tp,eg,ep,ev,re,r,rp,c)
	local mg=Duel.GetMatchingGroup(s.spfilter_alt,tp,LOCATION_MZONE,LOCATION_MZONE,nil,tp)
	local sg=aux.SelectUnselectGroup(mg,e,tp,2,2,s.rescon_alt,1,tp,HINTMSG_RELEASE,nil,nil,true)
	if #sg==2 then
		sg:KeepAlive()
		e:SetLabelObject(sg)
		return true
	end
	return false
end
function s.spop_alt(e,tp,eg,ep,ev,re,r,rp,c)
	local g=e:GetLabelObject()
	if not g then return end
	Duel.Release(g,REASON_COST|REASON_MATERIAL)
	c:SetMaterial(g)
	g:DeleteGroup()
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
	local att=rc:GetOriginalAttribute()
	local race=rc:GetOriginalRace()
	if att~=0 then
		local e3=Effect.CreateEffect(c)
		e3:SetType(EFFECT_TYPE_SINGLE)
		e3:SetCode(EFFECT_CHANGE_ATTRIBUTE)
		e3:SetValue(att)
		e3:SetReset(RESET_EVENT|RESETS_STANDARD)
		c:RegisterEffect(e3)
	end
	if race~=0 then
		local e4=Effect.CreateEffect(c)
		e4:SetType(EFFECT_TYPE_SINGLE)
		e4:SetCode(EFFECT_CHANGE_RACE)
		e4:SetValue(race)
		e4:SetReset(RESET_EVENT|RESETS_STANDARD)
		c:RegisterEffect(e4)
	end
	if rc:IsType(TYPE_LINK) then
		local e5=Effect.CreateEffect(c)
		e5:SetType(EFFECT_TYPE_SINGLE)
		e5:SetCode(EFFECT_ADD_ATTRIBUTE)
		e5:SetValue(ATTRIBUTE_ALL)
		e5:SetReset(RESET_EVENT|RESETS_STANDARD)
		c:RegisterEffect(e5)
	end
end

-- ============================================================
-- Battle Protection
-- ============================================================
function s.batval(e,c)
	return (c:GetAttribute() & e:GetHandler():GetAttribute()) ~= 0
end

-- ============================================================
-- Material Gain Callback
-- ============================================================
function s.matop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
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
	return c:IsAbleToDeckAsCost()
end
function s.cost2(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.cfilter2,tp,LOCATION_HAND|LOCATION_ONFIELD,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	local g=Duel.SelectMatchingCard(tp,s.cfilter2,tp,LOCATION_HAND|LOCATION_ONFIELD,0,1,1,nil)
	Duel.SendtoDeck(g,nil,SEQ_DECKSHUFFLE,REASON_COST)
end
function s.tgfilter2(c)
	if c:IsLocation(LOCATION_ONFIELD) then
		return c:IsDestructable()
	else
		return c:IsAbleToRemove()
	end
end
function s.tg2(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsControler(1-tp) and (chkc:IsLocation(LOCATION_ONFIELD) or chkc:IsLocation(LOCATION_GRAVE))
			and s.tgfilter2(chkc)
	end
	if chk==0 then return Duel.IsExistingTarget(s.tgfilter2,tp,0,LOCATION_ONFIELD|LOCATION_GRAVE,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	local g=Duel.SelectTarget(tp,s.tgfilter2,tp,0,LOCATION_ONFIELD|LOCATION_GRAVE,1,1,nil)
	local tc=g:GetFirst()
	if tc:IsLocation(LOCATION_ONFIELD) then
		Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
	else
		Duel.SetOperationInfo(0,CATEGORY_REMOVE,g,1,0,0)
	end
end
function s.op2(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if not tc or not tc:IsRelateToEffect(e) then return end
	if tc:IsLocation(LOCATION_ONFIELD) then
		Duel.Destroy(tc,REASON_EFFECT)
	elseif tc:IsLocation(LOCATION_GRAVE) then
		Duel.Remove(tc,POS_FACEUP,REASON_EFFECT)
	end
end

-- ============================================================
-- Effect 3 Callbacks
-- ============================================================
function s.linkcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():HasFlagEffect(id)
end
function s.cost3a(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(Card.IsAbleToDeckAsCost,tp,LOCATION_HAND|LOCATION_ONFIELD,0,2,nil)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	local g=Duel.SelectMatchingCard(tp,Card.IsAbleToDeckAsCost,tp,LOCATION_HAND|LOCATION_ONFIELD,0,2,2,nil)
	Duel.SendtoDeck(g,nil,SEQ_DECKSHUFFLE,REASON_COST)
end
function s.cost3b(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(Card.IsAbleToDeckAsCost,tp,LOCATION_HAND|LOCATION_ONFIELD,0,1,nil)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	local g=Duel.SelectMatchingCard(tp,Card.IsAbleToDeckAsCost,tp,LOCATION_HAND|LOCATION_ONFIELD,0,1,1,nil)
	Duel.SendtoDeck(g,nil,SEQ_DECKSHUFFLE,REASON_COST)
end
function s.tg3(e,tp,eg,ep,ev,re,r,rp,chk)
	local hcount=Duel.GetFieldGroupCount(1-tp,LOCATION_HAND,0)
	local ecount=Duel.GetFieldGroupCount(1-tp,LOCATION_EXTRA,0)
	if chk==0 then return (hcount>0 and Duel.IsExistingMatchingCard(Card.IsAbleToRemove,tp,0,LOCATION_HAND,1,nil))
		or (ecount>0 and Duel.IsExistingMatchingCard(Card.IsAbleToRemove,tp,0,LOCATION_EXTRA,1,nil)) end
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,1,1-tp,LOCATION_HAND|LOCATION_EXTRA)
end
function s.op3(e,tp,eg,ep,ev,re,r,rp)
	local hg=Duel.GetMatchingGroup(Card.IsAbleToRemove,tp,0,LOCATION_HAND,nil)
	local eg=Duel.GetMatchingGroup(Card.IsAbleToRemove,tp,0,LOCATION_EXTRA,nil)
	if #hg==0 and #eg==0 then return end
	local opt=0
	if #hg>0 and #eg>0 then
		opt=Duel.SelectOption(tp,aux.Stringid(id,2),aux.Stringid(id,3))
	elseif #hg>0 then
		opt=0
	else
		opt=1
	end
	if opt==0 then
		local sg=hg:RandomSelect(tp,1)
		Duel.Remove(sg,POS_FACEUP,REASON_EFFECT)
	else
		local sg=eg:RandomSelect(tp,1)
		Duel.Remove(sg,POS_FACEUP,REASON_EFFECT)
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
	return c:IsSetCard(SET_GENERICUS_MONSTRUM) and not c:IsType(TYPE_FUSION) and c:IsMonster()
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
