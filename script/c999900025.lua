-- Homura Soulgem
-- ID: 999900025
local s,id=GetID()

local SET_MAGICA	   = 0x654
local SET_SOULGEM	 = 0xc7d
local TOKEN_GRIEF_SEED = 999900006

s.listed_series={SET_MAGICA, SET_SOULGEM}
s.listed_names={
	TOKEN_GRIEF_SEED,
	999900019, -- Homura Akemi the Magica Student
	999900020, -- Homura the Magica Mahou Shoujo
	999900023, -- Homulily the Magica Puella Witch
	999900024  -- Endstage: Walpurgisnacht the Magica Puella Witch
}

function s.initial_effect(c)
	-- Luôn được coi là lá bài "Magica"
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_ADD_SETCODE)
	e0:SetValue(SET_MAGICA)
	c:RegisterEffect(e0)

	-- Điều kiện Trang bị (Equip Limit) - Đã sửa tên biến e_eq
	local e_eq=Effect.CreateEffect(c)
	e_eq:SetType(EFFECT_TYPE_SINGLE)
	e_eq:SetCode(EFFECT_EQUIP_LIMIT)
	e_eq:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e_eq:SetValue(s.eqlimit)
	c:RegisterEffect(e_eq)

	-- 1. Kích hoạt: Chọn 1 trong 2 hiệu ứng
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.target)
	e1:SetOperation(s.operation)
	c:RegisterEffect(e1)

	-- Tăng 1000 ATK cho quái thú được trang bị
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_EQUIP)
	e2:SetCode(EFFECT_UPDATE_ATTACK)
	e2:SetValue(1000)
	c:RegisterEffect(e2)

	-- Việc kích hoạt lá bài/hiệu ứng của quái thú được trang bị không thể bị negate
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetCode(EFFECT_CANNOT_INACTIVATE)
	e3:SetRange(LOCATION_SZONE)
	e3:SetTargetRange(1,0)
	e3:SetValue(s.effectfilter)
	c:RegisterEffect(e3)

	-- Hiệu ứng của quái thú được trang bị không thể bị vô hiệu hóa (negate)
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_FIELD)
	e4:SetCode(EFFECT_CANNOT_DISEFFECT)
	e4:SetRange(LOCATION_SZONE)
	e4:SetTargetRange(1,0)
	e4:SetValue(s.effectfilter)
	c:RegisterEffect(e4)

	-- 2. GY Trigger: Special Summon Token -> Send 1 Level 4 "Magica" từ Deck xuống GY
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,2))
	e5:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOKEN+CATEGORY_TOGRAVE)
	e5:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e5:SetProperty(EFFECT_FLAG_DELAY)
	e5:SetCode(EVENT_TO_GRAVE)
	e5:SetCountLimit(1,id+100)
	e5:SetTarget(s.gytg)
	e5:SetOperation(s.gyop)
	c:RegisterEffect(e5)
end

--------------------------------------------------------------------------------
-- HELPER FILTERS & EQUIP LIMIT
--------------------------------------------------------------------------------
function s.homurafilter(c)
	return c:IsCode(999900019, 999900020, 999900023, 999900024)
end

function s.eqlimit(e,c)
	return s.homurafilter(c)
end

function s.thfilter(c)
	return s.homurafilter(c) and c:IsType(TYPE_MONSTER) and c:IsAbleToHand()
end

function s.eqfilter(c)
	return c:IsFaceup() and s.homurafilter(c)
end

function s.effectfilter(e,ct)
	local te=Duel.GetChainInfo(ct,CHAININFO_TRIGGERING_EFFECT)
	local eq=e:GetHandler():GetEquipTarget()
	return te and eq and te:GetHandler()==eq
end

