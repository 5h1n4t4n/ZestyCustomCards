-- Chrysos Heirs: Hysilens - Demigod of Ocean
-- ID: 888800013
local s,id=GetID()

local SET_CHRYSOS_HEIRS = 0xffa
local CARD_ERA_NOVA	  = 888800001

s.listed_series={SET_CHRYSOS_HEIRS}
s.listed_names={CARD_ERA_NOVA}

function s.initial_effect(c)
	-- Fusion Material Setup
	c:EnableReviveLimit()
	if Fusion and Fusion.AddProcMix then
		Fusion.AddProcMix(c,true,true,s.mfilter)
	elseif aux.AddFusionProcMix then
		aux.AddFusionProcMix(c,true,true,s.mfilter)
	end

	-- Đếm lượt đã kích hoạt hiệu ứng quái thú "Chrysos Heirs"
	if not s.global_check then
		s.global_check=true
		local ge1=Effect.CreateEffect(c)
		ge1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		ge1:SetCode(EVENT_CHAINING)
		ge1:SetOperation(s.checkop)
		Duel.RegisterEffect(ge1,0)
	end

	----------------------------------------------------------------------------
	-- SPECIAL SUMMON PROCEDURE (Contact Fusion - 1 lần/lượt)
	----------------------------------------------------------------------------
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_FIELD)
	e0:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_SPSUMMON_PROC)
	e0:SetRange(LOCATION_EXTRA)
	e0:SetCountLimit(1,id)
	e0:SetCondition(s.hspcon)
	e0:SetTarget(s.hsptg)
	e0:SetOperation(s.hspop)
	c:RegisterEffect(e0)

	----------------------------------------------------------------------------
	-- MONSTER EFFECTS
	----------------------------------------------------------------------------
	-- Eff 1: Gửi "Era Nova" từ Tay/Deck xuống GY -> Ritual Summon 1 quái Ritual từ Deck (1 lần/lượt)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_RELEASE+CATEGORY_TOGRAVE)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1,id+100)
	e1:SetCost(s.ritcost)
	e1:SetTarget(s.rittg)
	e1:SetOperation(s.ritop)
	c:RegisterEffect(e1)

	-- Eff 2: Khi bị hiến tế (Tributed): Triệu hồi Đặc biệt lá này, bỏ qua điều kiện (1 lần/lượt)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_RELEASE)
	e2:SetCountLimit(1,id+200)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)

	-- Eff 2 (Dự phòng): Bắt thêm EVENT_TO_GRAVE
	local e3=e2:Clone()
	e3:SetCode(EVENT_TO_GRAVE)
	e3:SetCondition(s.spcon)
	c:RegisterEffect(e3)
end

--------------------------------------------------------------------------------
-- GLOBAL CHECK LOGIC
--------------------------------------------------------------------------------
function s.checkop(e,tp,eg,ep,ev,re,r,rp)
	if re:IsActiveType(TYPE_MONSTER) and re:GetHandler():IsSetCard(SET_CHRYSOS_HEIRS) then
		Duel.RegisterFlagEffect(rp,id,RESET_PHASE+PHASE_END,0,1)
	end
end

--------------------------------------------------------------------------------
-- CONTACT FUSION LOGIC
--------------------------------------------------------------------------------
function s.mfilter(c,fc,sumtype,tp)
	return c:IsSetCard(SET_CHRYSOS_HEIRS,fc,sumtype,tp)
end

function s.hspfilter(c,tp,fc)
	return c:IsSetCard(SET_CHRYSOS_HEIRS) and c:IsReleasable()
		and Duel.GetLocationCountFromEx(tp,tp,c,fc)>0
end

function s.hspcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	return Duel.GetFlagEffect(tp,id)>0
		and Duel.IsExistingMatchingCard(s.hspfilter,tp,LOCATION_MZONE,0,1,nil,tp,c)
end

function s.hsptg(e,tp,eg,ep,ev,re,r,rp,c)
	local g=Duel.SelectMatchingCard(tp,s.hspfilter,tp,LOCATION_MZONE,0,1,1,nil,tp,c)
	if #g>0 then
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
-- EFFECT 1 LOGIC
--------------------------------------------------------------------------------
function s.costfilter(c)
	return c:IsCode(CARD_ERA_NOVA) and c:IsAbleToGraveAsCost()
end

function s.matfilter(c)
	return c:IsSetCard(SET_CHRYSOS_HEIRS) and c:IsType(TYPE_MONSTER)
		and not c:IsType(TYPE_XYZ+TYPE_LINK) and c:GetLevel()>0
		and c:IsAbleToGrave()
end

function s.ritfilter(c,e,tp,mg)
	if not (c:IsSetCard(SET_CHRYSOS_HEIRS) and c:IsType(TYPE_RITUAL)
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_RITUAL,tp,false,true)) then return false end
	local lv=c:GetLevel()
	return mg:CheckWithSumEqual(Card.GetLevel,lv,1,#mg)
end

function s.ritcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.costfilter,tp,LOCATION_HAND+LOCATION_DECK,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g=Duel.SelectMatchingCard(tp,s.costfilter,tp,LOCATION_HAND+LOCATION_DECK,0,1,1,nil)
	Duel.SendtoGrave(g,REASON_COST)
end

function s.rittg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		local mg=Duel.GetMatchingGroup(s.matfilter,tp,LOCATION_DECK,0,nil)
		return Duel.IsExistingMatchingCard(s.ritfilter,tp,LOCATION_DECK,0,1,nil,e,tp,mg)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK)
	Duel.SetOperationInfo(0,CATEGORY_RELEASE,nil,1,tp,LOCATION_DECK)
end

function s.ritop(e,tp,eg,ep,ev,re,r,rp)
	local mg=Duel.GetMatchingGroup(s.matfilter,tp,LOCATION_DECK,0,nil)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local tg=Duel.SelectMatchingCard(tp,s.ritfilter,tp,LOCATION_DECK,0,1,1,nil,e,tp,mg)
	local tc=tg:GetFirst()
	if tc then
		local lv=tc:GetLevel()
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
		local mat=mg:SelectWithSumEqual(tp,Card.GetLevel,lv,1,#mg)
		tc:SetMaterial(mat)
		Duel.SendtoGrave(mat,REASON_EFFECT+REASON_MATERIAL+REASON_RITUAL+REASON_RELEASE)
		Duel.BreakEffect()
		if Duel.SpecialSummon(tc,SUMMON_TYPE_RITUAL,tp,tp,false,true,POS_FACEUP)>0 then
			tc:CompleteProcedure()
		end
	end
end

--------------------------------------------------------------------------------
-- EFFECT 2 LOGIC
--------------------------------------------------------------------------------
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return (r&REASON_RITUAL)~=0 and not e:GetHandler():IsReason(REASON_RELEASE)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and c:IsCanBeSpecialSummoned(e,0,tp,true,false) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SpecialSummon(c,0,tp,tp,true,false,POS_FACEUP)
	end
end