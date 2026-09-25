-- ============================================================
-- Card Name: Genericus Monstrum the Xyz
-- Passcode : 192500006
-- Type     : Monster / Xyz / Effect
-- Attribute: DARK
-- Rank     : 10
-- ATK/DEF  : ? / ?
-- Race     : Machine
-- Archetype: Genericus Monstrum (0x785)
-- ============================================================
-- Materials: 2 Xyz monsters with the same rank
-- Must first be either Xyz Summoned, or Special Summoned during a turn
-- your opponent activated 2 or more monster effects, by using 1 Xyz
-- Monster you control as material. (Transfer its materials to this card.)
-- If this card is Special Summoned by the effect of a "Genericus
-- Monstrum" monster: Its original ATK/DEF become 3000 (if it was Special
-- Summoned by the effect of a "Genericus Monstrum" Link Monster, you can
-- look at your opponent's Deck and attach 10 cards from it to this card
-- as material).
-- ① This card gains the original Attributes, Types, ATK, and DEF of its
--    materials.
-- ② If a monster(s) you control leaves the field: You can attach 1 of
--    those monsters to this card as material.
-- ③ (Quick Effect): You can detach 1 material from this card, then target
--    1 card on the field; attach it to this card as material.
-- ④ (Quick Effect): You can detach 5 materials from this card; shuffle all
--    cards on the field, in the GYs, and that are banished into the Decks.
-- ⑤ While this card has 10 or more materials, negate the effects of all
--    monsters on the field with ATK lower than this card's current ATK,
--    also this card is unaffected by monster effects activated by an
--    opponent's monster with the same Attribute as this card.
-- ⑥ If this card in its owner's possession leaves the field because of an
--    opponent's card effect: Return this card to the Extra Deck, and if you
--    do, Special Summon 1 non-Xyz "Genericus Monstrum" monster from your
--    Deck or Extra Deck, ignoring its Summoning conditions.
-- You can only use each effect of "Genericus Monstrum the Xyz" once per turn.
-- ============================================================

local s,id=GetID()
Duel.LoadScript("constants.lua")

