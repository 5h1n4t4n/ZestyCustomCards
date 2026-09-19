-- Chrysos Heirs: Castorice - Demigod of Death
-- ID: 888800015
local s,id=GetID()

local SET_CHRYSOS_HEIRS = 0xffa
local CARD_ERA_NOVA	 = 888800001

s.listed_series={SET_CHRYSOS_HEIRS}
s.listed_names={CARD_ERA_NOVA}

function s.initial_effect(c)
	-- Fusion / Revive Limit
	c:EnableReviveLimit()

	----------------------------------------------------------------------------
	-- SPECIAL SUMMON PROCEDURE
	-- Xáo 5 lá "Era Nova" hoặc đề cập "Era Nova" từ Field/GY/Banish vào Deck/Extra Deck
	-- Giới hạn: 1 lần/trận (Once per duel)
	----------------------------------------------------------------------------
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_FIELD)
	e0:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_SPSUMMON_PROC)
	e0:SetRange(LOCATION_EXTRA)
	e0:SetCountLimit(1,id,EFFECT_COUNT_CODE_DUEL)
	e0:SetCondition(s.hspcon)
	e0:SetTarget(s.hsptg)
	e0:SetOperation(s.hspop)
	c:RegisterEffect(e0)

	----------------------------------------------------------------------------
	-- EFFECT 1: Bài đưa vào Mộ đối thủ sẽ bị Trục xuất thay thế
	----------------------------------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_SET_AVAILABLE)
	e1:SetCode(EFFECT_TO_GRAVE_REDIRECT)
	e1:SetRange(LOCATION_MZONE)
	e1:SetTargetRange(0,LOCATION_ALL)
	e1:SetValue(LOCATION_REMOVED)
	e1:SetTarget(s.rmtarget)
	c:RegisterEffect(e1)

	----------------------------------------------------------------------------
	-- EFFECT 2: Quick Effect - Trả một nửa LP để Negate & Banish (1 lần/lượt)
	----------------------------------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_NEGATE+CATEGORY_REMOVE)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_CHAINING)
	e2:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DAMAGE_CAL)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,id+100)
	e2:SetCondition(s.negcon)
	e2:SetCost(s.negcost)
	e2:SetTarget(s.negtg)
	e2:SetOperation(s.negop)
	c:RegisterEffect(e2)

	----------------------------------------------------------------------------
	-- EFFECT 3: Khi bị Tributed -> Triệu hồi Ritual "Chrysos Heirs" từ GY/Banish
	----------------------------------------------------------------------------
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e3:SetCode(EVENT_RELEASE)
	e3:SetCountLimit(1,id+200)
	e3:SetTarget(s.sptg)
	e3:SetOperation(s.spop)
	c:RegisterEffect(e3)
end

--------------------------------------------------------------------------------
-- SPECIAL SUMMON PROCEDURE LOGIC
--------------------------------------------------------------------------------
function s.novafilter(c)
	return (c:IsCode(CARD_ERA_NOVA) or c:ListsCode(CARD_ERA_NOVA))
		and c:IsAbleToDeck()
		and (c:IsFaceup() or c:IsLocation(LOCATION_GRAVE))
end

function s.hspcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	local g=Duel.GetMatchingGroup(s.novafilter,tp,LOCATION_ONFIELD+LOCATION_GRAVE+LOCATION_REMOVED,0,nil)
	return #g>=5 and Duel.GetLocationCountFromEx(tp,tp,g,c)>0
end

function s.hsptg(e,tp,eg,ep,ev,re,r,rp,c)
	local g=Duel.GetMatchingGroup(s.novafilter,tp,LOCATION_ONFIELD+LOCATION_GRAVE+LOCATION_REMOVED,0,nil)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	local sg=g:Select(tp,5,5,nil)
	if #sg==5 then
		sg:KeepAlive()
		e:SetLabelObject(sg)
		return true
	end
	return false
end

function s.hspop(e,tp,eg,ep,ev,re,r,rp,c)
	local g=e:GetLabelObject()
	if not g then return end
	Duel.SendtoDeck(g,nil,SEQ_DECKSHUFFLE,REASON_COST+REASON_MATERIAL)
	g:DeleteGroup()
end

--------------------------------------------------------------------------------
-- EFFECT 1 LOGIC
--------------------------------------------------------------------------------
function s.rmtarget(e,c)
	return c:GetOwner()~=e:GetHandlerPlayer()
end

--------------------------------------------------------------------------------
-- EFFECT 2 LOGIC
--------------------------------------------------------------------------------
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	return ep~=tp and Duel.IsChainNegatable(ev)
end

function s.negcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.PayLPCost(tp,math.floor(Duel.GetLP(tp)/2))
end

function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
	if re:GetHandler():IsRelateToEffect(re) and re:GetHandler():IsAbleToRemove() then
		Duel.SetOperationInfo(0,CATEGORY_REMOVE,eg,1,0,0)
	end
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.NegateActivation(ev) and re:GetHandler():IsRelateToEffect(re) then
		Duel.Remove(eg,POS_FACEUP,REASON_EFFECT)
	end
end

--------------------------------------------------------------------------------
-- EFFECT 3 LOGIC
--------------------------------------------------------------------------------
function s.spfilter(c,e,tp)
	return c:IsSetCard(SET_CHRYSOS_HEIRS) and c:IsType(TYPE_RITUAL) and c:IsType(TYPE_MONSTER)
		and not c:IsCode(id)
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_RITUAL,tp,false,true)
		and (c:IsFaceup() or c:IsLocation(LOCATION_GRAVE))
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_GRAVE+LOCATION_REMOVED) and chkc:IsControler(tp) and s.spfilter(chkc,e,tp) end
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingTarget(s.spfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,nil,e,tp) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectTarget(tp,s.spfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,1,nil,e,tp)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,g,1,0,0)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		if Duel.SpecialSummon(tc,SUMMON_TYPE_RITUAL,tp,tp,false,true,POS_FACEUP)>0 then
			tc:CompleteProcedure()
		end
	end
end