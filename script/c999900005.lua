-- Madoka Soulgems
-- ID: 999900005
local s,id=GetID()

local SET_MAGICA		  = 0x654
local SET_SOULGEM		= 0xc7d
local CARD_MADOKA_1	= 999900001
local CARD_MADOKA_2	= 999900002
local CARD_MADOKA_3	= 999900003
local CARD_KYUBEI		= 999900007
local TOKEN_GRIEF_SEED  = 999900006

s.listed_series={SET_MAGICA, SET_SOULGEM}
s.listed_names={CARD_MADOKA_1, CARD_MADOKA_2, CARD_MADOKA_3, CARD_KYUBEI, TOKEN_GRIEF_SEED}

function s.initial_effect(c)
	-- (This card is always treated as a "Magica" card.)
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_ADD_SETCODE)
	e0:SetValue(SET_MAGICA)
	c:RegisterEffect(e0)

	-- Equip Limit (Chỉ trang bị cho 1 trong 3 lá Madoka)
	local e_eq=Effect.CreateEffect(c)
	e_eq:SetType(EFFECT_TYPE_SINGLE)
	e_eq:SetCode(EFFECT_EQUIP_LIMIT)
	e_eq:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e_eq:SetValue(s.eqlimit)
	c:RegisterEffect(e_eq)

	-- 1. Kích hoạt từ tay (You can only activate 1 "Madoka Soulgems" per turn)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_EQUIP)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)

	-- 2. Trao hiệu ứng cho quái thú được trang bị
	local ge=Effect.CreateEffect(c)
	ge:SetDescription(aux.Stringid(id,4))
	ge:SetCategory(CATEGORY_DESTROY)
	ge:SetType(EFFECT_TYPE_IGNITION)
	ge:SetRange(LOCATION_MZONE)
	ge:SetCountLimit(1)
	ge:SetTarget(s.looktg)
	ge:SetOperation(s.lookop)

	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_GRANT)
	e2:SetRange(LOCATION_SZONE)
	e2:SetTargetRange(LOCATION_MZONE,LOCATION_MZONE)
	e2:SetTarget(s.eftg)
	e2:SetValue(function(e,c) return ge end)
	c:RegisterEffect(e2)

	-- 3. Hiệu ứng GY/Discard (Tối đa triệu hồi Grief Seed Token 2 lần/lượt toàn game)
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
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
	return c:IsFaceup() and c:IsCode(CARD_MADOKA_1, CARD_MADOKA_2, CARD_MADOKA_3)
end

function s.eftg(e,c)
	return c==e:GetHandler():GetEquipTarget()
end

--------------------------------------------------------------------------------
-- 1. ACTIVATION EFFECTS
--------------------------------------------------------------------------------
function s.thfilter(c)
	return c:IsCode(CARD_MADOKA_1, CARD_KYUBEI) and c:IsAbleToHand()
end

function s.madokafilter(c)
	return c:IsFaceup() and c:IsCode(CARD_MADOKA_1, CARD_MADOKA_2, CARD_MADOKA_3)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and s.madokafilter(chkc) and chkc:IsControler(tp) end
	local b1=Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil)
	local b2=Duel.IsExistingTarget(s.madokafilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil)
	if chk==0 then return b1 or b2 end

	local op=0
	if b1 and b2 then
		op=Duel.SelectOption(tp,aux.Stringid(id,2),aux.Stringid(id,3))
	elseif b1 then
		op=Duel.SelectOption(tp,aux.Stringid(id,2))
	else
		op=Duel.SelectOption(tp,aux.Stringid(id,3))+1
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
		Duel.SelectTarget(tp,s.madokafilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,1,nil)
		Duel.SetOperationInfo(0,CATEGORY_EQUIP,e:GetHandler(),1,0,0)
	end
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local op=e:GetLabel()

	if op==0 then
		-- Nếu chọn Search: Tìm bài xong thì đưa lá Spell này xuống Mộ luôn để tránh kẹt sân
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
		if #g>0 then
			Duel.SendtoHand(g,nil,REASON_EFFECT)
			Duel.ConfirmCards(1-tp,g)
			if c:IsRelateToEffect(e) then
				Duel.BreakEffect()
				Duel.SendtoGrave(c,REASON_EFFECT) 
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
-- 2. GRANTED EFFECT FOR EQUIPPED MONSTER
--------------------------------------------------------------------------------
function s.looktg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetFieldGroupCount(tp,0,LOCATION_DECK)>=5 end
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,1,1-tp,LOCATION_DECK)
end

function s.lookop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetFieldGroupCount(tp,0,LOCATION_DECK)<5 then return end
	local g=Duel.GetDecktopGroup(1-tp,5)
	Duel.ConfirmCards(tp,g)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local sg=g:Select(tp,1,1,nil)
	if #sg>0 and Duel.Destroy(sg,REASON_EFFECT)>0 then
		local rem=g-sg
		if #rem>0 then
			Duel.SortDecktop(tp,1-tp,#rem)
		end
	end
end

--------------------------------------------------------------------------------
-- 3. GY EFFECT & GRANT EFFECT TO TOKEN
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
		
		Duel.BreakEffect()
		local token=Duel.CreateToken(tp,TOKEN_GRIEF_SEED)
		if Duel.SpecialSummon(token,0,tp,tp,false,false,POS_FACEUP)>0 then
			-- Trao hiệu ứng Quick Effect hồi 1500 LP cho Token
			local e1=Effect.CreateEffect(c)
			e1:SetDescription(aux.Stringid(id,5))
			e1:SetCategory(CATEGORY_RECOVER)
			e1:SetType(EFFECT_TYPE_QUICK_O)
			e1:SetCode(EVENT_FREE_CHAIN)
			e1:SetRange(LOCATION_MZONE)
			e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E)
			e1:SetCountLimit(1)
			e1:SetTarget(s.lptg)
			e1:SetOperation(s.lpop)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD)
			token:RegisterEffect(e1)
		end
	end
end

function s.lptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetTargetPlayer(tp)
	Duel.SetTargetParam(1500)
	Duel.SetOperationInfo(0,CATEGORY_RECOVER,nil,0,tp,1500)
end

function s.lpop(e,tp,eg,ep,ev,re,r,rp)
	local p,d=Duel.GetChainInfo(0,CHAININFO_TARGET_PLAYER,CHAININFO_TARGET_PARAM)
	Duel.Recover(p,d,REASON_EFFECT)
end