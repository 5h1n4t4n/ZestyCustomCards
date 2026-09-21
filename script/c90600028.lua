-- Sky Striker Maneuver - Crimson Slash
-- ID: 02772337
local s,id=GetID()
function s.initial_effect(c)
	-- Kích hoạt: Tiêu diệt 1 quái ngửa đối thủ, gửi 1 lá từ đỉnh Deck đối thủ vào Mộ nếu điều khiển quái "Sky Striker", và loại bỏ 1 lá từ Mộ đối thủ nếu có từ 3 Phép trở lên trong Mộ
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DESTROY+CATEGORY_TOGRAVE+CATEGORY_REMOVE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetCountLimit(2,id,EFFECT_COUNT_CODE_OATH)
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
function s.filter(c)
	return c:IsFaceup()
end

function s.cfilter(c)
	return c:IsFaceup() and c:IsSetCard(SET_SKY_STRIKER)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(1-tp) and s.filter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.filter,tp,0,LOCATION_MZONE,1,nil) end
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectTarget(tp,s.filter,tp,0,LOCATION_MZONE,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,0,1-tp,LOCATION_DECK)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) and tc:IsFaceup() then
		if Duel.Destroy(tc,REASON_EFFECT)>0 then
			-- Nếu bạn điều khiển quái thú "Sky Striker", gửi 1 lá từ đỉnh Deck đối thủ vào Mộ
			if Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_MZONE,0,1,nil) 
				and Duel.GetFieldGroupCount(1-tp,LOCATION_DECK,0)>0 then
				Duel.BreakEffect()
				Duel.DiscardDeck(1-tp,1,REASON_EFFECT)
			end
			
			-- Nếu trong Mộ bạn có từ 3 Phép trở lên, có thể loại bỏ 1 lá từ Mộ đối thủ cho đến End Phase
			if Duel.GetMatchingGroupCount(Card.IsSpell,tp,LOCATION_GRAVE,0,nil)>=3 
				and Duel.IsExistingMatchingCard(Card.IsAbleToRemove,tp,0,LOCATION_GRAVE,1,nil)
				and Duel.SelectYesNo(tp,aux.Stringid(id,1)) then
				
				Duel.BreakEffect()
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
				local rg=Duel.SelectMatchingCard(tp,Card.IsAbleToRemove,tp,0,LOCATION_GRAVE,1,1,nil)
				if #rg>0 then
					local rc=rg:GetFirst()
					if Duel.Remove(rc,POS_FACEUP,REASON_EFFECT>0) and rc:IsLocation(LOCATION_REMOVED) then
						rc:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END,0,1)
						local e1=Effect.CreateEffect(e:GetHandler())
						e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
						e1:SetCode(EVENT_PHASE+PHASE_END)
						e1:SetReset(RESET_PHASE+PHASE_END)
						e1:SetCountLimit(1)
						e1:SetLabelObject(rc)
						e1:SetOperation(s.retop)
						Duel.RegisterEffect(e1,tp)
					end
				end
			end
		end
	end
end

function s.retop(e,tp,eg,ep,ev,re,r,rp)
	local rc=e:GetLabelObject()
	if rc and rc:GetFlagEffect(id)>0 then
		Duel.SendtoGrave(rc,REASON_EFFECT+REASON_RETURN)
	end
end