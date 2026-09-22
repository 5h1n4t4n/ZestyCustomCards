-- ============================================================
-- Card Name: Vanguard of the Ice Barrier
-- Passcode : 4700003
-- Type     : Monster / Effect
-- Attribute: WATER
-- Level    : 4
-- ATK/DEF  : 1600 / 1200
-- Race     : Warrior
-- Archetype: Ice Barrier (0x2f)
-- ============================================================
-- Effect 1: If you control an "Ice Barrier" monster: You can
--           Special Summon this card from your hand. You can only
--           Special Summon "Vanguard of the Ice Barrier" once
--           per turn this way.
-- Effect 2: While you control another "Ice Barrier" monster,
--           your opponent cannot negate the activations, or the
--           effects, of "Ice Barrier" monsters you control.
-- Effect 3: If this card is sent to the GY as Synchro Material:
--           You can target 1 face-up monster your opponent
--           controls; change its battle position.
-- ============================================================

local s,id=GetID()

function s.initial_effect(c)
	-- Effect 1: Special Summon procedure from hand
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetCondition(s.spcon)
	c:RegisterEffect(e1)

	-- Effect 2: Opponent cannot negate activations or effects of "Ice Barrier" monsters you control
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_CANNOT_INACTIVATE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCondition(s.negcon)
	e2:SetValue(s.efilter)
	c:RegisterEffect(e2)
	local e3=e2:Clone()
	e3:SetCode(EFFECT_CANNOT_DISEFFECT)
	c:RegisterEffect(e3)

	-- Effect 3: Change battle position when sent to GY as Synchro Material
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,1))
	e4:SetCategory(CATEGORY_POSITION)
	e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e4:SetProperty(EFFECT_FLAG_CARD_TARGET+EFFECT_FLAG_DELAY)
	e4:SetCode(EVENT_BE_MATERIAL)
	e4:SetCondition(s.poscon)
	e4:SetTarget(s.postg)
	e4:SetOperation(s.posop)
	c:RegisterEffect(e4)
end

s.listed_series={SET_ICE_BARRIER}

-- ============================================================
-- Effect 1 Logic: Inherent Special Summon from hand
-- ============================================================
function s.spcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsSetCard,SET_ICE_BARRIER),tp,LOCATION_MZONE,0,1,nil)
end

-- ============================================================
-- Effect 2 Logic: Anti-Negate Continuous Protection
-- ============================================================
function s.negcon(e)
	local tp=e:GetHandlerPlayer()
	return Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsSetCard,SET_ICE_BARRIER),
		tp,LOCATION_MZONE,0,1,e:GetHandler())
end

function s.efilter(e,ct)
	local p,te,loc=Duel.GetChainInfo(ct,CHAININFO_TRIGGERING_PLAYER,
		CHAININFO_TRIGGERING_EFFECT,CHAININFO_TRIGGERING_LOCATION)
	return p==e:GetHandlerPlayer() and te:IsMonsterEffect()
		and te:GetHandler():IsSetCard(SET_ICE_BARRIER) and loc&LOCATION_MZONE~=0
end

-- ============================================================
-- Effect 3 Logic: Synchro Material Trigger
-- ============================================================
function s.poscon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsLocation(LOCATION_GRAVE) and r==REASON_SYNCHRO
end

function s.postg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsControler(1-tp) and chkc:IsLocation(LOCATION_MZONE)
			and chkc:IsFaceup() and chkc:IsCanChangePosition()
	end
	if chk==0 then return Duel.IsExistingTarget(aux.FaceupFilter(Card.IsCanChangePosition),tp,0,LOCATION_MZONE,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_POSCHANGE)
	local g=Duel.SelectTarget(tp,aux.FaceupFilter(Card.IsCanChangePosition),tp,0,LOCATION_MZONE,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_POSITION,g,1,0,0)
end

function s.posop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) and tc:IsFaceup() then
		Duel.ChangePosition(tc,POS_FACEUP_DEFENSE,POS_FACEDOWN_DEFENSE,POS_FACEUP_ATTACK,POS_FACEUP_ATTACK)
	end
end
