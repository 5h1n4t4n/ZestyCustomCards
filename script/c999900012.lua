-- Sayaka Soulgem
-- ID: 999900012
local s,id=GetID()

local SET_MAGICA		  = 0x654
local SET_SOULGEM	   = 0xc7d
local CARD_SAYAKA_STUDENT = 999900008
local CARD_SAYAKA_MAHOU   = 999900009
local CARD_OKTAVIA_WITCH  = 999900010
local TOKEN_GRIEF_SEED  = 999900006
local COUNTER_NOTE	  = 0x1655

-- Custom Event Code cho việc Pay LP
local EVENT_PAY_LP	  = 99990000

s.listed_series={SET_MAGICA, SET_SOULGEM}
s.listed_names={CARD_SAYAKA_STUDENT, CARD_SAYAKA_MAHOU, CARD_OKTAVIA_WITCH, TOKEN_GRIEF_SEED}

function s.initial_effect(c)
	-- Luôn được tính là lá bài "Magica"
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_ADD_SETCODE)
	e0:SetValue(SET_MAGICA)
	c:RegisterEffect(e0)

	-- ĐK Trang bị (chỉ Sayaka monsters + Oktavia Witch)
	local e_eq=Effect.CreateEffect(c)
	e_eq:SetType(EFFECT_TYPE_SINGLE)
	e_eq:SetCode(EFFECT_EQUIP_LIMIT)
	e_eq:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e_eq:SetValue(s.eqlimit)
	c:RegisterEffect(e_eq)

	-- 1. Kích hoạt bài từ tay (HOPT Card Activation)
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_EQUIP)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E+TIMING_MAIN_END)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)

	-- Trao hiệu ứng cho quái thú đang trang bị lá này
	local e_g1=Effect.CreateEffect(c)
	e_g1:SetDescription(aux.Stringid(id,2))
	e_g1:SetType(EFFECT_TYPE_QUICK_O)
	e_g1:SetCode(EVENT_FREE_CHAIN)
	e_g1:SetRange(LOCATION_MZONE)
	e_g1:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E)
	e_g1:SetCountLimit(1)
	e_g1:SetCost(s.immunecost)
	e_g1:SetOperation(s.immuneop)

	-- Bắt sự kiện Trả LP (dùng Custom Event)
	local e_g2=Effect.CreateEffect(c)
	e_g2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e_g2:SetCode(EVENT_PAY_LP)
	e_g2:SetRange(LOCATION_MZONE)
	e_g2:SetOperation(s.ctop)

	-- Bắt sự kiện Hồi LP (dùng hằng số chuẩn EVENT_RECOVER)
	local e_g3=e_g2:Clone()
	e_g3:SetCode(EVENT_RECOVER)

	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_GRANT)
	e2:SetRange(LOCATION_SZONE)
	e2:SetTargetRange(LOCATION_MZONE,LOCATION_MZONE)
	e2:SetTarget(s.eftg)
	e2:SetValue(function(e,c) return e_g1 end)
	c:RegisterEffect(e2)

	local e3=e2:Clone()
	e3:SetValue(function(e,c) return e_g2 end)
	c:RegisterEffect(e3)

	local e4=e2:Clone()
	e4:SetValue(function(e,c) return e_g3 end)
	c:RegisterEffect(e4)

	-- 2. Hiệu ứng khi bị gửi xuống GY (Đã thêm Count Limit tránh Loop)
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,3))
	e5:SetCategory(CATEGORY_TOHAND+CATEGORY_SPECIAL_SUMMON+CATEGORY_TOKEN)
	e5:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e5:SetProperty(EFFECT_FLAG_DELAY)
	e5:SetCode(EVENT_TO_GRAVE)
	e5:SetCountLimit(2,TOKEN_GRIEF_SEED,EFFECT_COUNT_CODE_OATH)
	e5:SetTarget(s.gytg)
	e5:SetOperation(s.gyop)
	c:RegisterEffect(e5)
end

function s.eqlimit(e,c)
	return c:IsCode(CARD_SAYAKA_STUDENT, CARD_SAYAKA_MAHOU, CARD_OKTAVIA_WITCH)
end

--------------------------------------------------------------------------------
-- ACTIVATION (SEARCH OR EQUIP)
--------------------------------------------------------------------------------
function s.searchfilter(c)
	return c:IsCode(CARD_SAYAKA_STUDENT, CARD_SAYAKA_MAHOU, CARD_OKTAVIA_WITCH) and c:IsAbleToHand()
