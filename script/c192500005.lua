-- ============================================================
-- Card Name: Genericus Monstrum the Synchro
-- Passcode : 192500005
-- Type     : Monster / Synchro / Effect
-- Attribute: DARK
-- Level    : 10
-- ATK/DEF  : ? / ?
-- Race     : Warrior
-- Archetype: Genericus Monstrum (0x785)
-- ============================================================
-- Materials: 1+ Tuner + 1+ non-Tuner monsters
-- Must first be Synchro Summoned. If this card is Special Summoned by
-- the effect of a "Genericus Monstrum" monster: Its original ATK/DEF
-- become 3000, also you can choose 1 Attribute; this card gains that
-- original Attribute (if it was Special Summoned by the effect of a
-- "Genericus Monstrum" Link Monster, this card's Attributes instead
-- become DIVINE, DARK, LIGHT, WATER, FIRE, WIND, and EARTH).
-- ① This card gains the original Attributes, Types, ATK, and DEF of the
--    materials used for its Synchro Summon.
-- ② Gains these effects based on its Attributes:
--    ● LIGHT: You can add 1 Tuner monster from your Deck to your hand, but
--      you cannot activate its effects until the end of the next turn,
--      unless it is Summoned.
--    ● DARK: Cannot be targeted or destroyed by your opponent's card
--      effects.
--    ● WIND (Quick Effect): When a monster effect is activated: You can
--      banish 1 Tuner monster and 1 non-Tuner monster from your GY;
--      negate the activation, and if you do, destroy that card.
--    ● WATER (Quick Effect): You can banish 1 card your opponent controls,
--      and if you do, this card gains 1000 ATK.
--    ● FIRE: Special Summon 1 Tuner monster or 1 Synchro Monster from your
--      GY or banishment, but negate its effects.
--    ● EARTH (Quick Effect): When a Spell/Trap Card or effect is activated:
--      You can banish the top 2 cards of your Deck; negate the activation,
--      and if you do, destroy that card.
--    ● DIVINE: Face-up cards you control are unaffected by your opponent's
--      card effects.
-- ③ If this card in its owner's possession leaves the field because of an
--    opponent's card effect: Return this card to the Extra Deck, and if you
--    do, Special Summon 1 non-Synchro "Genericus Monstrum" monster from
--    your Deck or Extra Deck, ignoring its Summoning conditions.
-- You can only use each effect of "Genericus Monstrum the Synchro" once per turn.
-- ============================================================

local s,id=GetID()
Duel.LoadScript("constants.lua")

