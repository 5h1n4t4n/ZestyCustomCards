--Maiden of Flower Spirit
local s,id=GetID()

function s.initial_effect(c)
	--You can only activate this card while you have at least 1 "Flower Spirit" card in your GY
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.actcon)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
	--While you control a "Flower Spirit" monster or "Flower Spirit Token", opponent
	--cannot activate cards/effects in response to your Spell Card activations during
	--your Main Phase
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_CANNOT_CHAIN)
	e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e2:SetRange(LOCATION_SZONE)
	e2:SetTargetRange(0,1)
	e2:SetCondition(s.chaincon)
	e2:SetValue(s.chainlimit)
	c:RegisterEffect(e2)
	--Once per turn: shuffle 3 "Flower Spirit" cards from GY/banishment into the Deck; draw 1
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_SZONE)
	e3:SetCountLimit(1,id+1)
	e3:SetCost(s.drcost)
	e3:SetTarget(s.drtg)
	e3:SetOperation(s.drop)
	c:RegisterEffect(e3)
	--If there are no "Flower Spirit" Spell Cards in your GY: send this card to the GY
	--NOTE: this is a continuous self-check with no single natural trigger event; it is
	--approximated here via EVENT_CHAIN_END (re-checked whenever a chain resolves).
	--Please test the timing and adjust if your engine has a more suitable hook.
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_FIELD)
	e4:SetCode(EVENT_CHAIN_END)
	e4:SetRange(LOCATION_SZONE)
	e4:SetCondition(s.selfcon)
	e4:SetOperation(s.selfop)
	c:RegisterEffect(e4)
end

function s.gyspiritfilter(c)
	return c:IsSetCard(0x702)
end
function s.actcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(s.gyspiritfilter,tp,LOCATION_GRAVE,0,1,nil)
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
end

--Opponent cannot chain to your Spell Cards during your Main Phase while you control
--a "Flower Spirit" monster or Token
function s.mzfilter(c)
	return c:IsSetCard(0x702) or c:IsCode(70213)
end
function s.chaincon(e)
	local tp=e:GetHandlerPlayer()
	return (Duel.GetCurrentPhase()==PHASE_MAIN1 or Duel.GetCurrentPhase()==PHASE_MAIN2)
		and Duel.IsExistingMatchingCard(s.mzfilter,tp,LOCATION_MZONE,0,1,nil)
end
function s.chainlimit(e,re,tp)
	return re:GetHandlerPlayer()==e:GetHandlerPlayer() and re:GetHandler():GetType()&TYPE_SPELL==TYPE_SPELL
end

function s.rmfilter(c)
	return c:IsSetCard(0x702) and c:IsAbleToDeckAsCost()
end
function s.drcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.rmfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,3,nil) end
	local g=Duel.SelectMatchingCard(tp,s.rmfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,3,3,nil)
	Duel.SendtoDeck(g,nil,SEQ_DECKSHUFFLE,REASON_COST)
end
function s.drtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsPlayerCanDraw(tp,1) end
	Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,1)
end
function s.drop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Draw(tp,1,REASON_EFFECT)
end

function s.spellgyfilter(c)
	return c:IsSetCard(0x702) and c:IsType(TYPE_SPELL)
end
function s.selfcon(e,tp,eg,ep,ev,re,r,rp)
	return not Duel.IsExistingMatchingCard(s.spellgyfilter,tp,LOCATION_GRAVE,0,1,nil)
end
function s.selfop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) and c:IsFaceup() then
		Duel.SendtoGrave(c,REASON_EFFECT)
	end
end
