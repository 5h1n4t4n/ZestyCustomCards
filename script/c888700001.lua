-- Rising HERO Manaccaniter
-- ID: 888700001
local s,id=GetID()

local SET_RISING_HERO = 0xff8
local SET_HERO		= 0x8

s.listed_series={SET_RISING_HERO, SET_HERO}

function s.initial_effect(c)
	-- 1. Triệu hồi Đặc biệt từ tay (Inherent Special Summon)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(2,id) -- Tối đa 2 lần/lượt
	e1:SetCondition(s.spcon1)
	c:RegisterEffect(e1)

	-- 2. Search quái thú "Rising HERO" khi Normal hoặc Special Summon
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_SUMMON_SUCCESS)
	e2:SetCountLimit(2,id+100) -- Tối đa 2 lần/lượt
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)

	local e3=e2:Clone()
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e3)

	-- 3. Triệu hồi Đặc biệt từ Mộ khi làm Nguyên liệu Dung hợp cho quái "HERO"
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,2))
	e4:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e4:SetProperty(EFFECT_FLAG_DELAY)
	e4:SetCode(EVENT_BE_MATERIAL)
	e4:SetCountLimit(2,id+200) -- Tối đa 2 lần/lượt
	e4:SetCondition(s.spcon2)
	e4:SetTarget(s.sptg2)
	e4:SetOperation(s.spop2)
	c:RegisterEffect(e4)
end

--------------------------------------------------------------------------------
-- 1. LOGIC TRIỆU HỒI TỪ TAY
--------------------------------------------------------------------------------
function s.cfilter(c)
	return c:IsFaceup() and c:IsSetCard(SET_HERO)
end

function s.spcon1(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and (Duel.GetFieldGroupCount(tp,LOCATION_MZONE,0)==0 or Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_MZONE,0,1,nil))
end

--------------------------------------------------------------------------------
-- 2. LOGIC SEARCH KHI SUMMON
--------------------------------------------------------------------------------
function s.thfilter(c)
	return c:IsSetCard(SET_RISING_HERO) and c:IsType(TYPE_MONSTER) and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end

--------------------------------------------------------------------------------
-- 3. LOGIC HỒI SINH TỪ MỘ KHI LÀM NGUYÊN LIỆU DUNG HỢP
--------------------------------------------------------------------------------
function s.spcon2(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local rc=c:GetReasonCard()
	return c:IsLocation(LOCATION_GRAVE) and (r&REASON_FUSION)~=0 and rc and rc:IsSetCard(SET_HERO)
end

function s.sptg2(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end

function s.spop2(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
	end
end