function s.initial_effect(c)
	c:EnableReviveLimit()

	-- ============================================================
	-- Summon Procedures & Constraints
	-- ============================================================
	-- Synchro Material: 1+ Tuner + 1+ non-Tuner monsters
	Synchro.AddProcedure(c,nil,1,99,Synchro.NonTuner(nil),1,99)

	-- Must first be Synchro Summoned
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_SPSUMMON_CONDITION)
	e0:SetValue(aux.synlimit)
	c:RegisterEffect(e0)

	-- ============================================================
	-- Continuous & Inherent Effects
	-- ============================================================
	-- Special Summoned by "Genericus Monstrum" monster effect
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCondition(s.gen_spcon)
	e1:SetOperation(s.gen_spop)
	c:RegisterEffect(e1)

	-- Effect 1: Gain original Attributes, Types, ATK, and DEF of materials
	local e_mat=Effect.CreateEffect(c)
	e_mat:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e_mat:SetCode(EVENT_SPSUMMON_SUCCESS)
	e_mat:SetOperation(s.matop)
	c:RegisterEffect(e_mat)

	-- ============================================================
	-- Effect 2: Attribute-based Effects
	-- ============================================================
	-- Effect 2 LIGHT: Search 1 Tuner monster
	local e_light=Effect.CreateEffect(c)
	e_light:SetDescription(aux.Stringid(id,1))
	e_light:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e_light:SetType(EFFECT_TYPE_IGNITION)
	e_light:SetRange(LOCATION_MZONE)
	e_light:SetCountLimit(1,{id,1})
	e_light:SetCondition(function(e) return e:GetHandler():IsAttribute(ATTRIBUTE_LIGHT) end)
	e_light:SetTarget(s.thtg_light)
	e_light:SetOperation(s.thop_light)
	c:RegisterEffect(e_light)

	-- Effect 2 DARK: Cannot be targeted or destroyed by opponent's card effects
	local e_dark1=Effect.CreateEffect(c)
	e_dark1:SetType(EFFECT_TYPE_SINGLE)
	e_dark1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e_dark1:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e_dark1:SetRange(LOCATION_MZONE)
	e_dark1:SetCondition(function(e) return e:GetHandler():IsAttribute(ATTRIBUTE_DARK) end)
	e_dark1:SetValue(aux.tgoval)
	c:RegisterEffect(e_dark1)
	local e_dark2=e_dark1:Clone()
	e_dark2:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e_dark2:SetValue(aux.indoval)
	c:RegisterEffect(e_dark2)

	-- Effect 2 WIND: (Quick Effect) Negate monster effect activation and destroy
	local e_wind=Effect.CreateEffect(c)
	e_wind:SetDescription(aux.Stringid(id,2))
	e_wind:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY)
	e_wind:SetType(EFFECT_TYPE_QUICK_O)
	e_wind:SetCode(EVENT_CHAINING)
	e_wind:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DAMAGE_CAL)
	e_wind:SetRange(LOCATION_MZONE)
	e_wind:SetCountLimit(1,{id,2})
	e_wind:SetCondition(s.discon_wind)
	e_wind:SetCost(s.discost_wind)
	e_wind:SetTarget(s.distg_wind)
	e_wind:SetOperation(s.disop_wind)
	c:RegisterEffect(e_wind)

	-- Effect 2 WATER: (Quick Effect) Banish 1 opponent card, gains 1000 ATK
	local e_water=Effect.CreateEffect(c)
	e_water:SetDescription(aux.Stringid(id,3))
	e_water:SetCategory(CATEGORY_REMOVE+CATEGORY_ATKCHANGE)
	e_water:SetType(EFFECT_TYPE_QUICK_O)
	e_water:SetCode(EVENT_FREE_CHAIN)
	e_water:SetRange(LOCATION_MZONE)
	e_water:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E|TIMING_MAIN_END)
	e_water:SetCountLimit(1,{id,3})
	e_water:SetCondition(function(e) return e:GetHandler():IsAttribute(ATTRIBUTE_WATER) end)
	e_water:SetTarget(s.rmtg_water)
	e_water:SetOperation(s.rmop_water)
	c:RegisterEffect(e_water)

	-- Effect 2 FIRE: Special Summon 1 Tuner or Synchro from GY/banishment, negate effects
	local e_fire=Effect.CreateEffect(c)
	e_fire:SetDescription(aux.Stringid(id,4))
	e_fire:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e_fire:SetType(EFFECT_TYPE_IGNITION)
	e_fire:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e_fire:SetRange(LOCATION_MZONE)
	e_fire:SetCountLimit(1,{id,4})
	e_fire:SetCondition(function(e) return e:GetHandler():IsAttribute(ATTRIBUTE_FIRE) end)
	e_fire:SetTarget(s.sptg_fire)
	e_fire:SetOperation(s.spop_fire)
	c:RegisterEffect(e_fire)

	-- Effect 2 EARTH: (Quick Effect) Negate Spell/Trap activation and destroy
	local e_earth=Effect.CreateEffect(c)
	e_earth:SetDescription(aux.Stringid(id,5))
	e_earth:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY)
	e_earth:SetType(EFFECT_TYPE_QUICK_O)
	e_earth:SetCode(EVENT_CHAINING)
	e_earth:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DAMAGE_CAL)
	e_earth:SetRange(LOCATION_MZONE)
	e_earth:SetCountLimit(1,{id,5})
	e_earth:SetCondition(s.discon_earth)
	e_earth:SetCost(s.discost_earth)
	e_earth:SetTarget(s.distg_earth)
	e_earth:SetOperation(s.disop_earth)
	c:RegisterEffect(e_earth)

	-- Effect 2 DIVINE: Face-up cards you control are unaffected by opponent's card effects
	local e_div=Effect.CreateEffect(c)
	e_div:SetType(EFFECT_TYPE_FIELD)
	e_div:SetCode(EFFECT_IMMUNE_EFFECT)
	e_div:SetRange(LOCATION_MZONE)
	e_div:SetTargetRange(LOCATION_ONFIELD,0)
	e_div:SetCondition(function(e) return e:GetHandler():IsAttribute(ATTRIBUTE_DIVINE) end)
	e_div:SetTarget(function(e,c) return c:IsFaceup() end)
	e_div:SetValue(function(e,re) return re:GetOwnerPlayer()~=e:GetHandlerPlayer() end)
	c:RegisterEffect(e_div)

	-- ============================================================
	-- Effect 3: Leaves Field Floating Effect
	-- ============================================================
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,6))
	e3:SetCategory(CATEGORY_TOEXTRA+CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_DAMAGE_STEP)
	e3:SetCode(EVENT_LEAVE_FIELD)
	e3:SetCountLimit(1,{id,6})
	e3:SetCondition(s.spcon3)
	e3:SetTarget(s.sptg3)
	e3:SetOperation(s.spop3)
	c:RegisterEffect(e3)
