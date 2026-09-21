-- Sky Striker Maneuver - Requisition
-- ID: 90600022
local s,id=GetID()
function s.initial_effect(c)
	-- Hiệu ứng: Kích hoạt 1 trong 2 hiệu ứng (nếu không điều khiển quái thú nào ở Vùng Quái Thú Chính)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCondition(s.condition)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	c:RegisterEffect(e1)
end

s.listed_series={0x115}
s.listed_names={id}

-- ==================================================
-- LOGIC HIỆU ỨNG
-- ==================================================
function s.condition(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetFieldGroupCount(tp,LOCATION_MMZONE,0)==0
end

-- Bộ lọc cho hiệu ứng 1: Thêm 1 lá "Sky Striker" từ Deck, GY, hoặc bị trục xuất lên tay (trừ chính nó)
function s.thfilter(c)
	return c:IsSetCard(0x115) and not c:IsCode(id) and c:IsAbleToHand()
end

-- Bộ lọc cho hiệu ứng 2: Mục tiêu là 1 lá bài trong Mộ đối thủ và gắn vào Quái thú Xyz "Sky Striker"
function s.xyzfilter(c)
	return c:IsFaceup() and c:IsSetCard(0x115) and c:IsType(TYPE_XYZ)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		if e:GetLabel()==2 then
			return chkc:IsControler(1-tp) and chkc:IsLocation(LOCATION_GRAVE)
		end
		return false
	end
	
	local b1=Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK+LOCATION_GRAVE+LOCATION_REMOVED,0,1,nil)
	local b2=Duel.IsExistingTarget(aux.TRUE,tp,0,LOCATION_GRAVE,1,nil) 
		and Duel.IsExistingMatchingCard(s.xyzfilter,tp,LOCATION_MZONE,0,1,nil)

	if chk==0 then return b1 or b2 end

	local op=0
	if b1 and b2 then
		op=Duel.SelectOption(tp,aux.Stringid(id,1),aux.Stringid(id,2))
	elseif b1 then
		op=Duel.SelectOption(tp,aux.Stringid(id,1))
	else
		op=Duel.SelectOption(tp,aux.Stringid(id,2))+1
	end
	e:SetLabel(op+1)

	if op==0 then
		e:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
		e1:SetProperty(0)
		Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE+LOCATION_REMOVED)
	else
		e:SetCategory(0)
		e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATTACH)
		local g=Duel.SelectTarget(tp,aux.TRUE,tp,0,LOCATION_GRAVE,1,1,nil)
		Duel.SetOperationInfo(0,CATEGORY_LEAVE_GRAVE,g,1,0,0)
	end
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local op=e:GetLabel()
	if op==1 then
		-- Hiệu ứng 1: Thêm bài lên tay
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK+LOCATION_GRAVE+LOCATION_REMOVED,0,1,1,nil)
		if #g>0 then
			Duel.SendtoHand(g,nil,REASON_EFFECT)
			Duel.ConfirmCards(1-tp,g)
		end
	else
		-- Hiệu ứng 2: Gắn bài vào Xyz Monster
		local tc=Duel.GetFirstTarget()
		local xyz=Duel.SelectMatchingCard(tp,s.xyzfilter,tp,LOCATION_MZONE,0,1,1,nil):GetFirst()
		if tc and tc:IsRelateToEffect(e) and xyz then
			Duel.Overlay(xyz,tc)
		end
	end
end