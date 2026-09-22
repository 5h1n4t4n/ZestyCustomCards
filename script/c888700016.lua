-- Rising Equip
-- ID: 888700016
local s,id=GetID()

local SET_HERO		= 0x8
local SET_RISING_UNIT = 0xa63

s.listed_series={SET_HERO, SET_RISING_UNIT}

function s.initial_effect(c)
	-- Quy tắc Phép Trang Bị: Chỉ trang bị cho quái thú "HERO"
	aux.AddEquipProcedure(c, 0, s.eqfilter)

	-- Hiệu ứng 1: Quái được trang bị không thể bị Hiến tế (cannot be Tributed)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_EQUIP)
	e1:SetCode(EFFECT_UNRELEASABLE_SUM)
	e1:SetValue(1)
	c:RegisterEffect(e1)
	local e2=e1:Clone()
	e2:SetCode(EFFECT_UNRELEASABLE_NONSUM)
	c:RegisterEffect(e2)

	-- Hiệu ứng 2: Đối thủ không thể chỉ định quái được trang bị bằng hiệu ứng bài
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_EQUIP)
	e3:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e3:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE)
	e3:SetValue(aux.tgoval)
	c:RegisterEffect(e3)

	-- Hiệu ứng 3: Nếu lá này bị gửi từ Deck xuống Mộ -> Lấy lên tay
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,0))
	e4:SetCategory(CATEGORY_TOHAND)
	e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e4:SetProperty(EFFECT_FLAG_DELAY)
	e4:SetCode(EVENT_TO_GRAVE)
	e4:SetCountLimit(1,id) -- [HOPT] Mỗi lượt chỉ dùng hiệu ứng này 1 lần
	e4:SetCondition(s.thcon)
	e4:SetTarget(s.thtg)
	e4:SetOperation(s.thop)
	c:RegisterEffect(e4)
end

function s.eqfilter(c)
	return c:IsSetCard(SET_HERO)
end

--------------------------------------------------------------------------------
-- ADD TO HAND LOGIC
--------------------------------------------------------------------------------
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsPreviousLocation(LOCATION_DECK)
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsAbleToHand() end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,c,1,0,0)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SendtoHand(c,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,c)
	end
end