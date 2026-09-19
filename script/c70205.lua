--Flower Spirit – Blizzard Lancelot
local s,id=GetID()

function s.initial_effect(c)
	c:EnableReviveLimit()
	--Xyz Summon: 2+ Level 4 monsters
	--Hoặc Xyz Summon bằng 2 Normal Monsters
	Xyz.AddProcedure(c,nil,4,2,s.ovfilter,aux.Stringid(id,2),Xyz.InfiniteMats,s.xyzop)

	--(Quick Effect): Detach 1 material; negate the first response from opponent
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1,id)
	e1:SetCost(s.detachcost)
	e1:SetOperation(s.negsetop)
	c:RegisterEffect(e1)

	--(Quick Effect): When a Spell is activated: target it; attach to this card
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_CHAINING)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,id+100)
	e2:SetCondition(s.atcon)
	e2:SetTarget(s.attg)
	e2:SetOperation(s.atop)
	c:RegisterEffect(e2)
end

--Filter check alternative overlay bằng 2 Normal Monsters
function s.ovfilter(c,tp,xyzc)
	return c:IsFaceup() and c:IsType(TYPE_NORMAL) and c:IsCanBeXyzMaterial(xyzc)
end
function s.xyzop(e,tp,chk,mc)
	if chk==0 then return Duel.GetFlagEffect(tp,id)==0 end
	Duel.RegisterFlagEffect(tp,id,RESET_PHASE+PHASE_END,0,1)
	return true
end

--Detach cost
function s.detachcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():CheckRemoveOverlayCard(tp,1,REASON_COST) end
	e:GetHandler():RemoveOverlayCard(tp,1,1,REASON_COST)
end

--Negate first response
function s.negsetop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_CHAINING)
	e1:SetReset(RESET_PHASE+PHASE_END)
	e1:SetOperation(s.chainop)
	Duel.RegisterEffect(e1,tp)
end
function s.chainop(e,tp,eg,ep,ev,re,r,rp)
	if ep==1-tp then
		Duel.NegateEffect(ev)
		e:Reset()
	end
end

--Attach activated Spell
function s.atcon(e,tp,eg,ep,ev,re,r,rp)
	return re:IsActiveType(TYPE_SPELL)
end
function s.attg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc==re:GetHandler() end
	if chk==0 then return re:GetHandler():IsCanBeEffectTarget(e) end
	Duel.SetTargetCard(re:GetHandler())
end
function s.atop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if c:IsRelateToEffect(e) and tc and tc:IsRelateToEffect(e) and not tc:IsImmuneToEffect(e) then
		tc:CancelToGrave()
		Duel.Overlay(c,tc)
	end
end
