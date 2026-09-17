-- Mami Soulgems
-- ID: 999900017
local s,id=GetID()

local SET_MAGICA		= 0x654
local SET_SOULGEM	  = 0xc7d
local CARD_MAMI_STUDENT = 999900013
local CARD_MAMI_MAHOU   = 999900014
local CARD_MAMI_WITCH   = 999900015
local TOKEN_GRIEF_SEED  = 999900006

s.listed_series={SET_SOULGEM, SET_MAGICA}
s.listed_names={CARD_MAMI_STUDENT, CARD_MAMI_MAHOU, CARD_MAMI_WITCH, TOKEN_GRIEF_SEED}

function s.initial_effect(c)
	-- Luôn được xem là lá bài "Magica"
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_ADD_SETCODE)
	e0:SetValue(SET_MAGICA)
	c:RegisterEffect(e0)

	-- Điều kiện Trang bị (Equip Limit)
	local e_eq=Effect.CreateEffect(c)
	e_eq:SetType(EFFECT_TYPE_SINGLE)
	e_eq:SetCode(EFFECT_EQUIP_LIMIT)
	e_eq:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e_eq:SetValue(s.eqlimit)
	c:RegisterEffect(e_eq)

	-- 1. KÍCH HOẠT: Chọn 1 trong 2 hiệu ứng
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E+TIMING_MAIN_END)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)

	-- Hiệu ứng được trao cho quái thú (Khai báo độc lập)
	local ge=Effect.CreateEffect(c)
	ge:SetDescription(aux.Stringid(id,2))
	ge:SetCategory(CATEGORY_DISABLE)
	ge:SetType(EFFECT_TYPE_QUICK_O)
	ge:SetCode(EVENT_FREE_CHAIN)
	ge:SetProperty(EFFECT_FLAG_CARD_TARGET)
	ge:SetRange(LOCATION_MZONE)
	ge:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E+TIMING_MAIN_END)
	ge:SetCountLimit(1)
	ge:SetTarget(s.distg)
	ge:SetOperation(s.disop)

	-- CẤP HIỆU ỨNG CHO QUÁI THÚ ĐƯỢC TRANG BỊ (Đã sửa SetValue chuẩn)
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_GRANT)
	e2:SetRange(LOCATION_SZONE)
	e2:SetTargetRange(LOCATION_MZONE,LOCATION_MZONE)
	e2:SetTarget(s.eftg)
	e2:SetValue(function(e,c) return ge end)
	c:RegisterEffect(e2)

	-- 2. HIỆU ỨNG TỪ GY: Thu hồi về tay & Special Summon Grief Seed Token
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,3))
	e3:SetCategory(CATEGORY_TOHAND+CATEGORY_SPECIAL_SUMMON+CATEGORY_TOKEN)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_TO_GRAVE)
	e3:SetCountLimit(2,TOKEN_GRIEF_SEED,EFFECT_COUNT_CODE_OATH)
	e3:SetTarget(s.gytg)
	e3:SetOperation(s.gyop)
	c:RegisterEffect(e3)
end

function s.eqlimit(e,c)
	return c:IsCode(CARD_MAMI_STUDENT, CARD_MAMI_MAHOU, CARD_MAMI_WITCH)
end

--------------------------------------------------------------------------------
-- EFFECT 1: ACTIVATION (CHOOSE 1 OF 2)
--------------------------------------------------------------------------------
function s.thfilter(c)
	return c:IsCode(CARD_MAMI_STUDENT, CARD_MAMI_MAHOU) and c:IsAbleToHand()
end

function s.mamifilter(c)
	return c:IsFaceup() and c:IsCode(CARD_MAMI_STUDENT, CARD_MAMI_MAHOU, CARD_MAMI_WITCH)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and s.mamifilter(chkc) end
	local b1=Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil)
	local b2=Duel.IsExistingTarget(s.mamifilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil)
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
		Duel.SelectTarget(tp,s.mamifilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,1,nil)
		Duel.SetOperationInfo(0,CATEGORY_EQUIP,e:GetHandler(),1,0,0)
	end
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local op=e:GetLabel()
	if op==0 then
		-- Search 1 Mami Student hoặc Mami Mahou Shoujo từ Deck
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
		if #g>0 then
			Duel.SendtoHand(g,nil,REASON_EFFECT)
			Duel.ConfirmCards(1-tp,g)
			if c:IsRelateToEffect(e) then
				Duel.BreakEffect()
				Duel.SendtoGrave(c,REASON_EFFECT) -- Khắc phục lỗi kẹt sân
			end
		end
	else
		-- Trang bị lá bài này vào quái thú "Mami"
		local tc=Duel.GetFirstTarget()
		if c:IsRelateToEffect(e) and tc and tc:IsRelateToEffect(e) and tc:IsFaceup() then
			Duel.Equip(tp,c,tc)
		end
	end
