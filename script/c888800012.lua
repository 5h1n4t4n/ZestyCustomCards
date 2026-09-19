-- Chrysos Heirs: Mydeimos - Demigod of Strife
-- ID: 888800012
local s,id=GetID()

local SET_CHRYSOS_HEIRS = 0xffa

s.listed_series={SET_CHRYSOS_HEIRS}

function s.initial_effect(c)
	c:EnableReviveLimit()

	----------------------------------------------------------------------------
	-- CONTACT FUSION PROCEDURE (Hiến tế 3 quái thú: ít nhất 2 "Chrysos Heirs", ít nhất 1 Effect Monster)
	----------------------------------------------------------------------------
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_FIELD)
	e0:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_SPSUMMON_PROC)
	e0:SetRange(LOCATION_EXTRA)
	e0:SetCondition(s.hspcon)
	e0:SetTarget(s.hsptg)
	e0:SetOperation(s.hspop)
	c:RegisterEffect(e0)

	----------------------------------------------------------------------------
	-- CONTINUOUS EFFECTS
	----------------------------------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
	e1:SetValue(1)
	c:RegisterEffect(e1)

	local e2=e1:Clone()
	e2:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	c:RegisterEffect(e2)

	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCode(EFFECT_UPDATE_ATTACK)
	e3:SetValue(s.atkval)
	c:RegisterEffect(e3)

	----------------------------------------------------------------------------
	-- QUICK EFFECT: Trừ 2000 LP hủy toàn bộ quái đối thủ
	----------------------------------------------------------------------------
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,0))
	e4:SetCategory(CATEGORY_DESTROY)
	e4:SetType(EFFECT_TYPE_QUICK_O)
	e4:SetCode(EVENT_FREE_CHAIN)
	e4:SetRange(LOCATION_MZONE)
	e4:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E)
	e4:SetCountLimit(1,id)
	e4:SetCost(s.descost)
	e4:SetTarget(s.destg)
	e4:SetOperation(s.desop)
	c:RegisterEffect(e4)
end

--------------------------------------------------------------------------------
-- CONTACT FUSION LOGIC (Sử dụng hàm chuẩn EDOPro Group Check)
--------------------------------------------------------------------------------
function s.hspfilter(c,tp)
	return c:IsReleasable() and (c:IsControler(tp) or c:IsFaceup())
end

function s.matfilter(c)
	return c:IsReleasable()
end

function s.rescon(g,e,tp,mg)
	return g:GetCount()==3 
		and g:FilterCount(Card.IsSetCard,nil,SET_CHRYSOS_HEIRS)>=2
		and g:FilterCount(Card.IsType,nil,TYPE_EFFECT)>=1
end

function s.hspcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	local mg=Duel.GetMatchingGroup(s.matfilter,tp,LOCATION_MZONE,LOCATION_MZONE,nil)
	return Duel.GetLocationCountFromEx(tp,tp,nil,c)>0 and aux.SelectUnselectGroup(mg,e,tp,3,3,s.rescon,0)
end

function s.hsptg(e,tp,eg,ep,ev,re,r,rp,c)
	local mg=Duel.GetMatchingGroup(s.matfilter,tp,LOCATION_MZONE,LOCATION_MZONE,nil)
	local g=aux.SelectUnselectGroup(mg,e,tp,3,3,s.rescon,1,tp,HINTMSG_RELEASE,s.rescon,s.rescon)
	if g and g:GetCount()>0 then
		g:KeepAlive()
		e:SetLabelObject(g)
		return true
	end
	return false
end

function s.hspop(e,tp,eg,ep,ev,re,r,rp,c)
	local g=e:GetLabelObject()
	if not g then return end
	Duel.Release(g,REASON_COST+REASON_MATERIAL+REASON_FUSION)
	g:DeleteGroup()
end

--------------------------------------------------------------------------------
-- OTHER EFFECTS
--------------------------------------------------------------------------------
function s.atkval(e,c)
	return Duel.GetLP(c:GetControler())
end

function s.descost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckLPCost(tp,2000) end
	Duel.PayLPCost(tp,2000)
end

function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(nil,tp,0,LOCATION_MZONE,1,nil) end
	local g=Duel.GetMatchingGroup(nil,tp,0,LOCATION_MZONE,nil)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,#g,0,0)
end

function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(nil,tp,0,LOCATION_MZONE,nil)
	if #g>0 then
		Duel.Destroy(g,REASON_EFFECT)
	end
end