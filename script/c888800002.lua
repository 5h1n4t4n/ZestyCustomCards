-- Amphoreus' Saga of Heroes
-- ID: 888800002
local s,id=GetID()

local SET_CHRYSOS_HEIRS = 0xffa
local CARD_ERA_NOVA	  = 888800001

s.listed_series={SET_CHRYSOS_HEIRS}
s.listed_names={CARD_ERA_NOVA}

function s.initial_effect(c)
	-- 1. Activate từ tay: Lấy 1 Chrysos Heirs monster và/hoặc 1 Era Nova
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)

	-- 2. Hiệu ứng Dưới Mộ (Quick Effect): Đổi hiệu ứng Spell/Trap đối thủ
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,3))
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_CHAINING)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,id,EFFECT_COUNT_CODE_DUEL)
	e2:SetCondition(s.chcon)
	e2:SetCost(aux.bfgcost)
	e2:SetTarget(s.chtg)
	e2:SetOperation(s.chop)
	c:RegisterEffect(e2)
end

--------------------------------------------------------------------------------
-- EFFECT 1: SEARCH LOGIC
--------------------------------------------------------------------------------
function s.monfilter(c)
	return c:IsSetCard(SET_CHRYSOS_HEIRS) and c:IsType(TYPE_MONSTER) and c:IsAbleToHand()
end

function s.novafilter(c)
	return c:IsCode(CARD_ERA_NOVA) and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.monfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil)
			or Duel.IsExistingMatchingCard(s.novafilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local g1=Duel.GetMatchingGroup(aux.NecroValleyFilter(s.monfilter),tp,LOCATION_DECK+LOCATION_GRAVE,0,nil)
	local g2=Duel.GetMatchingGroup(aux.NecroValleyFilter(s.novafilter),tp,LOCATION_DECK+LOCATION_GRAVE,0,nil)
	if #g1==0 and #g2==0 then return end

	local sg=Group.CreateGroup()
	local opt=0
	
	-- Cho phép người chơi lựa chọn theo điều kiện thực tế
	if #g1>0 and #g2>0 then
		opt=Duel.SelectOption(tp,aux.Stringid(id,0),aux.Stringid(id,1),aux.Stringid(id,2))
	elseif #g1>0 then
		opt=0
	else
		opt=1
	end

	if opt==0 or opt==2 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local sg1=g1:Select(tp,1,1,nil)
		sg:Merge(sg1)
	end
	if opt==1 or opt==2 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local sg2=g2:Select(tp,1,1,nil)
		sg:Merge(sg2)
	end

	if #sg>0 then
		Duel.SendtoHand(sg,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,sg)
	end
end

--------------------------------------------------------------------------------
-- EFFECT 2: CHAIN MODIFICATION IN GY
--------------------------------------------------------------------------------
function s.chcon(e,tp,eg,ep,ev,re,r,rp)
	if rp==tp or not re:IsActiveType(TYPE_SPELL+TYPE_TRAP) or ev<2 then return false end
	local pe,pep=Duel.GetChainInfo(ev-1,CHAININFO_TRIGGERING_EFFECT,CHAININFO_TRIGGERING_PLAYER)
	return pep==tp and pe:GetHandler():IsSetCard(SET_CHRYSOS_HEIRS)
end

function s.chtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
end

function s.chop(e,tp,eg,ep,ev,re,r,rp)
	Duel.ChangeChainOperation(ev,s.repop)
end

function s.repfilter(c)
	return c:IsSetCard(SET_CHRYSOS_HEIRS) and c:IsType(TYPE_MONSTER) and c:IsAbleToHand()
end

function s.repop(e,tp,eg,ep,ev,re,r,rp)
	-- tp ở đây là đối thủ (người kích hoạt hiệu ứng bị ghi đè)
	-- 1-tp là bạn (chủ sở hữu lá bài Chrysos Heirs)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.repfilter,tp,0,LOCATION_DECK,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,tp,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end