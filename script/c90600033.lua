-- Sky Striker Mobilize - Vanguard
-- ID: 90600033
local s,id=GetID()
function s.initial_effect(c)
	-- Kích hoạt: Đào 5 lá từ đỉnh Deck, thêm 1 lá "Sky Striker" lên tay, phần còn lại xáo vào Deck, nếu có từ 3 Phép trở lên trong Mộ -> Đưa tối đa 2 lá "Sky Striker" bị loại bỏ vào Mộ
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_DECKDES+CATEGORY_TOGRAVE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
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
function s.cfilter(c)
	return c:GetSequence()<5
end

function s.actcon(e,tp,eg,ep,ev,re,r,rp)
	-- Kiểm tra nếu có lá bài khác trên sân cấp quyền bỏ qua điều kiện Main Zone
	if Duel.IsPlayerAffectedByEffect(tp, 90600033+TYPE_SPELL) -- Giả định cờ bỏ qua điều kiện của bạn
		or Duel.IsPlayerAffectedByEffect(tp, EFFECT_SKIP_MAIN_ZONE_CHECK) then 
		return true 
	end

	-- Kiểm tra chuẩn: Main Monster Zone (ô 0 đến 4) không có quái thú nào
	return not Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_MZONE,0,1,nil)
end

--------------------------------------------------------------------------------
-- TARGET & OPERATION
--------------------------------------------------------------------------------
function s.thfilter(c)
	return c:IsSetCard(SET_SKY_STRIKER) and c:IsAbleToHand()
end

function s.gyfilter(c)
	return c:IsSetCard(SET_SKY_STRIKER) and c:IsFaceup() and c:IsAbleToGrave()
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)>=5 end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)<5 then return end
	Duel.ConfirmDecktop(tp,5)
	local g=Duel.GetDecktopGroup(tp,5)
	if #g>0 then
		if g:IsExists(s.thfilter,1,nil) and Duel.SelectYesNo(tp,aux.Stringid(id,1)) then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
			local sg=g:FilterSelect(tp,s.thfilter,1,1,nil)
			if #sg>0 then
				Duel.SendtoHand(sg,nil,REASON_EFFECT)
				Duel.ConfirmCards(1-tp,sg)
				g:Sub(sg)
			end
		end
		Duel.ShuffleDeck(tp)
		
		-- Nếu trong Mộ có từ 3 Phép trở lên, có thể đưa tối đa 2 lá "Sky Striker" bị loại bỏ vào Mộ
		if Duel.GetMatchingGroupCount(Card.IsSpell,tp,LOCATION_GRAVE,0,nil)>=3 
			and Duel.IsExistingMatchingCard(s.gyfilter,tp,LOCATION_REMOVED,LOCATION_REMOVED,1,nil)
			and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
			
			Duel.BreakEffect()
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
			local tg=Duel.SelectMatchingCard(tp,s.gyfilter,tp,LOCATION_REMOVED,LOCATION_REMOVED,1,2,nil)
			if #tg>0 then
				Duel.SendtoGrave(tg,REASON_EFFECT+REASON_RETURN)
			end
		end
	end
end