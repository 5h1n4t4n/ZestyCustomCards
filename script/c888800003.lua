-- Vortex of Genesis
-- ID: 888800003
local s,id=GetID()

local SET_CHRYSOS_HEIRS = 0xffa
local CARD_ERA_NOVA	 = 888800001
local COUNTER_CHRYSOS   = 0x1ffa -- Mã Counter (Chrysos Counter)

s.listed_series={SET_CHRYSOS_HEIRS}
s.listed_names={CARD_ERA_NOVA}

function s.initial_effect(c)
	c:EnableCounterPermit(COUNTER_CHRYSOS)
	c:SetCounterLimit(COUNTER_CHRYSOS,12)

	-- Kích hoạt lá bài (Continuous Spell)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e1)

	-- Đặt Counter khi Triệu hồi Đặc biệt quái thú "Chrysos Heirs"
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetRange(LOCATION_SZONE)
	e2:SetCondition(s.ctcon)
	e2:SetOperation(s.ctop)
	c:RegisterEffect(e2)

	-- Hiệu ứng kích hoạt (1 trong 2 hiệu ứng, 1 lần/lượt)
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_SZONE)
	e3:SetCountLimit(1,id)
	e3:SetTarget(s.efftg)
	e3:SetOperation(s.effop)
	c:RegisterEffect(e3)
end

--------------------------------------------------------------------------------
-- COUNTER PLACEMENT LOGIC
--------------------------------------------------------------------------------
function s.ctfilter(c,tp)
	return c:IsSetCard(SET_CHRYSOS_HEIRS) and c:IsControler(tp) and c:IsFaceup()
end

function s.ctcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.ctfilter,1,nil,tp)
end

function s.ctop(e,tp,eg,ep,ev,re,r,rp)
	e:GetHandler():AddCounter(COUNTER_CHRYSOS,1)
end

--------------------------------------------------------------------------------
-- IGNITION EFFECT LOGIC
--------------------------------------------------------------------------------
function s.thfilter(c)
	return (c:IsCode(CARD_ERA_NOVA) or c:ListsCode(CARD_ERA_NOVA))
		and not c:IsCode(id) and c:IsAbleToHand()
end

function s.efftg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	local b1=Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil)
	local b2=c:GetCounter(COUNTER_CHRYSOS)>0
	if chk==0 then return b1 or b2 end
	local opt=0
	if b1 and b2 then
		opt=Duel.SelectOption(tp,aux.Stringid(id,0),aux.Stringid(id,1))
	elseif b1 then
		opt=Duel.SelectOption(tp,aux.Stringid(id,0))
	else
		opt=Duel.SelectOption(tp,aux.Stringid(id,1))+1
	end
	e:SetLabel(opt)
	if opt==0 then
		e:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
		Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
	else
		e:SetCategory(CATEGORY_RECOVER)
		local count=c:GetCounter(COUNTER_CHRYSOS)
		Duel.SetOperationInfo(0,CATEGORY_RECOVER,nil,0,tp,count*300)
	end
end

function s.effop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local opt=e:GetLabel()
	if opt==0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.thfilter),tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil)
		if #g>0 then
			Duel.SendtoHand(g,nil,REASON_EFFECT)
			Duel.ConfirmCards(1-tp,g)
		end
	elseif opt==1 then
		if not c:IsRelateToEffect(e) then return end
		local count=c:GetCounter(COUNTER_CHRYSOS)
		if count>0 and c:RemoveCounter(tp,COUNTER_CHRYSOS,count,REASON_EFFECT) then
			Duel.Recover(tp,count*300,REASON_EFFECT)
		end
	end
end