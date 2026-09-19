-- Phainon: Khaslana Demigod of Worldbearing
-- ID: 888800016
local s,id=GetID()

local SET_CHRYSOS_HEIRS = 0xffa
local CARD_ERA_NOVA	 = 888800001

s.listed_series={SET_CHRYSOS_HEIRS}
s.listed_names={CARD_ERA_NOVA}

function s.initial_effect(c)
	-- Fusion Procedure & Revive Limit
	c:EnableReviveLimit()
	Fusion.AddProcMix(c,true,true,s.mat1,s.mat2,s.mat3)

	-- Quy tắc: Luôn được coi là lá "Chrysos Heirs"
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_ADD_SETCODE)
	e0:SetValue(SET_CHRYSOS_HEIRS)
	c:RegisterEffect(e0)

	----------------------------------------------------------------------------
	-- SPECIAL SUMMON PROCEDURE
	-- Tributed 1 Ritual + 1 Fusion + 1 Pendulum "Chrysos Heirs" từ Field (1 lần/trận)
	----------------------------------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetRange(LOCATION_EXTRA)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_DUEL)
	e1:SetCondition(s.hspcon)
	e1:SetTarget(s.hsptg)
	e1:SetOperation(s.hspop)
	c:RegisterEffect(e1)

	----------------------------------------------------------------------------
	-- EFFECT 1: Miễn nhiễm hiệu ứng ngoại trừ "Era Nova" hoặc đề cập "Era Nova"
	----------------------------------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCode(EFFECT_IMMUNE_EFFECT)
	e2:SetValue(s.efilter)
	c:RegisterEffect(e2)

	----------------------------------------------------------------------------
	-- EFFECT 2: Quick Effect - Trả nửa LP + Tribute 1 "Chrysos Heirs" từ Hand/Deck
	-- -> Gửi toàn bộ card đối thủ kiểm soát xuống GY (1 lần/trận)
	----------------------------------------------------------------------------
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetCategory(CATEGORY_TOGRAVE)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,id+100,EFFECT_COUNT_CODE_DUEL)
	e3:SetCost(s.tgcost)
	e3:SetTarget(s.tgtg)
	e3:SetOperation(s.tgop)
	c:RegisterEffect(e3)

	----------------------------------------------------------------------------
	-- EFFECT 3: Khi bị Tributed -> Triệu hồi tối đa mỗi loại 1 quái Ritual,
	-- Fusion, Pendulum "Chrysos Heirs" từ Hand/GY/Banish/Extra (1 lần/trận)
	----------------------------------------------------------------------------
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,1))
	e4:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e4:SetProperty(EFFECT_FLAG_DELAY)
	e4:SetCode(EVENT_RELEASE)
	e4:SetCountLimit(1,id+200,EFFECT_COUNT_CODE_DUEL)
	e4:SetTarget(s.sptg)
	e4:SetOperation(s.spop)
	c:RegisterEffect(e4)
end

--------------------------------------------------------------------------------
-- FUSION MATERIAL DEFINITIONS
--------------------------------------------------------------------------------
function s.mat1(c) return c:IsSetCard(SET_CHRYSOS_HEIRS) and c:IsType(TYPE_RITUAL) end
function s.mat2(c) return c:IsSetCard(SET_CHRYSOS_HEIRS) and c:IsType(TYPE_FUSION) end
function s.mat3(c) return c:IsSetCard(SET_CHRYSOS_HEIRS) and c:IsType(TYPE_PENDULUM) end

--------------------------------------------------------------------------------
-- SPECIAL SUMMON PROCEDURE LOGIC
--------------------------------------------------------------------------------
function s.hspfilter(c)
	return c:IsSetCard(SET_CHRYSOS_HEIRS) and c:IsReleasable()
		and (c:IsType(TYPE_RITUAL) or c:IsType(TYPE_FUSION) or c:IsType(TYPE_PENDULUM))
end

function s.rescon(sg,e,tp,mg)
	if #sg~=3 then return false end
	local g1=sg:Filter(s.mat1,nil)
	local g2=sg:Filter(s.mat2,nil)
	local g3=sg:Filter(s.mat3,nil)
	local valid=false
	for c1 in g1:Iter() do
		for c2 in g2:Iter() do
			if c2~=c1 then
				for c3 in g3:Iter() do
					if c3~=c1 and c3~=c2 then
						valid=true
						break
					end
				end
			end
			if valid then break end
		end
		if valid then break end
	end
	return valid and Duel.GetLocationCountFromEx(tp,tp,sg,e:GetHandler())>0
end

function s.hspcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	local g=Duel.GetMatchingGroup(s.hspfilter,tp,LOCATION_ONFIELD,0,nil)
	return aux.SelectUnselectGroup(g,e,tp,3,3,s.rescon,0)
end