function s.initial_effect(c)
	c:EnableReviveLimit()

	-- ============================================================
	-- Summon Procedures & Constraints
	-- ============================================================
	-- Xyz Summon Procedure: 2 Xyz monsters with the same rank
	-- Alternative Summon: 1 Xyz Monster you control if opponent activated 2+ monster effects
	Xyz.AddProcedure(c,s.xyzfilter,nil,2,s.altfilter,aux.Stringid(id,0),2,s.altop,false,s.xyzcheck)

	-- ============================================================
	-- Continuous & Inherent Effects
	-- ============================================================
	-- Special Summoned by "Genericus Monstrum" monster effect
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,1))
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCondition(s.gen_spcon)
	e1:SetOperation(s.gen_spop)
	c:RegisterEffect(e1)

	-- Effect 1: Gain original Attributes, Types, ATK, and DEF of materials
	local e_atk=Effect.CreateEffect(c)
	e_atk:SetType(EFFECT_TYPE_SINGLE)
	e_atk:SetCode(EFFECT_UPDATE_ATTACK)
	e_atk:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e_atk:SetRange(LOCATION_MZONE)
	e_atk:SetValue(s.atkval)
	c:RegisterEffect(e_atk)
	local e_def=e_atk:Clone()
	e_def:SetCode(EFFECT_UPDATE_DEFENSE)
	e_def:SetValue(s.defval)
	c:RegisterEffect(e_def)
	local e_att=Effect.CreateEffect(c)
	e_att:SetType(EFFECT_TYPE_SINGLE)
	e_att:SetCode(EFFECT_ADD_ATTRIBUTE)
	e_att:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e_att:SetRange(LOCATION_MZONE)
	e_att:SetValue(s.attval)
	c:RegisterEffect(e_att)
	local e_race=Effect.CreateEffect(c)
	e_race:SetType(EFFECT_TYPE_SINGLE)
	e_race:SetCode(EFFECT_ADD_RACE)
	e_race:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e_race:SetRange(LOCATION_MZONE)
	e_race:SetValue(s.raceval)
	c:RegisterEffect(e_race)

	-- Effect 5: While 10+ materials -> negate effects of monsters with lower ATK
	local e5a=Effect.CreateEffect(c)
	e5a:SetType(EFFECT_TYPE_FIELD)
	e5a:SetCode(EFFECT_DISABLE)
	e5a:SetRange(LOCATION_MZONE)
	e5a:SetTargetRange(LOCATION_MZONE,LOCATION_MZONE)
	e5a:SetCondition(s.con5)
	e5a:SetTarget(s.disfilter5)
	c:RegisterEffect(e5a)

	-- Effect 5: While 10+ materials -> unaffected by monster effects with same Attribute
	local e5b=Effect.CreateEffect(c)
	e5b:SetType(EFFECT_TYPE_SINGLE)
	e5b:SetCode(EFFECT_IMMUNE_EFFECT)
	e5b:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e5b:SetRange(LOCATION_MZONE)
	e5b:SetCondition(s.con5)
	e5b:SetValue(s.efilter5)
	c:RegisterEffect(e5b)

	-- ============================================================
	-- Activated Effects
	-- ============================================================
	-- Effect 2: Monster leaves field -> attach 1 to this card
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,2))
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_LEAVE_FIELD)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,id)
	e2:SetCondition(s.attcon2)
	e2:SetTarget(s.atttg2)
	e2:SetOperation(s.attop2)
	c:RegisterEffect(e2)

	-- Effect 3: (Quick Effect) Detach 1 material -> target 1 card on field; attach to this card
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,3))
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e3:SetRange(LOCATION_MZONE)
	e3:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E|TIMING_MAIN_END)
	e3:SetCountLimit(1,{id,1})
	e3:SetCost(s.cost3)
	e3:SetTarget(s.tg3)
	e3:SetOperation(s.op3)
	c:RegisterEffect(e3)

	-- Effect 4: (Quick Effect) Detach 5 materials -> shuffle all cards into Decks
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,4))
	e4:SetCategory(CATEGORY_TODECK)
	e4:SetType(EFFECT_TYPE_QUICK_O)
	e4:SetCode(EVENT_FREE_CHAIN)
	e4:SetRange(LOCATION_MZONE)
	e4:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E|TIMING_MAIN_END)
	e4:SetCountLimit(1,{id,2})
	e4:SetCost(s.cost4)
	e4:SetTarget(s.tg4)
	e4:SetOperation(s.op4)
	c:RegisterEffect(e4)

	-- Effect 6: Leaves field by opponent's card effect -> return to Extra Deck, Special Summon 1 non-Xyz
	local e6=Effect.CreateEffect(c)
	e6:SetDescription(aux.Stringid(id,5))
	e6:SetCategory(CATEGORY_TOEXTRA+CATEGORY_SPECIAL_SUMMON)
	e6:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e6:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_DAMAGE_STEP)
	e6:SetCode(EVENT_LEAVE_FIELD)
	e6:SetCountLimit(1,{id,3})
	e6:SetCondition(s.spcon6)
	e6:SetTarget(s.sptg6)
	e6:SetOperation(s.spop6)
	c:RegisterEffect(e6)

	-- Register global check for opponent's activated monster effects
	aux.GlobalCheck(s,function()
		local ge1=Effect.CreateEffect(c)
		ge1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		ge1:SetCode(EVENT_CHAINING)
		ge1:SetOperation(s.checkop)
		Duel.RegisterEffect(ge1,0)
	end)
end
s.listed_series={SET_GENERICUS_MONSTRUM}

-- ============================================================
-- Global Tracker: Opponent's monster effect activations
-- ============================================================
function s.checkop(e,tp,eg,ep,ev,re,r,rp)
	if re:IsMonsterEffect() then
		Duel.RegisterFlagEffect(rp,id,RESET_PHASE|PHASE_END,0,1)
	end
