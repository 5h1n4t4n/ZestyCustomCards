-- Cyrene - Demigod of Time, Genesis
-- ID: 888800017
local s,id=GetID()

local SET_CHRYSOS_HEIRS = 0xffa
local CARD_ERA_NOVA  = 888800001
local CARD_VORTEX_GENESIS = 888800003

s.listed_series={SET_CHRYSOS_HEIRS}
s.listed_names={CARD_ERA_NOVA, CARD_VORTEX_GENESIS}

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
	-- PENDULUM EFFECTS (Scale = 0)
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

	-- P-Eff 2: Hủy lá này để đặt "Vortex of Genesis" từ Hand/Deck/GY lên S/T Zone (1 lần/lượt)
	local pe2=Effect.CreateEffect(c)
	pe2:SetDescription(aux.Stringid(id,0))
	pe2:SetCategory(CATEGORY_DESTROY)
	pe2:SetType(EFFECT_TYPE_IGNITION)
	pe2:SetRange(LOCATION_PZONE)
	pe2:SetCountLimit(1,id)
	pe2:SetTarget(s.pltg)
	pe2:SetOperation(s.plop)
	c:RegisterEffect(pe2)

	----------------------------------------------------------------------------
	-- MONSTER EFFECTS
	----------------------------------------------------------------------------
	-- M-Eff 1: Tự nhảy từ Extra Deck khi "Chrysos Heirs" được SS (1 lần/lượt)
	local me1=Effect.CreateEffect(c)
	me1:SetDescription(aux.Stringid(id,1))
	me1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOHAND)
	me1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	me1:SetProperty(EFFECT_FLAG_DELAY)
	me1:SetCode(EVENT_SPSUMMON_SUCCESS)
	me1:SetRange(LOCATION_EXTRA)
	me1:SetCountLimit(1,id+100)
	me1:SetCondition(s.exspcon)
	me1:SetTarget(s.exsptg)
	me1:SetOperation(s.exspop)
	c:RegisterEffect(me1)

	-- M-Eff 2: Xáo lá này vào Deck để SS 1 "Chrysos Heirs" từ Deck (Được coi là Ritual Summon) (1 lần/lượt)
	local me2=Effect.CreateEffect(c)
	me2:SetDescription(aux.Stringid(id,2))
	me2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	me2:SetType(EFFECT_TYPE_IGNITION)
	me2:SetRange(LOCATION_MZONE)
	me2:SetCountLimit(1,id+200)
	me2:SetTarget(s.sptg)
	me2:SetOperation(s.spop)
	c:RegisterEffect(me2)

	-- M-Eff 3: Khi bị hiến tế (Tributed): Thêm 1 "Era Nova" hoặc bài đề cập nó từ Deck (1 lần/lượt)
	local me3=Effect.CreateEffect(c)
	me3:SetDescription(aux.Stringid(id,3))
	me3:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	me3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	me3:SetProperty(EFFECT_FLAG_DELAY)
	me3:SetCode(EVENT_RELEASE)
	me3:SetCountLimit(1,id+300)
	me3:SetTarget(s.thtg)
	me3:SetOperation(s.thop)
	c:RegisterEffect(me3)
end

--------------------------------------------------------------------------------
-- PENDULUM EFFECT LOGIC
--------------------------------------------------------------------------------
function s.pendlimit(e,c,sump,sumtype,sumpos,targetp,se)
	return (sumtype&SUMMON_TYPE_PENDULUM)==SUMMON_TYPE_PENDULUM
end

function s.plfilter(c)
	return c:IsCode(CARD_VORTEX_GENESIS) and not c:IsForbidden()
end

function s.pltg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsDestructable() 
		and Duel.IsExistingMatchingCard(s.plfilter,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE,0,1,nil) 
		and Duel.GetLocationCount(tp,LOCATION_SZONE)>0 end
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,c,1,0,0)
end

function s.plop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) and Duel.Destroy(c,REASON_EFFECT)>0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOFIELD)
		local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.plfilter),tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil)
		local tc=g:GetFirst()
		if tc then
			Duel.MoveToField(tc,tp,tp,LOCATION_SZONE,POS_FACEUP,true)
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
	if chk==0 then return Duel.GetLocationCountFromEx(tp,tp,nil,c)>0
		and c:IsCanBeSpecialSummoned(e,0,tp,false,true) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,c,1,tp,LOCATION_EXTRA)
end

function s.exspop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) or not c:IsFaceup() then return end
	
	-- Người chơi chọn Add lên tay hoặc Special Summon
	local op=Duel.SelectOption(tp,aux.Stringid(id,4),aux.Stringid(id,5)) -- 0: Add to hand, 1: Special Summon
	if op==0 then
		Duel.SendtoHand(c,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,c)
	else
		Duel.SpecialSummon(c,0,tp,tp,false,true,POS_FACEUP)
	end
end

-- M-Eff 2: Xáo lá này vào Deck để gọi quái Ritual từ Deck
function s.spfilter(c,e,tp)
	return c:IsSetCard(SET_CHRYSOS_HEIRS) and c:IsType(TYPE_MONSTER) and not c:IsCode(id)
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_RITUAL,tp,false,true)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsAbleToDeck() and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_DECK,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_TODECK,c,1,tp,LOCATION_MZONE)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) or Duel.SendtoDeck(c,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)==0 then return end
	if c:IsLocation(LOCATION_DECK+LOCATION_EXTRA) then
		if c:IsLocation(LOCATION_DECK) then Duel.ShuffleDeck(tp) end
		if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_DECK,0,1,1,nil,e,tp)
		if #g>0 then
			local tc=g:GetFirst()
			tc:SetMaterial(nil)
			if Duel.SpecialSummon(tc,SUMMON_TYPE_RITUAL,tp,tp,false,true,POS_FACEUP)>0 then
				tc:CompleteProcedure()
			end
		end
	end

	-- Khóa Triệu hồi ngoại trừ "Chrysos Heirs" đến hết lượt kế tiếp
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT)
	e1:SetDescription(aux.Stringid(id,6))
	e1:SetTargetRange(1,0)
	e1:SetTarget(s.splimit)
	e1:SetReset(RESET_PHASE+PHASE_END+RESET_SELF_TURN,2)
	Duel.RegisterEffect(e1,tp)
end

function s.splimit(e,c,sump,sumtype,sumpos,targetp,se)
	return not c:IsSetCard(SET_CHRYSOS_HEIRS)
end

-- M-Eff 3: Search khi bị Tributed
function s.thfilter(c)
	return (c:IsCode(CARD_ERA_NOVA) or c:ListsCode(CARD_ERA_NOVA))
		and not c:IsCode(id) and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.thfilter),tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end
