-- Sky Striker Airspace - Sector Omega
-- ID: 02772337
local s,id=GetID()
function s.initial_effect(c)
	-- Activate: Kích hoạt thẻ bài Field Spell
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e0)

	-- HIỆU ỨNG 1: Target 1 lá khác bạn điều khiển -> Lật 4 lá top Deck, chọn 1 lá "Sky Striker" thêm lên tay hoặc gắn làm nguyên liệu cho Xyz "Sky Striker", trộn phần còn lại vào Deck
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_FZONE)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.target)
	e1:SetOperation(s.operation)
	c:RegisterEffect(e1)

	-- HIỆU ỨNG 2: Có thể kích hoạt Phép "Sky Striker" ngay cả khi điều khiển quái thú ở Main Monster Zone
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_SKY_STRIKER_SPELL_ZONE) -- Cờ hiệu chỉnh cho phép kích hoạt Phép Sky Striker trong MMZ
	e2:SetRange(LOCATION_FZONE)
	e2:SetTargetRange(LOCATION_SZONE,0)
	c:RegisterEffect(e2)
	
	-- HIỆU ỨNG 3: Quái thú "Sky Striker" bạn điều khiển tăng 100 ATK/DEF cho mỗi lá Phép trong Mộ của bạn
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetCode(EFFECT_UPDATE_ATTACK)
	e3:SetRange(LOCATION_FZONE)
	e3:SetTargetRange(LOCATION_MZONE,0)
	e3:SetTarget(aux.TargetBoolFunction(Card.IsSetCard,0x115))
	e3:SetValue(s.atkval)
	c:RegisterEffect(e3)
	local e4=e3:Clone()
	e4:SetCode(EFFECT_UPDATE_DEFENSE)
	c:RegisterEffect(e4)
end
s.listed_series={0x115}

--------------------------------------------------------------------------------
-- LOGIC HIỆU ỨNG 1
--------------------------------------------------------------------------------
function s.tgfilter(c,tp)
	return c:IsFaceup() and c~=Duel.GetFieldCard(tp,LOCATION_FZONE,0)
end

function s.excfilter(c)
	return c:IsSetCard(0x115) and (c:IsAbleToHand() or c:IsAbleToChangeToEffect())
end

function s.xyzfilter(c)
	return c:IsFaceup() and c:IsSetCard(0x115) and c:IsType(TYPE_XYZ)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsOnField() and chkc:IsControler(tp) and s.tgfilter(chkc,tp) end
	if chk==0 then return Duel.IsExistingTarget(s.tgfilter,tp,LOCATION_ONFIELD,0,1,e:GetHandler(),tp)
		and Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)>=4 end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	Duel.SelectTarget(tp,s.tgfilter,tp,LOCATION_ONFIELD,0,1,1,e:GetHandler(),tp)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,0,tp,LOCATION_DECK)
end

function s.operation(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if not tc or not tc:IsRelateToEffect(e) then return end
	if Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)<4 then return end
	
	Duel.ConfirmDecktop(tp,4)
	local g=Duel.GetDecktopGroup(tp,4)
	if #g>0 then
		local sg=g:Filter(s.excfilter,nil)
		if #sg>0 and Duel.SelectYesNo(tp,aux.Stringid(id,1)) then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SELECT)
			local tg=sg:Select(tp,1,1,nil)
			local sc=tg:GetFirst()
			g:RemoveCard(sc)
			
			-- Kiểm tra xem muốn thêm lên tay hay gắn làm nguyên liệu cho Xyz "Sky Striker"
			local b1=sc:IsAbleToHand()
			local b2=Duel.IsExistingMatchingCard(s.xyzfilter,tp,LOCATION_MZONE,0,1,nil)
			local op=0
			if b1 and b2 then
				op=Duel.SelectOption(tp,aux.Stringid(id,2),aux.Stringid(id,3))
			elseif b1 then
				op=Duel.SelectOption(tp,aux.Stringid(id,2))
			elseif b2 then
				op=Duel.SelectOption(tp,aux.Stringid(id,3))+1
			else
				op=-1
			end
			
			if op==0 then
				Duel.SendtoHand(sc,nil,REASON_EFFECT)
				Duel.ConfirmCards(1-tp,sc)
			elseif op==1 then
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
				local xyzg=Duel.SelectMatchingCard(tp,s.xyzfilter,tp,LOCATION_MZONE,0,1,1,nil)
				local xyzc=xyzg:GetFirst()
				if xyzc then
					Duel.Overlay(xyzc,sc)
				end
			end
		end
		Duel.ShuffleDeck(tp)
	end
end

--------------------------------------------------------------------------------
-- LOGIC HIỆU ỨNG 3 (Tăng ATK/DEF)
--------------------------------------------------------------------------------
function s.atkval(e,c)
	return Duel.GetMatchingGroupCount(Card.IsType,e:GetHandlerPlayer(),LOCATION_GRAVE,0,nil,TYPE_SPELL)*100
end