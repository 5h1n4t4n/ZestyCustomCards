-- Zhuge Kongming – Supreme Celestial Strategist
local s,id=GetID()
function s.initial_effect(c)
	-- Synchro Summon procedure: 1 Tuner + 1+ non-Tuner "Mecha Three Kingdoms"
	Synchro.AddProcedure(c, nil, 1, 1, Synchro.NonTunerEx(Card.IsSetCard, 0xb4c), 1, 99)
	c:EnableReviveLimit()

	-- Always treated as "Zhuge Liang - Omniscient Mecha Tactician"
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_ADD_CODE)
	e0:SetValue(99900105)
	c:RegisterEffect(e0)

	-- Cannot be targeted or destroyed if synchro summoned with Zhuge Liang
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCondition(s.protcon)
	e1:SetValue(aux.tgoval)
	c:RegisterEffect(e1)

	local e2=e1:Clone()
	e2:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e2:SetValue(aux.indoval)
	c:RegisterEffect(e2)

	local e3=e1:Clone()
	e3:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
	e3:SetValue(1)
	c:RegisterEffect(e3)

	-- Banish instead of sending to GY (Dark Law effect)
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_FIELD)
	e4:SetProperty(EFFECT_FLAG_SET_AVAILABLE)
	e4:SetCode(EFFECT_TO_GRAVE_REDIRECT)
	e4:SetRange(LOCATION_MZONE)
	e4:SetTargetRange(0, 0xff)
	e4:SetValue(LOCATION_REMOVED)
	e4:SetCondition(s.rmcon)
	c:RegisterEffect(e4)

	-- Banish from opponent's hand and extra deck
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,0))
	e5:SetCategory(CATEGORY_REMOVE)
	e5:SetType(EFFECT_TYPE_IGNITION)
	e5:SetRange(LOCATION_MZONE)
	e5:SetCountLimit(1)
	e5:SetTarget(s.rmtg)
	e5:SetOperation(s.rmop)
	c:RegisterEffect(e5)

	-- Negate opponent's card effect (Quick Effect)
	local e6=Effect.CreateEffect(c)
	e6:SetDescription(aux.Stringid(id,1))
	e6:SetCategory(CATEGORY_NEGATE)
	e6:SetType(EFFECT_TYPE_QUICK_O)
	e6:SetCode(EVENT_CHAINING)
	e6:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DAMAGE_CAL)
	e6:SetRange(LOCATION_MZONE)
	e6:SetCountLimit(1)
	e6:SetCondition(s.negcon)
	e6:SetTarget(s.negtg)
	e6:SetOperation(s.negop)
	c:RegisterEffect(e6)

	-- Special Summon Xyz when sent to GY or banished
	local e7=Effect.CreateEffect(c)
	e7:SetDescription(aux.Stringid(id,2))
	e7:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e7:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e7:SetProperty(EFFECT_FLAG_DELAY)
	e7:SetCode(EVENT_TO_GRAVE)
	e7:SetTarget(s.xyztg)
	e7:SetOperation(s.xyzop)
	c:RegisterEffect(e7)

	local e8=e7:Clone()
	e8:SetCode(EVENT_REMOVE)
	c:RegisterEffect(e8)

	-- Flag for synchro summoned with Zhuge Liang
	local e9=Effect.CreateEffect(c)
	e9:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e9:SetCode(EVENT_SPSUMMON_SUCCESS)
	e9:SetCondition(s.regcon)
	e9:SetOperation(s.regop)
	c:RegisterEffect(e9)
end

s.listed_names={99900105,99900123}
s.listed_series={0xb4c}

--------------------------------------------------------------------------------
-- SYNCHRO MATERIAL CHECK & FLAG
--------------------------------------------------------------------------------
function s.matcheck(c)
	return c:IsCode(99900105)
end

function s.regcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_SYNCHRO) 
		and e:GetHandler():GetMaterial():IsExists(s.matcheck,1,nil)
end

function s.regop(e,tp,eg,ep,ev,re,r,rp)
	e:GetHandler():RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD,0,1)
end

function s.protcon(e)
	return e:GetHandler():GetFlagEffect(id)>0
end

--------------------------------------------------------------------------------
-- BANISH REDIRECT
--------------------------------------------------------------------------------
function s.rmcon(e)
	return Duel.GetCurrentPhase()~=PHASE_DAMAGE or not Duel.IsDamageCalculated()
end

--------------------------------------------------------------------------------
-- HAND & EXTRA DECK BANISH
--------------------------------------------------------------------------------
function s.altarfilter(c)
	return c:IsFaceup() and c:IsCode(99900123)
end

function s.rmtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetFieldGroupCount(tp,0,LOCATION_HAND)>0 end
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,1,1-tp,LOCATION_HAND)
end

function s.rmop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetFieldGroup(tp,0,LOCATION_HAND)
	if #g>0 then
		local sg=g:RandomSelect(tp,1)
		Duel.Remove(sg,POS_FACEUP,REASON_EFFECT)
	end
	if Duel.IsExistingMatchingCard(s.altarfilter,tp,LOCATION_ONFIELD,0,1,nil) then
		local exg=Duel.GetFieldGroup(tp,0,LOCATION_EXTRA)
		if #exg>0 and Duel.SelectYesNo(tp,aux.Stringid(id,3)) then
			Duel.BreakEffect()
			Duel.ConfirmCards(tp,exg)
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
			local rg=exg:Select(tp,1,1,nil)
			Duel.Remove(rg,POS_FACEUP,REASON_EFFECT)
			Duel.ShuffleExtra(1-tp)
		end
	end
end

--------------------------------------------------------------------------------
-- NEGATE EFFECT
--------------------------------------------------------------------------------
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	local loc=Duel.GetChainInfo(ev,CHAININFO_TRIGGERING_LOCATION)
	return rp==1-tp and (loc==LOCATION_HAND or (loc&LOCATION_ONFIELD)~=0) and Duel.IsChainNegatable(ev)
end

function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)
	Duel.NegateActivation(ev)
end

--------------------------------------------------------------------------------
-- FLOATING INTO XYZ & ATTACH MATERIALS
--------------------------------------------------------------------------------
function s.xyzfilter(c,e,tp)
	return c:IsType(TYPE_XYZ) and c:IsSetCard(0xb4c) and c:IsCanBeSpecialSummoned(e,0,tp,true,true)
end

function s.xyztg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCountFromEx(tp)>0
		and Duel.IsExistingMatchingCard(s.xyzfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

function s.attachfilter(c)
	return c:IsCanOverlay()
end

function s.xyzop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCountFromEx(tp)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.xyzfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp)
	local tc=g:GetFirst()
	if tc and Duel.SpecialSummon(tc,0,tp,tp,true,true,POS_FACEUP)>0 then
		tc:CompleteProcedure()
		local ag=Duel.GetMatchingGroup(s.attachfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,nil)
		if #ag>0 and Duel.SelectYesNo(tp,aux.Stringid(id,4)) then
			Duel.BreakEffect()
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_XMATERIAL)
			local sg=ag:Select(tp,1,5,nil)
			Duel.Overlay(tc,sg)
		end
	end
end