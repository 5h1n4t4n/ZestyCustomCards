-- Sky Striker Maneuver - Sabotage
-- ID: 90600021
local s,id=GetID()

function s.initial_effect(c)
	-- Kích hoạt: Bỏ ngẫu nhiên 1 quái thú từ Extra Deck của đối thủ úp xuống
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_REMOVE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetCondition(s.actcon)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

s.listed_series={0x115} -- SET_SKY_STRIKER

-- Kiểm tra không có quái thú nào trong Main Monster Zone của bạn
function s.zone_filter(c)
	return c:IsSequence() and c:GetSequence()<5
end

function s.actcon(e,tp,eg,ep,ev,re,r,rp)
	return not Duel.IsExistingMatchingCard(s.zone_filter,tp,LOCATION_MZONE,0,1,nil)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetFieldGroupCount(1-tp,LOCATION_EXTRA,0)>0 end
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,1,1-tp,LOCATION_EXTRA)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetFieldGroup(1-tp,LOCATION_EXTRA,0)
	if #g>0 then
		local sg=g:RandomSelect(tp,1)
		if #sg>0 and Duel.Remove(sg,POS_FACEDOWN,REASON_EFFECT)~=0 then
			-- Kiểm tra xem trong Mộ có từ 3 Phép trở lên hay không
			if Duel.GetMatchingGroupCount(Card.IsSpell,tp,LOCATION_GRAVE,0,nil)>=3 then
				local g2=Duel.GetFieldGroup(1-tp,LOCATION_EXTRA,0)
				if #g2>0 and Duel.SelectYesNo(tp,aux.Stringid(id,1)) then
					Duel.BreakEffect()
					local sg2=g2:RandomSelect(tp,1)
					if #sg2>0 then
						Duel.Remove(sg2,POS_FACEDOWN,REASON_EFFECT)
					end
				end
			end
		end
	end

	-- Giới hạn Triệu hồi Đặc biệt: chỉ được gọi quái thú "Sky Striker" trong phần còn lại của lượt
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT)
	e1:SetDescription(aux.Stringid(id,2))
	e1:SetTargetRange(1,0)
	e1:SetTarget(s.splimit)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
end

function s.splimit(e,c,sump,sumtype,sumpos,targetp,se)
	return not c:IsSetCard(0x115)
end