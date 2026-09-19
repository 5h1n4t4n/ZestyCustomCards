-- Chrysos Heirs: Hyacinthia - Demigod of Sky
-- ID: 888800011
local s,id=GetID()

local SET_CHRYSOS_HEIRS = 0xffa
local CARD_ERA_NOVA	 = 888800001

s.listed_series={SET_CHRYSOS_HEIRS}
s.listed_names={CARD_ERA_NOVA}

function s.initial_effect(c)
	-- Ritual Monster setup
	c:EnableReviveLimit()

	----------------------------------------------------------------------------
	-- MONSTER EFFECTS
	----------------------------------------------------------------------------
	-- Eff 1: Khi được Triệu hồi Đặc biệt: Hồi 2000 LP (1 lần/lượt)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_RECOVER)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.rectg)
	e1:SetOperation(s.recop)
	c:RegisterEffect(e1)

	-- Eff 2: Khi bị hiến tế (Tributed): Lấy 1 "Era Nova" từ GY lên tay, sau đó có thể Triệu hồi Đặc biệt lá này (1 lần/lượt)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_RELEASE)
	e2:SetCountLimit(1,id+100)
	e2:SetTarget(s.thsptg)
	e2:SetOperation(s.thspop)
	c:RegisterEffect(e2)
end

--------------------------------------------------------------------------------
-- EFFECT 1 LOGIC
--------------------------------------------------------------------------------
function s.rectg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetTargetPlayer(tp)
	Duel.SetTargetParam(2000)
	Duel.SetOperationInfo(0,CATEGORY_RECOVER,nil,0,tp,2000)
end

function s.recop(e,tp,eg,ep,ev,re,r,rp)
	local p,d=Duel.GetChainInfo(0,CHAININFO_TARGET_PLAYER,CHAININFO_TARGET_PARAM)
	Duel.Recover(p,d,REASON_EFFECT)
end

--------------------------------------------------------------------------------
-- EFFECT 2 LOGIC
--------------------------------------------------------------------------------
function s.novafilter(c)
	return c:IsCode(CARD_ERA_NOVA) and c:IsAbleToHand()
end

function s.thsptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return Duel.IsExistingMatchingCard(s.novafilter,tp,LOCATION_GRAVE,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_GRAVE)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end

function s.thspop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.novafilter),tp,LOCATION_GRAVE,0,1,1,nil)
	if #g>0 and Duel.SendtoHand(g,nil,REASON_EFFECT)>0 and g:GetFirst():IsLocation(LOCATION_HAND) then
		Duel.ConfirmCards(1-tp,g)
		-- Đã sửa: Truyền true để bỏ qua Revive Limit khi Special Summon từ Mộ
		if c:IsRelateToEffect(e) and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and c:IsCanBeSpecialSummoned(e,0,tp,false,true)
			and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
			Duel.BreakEffect()
			Duel.SpecialSummon(c,0,tp,tp,false,true,POS_FACEUP)
		end
	end
end