end
s.listed_series={SET_GENERICUS_MONSTRUM}

-- ============================================================
-- Genericus Special Summon Enhancements
-- ============================================================
function s.gen_spcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local rc=re and re:GetHandler()
	return re and re:IsMonsterEffect()
		and rc and rc:IsSetCard(SET_GENERICUS_MONSTRUM) and rc~=c
		and not c:IsSynchroSummoned()
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
	if rc:IsType(TYPE_LINK) then
		local e3=Effect.CreateEffect(c)
		e3:SetType(EFFECT_TYPE_SINGLE)
		e3:SetCode(EFFECT_CHANGE_ATTRIBUTE)
		e3:SetValue(ATTRIBUTE_ALL)
		e3:SetReset(RESET_EVENT|RESETS_STANDARD)
		c:RegisterEffect(e3)
	else
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATTRIBUTE)
		local att=Duel.AnnounceAttribute(tp,1,ATTRIBUTE_ALL)
		local e3=Effect.CreateEffect(c)
		e3:SetType(EFFECT_TYPE_SINGLE)
		e3:SetCode(EFFECT_ADD_ATTRIBUTE)
		e3:SetValue(att)
		e3:SetReset(RESET_EVENT|RESETS_STANDARD)
		c:RegisterEffect(e3)
	end
end

-- ============================================================
-- Material Gain Callback
-- ============================================================
function s.matop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsSynchroSummoned() then return end
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
-- Effect 2 Callbacks: LIGHT
-- ============================================================
function s.thfilter_light(c)
	return c:IsType(TYPE_TUNER) and c:IsMonster() and c:IsAbleToHand()
