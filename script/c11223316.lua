-- ============================================================
-- Card Name: Maverick Boost - Raijingeki
-- Passcode : 11223316
-- Type     : Spell / Normal
-- Archetype: Maverick Boost (0x304)
-- ============================================================
-- Effect 1: Target 1 "Maverick Hunter" monster you control; it gains
--           1000 ATK. If you control a "Zero" monster, the targeted
--           monster gains these effects until the end of this turn:
--           ● At the start of the Damage Step, if this card battles
--             an opponent's monster: You can return the opponent's
--             monster to the hand.
--           ● Its attacks cannot be negated.
-- You can only activate 1 "Maverick Boost - Raijingeki" per turn.
-- ============================================================

Duel.LoadScript("constants.lua")
local s,id=GetID()

function s.initial_effect(c)
	-- ============================================================
	-- Effect 1 — Activation: Target "Maverick Hunter" to boost ATK & grant effects
	-- ============================================================
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_ATKCHANGE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

s.listed_series={SET_MAVERICK_HUNTER,SET_ZERO,SET_MAVERICK_BOOST}

-- ============================================================
-- Effect 1 Logic
-- ============================================================
function s.filter(c)
	return c:IsFaceup() and c:IsSetCard(SET_MAVERICK_HUNTER)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(tp) and s.filter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.filter,tp,LOCATION_MZONE,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	Duel.SelectTarget(tp,s.filter,tp,LOCATION_MZONE,0,1,1,nil)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if not tc or not tc:IsRelateToEffect(e) or tc:IsFacedown() then return end
	local c=e:GetHandler()
	-- ATK gain
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_UPDATE_ATTACK)
	e1:SetValue(1000)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD)
	tc:RegisterEffect(e1)
	-- If control "Zero" monster: gains extra effects
	if Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsSetCard,SET_ZERO),tp,LOCATION_MZONE,0,1,nil) then
		-- Bounce at start of damage step
		local e2=Effect.CreateEffect(c)
		e2:SetDescription(aux.Stringid(id,1))
		e2:SetCategory(CATEGORY_TOHAND)
		e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
		e2:SetCode(EVENT_BATTLE_START)
		e2:SetTarget(s.bouncetg)
		e2:SetOperation(s.bounceop)
		e2:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		tc:RegisterEffect(e2)
		-- Attacks cannot be negated
		local e3=Effect.CreateEffect(c)
		e3:SetType(EFFECT_TYPE_SINGLE)
		e3:SetCode(EFFECT_UNSTOPPABLE_ATTACK)
		e3:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		tc:RegisterEffect(e3)
	end
end

function s.bouncetg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	local bc=c:GetBattleTarget()
	if chk==0 then return bc and bc:IsControler(1-tp) and bc:IsAbleToHand() end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,bc,1,0,0)
end

function s.bounceop(e,tp,eg,ep,ev,re,r,rp)
	local bc=e:GetHandler():GetBattleTarget()
	if bc and bc:IsRelateToBattle() then
		Duel.SendtoHand(bc,nil,REASON_EFFECT)
	end
end
