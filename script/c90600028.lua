-- Sky Striker Maneuver - Crimson Slash
-- ID: 90600028
local s,id=GetID()

function s.initial_effect(c)
	-- Kích hoạt
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DESTROY+CATEGORY_DECKDES+CATEGORY_TOGRAVE+CATEGORY_REMOVE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetCondition(s.condition)
	e1:SetTarget(s.target)
	e1:SetOperation(s.operation)
	c:RegisterEffect(e1)
end

s.listed_series={0x115}

-- Kiểm tra không có quái thú nào ở Main Monster Zone của bạn
function s.zone_filter(c)
	return c:IsSequence() and c:GetSequence()<5
end

function s.condition(e,tp,eg,ep,ev,re,r,rp)
	return not Duel.IsExistingMatchingCard(s.zone_filter,tp,LOCATION_MZONE,0,1,nil)
end

function s.desfilter(c)
	return c:IsFaceup()
end

function s.stkfilter(c)
	return c:IsFaceup() and c:IsSetCard(0x115)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsControler(1-tp) and chkc:IsOnField() and s.desfilter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.desfilter,tp,0,LOCATION_MZONE,1,nil) end
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectTarget(tp,s.desfilter,tp,0,LOCATION_MZONE,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
	Duel.SetPossibleOperationInfo(0,CATEGORY_TOGRAVE,nil,1,1-tp,LOCATION_DECK)
	Duel.SetPossibleOperationInfo(0,CATEGORY_REMOVE,nil,1,1-tp,LOCATION_HAND)
end

function s.operation(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) and Duel.Destroy(tc,REASON_EFFECT)~=0 then
		-- Nếu bạn điều khiển quái thú "Sky Striker" -> Đào 3 lá từ đỉnh Deck đối thủ, gửi 1 lá xuống Mộ, phần còn lại xáo về Deck
		if Duel.IsExistingMatchingCard(s.stkfilter,tp,LOCATION_MZONE,0,1,nil) 
			and Duel.GetFieldGroupCount(1-tp,LOCATION_DECK,0)>=3 then
			Duel.BreakEffect()
			Duel.ConfirmDecktop(1-tp,3)
			local g=Duel.GetDecktopGroup(1-tp,3)
			if #g>0 then
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
				local tg=g:Select(tp,1,1,nil)
				if #tg>0 then
					Duel.SendtoGrave(tg,REASON_EFFECT)
					g:Sub(tg)
				end
				Duel.ShuffleDeck(1-tp)
			end
		end

		-- Nếu trong Mộ có từ 3 Phép trở lên -> Trục xuất ngẫu nhiên 1 lá trên tay đối thủ đến cuối lượt kế tiếp
		if Duel.GetMatchingGroupCount(Card.IsType,tp,LOCATION_GRAVE,0,nil,TYPE_SPELL)>=3 
			and Duel.GetFieldGroupCount(1-tp,LOCATION_HAND,0)>0 
			and Duel.SelectYesNo(tp,aux.Stringid(id,1)) then
			Duel.BreakEffect()
			local hg=Duel.GetFieldGroup(1-tp,LOCATION_HAND,0):RandomSelect(tp,1)
			if #hg>0 then
				local hc=hg:GetFirst()
				if Duel.Remove(hc,POS_FACEUP,REASON_EFFECT+REASON_TEMPORARY)~=0 then
					hc:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END,0,2)
					local e1=Effect.CreateEffect(e:GetHandler())
					e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
					e1:SetCode(EVENT_PHASE+PHASE_END)
					e1:SetReset(RESET_PHASE+PHASE_END,2)
					e1:SetLabelObject(hc)
					e1:SetCountLimit(1)
					e1:SetCondition(s.retcon)
					e1:SetOperation(s.retop)
					Duel.RegisterEffect(e1,tp)
				end
			end
		end
	end

	-- Giới hạn Triệu hồi Đặc biệt: chỉ được gọi quái thú "Sky Striker" trong phần còn lại của lượt
	local e2=Effect.CreateEffect(e:GetHandler())
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT)
	e2:SetDescription(aux.Stringid(id,2))
	e2:SetTargetRange(1,0)
	e2:SetTarget(s.splimit)
	e2:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e2,tp)
end

function s.splimit(e,c,sump,sumtype,sumpos,targetp,se)
	return not c:IsSetCard(0x115)
end

function s.retcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetTurnPlayer()~=tp and e:GetLabelObject():GetFlagEffect(id)~=0
end

function s.retop(e,tp,eg,ep,ev,re,r,rp)
	local hc=e:GetLabelObject()
	Duel.SendtoHand(hc,nil,REASON_EFFECT)
end