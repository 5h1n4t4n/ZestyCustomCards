-- Madoka the Magica Divine
-- ID: 999900003
local s,id=GetID()

local SET_MAGICA		  = 0x654
local SET_PUELLA_WITCH  = 0x1654

local CARD_MADOKA_STUDENT = 999900001
local CARD_MADOKA_MAHOU   = 999900002
local CARD_MADOKA_DIVINE  = 999900003

s.listed_series={SET_MAGICA, SET_PUELLA_WITCH}
s.listed_names={CARD_MADOKA_MAHOU, CARD_MADOKA_STUDENT}

function s.initial_effect(c)
	c:EnableReviveLimit()
	
	-- Chỉ được điều khiển 1 "Madoka the Magica Divine" trên sân
	c:SetUniqueOnField(1,0,id)

	-- Bắt buộc Xyz Summon bằng hiệu ứng của "Madoka the Magica Mahou Shoujo"
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_SPSUMMON_CONDITION)
	e0:SetValue(s.splimit)
	c:RegisterEffect(e0)

	-- 1. Không thể bị trục xuất hoặc gửi xuống GY bởi hiệu ứng lá bài
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCode(EFFECT_CANNOT_REMOVE)
	e1:SetValue(1)
	c:RegisterEffect(e1)

	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCode(EFFECT_CANNOT_TO_GRAVE)
	e2:SetValue(s.tograveval)
	c:RegisterEffect(e2)

	-- 2. Không người chơi nào có thể trục xuất quái thú trên sân
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetCode(EFFECT_CANNOT_REMOVE)
	e3:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e3:SetRange(LOCATION_MZONE)
	e3:SetTargetRange(1,1)
	e3:SetTarget(s.rmlimit)
	c:RegisterEffect(e3)

	-- 3. Quái thú "Magica" bạn điều khiển không thể bị chỉ định bởi hiệu ứng
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_FIELD)
	e4:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e4:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE)
	e4:SetRange(LOCATION_MZONE)
	e4:SetTargetRange(LOCATION_MZONE,0)
	e4:SetTarget(s.tglimit)
	e4:SetValue(aux.tgoval)
	c:RegisterEffect(e4)

	-- 4. Quick Effect: Detach 1 material & Trả lá này về Extra Deck làm COST
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,0))
	e5:SetCategory(CATEGORY_TOHAND+CATEGORY_TODECK+CATEGORY_SPECIAL_SUMMON)
	e5:SetType(EFFECT_TYPE_QUICK_O)
	e5:SetCode(EVENT_FREE_CHAIN)
	e5:SetRange(LOCATION_MZONE)
	e5:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E)
	e5:SetCost(s.effcost)
	e5:SetTarget(s.efftg)
	e5:SetOperation(s.effop)
	c:RegisterEffect(e5)
end

--------------------------------------------------------------------------------
-- SUMMON LIMIT & CONTINUOUS EFFECTS
--------------------------------------------------------------------------------
function s.splimit(e,se,sp,st)
	return se and se:GetHandler():IsCode(CARD_MADOKA_MAHOU)
end

function s.tograveval(e,re,r,rp)
	return (r&REASON_EFFECT)~=0
end

function s.rmlimit(e,c,tp,r,re)
	return c:IsLocation(LOCATION_MZONE) and c:IsType(TYPE_MONSTER)
end

function s.tglimit(e,c)
	return c:IsSetCard(SET_MAGICA)
end

--------------------------------------------------------------------------------
-- MAIN QUICK EFFECT
--------------------------------------------------------------------------------
function s.effcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:CheckRemoveOverlayCard(tp,1,REASON_COST) and c:IsAbleToExtraAsCost() end
	c:RemoveOverlayCard(tp,1,1,REASON_COST)
	Duel.SendtoDeck(c,nil,SEQ_DECKSHUFFLE,REASON_COST)
end

function s.witchfilter(c)
	return c:IsFaceup() and c:IsSetCard(SET_PUELLA_WITCH) and (c:IsAbleToHand() or c:IsAbleToDeck())
end

