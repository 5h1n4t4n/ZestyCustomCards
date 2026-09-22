-- Sky Striker Maneuver - Interception
-- ID: 02772337
local s,id=GetID()
function s.initial_effect(c)
	-- Kích hoạt: Loại bỏ úp mặt 1 lá ngửa đối thủ điều khiển (nếu MMZ trống), nếu có từ 3 Phép trở lên trong Mộ -> Chọn 1 trong 2 hiệu ứng phụ
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
function s.tgfilter(c)
	return c:IsFaceup() and c:IsAbleToRemove(tp,POS_FACEDOWN)
end

function s.xyzfilter(c)
	return c:IsFaceup() and c:IsSetCard(SET_SKY_STRIKER) and c:IsType(TYPE_XYZ)
end

function s.matfilter(c)
	return c:IsCanBeEffectTarget()
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsOnField() and chkc:IsControler(1-tp) and s.tgfilter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.tgfilter,tp,0,LOCATION_ONFIELD,1,nil) end
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectTarget(tp,s.tgfilter,tp,0,LOCATION_ONFIELD,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,g,1,1-tp,LOCATION_ONFIELD)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		if Duel.Remove(tc,POS_FACEDOWN,REASON_EFFECT)>0 then
			-- Kiểm tra xem trong Mộ có từ 3 Phép trở lên hay không
			if Duel.GetMatchingGroupCount(Card.IsSpell,tp,LOCATION_GRAVE,0,nil)>=3 then
				local b1=Duel.GetFieldGroupCount(1-tp,LOCATION_EXTRA)>0
				local b2=Duel.IsExistingMatchingCard(s.xyzfilter,tp,LOCATION_MZONE,0,1,nil) 
					and Duel.IsExistingTarget(s.matfilter,tp,0,LOCATION_GRAVE,1,nil)
				
				if (b1 or b2) and Duel.SelectYesNo(tp,aux.Stringid(id,1)) then
					Duel.BreakEffect()
					local op=0
					if b1 and b2 then
						op=Duel.SelectOption(tp,aux.Stringid(id,2),aux.Stringid(id,3))
					elseif b1 then
						op=Duel.SelectOption(tp,aux.Stringid(id,2))
					else
						op=Duel.SelectOption(tp,aux.Stringid(id,3))+1
					end
					
					if op==0 then
						-- Nhìn Extra Deck đối thủ và loại bỏ úp mặt 1 lá ngẫu nhiên
						local g=Duel.GetFieldGroup(1-tp,LOCATION_EXTRA,0)
						if #g>0 then
							local rg=g:RandomSelect(tp,1)
							Duel.Remove(rg,POS_FACEDOWN,REASON_EFFECT)
						end
					else
						-- Gắn 1 lá từ Mộ đối thủ làm nguyên liệu cho Xyz "Sky Striker"
						Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
						local mg=Duel.SelectMatchingCard(tp,s.matfilter,tp,0,LOCATION_GRAVE,1,1,nil)
						if #mg>0 then
							Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
							local xg=Duel.SelectMatchingCard(tp,s.xyzfilter,tp,LOCATION_MZONE,0,1,1,nil)
							local xc=xg:GetFirst()
							if xc then
								Duel.Overlay(xc,mg)
							end
						end
					end
				end
			end
		end
	end
end