end

function s.sayakamonfilter(c)
	return c:IsFaceup() and c:IsCode(CARD_SAYAKA_STUDENT, CARD_SAYAKA_MAHOU, CARD_OKTAVIA_WITCH)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and s.sayakamonfilter(chkc) end
	local b1=Duel.IsExistingMatchingCard(s.searchfilter,tp,LOCATION_DECK,0,1,nil)
	local b2=Duel.IsExistingTarget(s.sayakamonfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil)
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
		Duel.SelectTarget(tp,s.sayakamonfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,1,nil)
		Duel.SetOperationInfo(0,CATEGORY_EQUIP,e:GetHandler(),1,0,0)
	end
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local op=e:GetLabel()
	if op==0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local g=Duel.SelectMatchingCard(tp,s.searchfilter,tp,LOCATION_DECK,0,1,1,nil)
		if #g>0 then
			Duel.SendtoHand(g,nil,REASON_EFFECT)
			Duel.ConfirmCards(1-tp,g)
			if c:IsRelateToEffect(e) then
				Duel.BreakEffect()
				Duel.SendtoGrave(c,REASON_EFFECT) -- Khắc phục lỗi kẹt bài trên sân
			end
		end
	else
		local tc=Duel.GetFirstTarget()
		if c:IsRelateToEffect(e) and tc and tc:IsRelateToEffect(e) and tc:IsFaceup() then
			Duel.Equip(tp,c,tc)
		end
	end
end

--------------------------------------------------------------------------------
-- GRANTED EFFECTS TO EQUIPPED MONSTER
--------------------------------------------------------------------------------
function s.eftg(e,c)
	return c==e:GetHandler():GetEquipTarget()
end

function s.immunecost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckLPCost(tp,1000) end
	Duel.PayLPCost(tp,1000)
	Duel.RaiseEvent(e:GetHandler(), EVENT_PAY_LP, e, 0, tp, tp, 1000)
end

function s.immuneop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_IMMUNE_EFFECT)
	e1:SetTargetRange(LOCATION_ONFIELD,0)
	e1:SetTarget(s.immfilter)
	e1:SetValue(s.efilter)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
end

function s.immfilter(e,c)
	return c:IsSetCard(SET_MAGICA)
end

function s.efilter(e,te)
	return te:GetOwnerPlayer()~=e:GetOwnerPlayer() and te:IsActiveType(TYPE_SPELL+TYPE_TRAP)
end

function s.sayakamafilter(c)
	return c:IsFaceup() and (c:IsCode(CARD_SAYAKA_MAHOU) or c:IsCode(CARD_OKTAVIA_WITCH))
end

function s.ctop(e,tp,eg,ep,ev,re,r,rp)
	if ep~=tp then return end
	local g=Duel.GetMatchingGroup(s.sayakamafilter,tp,LOCATION_MZONE,0,nil)
	for tc in aux.Next(g) do
		tc:AddCounter(COUNTER_NOTE,1)
	end
end

--------------------------------------------------------------------------------
-- GY TRIGGER EFFECT
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
			local e1=Effect.CreateEffect(c)
			e1:SetDescription(aux.Stringid(id,4))
			e1:SetCategory(CATEGORY_RECOVER)
			e1:SetType(EFFECT_TYPE_QUICK_O)
			e1:SetCode(EVENT_FREE_CHAIN)
			e1:SetRange(LOCATION_MZONE)
			e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E)
			e1:SetCountLimit(1)
			e1:SetCost(s.tokcost)
			e1:SetTarget(s.toktg)
			e1:SetOperation(s.tokop)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD)
			token:RegisterEffect(e1)
		end
	end
end

function s.tokcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckLPCost(tp,500) end
	Duel.PayLPCost(tp,500)
	Duel.RaiseEvent(e:GetHandler(), EVENT_PAY_LP, e, 0, tp, tp, 500)
end

function s.toktg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetTargetPlayer(tp)
	Duel.SetTargetParam(1500)
	Duel.SetOperationInfo(0,CATEGORY_RECOVER,nil,0,tp,1500)
end

function s.tokop(e,tp,eg,ep,ev,re,r,rp)
	local p,d=Duel.GetChainInfo(0,CHAININFO_TARGET_PLAYER,CHAININFO_TARGET_PARAM)
	Duel.Recover(p,d,REASON_EFFECT)
end