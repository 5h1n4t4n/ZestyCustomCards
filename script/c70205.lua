--Flower Spirit – Blizzard Lancelot
local s,id=GetID()

function s.initial_effect(c)
	--Xyz Summon: 2+ Level 4 monsters
	aux.AddXyzProcedure(c,aux.TRUE,2,99,4)
	--Alternative material: 2 Normal Monsters (regardless of Level)
	aux.AddXyzProcedure(c,Card.IsNormal,2,2,0)
	--(Quick Effect): Detach 1 material; negate the effect of the first card/effect your
	--opponent activates in response
	--NOTE: "the first card/effect they activate in response" is approximated with a
	--temporary registered effect watching for the opponent's next chain link. Please
	--test this carefully, timing edge cases may need engine-specific adjustment.
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1,id)
	e1:SetCost(s.detachcost)
	e1:SetTarget(s.negsettg)
	e1:SetOperation(s.negsetop)
	c:RegisterEffect(e1)
	--(Quick Effect): When a Spell Card is activated: target that card; attach it to this
	--card as material
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_CHAINING)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,id+1)
	e2:SetCondition(s.atcon)
	e2:SetTarget(s.attg)
	e2:SetOperation(s.atop)
	c:RegisterEffect(e2)
end

function s.detachcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():GetOverlayCount()>0 end
	Duel.RemoveOverlayCard(tp,0,1,1,1,REASON_COST)
end
function s.negsettg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
end
function s.negsetop(e,tp,eg,ep,ev,re,r,rp)
	local te=Effect.CreateEffect(e:GetHandler())
	te:SetType(EFFECT_TYPE_FIELD)
	te:SetCode(EVENT_CHAINING)
	te:SetRange(LOCATION_MZONE)
	te:SetCountLimit(1)
	te:SetCondition(function(te,tp2,eg2,ep2,ev2,re2,r2,rp2)
		return re2:GetHandlerPlayer()==1-tp and Duel.IsChainNegatable(ev2)
	end)
	te:SetOperation(function(te,tp2,eg2,ep2,ev2,re2,r2,rp2)
		Duel.NegateActivation(ev2)
		Duel.Reset(te)
	end)
	te:SetReset(RESET_PHASE+PHASE_END,1)
	Duel.RegisterEffect(te,tp)
end

--When a Spell Card is activated: target it, negate it, attach it to this card as material
function s.atcon(e,tp,eg,ep,ev,re,r,rp)
	return re:GetHandler():GetType()&TYPE_SPELL==TYPE_SPELL and Duel.IsChainNegatable(ev)
end
function s.attg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,re:GetHandler(),1,0,0)
end
function s.atop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=re:GetHandler()
	if Duel.NegateActivation(ev) and tc:IsRelateToEffect(re) and c:IsRelateToEffect(e) and c:IsFaceup() then
		Duel.Overlay(c,tc)
	end
end
