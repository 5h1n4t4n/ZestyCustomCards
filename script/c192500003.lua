-- ============================================================
-- Card Name: Genericus Monstrum the Pendulum
-- Passcode : 192500003
-- Type     : Monster / Pendulum / Effect
-- Attribute: LIGHT
-- Level    : 10
-- Scale    : 12 / 12
-- ATK/DEF  : ? / ?
-- Race     : Spellcaster
-- Archetype: Genericus Monstrum (0x785)
-- ============================================================
-- [Pendulum Effect]
-- You can activate 1 of these effects. You can only use each Pendulum
-- Effect of "Genericus Monstrum the Pendulum" once per turn.
-- ● During your Main Phase: You can add 1 Pendulum Monster from your
--   Deck to your hand, but for the rest of this turn, unless you Pendulum
--   Summon after this effect resolves, you cannot activate monster effects.
-- ● You can pay 1000 LP; Change this card's Pendulum Scale to 0 until the
--   end of this turn.
-- ● You can pay half your LP; during your Main Phase this turn, you can
--   conduct 1 Pendulum Summon of a monster(s) in addition to your Pendulum
--   Summon.
-- ● If your LP is below 1000: Banish 1 card from your hand or field
--   face-down; gain 8000 LP.
--
-- [Monster Effect]
-- Must first be Pendulum Summoned, or Special Summoned by a "Genericus
-- Monstrum" card effect. If this card is Special Summoned by the effect
-- of a "Genericus Monstrum" monster, its original ATK/DEF become 3000
-- (if it was Special Summoned by the effect of a "Genericus Monstrum"
-- Link Monster, this card's Attributes also become DIVINE, DARK, LIGHT,
-- WATER, FIRE, WIND, and EARTH).
-- ① This card gains the original Attributes, Types, ATK, and DEF of all
--    face-up Pendulum Monsters currently on the field.
-- ② You can target 2 Spells or 1 monster you control; destroy them, and
--    if you do, Special Summon this card from your hand, or face-up Extra
--    Deck.
-- ③ If this card is Special Summoned: You can target 1 Pendulum Monster
--    in your GY; Special Summon it.
-- ④ Cannot be targeted by your opponent's Spell/Trap effects, or by your
--    opponent's monster effects with the same Attribute as this card.
-- ⑤ (Quick Effect): Banish 1 Pendulum Monster you control or from your GY,
--    then target 1 face-up card on the field; negate the activation. If this
--    card was Special Summoned by the effect of a "Genericus Monstrum" Link
--    Monster, you can banish 1 card your opponent controls instead, also
--    negate the effects of all cards your opponent currently controls.
-- ⑥ If this face-up card in its owner's possession leaves the field because
--    of an opponent's card effect: Return this card to the Deck, and if you
--    do, Special Summon 1 non-Pendulum "Genericus Monstrum" monster from
--    your Deck or Extra Deck, ignoring its Summoning conditions.
-- You can only use each monster effect of "Genericus Monstrum the Pendulum"
-- once per turn.
-- ============================================================

local s,id=GetID()
Duel.LoadScript("constants.lua")

