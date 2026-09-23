-- ============================================================
-- Card Name: Maverick Boost - Heart Tank
-- Passcode : 11223315
-- Type     : Spell / Quick-Play
-- Archetype: Maverick Boost (0x304)
-- ============================================================
-- Effect 1: Gain 1000 LP for each "Maverick Hunter" monster you control,
--           also for the rest of this turn, all "Maverick Hunter" monsters
--           you currently control cannot be destroyed by battle or card
--           effects once.
-- Effect 2: If a "Maverick Hunter" monster(s) you control would leave the
--           field by your opponent's card, you can banish this card from
--           the GY; apply the same effect as if this card was activated.
-- You can only use 1 effect of "Maverick Boost - Heart Tank" once per turn.
-- ============================================================

Duel.LoadScript("constants.lua")
local s,id=GetID()

function s.initial_effect(c)
	-- ============================================================
	-- Effect 1 — Activation: Gain LP + 1-time destruction protection
	-- ============================================================
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_RECOVER)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)

	-- ============================================================
	-- Effect 2 — Quick Effect from GY (on Chaining): Banish to apply effect
	-- ============================================================
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_RECOVER)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_CHAINING)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,id)
	e2:SetCondition(s.gycon)
	e2:SetCost(aux.bfgcost)
	e2:SetTarget(s.target)
	e2:SetOperation(s.activate)
	c:RegisterEffect(e2)

	-- ============================================================
	-- Effect 3 — Quick Effect from GY (on Attack): Banish to apply effect
	-- ============================================================
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_RECOVER)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_ATTACK_ANNOUNCE)
	e3:SetRange(LOCATION_GRAVE)
	e3:SetCountLimit(1,id)
	e3:SetCondition(s.atkcon)
	e3:SetCost(aux.bfgcost)
	e3:SetTarget(s.target)
	e3:SetOperation(s.activate)
	c:RegisterEffect(e3)
end

s.listed_series={SET_MAVERICK_HUNTER,SET_MAVERICK_BOOST}

-- ============================================================
-- Shared Effect Logic
-- ============================================================
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	local ct=Duel.GetMatchingGroupCount(aux.FaceupFilter(Card.IsSetCard,SET_MAVERICK_HUNTER),tp,LOCATION_MZONE,0,nil)
	if chk==0 then return ct>0 end
	Duel.SetOperationInfo(0,CATEGORY_RECOVER,nil,0,tp,ct*1000)
end

function s.indct(e,re,r,rp)
	return (r&(REASON_BATTLE+REASON_EFFECT))~=0
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(aux.FaceupFilter(Card.IsSetCard,SET_MAVERICK_HUNTER),tp,LOCATION_MZONE,0,nil)
	if #g==0 then return end
	if Duel.Recover(tp,#g*1000,REASON_EFFECT)>0 then
		for tc in aux.Next(g) do
			local e1=Effect.CreateEffect(e:GetHandler())
			e1:SetDescription(3000)
			e1:SetProperty(EFFECT_FLAG_CLIENT_HINT)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_INDESTRUCTABLE_COUNT)
			e1:SetCountLimit(1)
			e1:SetValue(s.indct)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
			tc:RegisterEffect(e1)
		end
	end
end

-- ============================================================
-- GY Trigger Conditions
-- ============================================================
function s.gycon(e,tp,eg,ep,ev,re,r,rp)
	return rp==1-tp
		and Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsSetCard,SET_MAVERICK_HUNTER),tp,LOCATION_MZONE,0,1,nil)
end

function s.atkcon(e,tp,eg,ep,ev,re,r,rp)
	local d=Duel.GetAttackTarget()
	return Duel.GetAttacker():IsControler(1-tp)
		and d and d:IsControler(tp) and d:IsFaceup() and d:IsSetCard(SET_MAVERICK_HUNTER)
end