function s.hsptg(e,tp,eg,ep,ev,re,r,rp,c)
	local g=Duel.GetMatchingGroup(s.hspfilter,tp,LOCATION_ONFIELD,0,nil)
	local sg=aux.SelectUnselectGroup(g,e,tp,3,3,s.rescon,1,tp,HINTMSG_RELEASE)
	if #sg==3 then
		sg:KeepAlive()
		e:SetLabelObject(sg)
		return true
	end
	return false
end

function s.hspop(e,tp,eg,ep,ev,re,r,rp,c)
	local g=e:GetLabelObject()
	if not g then return end
	Duel.Release(g,REASON_COST+REASON_MATERIAL)
	g:DeleteGroup()
end

--------------------------------------------------------------------------------
-- IMMUNITY LOGIC
--------------------------------------------------------------------------------
function s.efilter(e,te)
	local tc=te:GetHandler()
	return not (tc:IsCode(CARD_ERA_NOVA) or tc:ListsCode(CARD_ERA_NOVA))
end

--------------------------------------------------------------------------------
-- EFFECT 2 LOGIC (QUICK EFFECT)
--------------------------------------------------------------------------------
function s.cfilter(c)
	return c:IsSetCard(SET_CHRYSOS_HEIRS) and c:IsType(TYPE_MONSTER) and c:IsReleasable()
end

function s.tgcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckLPCost(tp,1)
		and Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_HAND+LOCATION_DECK,0,1,nil) end
	Duel.PayLPCost(tp,math.floor(Duel.GetLP(tp)/2))
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
	local g=Duel.SelectMatchingCard(tp,s.cfilter,tp,LOCATION_HAND+LOCATION_DECK,0,1,1,nil)
	Duel.SendtoGrave(g,REASON_COST+REASON_RELEASE)
end

function s.tgtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local g=Duel.GetMatchingGroup(nil,tp,0,LOCATION_ONFIELD,nil)
	if chk==0 then return #g>0 end
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,g,#g,0,0)
end

function s.tgop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(nil,tp,0,LOCATION_ONFIELD,nil)
	if #g>0 then
		Duel.SendtoGrave(g,REASON_EFFECT)
	end
end

--------------------------------------------------------------------------------
-- EFFECT 3 LOGIC (ON TRIBUTED)
--------------------------------------------------------------------------------
function s.spfilter(c,e,tp,type_flag)
	if not (c:IsSetCard(SET_CHRYSOS_HEIRS) and c:IsType(TYPE_MONSTER) and c:IsType(type_flag)) then return false end
	if c:IsLocation(LOCATION_EXTRA) and not c:IsFaceup() then return false end
	if c:IsLocation(LOCATION_REMOVED) and not c:IsFaceup() then return false end
	if not c:IsCanBeSpecialSummoned(e,0,tp,true,false) then return false end
	if c:IsLocation(LOCATION_EXTRA) then
		return Duel.GetLocationCountFromEx(tp,tp,nil,c)>0
	else
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
	end
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local loc=LOCATION_HAND+LOCATION_GRAVE+LOCATION_REMOVED+LOCATION_EXTRA
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.spfilter,tp,loc,0,1,nil,e,tp,TYPE_RITUAL)
			or Duel.IsExistingMatchingCard(s.spfilter,tp,loc,0,1,nil,e,tp,TYPE_FUSION)
			or Duel.IsExistingMatchingCard(s.spfilter,tp,loc,0,1,nil,e,tp,TYPE_PENDULUM)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,loc)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local loc=LOCATION_HAND+LOCATION_GRAVE+LOCATION_REMOVED+LOCATION_EXTRA
	local sg=Group.CreateGroup()

	-- 1. Ritual Monster
	local g1=Duel.GetMatchingGroup(s.spfilter,tp,loc,0,sg,e,tp,TYPE_RITUAL)
	if #g1>0 and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local sc1=g1:Select(tp,1,1,nil):GetFirst()
		if sc1 then sg:AddCard(sc1) end
	end

	-- 2. Fusion Monster
	local g2=Duel.GetMatchingGroup(s.spfilter,tp,loc,0,sg,e,tp,TYPE_FUSION)
	if #g2>0 and (#sg==0 or Duel.SelectYesNo(tp,aux.Stringid(id,3))) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local sc2=g2:Select(tp,1,1,nil):GetFirst()
		if sc2 then sg:AddCard(sc2) end
	end

	-- 3. Pendulum Monster
	local g3=Duel.GetMatchingGroup(s.spfilter,tp,loc,0,sg,e,tp,TYPE_PENDULUM)
	if #g3>0 and (#sg==0 or Duel.SelectYesNo(tp,aux.Stringid(id,4))) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local sc3=g3:Select(tp,1,1,nil):GetFirst()
		if sc3 then sg:AddCard(sc3) end
	end

	if #sg>0 then
		Duel.SpecialSummon(sg,0,tp,tp,true,false,POS_FACEUP)
	end
end