function s.initial_effect(c)
	c:EnableReviveLimit()

	-- ============================================================
	-- Summon Procedures & Constraints
	-- ============================================================
	-- Pendulum Summon procedure
	Pendulum.AddProcedure(c)

	-- Must first be Pendulum Summoned or Special Summoned by a "Genericus Monstrum" card effect
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_SPSUMMON_CONDITION)
	e0:SetValue(s.splimit)
	c:RegisterEffect(e0)

	-- ============================================================
	-- Pendulum Effects
	-- ============================================================
	-- Pendulum Effect 1: Add 1 Pendulum Monster from Deck to hand
	local ep1=Effect.CreateEffect(c)
	ep1:SetDescription(aux.Stringid(id,0))
	ep1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	ep1:SetType(EFFECT_TYPE_IGNITION)
	ep1:SetRange(LOCATION_PZONE)
	ep1:SetCountLimit(1,id)
	ep1:SetTarget(s.pthtg1)
	ep1:SetOperation(s.pthop1)
	c:RegisterEffect(ep1)

	-- Pendulum Effect 2: Pay 1000 LP; Change Scale to 0
	local ep2=Effect.CreateEffect(c)
	ep2:SetDescription(aux.Stringid(id,1))
	ep2:SetType(EFFECT_TYPE_IGNITION)
	ep2:SetRange(LOCATION_PZONE)
	ep2:SetCountLimit(1,{id,1})
	ep2:SetCost(s.pcost2)
	ep2:SetOperation(s.pop2)
	c:RegisterEffect(ep2)

	-- Pendulum Effect 3: Pay half LP; 1 additional Pendulum Summon
	local ep3=Effect.CreateEffect(c)
	ep3:SetDescription(aux.Stringid(id,2))
	ep3:SetType(EFFECT_TYPE_IGNITION)
	ep3:SetRange(LOCATION_PZONE)
	ep3:SetCountLimit(1,{id,2})
	ep3:SetCondition(function(e,tp) return Pendulum.PlayerCanGainAdditionalPendulumSummon(tp,id) end)
	ep3:SetCost(s.pcost3)
	ep3:SetOperation(s.pop3)
	c:RegisterEffect(ep3)

	-- Pendulum Effect 4: LP < 1000 -> Banish 1 card face-down; gain 8000 LP
	local ep4=Effect.CreateEffect(c)
	ep4:SetDescription(aux.Stringid(id,3))
	ep4:SetCategory(CATEGORY_RECOVER)
	ep4:SetType(EFFECT_TYPE_IGNITION)
	ep4:SetRange(LOCATION_PZONE)
	ep4:SetCountLimit(1,{id,3})
	ep4:SetCondition(function(e,tp) return Duel.GetLP(tp)<1000 end)
	ep4:SetCost(s.pcost4)
	ep4:SetTarget(s.ptg4)
	ep4:SetOperation(s.pop4)
	c:RegisterEffect(ep4)

	-- ============================================================
	-- Monster Inherent & Continuous Effects
	-- ============================================================
	-- Special Summoned by "Genericus Monstrum" monster effect
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetOperation(s.gen_spop)
	c:RegisterEffect(e1)

	-- Monster Effect 1: Gain original Attributes, Types, ATK, and DEF of face-up Pendulum Monsters on field
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

	-- Monster Effect 4: Cannot be targeted by opponent's Spell/Trap or same Attribute monster effect
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE)
	e4:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e4:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e4:SetRange(LOCATION_MZONE)
	e4:SetValue(s.tgval4)
	c:RegisterEffect(e4)

	-- ============================================================
	-- Monster Activated Effects
	-- ============================================================
	-- Monster Effect 2: Destroy 2 Spells or 1 monster you control -> Special Summon this card
	local e2=Effect.CreateEffect(c)
	e2:SetCategory(CATEGORY_DESTROY+CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetRange(LOCATION_HAND|LOCATION_EXTRA)
	e2:SetCountLimit(1,{id,4})
	e2:SetTarget(s.sptg2)
	e2:SetOperation(s.spop2)
	c:RegisterEffect(e2)

	-- Monster Effect 3: Special Summon 1 Pendulum Monster from GY
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,6))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	e3:SetCountLimit(1,{id,5})
	e3:SetTarget(s.sptg3)
	e3:SetOperation(s.spop3)
	c:RegisterEffect(e3)

	-- Monster Effect 5: (Quick Effect) Banish 1 Pendulum Monster -> negate activation/effects
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,7))
	e5:SetCategory(CATEGORY_DISABLE+CATEGORY_REMOVE)
	e5:SetType(EFFECT_TYPE_QUICK_O)
	e5:SetCode(EVENT_FREE_CHAIN)
	e5:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e5:SetRange(LOCATION_MZONE)
	e5:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E|TIMING_MAIN_END)
	e5:SetCountLimit(1,{id,6})
	e5:SetCost(s.cost5)
	e5:SetTarget(s.tg5)
	e5:SetOperation(s.op5)
	c:RegisterEffect(e5)

	-- Monster Effect 6: Face-up leaves field by opponent's card effect -> return to Deck, Special Summon
	local e6=Effect.CreateEffect(c)
	e6:SetDescription(aux.Stringid(id,8))
	e6:SetCategory(CATEGORY_TODECK+CATEGORY_SPECIAL_SUMMON)
	e6:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e6:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_DAMAGE_STEP)
	e6:SetCode(EVENT_LEAVE_FIELD)
	e6:SetCountLimit(1,{id,7})
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
	return (st&SUMMON_TYPE_PENDULUM)==SUMMON_TYPE_PENDULUM or (se and se:GetHandler():IsSetCard(SET_GENERICUS_MONSTRUM))
