-- Chrysos Heirs: Tribbie - Demigod of Passage
-- ID: 888800009
local s,id=GetID()

local SET_CHRYSOS_HEIRS = 0xffa
local CARD_ERA_NOVA	 = 888800001

s.listed_series={SET_CHRYSOS_HEIRS}
s.listed_names={CARD_ERA_NOVA}

function s.initial_effect(c)
	-- Ritual Monster setup
	c:EnableReviveLimit()

	----------------------------------------------------------------------------
	-- EFFECT 1: Reveal lá này trên tay -> Search lá "Era Nova" / đề cập "Era Nova"
	-- Xáo 1 lá trên tay vào Deck (Nếu xáo lá Tribbie -> được xáo thêm 1 lá Era Nova từ Hand/GY/Banish)
	-- Giới hạn: 1 lần/trận (Once per duel)
	----------------------------------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_TODECK)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_DUEL)
	e1:SetCost(s.revcost)
	e1:SetTarget(s.revtg)
	e1:SetOperation(s.revop)
	c:RegisterEffect(e1)

	----------------------------------------------------------------------------
	-- EFFECT 2: Khi bị Tributed -> Lấy 1 "Era Nova" từ GY lên tay (1 lần/lượt)
	----------------------------------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_RELEASE)
	e2:SetCountLimit(1,id+100)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
end

--------------------------------------------------------------------------------
-- HELPER CHECK (Tự động kiểm tra Era Nova - Không cần nhập thủ công ID)
--------------------------------------------------------------------------------
function s.check_nova(c)
	if c:IsCode(CARD_ERA_NOVA) then return true end
	---@diagnostic disable-next-line: undefined-field
	if c.ListsCode and c:ListsCode(CARD_ERA_NOVA) then return true end
	if c.listed_names then
		for _, code in ipairs(c.listed_names) do
			if code == CARD_ERA_NOVA then return true end
		end
	end
	return false
end

--------------------------------------------------------------------------------
-- EFFECT 1 LOGIC
--------------------------------------------------------------------------------
function s.srchfilter(c)
	return s.check_nova(c) and not c:IsCode(id) and c:IsAbleToHand()
end

function s.shuffilter(c)
	return s.check_nova(c) and c:IsAbleToDeck() and (c:IsFaceup() or not c:IsLocation(LOCATION_REMOVED))
end

function s.revcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return not c:IsPublic() end
	Duel.ConfirmCards(1-tp,c)
	Duel.ShuffleHand(tp)
end

function s.revtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.srchfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
	Duel.SetOperationInfo(0,CATEGORY_TODECK,nil,1,tp,LOCATION_HAND)
end

function s.revop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.srchfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 and Duel.SendtoHand(g,nil,REASON_EFFECT)>0 and g:GetFirst():IsLocation(LOCATION_HAND) then
		Duel.ConfirmCards(1-tp,g)
		Duel.ShuffleHand(tp)
		Duel.BreakEffect()
		
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
		local sg=Duel.SelectMatchingCard(tp,Card.IsAbleToDeck,tp,LOCATION_HAND,0,1,1,nil)
		if #sg>0 then
			local sc=sg:GetFirst()
			local is_tribbie=(sc==c) or sc:IsCode(id)
			if Duel.SendtoDeck(sc,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)>0 and sc:IsLocation(LOCATION_DECK+LOCATION_EXTRA) then
				if is_tribbie then
					local shuf_g=Duel.GetMatchingGroup(aux.NecroValleyFilter(s.shuffilter),tp,LOCATION_HAND+LOCATION_GRAVE+LOCATION_REMOVED,0,nil)
					if #shuf_g>0 and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
						Duel.BreakEffect()
						Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
						local g2=shuf_g:Select(tp,1,1,nil)
						if #g2>0 then
							Duel.SendtoDeck(g2,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
						end
					end
				end
			end
		end
	end
end

--------------------------------------------------------------------------------
-- EFFECT 2 LOGIC
--------------------------------------------------------------------------------
function s.novafilter(c)
	return c:IsCode(CARD_ERA_NOVA) and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.novafilter,tp,LOCATION_GRAVE,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_GRAVE)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.novafilter),tp,LOCATION_GRAVE,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end