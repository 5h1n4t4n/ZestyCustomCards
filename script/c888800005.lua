-- Evernight - Demigod of Time
-- ID: 888800005
local s,id=GetID()

local SET_CHRYSOS_HEIRS = 0xffa
local CARD_ERA_NOVA	 = 888800001

s.listed_series={SET_CHRYSOS_HEIRS}
s.listed_names={CARD_ERA_NOVA}

function s.initial_effect(c)
	-- Pendulum Summon & Ritual Procedure
	Pendulum.AddProcedure(c)
	c:EnableReviveLimit()

	-- Quy tắc: Luôn được coi là lá "Chrysos Heirs"
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_ADD_SETCODE)
	e0:SetValue(SET_CHRYSOS_HEIRS)
	c:RegisterEffect(e0)

	----------------------------------------------------------------------------
	-- PENDULUM EFFECTS
	----------------------------------------------------------------------------
	-- P-Eff 1: Không thể Pendulum Summon
	local pe1=Effect.CreateEffect(c)
	pe1:SetType(EFFECT_TYPE_FIELD)
	pe1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	pe1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	pe1:SetRange(LOCATION_PZONE)
	pe1:SetTargetRange(1,0)
	pe1:SetTarget(s.pendlimit)
	c:RegisterEffect(pe1)

	-- P-Eff 2: Gửi 1 lá đề cập "Era Nova" từ Deck xuống GY & SS lá này từ P-Zone (1 lần/trận)
	local pe2=Effect.CreateEffect(c)
	pe2:SetDescription(aux.Stringid(id,0))
	pe2:SetCategory(CATEGORY_TOGRAVE+CATEGORY_SPECIAL_SUMMON)
	pe2:SetType(EFFECT_TYPE_IGNITION)
	pe2:SetRange(LOCATION_PZONE)
	pe2:SetCountLimit(1,id,EFFECT_COUNT_CODE_DUEL)
	pe2:SetTarget(s.psptg)
	pe2:SetOperation(s.pspop)
	c:RegisterEffect(pe2)

	----------------------------------------------------------------------------
	-- MONSTER EFFECTS
	----------------------------------------------------------------------------
	-- M-Eff 1: Tự SS từ Extra Deck khi "Chrysos Heirs" được SS (1 lần/lượt)
	local me1=Effect.CreateEffect(c)
	me1:SetDescription(aux.Stringid(id,1))
	me1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	me1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	me1:SetProperty(EFFECT_FLAG_DELAY)
	me1:SetCode(EVENT_SPSUMMON_SUCCESS)
	me1:SetRange(LOCATION_EXTRA)
	me1:SetCountLimit(1,id+100)
	me1:SetCondition(s.exspcon)
	me1:SetTarget(s.exsptg)
	me1:SetOperation(s.exspop)
	c:RegisterEffect(me1)

	-- M-Eff 2: Khi bị hiến tế (Tributed): Lấy 1 quái "Chrysos Heirs" hoặc 1 "Era Nova" từ Deck/GY (1 lần/lượt)
	local me2=Effect.CreateEffect(c)
	me2:SetDescription(aux.Stringid(id,2))
	me2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	me2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	me2:SetProperty(EFFECT_FLAG_DELAY)
	me2:SetCode(EVENT_RELEASE)
	me2:SetCountLimit(1,id+200)
	me2:SetTarget(s.thtg)
	me2:SetOperation(s.thop)
	c:RegisterEffect(me2)
end

--------------------------------------------------------------------------------
-- PENDULUM EFFECT LOGIC
--------------------------------------------------------------------------------
function s.pendlimit(e,c,sump,sumtype,sumpos,targetp,se)
	return (sumtype&SUMMON_TYPE_PENDULUM)==SUMMON_TYPE_PENDULUM
end

function s.tgfilter(c)
	return (c:IsCode(CARD_ERA_NOVA) or c:ListsCode(CARD_ERA_NOVA)) 
		and not c:IsCode(id) and c:IsAbleToGrave()
end

function s.psptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	-- Sửa tham số true ở IsCanBeSpecialSummoned để lách Revive Limit
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and c:IsCanBeSpecialSummoned(e,0,tp,false,true)
		and Duel.IsExistingMatchingCard(s.tgfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_DECK)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end

function s.pspop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g=Duel.SelectMatchingCard(tp,s.tgfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 and Duel.SendtoGrave(g,REASON_EFFECT)>0 and g:GetFirst():IsLocation(LOCATION_GRAVE) then
		if c:IsRelateToEffect(e) then
			-- Sửa tham số true ở SpecialSummon
			Duel.SpecialSummon(c,0,tp,tp,false,true,POS_FACEUP)
		end
	end
end

--------------------------------------------------------------------------------
-- MONSTER EFFECT LOGIC
--------------------------------------------------------------------------------
function s.exspcfilter(c,tp)
	return c:IsSetCard(SET_CHRYSOS_HEIRS) and c:IsControler(tp) and c:IsFaceup()
end

function s.exspcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsFaceup() and eg:IsExists(s.exspcfilter,1,nil,tp)
end

function s.exsptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	-- Sửa tham số true ở IsCanBeSpecialSummoned
	if chk==0 then return Duel.GetLocationCountFromEx(tp,tp,nil,c)>0
		and c:IsCanBeSpecialSummoned(e,0,tp,false,true) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end

function s.exspop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) and c:IsFaceup() then
		-- Sửa tham số true ở SpecialSummon
		Duel.SpecialSummon(c,0,tp,tp,false,true,POS_FACEUP)
	end
end

function s.thfilter(c)
	return ((c:IsSetCard(SET_CHRYSOS_HEIRS) and c:IsType(TYPE_MONSTER)) or c:IsCode(CARD_ERA_NOVA))
		and not c:IsCode(id) and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.thfilter),tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end