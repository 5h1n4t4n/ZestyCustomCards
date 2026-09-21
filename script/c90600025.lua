-- Sky Striker Maneuver - Precision Strike
-- ID: 02772337
local s,id=GetID()
function s.initial_effect(c)
	-- Kích hoạt: Loại bỏ tối đa 3 lá từ Mộ đối thủ, nếu có từ 3 Phép trở lên trong Mộ -> Loại bỏ ngẫu nhiên 1 lá trên tay đối thủ
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_REMOVE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetCondition(s.actcon)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end
s.listed_series={SET_SKY_STRIKER}

--------------------------------------------------------------------------------
-- LOGIC KIỂM TRA ĐIỀU KIỆN KÍCH HOẠT (Main Monster Zone trống)
--------------------------------------------------------------------------------
function s.actcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetFieldGroupCount(tp,LOCATION_MZONE,0)==0 or not Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsLocation,LOCATION_MZONE),tp,LOCATION_MZONE,0,1,nil)
end

--------------------------------------------------------------------------------
-- TARGET & OPERATION
--------------------------------------------------------------------------------
function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_GRAVE) and chkc:IsControler(1-tp) and chkc:IsAbleToRemove() end
	if chk==0 then return Duel.IsExistingTarget(Card.IsAbleToRemove,tp,0,LOCATION_GRAVE,1,nil) end
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectTarget(tp,Card.IsAbleToRemove,tp,0,LOCATION_GRAVE,1,3,nil)
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,g,#g,1-tp,LOCATION_GRAVE)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local tg=Duel.GetChainInfo(0,CHAININFO_TARGET_CARDS)
	local sg=tg:Filter(Card.IsRelateToEffect,nil,e)
	if #sg>0 and Duel.Remove(sg,POS_FACEUP,REASON_EFFECT)>0 then
		-- Kiểm tra xem trong Mộ có từ 3 Phép trở lên hay không
		if Duel.GetMatchingGroupCount(Card.IsSpell,tp,LOCATION_GRAVE,0,nil)>=3 then
			local hand=Duel.GetFieldGroup(1-tp,LOCATION_HAND,0)
			if #hand>0 and Duel.SelectYesNo(tp,aux.Stringid(id,1)) then
				Duel.BreakEffect()
				local rg=hand:RandomSelect(tp,1)
				if #rg>0 then
					Duel.Remove(rg,POS_FACEDOWN,REASON_EFFECT)
				end
			end
		end
	end
end