--------------------------------------------------------------------------------
-- ACTIVATION LOGIC (OPTION 1 OR OPTION 2)
--------------------------------------------------------------------------------
function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and s.eqfilter(chkc) end
	local b1=Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil)
	local b2=Duel.IsExistingTarget(s.eqfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil)
	if chk==0 then return b1 or b2 end
	local op=0
	if b1 and b2 then
		op=Duel.SelectOption(tp,aux.Stringid(id,0),aux.Stringid(id,1))
	elseif b1 then
		op=Duel.SelectOption(tp,aux.Stringid(id,0))
	else
		op=Duel.SelectOption(tp,aux.Stringid(id,1))+1
	end
	e:SetLabel(op)
	if op==0 then
		e:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
		e:SetProperty(0)
		Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
	else
		e:SetCategory(CATEGORY_EQUIP)
		e:SetProperty(EFFECT_FLAG_CARD_TARGET)
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_EQUIP)
		Duel.SelectTarget(tp,s.eqfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,1,nil)
		Duel.SetOperationInfo(0,CATEGORY_EQUIP,e:GetHandler(),1,0,0)
	end
end

function s.operation(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local op=e:GetLabel()
	if op==0 then
		-- Add 1 "Homura" monster từ Deck lên tay
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
		if #g>0 then
			Duel.SendtoHand(g,nil,REASON_EFFECT)
			Duel.ConfirmCards(1-tp,g)
			if c:IsRelateToEffect(e) then
				Duel.BreakEffect()
				Duel.SendtoGrave(c,REASON_EFFECT) -- Khắc phục lỗi kẹt bài trên sân
			end
		end
	else
		-- Trang bị lá này cho 1 quái thú "Homura" trên sân
		local tc=Duel.GetFirstTarget()
		if c:IsRelateToEffect(e) and tc and tc:IsRelateToEffect(e) and tc:IsFaceup() then
			Duel.Equip(tp,c,tc)
		end
	end
end

--------------------------------------------------------------------------------
-- GY / DISCARD LOGIC
--------------------------------------------------------------------------------
function s.togravefilter(c)
	return c:IsSetCard(SET_MAGICA) and c:IsLevel(4) and c:IsAbleToGrave()
end

function s.gytg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		local b1=Duel.GetLocationCount(tp,LOCATION_MZONE)>0 and Duel.IsPlayerCanSpecialSummonMonster(tp,TOKEN_GRIEF_SEED,0,TYPES_TOKEN+TYPE_MONSTER,300,300,1,RACE_SPELLCASTER,ATTRIBUTE_DARK,POS_FACEUP,tp)
		local b2=Duel.GetLocationCount(1-tp,LOCATION_MZONE)>0 and Duel.IsPlayerCanSpecialSummonMonster(tp,TOKEN_GRIEF_SEED,0,TYPES_TOKEN+TYPE_MONSTER,300,300,1,RACE_SPELLCASTER,ATTRIBUTE_DARK,POS_FACEUP,1-tp)
		return (b1 or b2) and Duel.IsExistingMatchingCard(s.togravefilter,tp,LOCATION_DECK,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOKEN,nil,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_DECK)
end

function s.gyop(e,tp,eg,ep,ev,re,r,rp)
	local b1=Duel.GetLocationCount(tp,LOCATION_MZONE)>0 and Duel.IsPlayerCanSpecialSummonMonster(tp,TOKEN_GRIEF_SEED,0,TYPES_TOKEN+TYPE_MONSTER,300,300,1,RACE_SPELLCASTER,ATTRIBUTE_DARK,POS_FACEUP,tp)
	local b2=Duel.GetLocationCount(1-tp,LOCATION_MZONE)>0 and Duel.IsPlayerCanSpecialSummonMonster(tp,TOKEN_GRIEF_SEED,0,TYPES_TOKEN+TYPE_MONSTER,300,300,1,RACE_SPELLCASTER,ATTRIBUTE_DARK,POS_FACEUP,1-tp)

	if not (b1 or b2) then return end

	local target_player=tp
	if b1 and b2 then
		local op=Duel.SelectOption(tp,aux.Stringid(id,3),aux.Stringid(id,4))
		if op==1 then target_player=1-tp end
	elseif b2 then
		target_player=1-tp
	end

	local token=Duel.CreateToken(tp,TOKEN_GRIEF_SEED)
	if Duel.SpecialSummon(token,0,tp,target_player,false,false,POS_FACEUP)>0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
		local g=Duel.SelectMatchingCard(tp,s.togravefilter,tp,LOCATION_DECK,0,1,1,nil)
		if #g>0 then
			Duel.BreakEffect()
			Duel.SendtoGrave(g,REASON_EFFECT)
		end
	end
end