end
function s.thtg_light(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter_light,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.thop_light(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter_light,tp,LOCATION_DECK,0,1,1,nil)
	local tc=g:GetFirst()
	if tc and Duel.SendtoHand(tc,nil,REASON_EFFECT)>0 and tc:IsLocation(LOCATION_HAND) then
		Duel.ConfirmCards(1-tp,tc)
		-- Cannot activate its effects until end of next turn unless summoned
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_FIELD)
		e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
		e1:SetCode(EFFECT_CANNOT_ACTIVATE)
		e1:SetTargetRange(1,0)
		e1:SetValue(function(eff,re,p) return re:GetHandler():IsCode(tc:GetCode()) end)
		e1:SetReset(RESET_PHASE|PHASE_END,2)
		Duel.RegisterEffect(e1,tp)
		local e2=Effect.CreateEffect(e:GetHandler())
		e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		e2:SetCode(EVENT_SUMMON_SUCCESS)
		e2:SetLabelObject(e1)
		e2:SetLabel(tc:GetCode())
		e2:SetOperation(s.resetop_light)
		e2:SetReset(RESET_PHASE|PHASE_END,2)
		Duel.RegisterEffect(e2,tp)
		local e3=e2:Clone()
		e3:SetCode(EVENT_SPSUMMON_SUCCESS)
		Duel.RegisterEffect(e3,tp)
	end
end
function s.resetop_light(e,tp,eg,ep,ev,re,r,rp)
	local code=e:GetLabel()
	if eg:IsExists(Card.IsCode,1,nil,code) then
		e:GetLabelObject():Reset()
		e:Reset()
	end
end