end

-- ============================================================
-- Xyz Procedure Filters
-- ============================================================
function s.xyzfilter(c,xyz,sumtype,tp)
	return c:IsType(TYPE_XYZ,xyz,sumtype,tp)
end
function s.xyzcheck(g,tp,xyz)
	local mg=g:Filter(function(c) return not c:IsHasEffect(EFFECT_EQUIP_SPELL_XYZ_MAT) end,nil)
	return mg:GetClassCount(Card.GetRank)==1
end
function s.altfilter(c,tp,xyzc)
	return c:IsFaceup() and c:IsType(TYPE_XYZ,xyzc,SUMMON_TYPE_XYZ,tp) and c:IsControler(tp)
end
function s.altop(e,tp,chk)
	if chk==0 then return Duel.GetFlagEffect(1-tp,id)>=2 end
	return true
end

-- ============================================================
-- Genericus Special Summon Enhancements
-- ============================================================
function s.gen_spcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local rc=re and re:GetHandler()
	return re and re:IsMonsterEffect()
		and rc and rc:IsSetCard(SET_GENERICUS_MONSTRUM) and rc~=c
		and not c:IsXyzSummoned()
end
function s.gen_spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	local rc=re:GetHandler()
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_SET_BASE_ATTACK)
	e1:SetValue(3000)
	e1:SetReset(RESET_EVENT|RESETS_STANDARD)
	c:RegisterEffect(e1)
	local e2=e1:Clone()
	e2:SetCode(EFFECT_SET_BASE_DEFENSE)
	c:RegisterEffect(e2)
	if rc:IsType(TYPE_LINK) and Duel.GetFieldGroupCount(tp,0,LOCATION_DECK)>=10
		and Duel.SelectYesNo(tp,aux.Stringid(id,6)) then
		local g=Duel.GetFieldGroup(tp,0,LOCATION_DECK)
		Duel.ConfirmCards(tp,g)
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_XMATERIAL)
		local sg=g:Select(tp,10,10,nil)
		Duel.Overlay(c,sg)
		Duel.ShuffleDeck(1-tp)
	end
end

-- ============================================================
-- Material Stat/Attribute/Race Gain
-- ============================================================
function s.atkval(e,c)
	local g=c:GetOverlayGroup()
	local val=0
	for tc in g:Iter() do
		local atk=tc:GetTextAttack()
		if atk>0 then val=val+atk end
	end
	return val
end
function s.defval(e,c)
	local g=c:GetOverlayGroup()
	local val=0
	for tc in g:Iter() do
		local def=tc:GetTextDefense()
		if def>0 then val=val+def end
	end
	return val
end
function s.attval(e,c)
	local g=c:GetOverlayGroup()
	local val=0
	for tc in g:Iter() do
		val=val|tc:GetOriginalAttribute()
	end
	return val
end
function s.raceval(e,c)
	local g=c:GetOverlayGroup()
	local val=0
	for tc in g:Iter() do
		val=val|tc:GetOriginalRace()
	end
	return val
end

-- ============================================================
-- Effect 2 Callbacks
-- ============================================================
function s.attfilter2(c,tp)
	return c:IsPreviousLocation(LOCATION_MZONE) and c:IsPreviousControler(tp) and c:IsMonster()
		and not c:IsType(TYPE_TOKEN) and (c:IsControler(tp) or c:IsAbleToChangeControler())
