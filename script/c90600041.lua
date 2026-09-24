-- ============================================================
-- Card Name: Sky Striker Special Maneuver - The Chosen One
-- Passcode : 90600041
-- Type     : Spell / Quick-Play
-- Archetype: Sky Striker (0x115)
-- ============================================================
-- Effect 1 (Quick-Play Activation):
-- During the Standby Phase of each turn: You can declare 1 Monster Type;
-- neither player can activate the effects of monsters of that declared Type
-- for the rest of this turn. If this card is activated: You can only activate
-- the effects of "Sky Striker" monsters for the rest of this duel.
--
-- Effect 2 (GY Ignition):
-- During your Main Phase: You can banish this card from your GY;
-- add 1 "Sky Striker" Spell from your Deck to your hand.
--
-- Effect 3 (GY Trigger):
-- If a "Sky Striker" monster you control battles an opponent's monster while
-- you have 3 or more Spells in your GY: You can target 1 card your opponent
-- controls; destroy it.
--
-- OPT clause:
-- You can only use each effect of "Sky Striker Special Maneuver - The Chosen One" once per turn.
-- ============================================================

local s,id=GetID()

function s.initial_effect(c)
	-- Effect 1: Standby Phase activation
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.actcon)
	e1:SetTarget(s.acttg)
	e1:SetOperation(s.actop)
	c:RegisterEffect(e1)

	-- Effect 2: Banish from GY to search 1 Sky Striker Spell
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,{id,1})
	e2:SetCost(aux.bfgcost)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)

	-- Effect 3: When a Sky Striker monster battles an opponent's monster (while 3+ Spells in GY)
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_DESTROY)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_BATTLE_START)
	e3:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e3:SetRange(LOCATION_GRAVE)
	e3:SetCountLimit(1,{id,2})
	e3:SetCondition(s.descon)
	e3:SetTarget(s.destg)
	e3:SetOperation(s.desop)
	c:RegisterEffect(e3)
end

s.listed_series={SET_SKY_STRIKER}
s.listed_names={id}

-- ============================================================
-- Effect 1: Standby Phase activation & Duel lock
-- ============================================================
function s.actcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsStandbyPhase()
end

function s.acttg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RACE)
	local rc=Duel.AnnounceRace(tp,1,RACE_ALL)
	e:SetLabel(rc)
end

function s.actop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local rc=e:GetLabel()

	-- Neither player can activate the effects of monsters of that declared Type for the rest of this turn
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,3))
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT)
	e1:SetCode(EFFECT_CANNOT_ACTIVATE)
	e1:SetTargetRange(1,1)
	e1:SetValue(s.aclimit)
	e1:SetLabel(rc)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)

	-- If this card is activated: You can only activate the effects of "Sky Striker" monsters for the rest of this duel
	aux.RegisterClientHint(c,nil,tp,1,0,aux.Stringid(id,4))
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e2:SetCode(EFFECT_CANNOT_ACTIVATE)
	e2:SetTargetRange(1,0)
	e2:SetValue(s.duellimit)
	Duel.RegisterEffect(e2,tp)
end

function s.aclimit(e,re,tp)
	local rc=e:GetLabel()
	return re:IsActiveType(TYPE_MONSTER) and re:GetHandler():IsRace(rc)
end

function s.duellimit(e,re,tp)
	return re:IsActiveType(TYPE_MONSTER) and not re:GetHandler():IsSetCard(SET_SKY_STRIKER)
end

-- ============================================================
-- Effect 2: Search Sky Striker Spell
-- ============================================================
function s.thfilter(c)
	return c:IsSetCard(SET_SKY_STRIKER) and c:IsSpell() and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end

-- ============================================================
-- Effect 3: Destroy opponent's card when Sky Striker battles
-- ============================================================
function s.descon(e,tp,eg,ep,ev,re,r,rp)
	local a=Duel.GetAttacker()
	local d=Duel.GetAttackTarget()
	if not d then return false end
	if d:IsControler(tp) then a,d=d,a end
	return a:IsControler(tp) and a:IsFaceup() and a:IsSetCard(SET_SKY_STRIKER) and d:IsControler(1-tp)
		and Duel.GetMatchingGroupCount(Card.IsSpell,tp,LOCATION_GRAVE,0,nil)>=3
end

function s.destg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsOnField() and chkc:IsControler(1-tp) end
	if chk==0 then return Duel.IsExistingTarget(aux.TRUE,tp,0,LOCATION_ONFIELD,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectTarget(tp,aux.TRUE,tp,0,LOCATION_ONFIELD,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
end

function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		Duel.Destroy(tc,REASON_EFFECT)
	end
end