-- ============================================================
-- Effect 2 Callbacks: WIND
-- ============================================================
function s.discon_wind(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsAttribute(ATTRIBUTE_WIND)
		and not e:GetHandler():IsStatus(STATUS_BATTLE_DESTROYED)
		and ep==1-tp and re:IsMonsterEffect() and Duel.IsChainNegatable(ev)
end
function s.cfilter_tuner(c)
	return c:IsType(TYPE_TUNER) and c:IsMonster() and c:IsAbleToRemoveAsCost()
end
function s.cfilter_nontuner(c)
	return not c:IsType(TYPE_TUNER) and c:IsMonster() and c:IsAbleToRemoveAsCost()
end
function s.discost_wind(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.cfilter_tuner,tp,LOCATION_GRAVE,0,1,nil)
			and Duel.IsExistingMatchingCard(s.cfilter_nontuner,tp,LOCATION_GRAVE,0,1,nil)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g1=Duel.SelectMatchingCard(tp,s.cfilter_tuner,tp,LOCATION_GRAVE,0,1,1,nil)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g2=Duel.SelectMatchingCard(tp,s.cfilter_nontuner,tp,LOCATION_GRAVE,0,1,1,nil)
	g1:Merge(g2)
	Duel.Remove(g1,POS_FACEUP,REASON_COST)
end
function s.distg_wind(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
	if re:GetHandler():IsDestructable() and re:GetHandler():IsRelateToEffect(re) then
		Duel.SetOperationInfo(0,CATEGORY_DESTROY,eg,1,0,0)
	end
end
function s.disop_wind(e,tp,eg,ep,ev,re,r,rp)
	if Duel.NegateActivation(ev) and re:GetHandler():IsRelateToEffect(re) then
		Duel.Destroy(eg,REASON_EFFECT)
	end
end

-- ============================================================
-- Effect 2 Callbacks: WATER
-- ============================================================
function s.rmtg_water(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(Card.IsAbleToRemove,tp,0,LOCATION_ONFIELD,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,1,1-tp,LOCATION_ONFIELD)
end
function s.rmop_water(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectMatchingCard(tp,Card.IsAbleToRemove,tp,0,LOCATION_ONFIELD,1,1,nil)
	if #g>0 and Duel.Remove(g,POS_FACEUP,REASON_EFFECT)>0 and c:IsRelateToEffect(e) and c:IsFaceup() then
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_ATTACK)
		e1:SetValue(1000)
		e1:SetReset(RESET_EVENT|RESETS_STANDARD_DISABLE)
		c:RegisterEffect(e1)
	end
end

-- ============================================================
-- Effect 2 Callbacks: FIRE
-- ============================================================
function s.spfilter_fire(c,e,tp)
	return (c:IsType(TYPE_TUNER) or c:IsType(TYPE_SYNCHRO)) and c:IsMonster()
		and (c:IsLocation(LOCATION_GRAVE) or c:IsFaceup())
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sptg_fire(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsLocation(LOCATION_GRAVE|LOCATION_REMOVED) and chkc:IsControler(tp) and s.spfilter_fire(chkc,e,tp)
	end
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingTarget(s.spfilter_fire,tp,LOCATION_GRAVE|LOCATION_REMOVED,0,1,nil,e,tp) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectTarget(tp,s.spfilter_fire,tp,LOCATION_GRAVE|LOCATION_REMOVED,0,1,1,nil,e,tp)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,g,1,0,0)
end
function s.spop_fire(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		if Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)>0 then
			local e1=Effect.CreateEffect(e:GetHandler())
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_DISABLE)
			e1:SetReset(RESET_EVENT|RESETS_STANDARD)
			tc:RegisterEffect(e1)
			local e2=Effect.CreateEffect(e:GetHandler())
			e2:SetType(EFFECT_TYPE_SINGLE)
			e2:SetCode(EFFECT_DISABLE_EFFECT)
			e2:SetReset(RESET_EVENT|RESETS_STANDARD)
			tc:RegisterEffect(e2)
		end
	end
end

-- ============================================================
-- Effect 2 Callbacks: EARTH
-- ============================================================
function s.discon_earth(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsAttribute(ATTRIBUTE_EARTH)
		and not e:GetHandler():IsStatus(STATUS_BATTLE_DESTROYED)
		and ep==1-tp and re:IsSpellTrapEffect() and Duel.IsChainNegatable(ev)
end
function s.discost_earth(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsPlayerCanRemove(tp) and Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)>=2 end
	local g=Duel.GetDecktopGroup(tp,2)
	Duel.Remove(g,POS_FACEUP,REASON_COST)
end
function s.distg_earth(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
	if re:GetHandler():IsDestructable() and re:GetHandler():IsRelateToEffect(re) then
		Duel.SetOperationInfo(0,CATEGORY_DESTROY,eg,1,0,0)
	end
end
function s.disop_earth(e,tp,eg,ep,ev,re,r,rp)
	if Duel.NegateActivation(ev) and re:GetHandler():IsRelateToEffect(re) then
		Duel.Destroy(eg,REASON_EFFECT)
	end
end

-- ============================================================
-- Effect 3 Callbacks
-- ============================================================
function s.spcon3(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsPreviousLocation(LOCATION_ONFIELD) and c:IsPreviousControler(tp)
		and c:GetReasonPlayer()==1-tp and c:IsReason(REASON_EFFECT)
end
function s.spfilter3(c,e,tp)
	return c:IsSetCard(SET_GENERICUS_MONSTRUM) and not c:IsType(TYPE_SYNCHRO) and c:IsMonster()
		and c:IsCanBeSpecialSummoned(e,0,tp,true,false)
		and ((c:IsLocation(LOCATION_DECK) and Duel.GetLocationCount(tp,LOCATION_MZONE)>0)
			or (c:IsLocation(LOCATION_EXTRA) and Duel.GetLocationCountFromEx(tp,tp,nil,c)>0))
end
function s.sptg3(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsAbleToExtra()
		and Duel.IsExistingMatchingCard(s.spfilter3,tp,LOCATION_DECK|LOCATION_EXTRA,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_TOEXTRA,c,1,tp,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK|LOCATION_EXTRA)
end
function s.spop3(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) and Duel.SendtoDeck(c,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)>0
		and c:IsLocation(LOCATION_EXTRA) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local g=Duel.SelectMatchingCard(tp,s.spfilter3,tp,LOCATION_DECK|LOCATION_EXTRA,0,1,1,nil,e,tp)
		if #g>0 then
			Duel.SpecialSummon(g,0,tp,tp,true,false,POS_FACEUP)
		end
	end
end
