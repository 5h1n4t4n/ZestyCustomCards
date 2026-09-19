--Xiahou Dun - Steelbound Vanguard
--ID: 99900128
local s,id=GetID()
s.listed_series={0xb4c}
s.caocao_id=99900109 -- ID chuẩn của Cao Cao

function s.initial_effect(c)
	c:EnableReviveLimit()
	
	--Effect 1: Special Summon Procedure (Send LV8)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE+EFFECT_FLAG_SPSUM_PARAM)
	e1:SetRange(LOCATION_HAND)
	e1:SetTargetRange(POS_FACEUP_ATTACK,0)
	e1:SetCondition(s.spcon)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	--Effect 2: Counter Negate (Response to Mecha Three Kingdom)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_NEGATE)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_CHAINING)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1)
	e2:SetCondition(s.negcon)
	e2:SetCost(s.negcost)
	e2:SetTarget(s.negtg)
	e2:SetOperation(s.negop)
	c:RegisterEffect(e2)

	--Effect 3: Hand Boost (+2500 ATK)
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_ATKCHANGE)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetRange(LOCATION_HAND)
	e3:SetCountLimit(1)
	e3:SetCost(s.atkcost)
	e3:SetTarget(s.atktg)
	e3:SetOperation(s.atkop)
	c:RegisterEffect(e3)
end

---------------------------
-- EFFECT 1: SPECIAL SUMMON
---------------------------

-- Hàm lọc Cao Cao thay thế cho aux.FaceupFilter
function s.filter_caocao(c)
	return c:IsFaceup() and c:IsCode(s.caocao_id)
end

function s.spfilter(c,tp)
	-- Level 8, Sendable to Grave
	return c:IsLevel(8) and c:IsAbleToGraveAsCost()
		and (c:IsControler(tp) or c:IsFaceup()) -- Nếu là quái đối thủ thì phải face-up mới check được Level
end

function s.spcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	
	local loc=LOCATION_MZONE
	local opp_loc=0
	
	-- SỬA: Dùng hàm s.filter_caocao thay vì aux.FaceupFilter
	if Duel.IsExistingMatchingCard(s.filter_caocao,tp,LOCATION_ONFIELD,0,1,nil) then
		opp_loc=LOCATION_MZONE
	end
	
	local g=Duel.GetMatchingGroup(s.spfilter,tp,loc,opp_loc,nil,tp)
	return g:GetCount()>0 and Duel.GetLocationCount(tp,LOCATION_MZONE)>-1
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk,c)
	local loc=LOCATION_MZONE
	local opp_loc=0
	
	-- SỬA: Dùng hàm s.filter_caocao thay vì aux.FaceupFilter
	if Duel.IsExistingMatchingCard(s.filter_caocao,tp,LOCATION_ONFIELD,0,1,nil) then
		opp_loc=LOCATION_MZONE
	end
	
	local g=Duel.GetMatchingGroup(s.spfilter,tp,loc,opp_loc,nil,tp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local sg=g:Select(tp,1,1,nil)
	if sg:GetCount()>0 then
		sg:KeepAlive()
		e:SetLabelObject(sg)
		return true
	end
	return false
end

function s.spop(e,tp,eg,ep,ev,re,r,rp,c)
	local g=e:GetLabelObject()
	if not g then return end
	Duel.SendtoGrave(g,REASON_COST)
	g:DeleteGroup()
end

---------------------------
-- EFFECT 2: NEGATE (RESPONSE)
---------------------------
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	-- 1. Đối thủ kích hoạt Effect Monster
	if not (rp==1-tp and re:IsActiveType(TYPE_MONSTER) and Duel.IsChainNegatable(ev)) then return false end
	
	-- 2. Kiểm tra Chain Link trước đó
	if ev<=1 then return false end
	local te_prev,p_prev=Duel.GetChainInfo(ev-1,CHAININFO_TRIGGERING_EFFECT,CHAININFO_TRIGGERING_PLAYER)
	
	if not te_prev or p_prev~=tp then return false end
	local tc_prev=te_prev:GetHandler()
	
	-- Check: Chain trước là Monster + Archetype Mecha Three Kingdom
	return te_prev:IsActiveType(TYPE_MONSTER) and tc_prev:IsSetCard(0xb4c)
end

function s.costfilter(c)
	-- Filter này không cần sửa vì IsSetCard MDPro3 hiểu được
	return c:IsSetCard(0xb4c) and c:IsType(TYPE_SPELL+TYPE_TRAP) and c:IsAbleToRemoveAsCost()
end

function s.negcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsAbleToRemoveAsCost()
		and Duel.IsExistingMatchingCard(s.costfilter,tp,LOCATION_ONFIELD+LOCATION_HAND+LOCATION_GRAVE,0,1,c) end
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectMatchingCard(tp,s.costfilter,tp,LOCATION_ONFIELD+LOCATION_HAND+LOCATION_GRAVE,0,1,1,c)
	g:AddCard(c)
	Duel.Remove(g,POS_FACEUP,REASON_COST)
end

function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)
	Duel.NegateActivation(ev)
end

---------------------------
-- EFFECT 3: HAND BOOST
---------------------------
function s.atkcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsAbleToGraveAsCost() end
	Duel.SendtoGrave(c,REASON_COST)
end

function s.atkfilter(c)
	return c:IsFaceup() and c:IsSetCard(0xb4c)
end

function s.atktg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.atkfilter,tp,LOCATION_MZONE,0,1,nil) end
end

function s.atkop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(s.atkfilter,tp,LOCATION_MZONE,0,nil)
	local tc=g:GetFirst()
	while tc do
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_ATTACK)
		e1:SetValue(2500)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		tc:RegisterEffect(e1)
		tc=g:GetNext()
	end
end