-- Lọc quái thú trong tay CÓ ĐỀ CẬP "Madoka the Magica Mahou Shoujo", TRỪ CHÍNH NÓ
function s.mahoufilter(c,e,tp)
	return c:IsMonster() 
		and c:IsListsCode(CARD_MADOKA_MAHOU) 
		and not c:IsCode(CARD_MADOKA_MAHOU)
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_RITUAL,tp,true,false)
end

function s.studentfilter(c,e,tp)
	return c:IsCode(CARD_MADOKA_STUDENT) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.efftg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,0,LOCATION_ONFIELD)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND)
end

function s.effop(e,tp,eg,ep,ev,re,r,rp)
	-- 1. Trả toàn bộ "Magica Puella Witch" ngửa mặt trên sân về tay
	local wg=Duel.GetMatchingGroup(s.witchfilter,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,nil)
	if #wg>0 then
		Duel.SendtoHand(wg,nil,REASON_EFFECT)
	end

	-- 2. Special Summon TẤT CẢ quái thú từ tay có đề cập "Madoka the Magica Mahou Shoujo" (Coi như Ritual Summon)
	local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
	local rg=Duel.GetMatchingGroup(s.mahoufilter,tp,LOCATION_HAND,0,nil,e,tp)
	if ft>0 and #rg>0 then
		Duel.BreakEffect()
		if #rg>ft then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
			rg=rg:Select(tp,ft,ft,nil)
		end
		for tc in aux.Next(rg) do
			if Duel.SpecialSummonStep(tc,SUMMON_TYPE_RITUAL,tp,tp,true,false,POS_FACEUP) then
				tc:CompleteProcedure()
			end
		end
		Duel.SpecialSummonComplete()
	end

	-- 3. Special Summon 1 "Madoka Kaname the Magica Student" từ tay
	if Duel.GetLocationCount(tp,LOCATION_MZONE)>0 
		and Duel.IsExistingMatchingCard(s.studentfilter,tp,LOCATION_HAND,0,1,nil,e,tp) then
		Duel.BreakEffect()
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local sg=Duel.SelectMatchingCard(tp,s.studentfilter,tp,LOCATION_HAND,0,1,1,nil,e,tp)
		if #sg>0 then
			Duel.SpecialSummon(sg,0,tp,tp,false,false,POS_FACEUP)
		end
	end

	-- 4. Trao hiệu ứng cho toàn bộ quái thú đang hiện diện trên sân của bạn
	local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,LOCATION_MZONE,0,nil)
	if #g>0 then
		Duel.BreakEffect()
		for tc in aux.Next(g) do
			local e1=Effect.CreateEffect(tc)
			e1:SetDescription(aux.Stringid(id,1))
			e1:SetCategory(CATEGORY_DESTROY+CATEGORY_HANDES)
			e1:SetType(EFFECT_TYPE_QUICK_O)
			e1:SetCode(EVENT_FREE_CHAIN)
			e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
			e1:SetRange(LOCATION_MZONE)
			e1:SetCountLimit(1,EFFECT_COUNT_CODE_DUEL)
			e1:SetTarget(s.granttg)
			e1:SetOperation(s.grantop)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD)
			tc:RegisterEffect(e1)
			tc:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD,EFFECT_FLAG_CLIENT_HINT,1,0,aux.Stringid(id,1))
		end
	end
end

--------------------------------------------------------------------------------
-- GRANTED EFFECT LOGIC
--------------------------------------------------------------------------------
function s.granttg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsOnField() end
	if chk==0 then return Duel.IsExistingTarget(nil,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectTarget(tp,nil,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_HANDES,nil,0,1-tp,1)
end

function s.grantop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) and Duel.Destroy(tc,REASON_EFFECT)>0 then
		local hg=Duel.GetFieldGroup(tp,0,LOCATION_HAND)
		if #hg>0 then
			Duel.ConfirmCards(tp,hg)
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DISCARD)
			local sg=hg:Select(tp,1,1,nil)
			Duel.SendtoGrave(sg,REASON_EFFECT+REASON_DISCARD)
			Duel.ShuffleHand(1-tp)
		end
	end
end