end

-- ============================================================
-- Pendulum Effects Callbacks
-- ============================================================
function s.pthfilter1(c)
	return c:IsType(TYPE_PENDULUM) and c:IsMonster() and c:IsAbleToHand()
end
function s.pthtg1(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.pthfilter1,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.pthop1(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.pthfilter1,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
		-- Lock monster effect activations unless Pendulum Summoned
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_FIELD)
		e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
		e1:SetCode(EFFECT_CANNOT_ACTIVATE)
		e1:SetTargetRange(1,0)
		e1:SetValue(s.aclimit)
		e1:SetReset(RESET_PHASE|PHASE_END)
		Duel.RegisterEffect(e1,tp)
		local e2=Effect.CreateEffect(e:GetHandler())
		e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		e2:SetCode(EVENT_SPSUMMON_SUCCESS)
		e2:SetOperation(s.checkop)
		e2:SetLabelObject(e1)
		e2:SetReset(RESET_PHASE|PHASE_END)
		Duel.RegisterEffect(e2,tp)
	end
end
function s.aclimit(e,re,tp)
	return re:IsMonsterEffect()
end
function s.checkop(e,tp,eg,ep,ev,re,r,rp)
	if eg:IsExists(Card.IsSummonType,1,nil,SUMMON_TYPE_PENDULUM) and ep==tp then
		e:GetLabelObject():Reset()
		e:Reset()
	end
end

function s.pcost2(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckLPCost(tp,1000) end
	Duel.PayLPCost(tp,1000)
end
function s.pop2(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_CHANGE_LSCALE)
		e1:SetValue(0)
		e1:SetReset(RESET_EVENT|RESETS_STANDARD|RESET_PHASE|PHASE_END)
		c:RegisterEffect(e1)
		local e2=e1:Clone()
		e2:SetCode(EFFECT_CHANGE_RSCALE)
		c:RegisterEffect(e2)
	end
end

function s.pcost3(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckLPCost(tp,math.floor(Duel.GetLP(tp)/2)) end
	Duel.PayLPCost(tp,math.floor(Duel.GetLP(tp)/2))
end
function s.pop3(e,tp,eg,ep,ev,re,r,rp)
	-- Grant 1 additional Pendulum Summon
	Pendulum.GrantAdditionalPendulumSummon(tp,id)
end

function s.pcost4(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(Card.IsAbleToRemoveAsCost,tp,LOCATION_HAND|LOCATION_ONFIELD,0,1,nil,POS_FACEDOWN) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectMatchingCard(tp,Card.IsAbleToRemoveAsCost,tp,LOCATION_HAND|LOCATION_ONFIELD,0,1,1,nil,POS_FACEDOWN)
	Duel.Remove(g,POS_FACEDOWN,REASON_COST)
end
function s.ptg4(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetTargetPlayer(tp)
	Duel.SetTargetParam(8000)
	Duel.SetOperationInfo(0,CATEGORY_RECOVER,nil,0,tp,8000)
end
function s.pop4(e,tp,eg,ep,ev,re,r,rp)
	local p,d=Duel.GetChainInfo(0,CHAININFO_TARGET_PLAYER,CHAININFO_TARGET_PARAM)
	Duel.Recover(p,d,REASON_EFFECT)
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
-- Pendulum Field Stat/Attribute/Race Gain
-- ============================================================
function s.atkval(e,c)
	local g=Duel.GetMatchingGroup(function(tc) return tc:IsFaceup() and tc:IsType(TYPE_PENDULUM) and tc~=c end,
		c:GetControler(),LOCATION_MZONE,LOCATION_MZONE,nil)
	local val=0
	for tc in g:Iter() do
		local atk=tc:GetTextAttack()
		if atk>0 then val=val+atk end
	end
	return val
end
function s.defval(e,c)
	local g=Duel.GetMatchingGroup(function(tc) return tc:IsFaceup() and tc:IsType(TYPE_PENDULUM) and tc~=c end,
		c:GetControler(),LOCATION_MZONE,LOCATION_MZONE,nil)
	local val=0
	for tc in g:Iter() do
		local def=tc:GetTextDefense()
		if def>0 then val=val+def end
	end
	return val
end
function s.attval(e,c)
	local g=Duel.GetMatchingGroup(function(tc) return tc:IsFaceup() and tc:IsType(TYPE_PENDULUM) and tc~=c end,
		c:GetControler(),LOCATION_MZONE,LOCATION_MZONE,nil)
	local val=0
	for tc in g:Iter() do
		val=val|tc:GetOriginalAttribute()
	end
	return val
end
function s.raceval(e,c)
	local g=Duel.GetMatchingGroup(function(tc) return tc:IsFaceup() and tc:IsType(TYPE_PENDULUM) and tc~=c end,
		c:GetControler(),LOCATION_MZONE,LOCATION_MZONE,nil)
	local val=0
	for tc in g:Iter() do
		val=val|tc:GetOriginalRace()
	end
	return val
end

-- ============================================================
-- Monster Effect 2 Callbacks
-- ============================================================
function s.desfilter_spell(c)
	return c:IsFaceup() and c:IsType(TYPE_SPELL) and c:IsDestructable()
end
function s.desfilter_monster(c)
	return c:IsFaceup() and c:IsMonster() and c:IsDestructable()
end
function s.sptg2(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	local c=e:GetHandler()
	if c:IsLocation(LOCATION_EXTRA) and not c:IsFaceup() then return false end
	local b_spell=Duel.IsExistingTarget(s.desfilter_spell,tp,LOCATION_ONFIELD,0,2,nil)
	local b_mon=Duel.IsExistingTarget(s.desfilter_monster,tp,LOCATION_MZONE,0,1,nil)
	local can_sp=(c:IsLocation(LOCATION_HAND) and Duel.GetLocationCount(tp,LOCATION_MZONE)>0)
		or (c:IsLocation(LOCATION_EXTRA) and c:IsFaceup() and Duel.GetLocationCountFromEx(tp,tp,nil,c)>0)
	if chkc then return false end
	if chk==0 then return (b_spell or b_mon) and can_sp end
	local opt=0
	if b_spell and b_mon then
		opt=Duel.SelectOption(tp,aux.Stringid(id,4),aux.Stringid(id,5))
	elseif b_spell then
		opt=Duel.SelectOption(tp,aux.Stringid(id,4))
	else
		opt=Duel.SelectOption(tp,aux.Stringid(id,5))+1
	end
	e:SetLabel(opt)
	if opt==0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
		local g=Duel.SelectTarget(tp,s.desfilter_spell,tp,LOCATION_ONFIELD,0,2,2,nil)
		Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,2,0,0)
	else
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
		local g=Duel.SelectTarget(tp,s.desfilter_monster,tp,LOCATION_MZONE,0,1,1,nil)
		Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,tp,0)
end
function s.spop2(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tg=Duel.GetTargetCards(e)
	if #tg>0 and Duel.Destroy(tg,REASON_EFFECT)>0 and c:IsRelateToEffect(e) then
		Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
	end
end

-- ============================================================
-- Monster Effect 3 Callbacks
-- ============================================================
function s.spfilter3(c,e,tp)
	return c:IsType(TYPE_PENDULUM) and c:IsMonster() and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sptg3(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_GRAVE) and chkc:IsControler(tp) and s.spfilter3(chkc,e,tp) end
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingTarget(s.spfilter3,tp,LOCATION_GRAVE,0,1,nil,e,tp) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectTarget(tp,s.spfilter3,tp,LOCATION_GRAVE,0,1,1,nil,e,tp)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,g,1,0,0)
end
function s.spop3(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)
	end
end

-- ============================================================
-- Monster Effect 4 Callbacks
-- ============================================================
function s.tgval4(e,te)
	if te:GetOwnerPlayer()==e:GetHandlerPlayer() then return false end
	if te:IsActiveType(TYPE_SPELL|TYPE_TRAP) then return true end
	return te:IsActiveType(TYPE_MONSTER)
		and (te:GetHandler():GetAttribute() & e:GetHandler():GetAttribute() ~= 0)
end

-- ============================================================
-- Monster Effect 5 Callbacks
-- ============================================================
function s.cfilter5(c)
	return c:IsType(TYPE_PENDULUM) and c:IsMonster() and c:IsAbleToRemoveAsCost()
end
function s.cost5(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	local b_pen=Duel.IsExistingMatchingCard(s.cfilter5,tp,LOCATION_MZONE|LOCATION_GRAVE,0,1,nil)
	local b_link=c:HasFlagEffect(id) and Duel.IsExistingMatchingCard(Card.IsAbleToRemoveAsCost,tp,0,LOCATION_ONFIELD,1,nil)
	if chk==0 then return b_pen or b_link end
	if b_link and (not b_pen or Duel.SelectYesNo(tp,aux.Stringid(id,9))) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
		local g=Duel.SelectMatchingCard(tp,Card.IsAbleToRemoveAsCost,tp,0,LOCATION_ONFIELD,1,1,nil)
		Duel.Remove(g,POS_FACEUP,REASON_COST)
	else
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
		local g=Duel.SelectMatchingCard(tp,s.cfilter5,tp,LOCATION_MZONE|LOCATION_GRAVE,0,1,1,nil)
		Duel.Remove(g,POS_FACEUP,REASON_COST)
	end
end
function s.tg5(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsOnField() and chkc:IsFaceup() end
	if chk==0 then return Duel.IsExistingTarget(Card.IsFaceup,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	Duel.SelectTarget(tp,Card.IsFaceup,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,1,nil)
end
function s.op5(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) and tc:IsFaceup() then
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
	if c:HasFlagEffect(id) then
		local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,0,LOCATION_ONFIELD,nil)
		for oc in g:Iter() do
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_DISABLE)
			e1:SetReset(RESET_EVENT|RESETS_STANDARD|RESET_PHASE|PHASE_END)
			oc:RegisterEffect(e1)
			local e2=Effect.CreateEffect(c)
			e2:SetType(EFFECT_TYPE_SINGLE)
			e2:SetCode(EFFECT_DISABLE_EFFECT)
			e2:SetReset(RESET_EVENT|RESETS_STANDARD|RESET_PHASE|PHASE_END)
			oc:RegisterEffect(e2)
		end
	end
end

-- ============================================================
-- Monster Effect 6 Callbacks
-- ============================================================
function s.spcon6(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsPreviousPosition(POS_FACEUP) and c:IsPreviousLocation(LOCATION_ONFIELD)
		and c:IsPreviousControler(tp) and c:GetReasonPlayer()==1-tp and c:IsReason(REASON_EFFECT)
end
function s.spfilter6(c,e,tp)
	return c:IsSetCard(SET_GENERICUS_MONSTRUM) and not c:IsType(TYPE_PENDULUM) and c:IsMonster()
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
