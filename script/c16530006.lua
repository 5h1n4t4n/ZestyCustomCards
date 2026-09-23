-- Cyberdark Cybernizing
local s,id=GetID()

function s.initial_effect(c)
	-- Activate from hand condition
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetCode(EFFECT_TRAP_ACT_IN_HAND)
	e0:SetCondition(s.handcon)
	c:RegisterEffect(e0)

	-- Activate: Protect Extra Deck "Cyberdark" monsters
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E+TIMING_MAIN_END)
	e1:SetCountLimit(1,{id,1})
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)

	-- Banish from GY: allow GY self-summon effects of Cyberdark monsters as Quick Effects
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E+TIMING_MAIN_END)
	e2:SetCountLimit(1,{id,2})
	e2:SetCost(aux.bfgcost)
	e2:SetOperation(s.gyop)
	c:RegisterEffect(e2)
end

s.listed_series={SET_CYBERDARK}

function s.exfilter(c)
	return c:IsFaceup() and c:IsSetCard(SET_CYBERDARK) and c:IsSummonLocation(LOCATION_EXTRA)
end

function s.handcon(e)
	return Duel.IsExistingMatchingCard(s.exfilter,e:GetHandlerPlayer(),LOCATION_MZONE,0,1,nil)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	-- Cannot be Tributed
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_UNRELEASABLE_SUM)
	e1:SetTargetRange(LOCATION_MZONE,0)
	e1:SetTarget(function(e,c) return s.exfilter(c) end)
	e1:SetValue(1)
	e1:SetReset(RESET_PHASE|PHASE_END)
	Duel.RegisterEffect(e1,tp)
	local e1b=e1:Clone()
	e1b:SetCode(EFFECT_UNRELEASABLE_NONSUM)
	Duel.RegisterEffect(e1b,tp)

	-- Cannot be used as material
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_CANNOT_BE_FUSION_MATERIAL)
	e2:SetTargetRange(LOCATION_MZONE,0)
	e2:SetTarget(function(e,c) return s.exfilter(c) end)
	e2:SetValue(1)
	e2:SetReset(RESET_PHASE|PHASE_END)
	Duel.RegisterEffect(e2,tp)
	local e2b=e2:Clone()
	e2b:SetCode(EFFECT_CANNOT_BE_SYNCHRO_MATERIAL)
	Duel.RegisterEffect(e2b,tp)
	local e2c=e2:Clone()
	e2c:SetCode(EFFECT_CANNOT_BE_XYZ_MATERIAL)
	Duel.RegisterEffect(e2c,tp)
	local e2d=e2:Clone()
	e2d:SetCode(EFFECT_CANNOT_BE_LINK_MATERIAL)
	Duel.RegisterEffect(e2d,tp)
end

function s.gyop(e,tp,eg,ep,ev,re,r,rp)
	Duel.RegisterFlagEffect(tp,id,RESET_PHASE|PHASE_END,0,1)
end
