--Flower Spirit – Blizzard Lancelot
local s,id=GetID()

function s.initial_effect(c)
	c:EnableReviveLimit()
	--Xyz Summon: 2+ Level 4 monsters
	Xyz.AddProcedure(c,nil,4,2,99)
	--Alternative: 2 Normal Monsters
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_FIELD)
	e0:SetCode(EFFECT_SPSUMMON_PROC)
	e0:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e0:SetRange(LOCATION_EXTRA)
	e0:SetCondition(s.altcon)
	e0:SetTarget(s.alttg)
	e0:SetOperation(s.altop)
	e0:SetValue(SUMMON_TYPE_XYZ)
	c:RegisterEffect(e0)
	--(Quick Effect): Detach 1 material; negate the effect of the first response from opponent
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

function s.nfilter(c,sc,tp)
	return c:IsType(TYPE_NORMAL) and c:IsFaceup() and c:IsCanBeXyzMaterial(sc)
end
function s.altcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	return Duel.GetLocationCountFromEx(tp,tp,nil,c)>0
		and Duel.IsExistingMatchingCard(s.nfilter,tp,LOCATION_MZONE,0,2,nil,c,tp)
end
function s.alttg(e,tp,eg,ep,ev,re,r,rp,c)
	local g=Duel.SelectMatchingCard(tp,s.nfilter,tp,LOCATION_MZONE,0,2,2,nil,c,tp)
	if #g==2 then
		g:KeepAlive()
		e:SetLabelObject(g)
		return true
	end
	return false
end
function s.altop(e,tp,eg,ep,ev,re,r,rp,c)
	local g=e:GetLabelObject()
	if not g then return end
	c:SetMaterial(g)
	Duel.Overlay(c,g)
	g:DeleteGroup()
end

function s.detachcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():CheckRemoveOverlayCard(tp,1,REASON_COST) end
	e:GetHandler():RemoveOverlayCard(tp,1,1,REASON_COST)
end
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