end
function s.attcon2(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.attfilter2,1,nil,tp)
end
function s.atttg2(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return eg:IsExists(s.attfilter2,1,nil,tp) end
end
function s.attop2(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	local g=eg:Filter(s.attfilter2,nil,tp)
	if #g==0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_XMATERIAL)
	local tc=g:Select(tp,1,1,nil):GetFirst()
	if tc then
		Duel.Overlay(c,tc,true)
	end
end

-- ============================================================
-- Effect 3 Callbacks
-- ============================================================
function s.cost3(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():CheckRemoveOverlayCard(tp,1,REASON_COST) end
	e:GetHandler():RemoveOverlayCard(tp,1,1,REASON_COST)
end
function s.tgfilter3(c,tp)
	return not c:IsType(TYPE_TOKEN) and (c:IsControler(tp) or c:IsAbleToChangeControler())
end
function s.tg3(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsOnField() and chkc~=e:GetHandler() and s.tgfilter3(chkc,tp) end
	if chk==0 then return Duel.IsExistingTarget(s.tgfilter3,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,e:GetHandler(),tp) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	Duel.SelectTarget(tp,s.tgfilter3,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,1,e:GetHandler(),tp)
end
function s.op3(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if c:IsRelateToEffect(e) and tc and tc:IsRelateToEffect(e) and not tc:IsImmuneToEffect(e) then
		Duel.Overlay(c,tc,true)
	end
end

-- ============================================================
-- Effect 4 Callbacks
-- ============================================================
function s.cost4(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():CheckRemoveOverlayCard(tp,5,REASON_COST) end
	e:GetHandler():RemoveOverlayCard(tp,5,5,REASON_COST)
end
function s.tg4(e,tp,eg,ep,ev,re,r,rp,chk)
	local loc=LOCATION_ONFIELD|LOCATION_GRAVE|LOCATION_REMOVED
	if chk==0 then return Duel.IsExistingMatchingCard(Card.IsAbleToDeck,tp,loc,loc,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TODECK,nil,1,0,loc)
end
function s.op4(e,tp,eg,ep,ev,re,r,rp)
	local loc=LOCATION_ONFIELD|LOCATION_GRAVE|LOCATION_REMOVED
	local g=Duel.GetMatchingGroup(Card.IsAbleToDeck,tp,loc,loc,nil)
	if #g>0 then
		Duel.SendtoDeck(g,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
	end
end

-- ============================================================
-- Effect 5 Callbacks
-- ============================================================
function s.con5(e)
	return e:GetHandler():GetOverlayCount()>=10
end
function s.disfilter5(e,c)
	return c:IsFaceup() and c:GetAttack()<e:GetHandler():GetAttack()
end
function s.efilter5(e,te)
	return te:IsActiveType(TYPE_MONSTER) and te:IsActivated() and te:GetOwnerPlayer()~=e:GetHandlerPlayer()
		and (te:GetHandler():GetAttribute() & e:GetHandler():GetAttribute() ~= 0)
end

-- ============================================================
-- Effect 6 Callbacks
-- ============================================================
function s.spcon6(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsPreviousLocation(LOCATION_ONFIELD) and c:IsPreviousControler(tp)
		and c:GetReasonPlayer()==1-tp and c:IsReason(REASON_EFFECT)
end
function s.spfilter6(c,e,tp)
	return c:IsSetCard(SET_GENERICUS_MONSTRUM) and not c:IsType(TYPE_XYZ) and c:IsMonster()
		and c:IsCanBeSpecialSummoned(e,0,tp,true,false)
		and ((c:IsLocation(LOCATION_DECK) and Duel.GetLocationCount(tp,LOCATION_MZONE)>0)
			or (c:IsLocation(LOCATION_EXTRA) and Duel.GetLocationCountFromEx(tp,tp,nil,c)>0))
end
function s.sptg6(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsAbleToExtra()
		and Duel.IsExistingMatchingCard(s.spfilter6,tp,LOCATION_DECK|LOCATION_EXTRA,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_TOEXTRA,c,1,tp,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK|LOCATION_EXTRA)
end
function s.spop6(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) and Duel.SendtoDeck(c,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)>0
		and c:IsLocation(LOCATION_EXTRA) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local g=Duel.SelectMatchingCard(tp,s.spfilter6,tp,LOCATION_DECK|LOCATION_EXTRA,0,1,1,nil,e,tp)
		if #g>0 then
			Duel.SpecialSummon(g,0,tp,tp,true,false,POS_FACEUP)
		end
	end
end
