-- Rising HERO Argent
-- ID: 888700010
local s,id=GetID()

local SET_RISING_HERO = 0xff8
local SET_HERO		= 0x8

s.listed_series={SET_RISING_HERO, SET_HERO}

function s.initial_effect(c)
	-- Hiệu ứng 1: Tiết lộ 1 quái "HERO" từ Extra Deck -> Special Summon lá này từ tay
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND)
	e1:SetCost(s.spcost)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	-- Hiệu ứng 2: Khi Normal hoặc Special Summon -> Lật bài (Excavate) xem tối đa bằng số quái "HERO" trên sân
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_SUMMON_SUCCESS)
	e2:SetCountLimit(1,id) -- [HOPT] 1 lần mỗi lượt
	e2:SetTarget(s.exctg)
	e2:SetOperation(s.excop)
	c:RegisterEffect(e2)

	-- Trigger cho Special Summon
	local e3=e2:Clone()
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e3)
end

--------------------------------------------------------------------------------
-- 1. SPECIAL SUMMON LOGIC
--------------------------------------------------------------------------------
function s.cfilter(c)
	return c:IsSetCard(SET_HERO) and c:IsType(TYPE_MONSTER) and not c:IsPublic()
end

function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_EXTRA,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONFIRM)
	local g=Duel.SelectMatchingCard(tp,s.cfilter,tp,LOCATION_EXTRA,0,1,1,nil)
	Duel.ConfirmCards(1-tp,g)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
	end
end

--------------------------------------------------------------------------------
-- 2. EXCAVATE LOGIC
--------------------------------------------------------------------------------
function s.herofilter(c)
	return c:IsFaceup() and c:IsSetCard(SET_HERO)
end

function s.exctg(e,tp,eg,ep,ev,re,r,rp,chk)
	local ct=Duel.GetMatchingGroupCount(s.herofilter,tp,LOCATION_MZONE,LOCATION_MZONE,nil)
	if chk==0 then
		return ct>0 and Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)>=1
	end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function s.excop(e,tp,eg,ep,ev,re,r,rp)
	local ct=Duel.GetMatchingGroupCount(s.herofilter,tp,LOCATION_MZONE,LOCATION_MZONE,nil)
	local deck_ct=Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)
	if ct>deck_ct then ct=deck_ct end
	if ct==0 then return end

	-- Cho phép người chơi chọn số lá muốn lật (Từ 1 đến số lượng quái HERO trên sân)
	local t={}
	for i=1,ct do t[i]=i end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_NUMBER)
	local count=Duel.AnnounceNumber(tp,table.unpack(t))

	Duel.ConfirmDecktop(tp,count)
	local g=Duel.GetDecktopGroup(tp,count)
	if #g>0 then
		local sg=g:Filter(Card.IsSetCard,nil,SET_HERO):Filter(Card.IsAbleToHand,nil)
		if #sg>0 and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
			local hg=sg:Select(tp,1,1,nil)
			Duel.SendtoHand(hg,nil,REASON_EFFECT)
			Duel.ConfirmCards(1-tp,hg)
		end
		Duel.ShuffleDeck(tp)
	end
end