end

--------------------------------------------------------------------------------
-- GRANTED EFFECT FOR EQUIPPED MONSTER
--------------------------------------------------------------------------------
function s.eftg(e,c)
	return e:GetHandler():GetEquipTarget()==c
end

function s.distg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsControler(1-tp) and chkc:IsLocation(LOCATION_MZONE) and chkc:IsFaceup() end
	if chk==0 then return Duel.IsExistingTarget(Card.IsFaceup,tp,0,LOCATION_MZONE,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_NEGATE)
	local g=Duel.SelectTarget(tp,Card.IsFaceup,tp,0,LOCATION_MZONE,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_DISABLE,g,1,0,0)
end

function s.disop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) and tc:IsFaceup() then
		local c=e:GetHandler()
		Duel.NegateRelatedChain(tc,RESET_TURN_SET)
		
		-- Negate hiệu ứng
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_DISABLE)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		tc:RegisterEffect(e1)

		local e2=Effect.CreateEffect(c)
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetCode(EFFECT_DISABLE_EFFECT)
		e2:SetValue(RESET_TURN_SET)
		e2:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		tc:RegisterEffect(e2)

		-- Không thể đổi tư thế chiến đấu
		local e3=Effect.CreateEffect(c)
		e3:SetType(EFFECT_TYPE_SINGLE)
		e3:SetCode(EFFECT_CANNOT_CHANGE_POSITION)
		e3:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		tc:RegisterEffect(e3)

		-- Không thể dùng làm nguyên liệu Extra Deck
		local e4=Effect.CreateEffect(c)
		e4:SetType(EFFECT_TYPE_SINGLE)
		e4:SetCode(EFFECT_CANNOT_BE_FUSION_MATERIAL)
		e4:SetValue(1)
		e4:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		tc:RegisterEffect(e4)

		local e5=e4:Clone()
		e5:SetCode(EFFECT_CANNOT_BE_SYNCHRO_MATERIAL)
		tc:RegisterEffect(e5)

		local e6=e4:Clone()
		e6:SetCode(EFFECT_CANNOT_BE_XYZ_MATERIAL)
		tc:RegisterEffect(e6)

		local e7=e4:Clone()
		e7:SetCode(EFFECT_CANNOT_BE_LINK_MATERIAL)
		tc:RegisterEffect(e7)
	end
end

--------------------------------------------------------------------------------
-- EFFECT 2: GY TRIGGER EFFECT
--------------------------------------------------------------------------------
function s.gytg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		return c:IsAbleToHand()
			and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.IsPlayerCanSpecialSummonMonster(tp,TOKEN_GRIEF_SEED,0,TYPES_TOKEN+TYPE_MONSTER,300,300,1,RACE_SPELLCASTER,ATTRIBUTE_DARK)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,c,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_TOKEN,nil,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,0)
end

function s.gyop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) and Duel.SendtoHand(c,nil,REASON_EFFECT)>0 and c:IsLocation(LOCATION_HAND) then
		Duel.ConfirmCards(1-tp,c)
		if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0
			or not Duel.IsPlayerCanSpecialSummonMonster(tp,TOKEN_GRIEF_SEED,0,TYPES_TOKEN+TYPE_MONSTER,300,300,1,RACE_SPELLCASTER,ATTRIBUTE_DARK) then return end
		
		local token=Duel.CreateToken(tp,TOKEN_GRIEF_SEED)
		if Duel.SpecialSummon(token,0,tp,tp,false,false,POS_FACEUP)>0 then
			-- Token nhận Quick Effect gây 500 damage
			local e1=Effect.CreateEffect(c)
			e1:SetDescription(aux.Stringid(id,4))
			e1:SetCategory(CATEGORY_DAMAGE)
			e1:SetType(EFFECT_TYPE_QUICK_O)
			e1:SetCode(EVENT_FREE_CHAIN)
			e1:SetRange(LOCATION_MZONE)
			e1:SetCountLimit(1)
			e1:SetTarget(s.damtg)
			e1:SetOperation(s.damop)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD)
			token:RegisterEffect(e1)
		end
	end
end

function s.damtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetTargetPlayer(1-tp)
	Duel.SetTargetParam(500)
	Duel.SetOperationInfo(0,CATEGORY_DAMAGE,nil,0,1-tp,500)
end

function s.damop(e,tp,eg,ep,ev,re,r,rp)
	local p,d=Duel.GetChainInfo(0,CHAININFO_TARGET_PLAYER,CHAININFO_TARGET_PARAM)
	Duel.Damage(p,d,REASON_EFFECT)
end