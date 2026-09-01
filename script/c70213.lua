--Flower Spirit-Piece of Memories
local s,id=GetID()

function s.initial_effect(c)
	--Activate
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_TODECK+CATEGORY_DRAW+CATEGORY_TOGRAVE+CATEGORY_REMOVE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id+EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
	--Banish trigger from GY
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_TOHAND+CATEGORY_TOGRAVE)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_REMOVE)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCondition(s.thcon)
	e2:SetCost(s.thcost)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
end

function s.spfilter(c)
	return c:IsType(TYPE_SPELL) and c:IsAbleToDeck()
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		local hg=Duel.GetMatchingGroup(s.spfilter,tp,LOCATION_HAND,0,c)
		local fg=Duel.GetMatchingGroup(s.spfilter,tp,LOCATION_ONFIELD,0,c)
		local gg=Duel.GetMatchingGroup(s.spfilter,tp,LOCATION_GRAVE,0,nil)
		local bg=Duel.GetMatchingGroup(s.spfilter,tp,LOCATION_REMOVED,0,nil)
		return #hg>0 and #fg>0 and #gg>0 and #bg>0 and Duel.IsPlayerCanDraw(tp,4)
	end
	Duel.SetOperationInfo(0,CATEGORY_TODECK,nil,4,tp,LOCATION_HAND+LOCATION_ONFIELD+LOCATION_GRAVE+LOCATION_REMOVED)
	Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,4)
end

function s.fsspell(c)
	return c:IsSetCard(0x702) and c:IsType(TYPE_SPELL)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local hg=Duel.GetMatchingGroup(s.spfilter,tp,LOCATION_HAND,0,c)
	local fg=Duel.GetMatchingGroup(s.spfilter,tp,LOCATION_ONFIELD,0,c)
	local gg=Duel.GetMatchingGroup(s.spfilter,tp,LOCATION_GRAVE,0,nil)
	local bg=Duel.GetMatchingGroup(s.spfilter,tp,LOCATION_REMOVED,0,nil)
	if #hg==0 or #fg==0 or #gg==0 or #bg==0 then return end
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	local sh=hg:Select(tp,1,1,nil)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	local sf=fg:Select(tp,1,1,nil)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	local sg=gg:Select(tp,1,1,nil)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	local sb=bg:Select(tp,1,1,nil)
	
	local g=Group.CreateGroup()
	g:Merge(sh)
	g:Merge(sf)
	g:Merge(sg)
	g:Merge(sb)
	
	if #g==4 and Duel.SendtoDeck(g,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)==4 then
		Duel.BreakEffect()
		if Duel.Draw(tp,4,REASON_EFFECT)==4 then
			local og=Duel.GetOperatedGroup()
			Duel.ConfirmCards(1-tp,og)
			if not og:IsExists(s.fsspell,1,nil) then
				local hand=Duel.GetFieldGroup(tp,LOCATION_HAND,0)
				Duel.SendtoGrave(hand,REASON_EFFECT)
			else
				-- Chuỗi bắt buộc 4 bước tuần tự theo đúng text lá bài:
				-- Bước 1: Bắt buộc Set 1 lá từ tay (nếu có lá bài Set được)
				local hand=Duel.GetFieldGroup(tp,LOCATION_HAND,0)
				local setg=hand:Filter(Card.IsSSetable,nil)
				if #setg>0 then
					Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
					local setc=setg:Select(tp,1,1,nil)
					Duel.SSet(tp,setc)
				end
				
				-- Bước 2: Bắt buộc gửi 1 lá từ tay xuống Mộ
				hand=Duel.GetFieldGroup(tp,LOCATION_HAND,0)
				if #hand>0 then
					Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
					local tgc=hand:Select(tp,1,1,nil)
					Duel.SendtoGrave(tgc,REASON_EFFECT)
				end
				
				-- Bước 3: Bắt buộc Banish 1 lá từ tay
				hand=Duel.GetFieldGroup(tp,LOCATION_HAND,0)
				if #hand>0 then
					Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
					local rmc=hand:Select(tp,1,1,nil)
					Duel.Remove(rmc,POS_FACEUP,REASON_EFFECT)
				end
				
				-- Bước 4: Bắt buộc đặt 1 lá từ tay xuống đáy Deck
				hand=Duel.GetFieldGroup(tp,LOCATION_HAND,0)
				if #hand>0 then
					Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
					local btc=hand:Select(tp,1,1,nil)
					Duel.SendtoDeck(btc,nil,SEQ_DECKBOTTOM,REASON_EFFECT)
				end
			end
			Duel.ShuffleHand(tp)
		end
	end
end

function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsPreviousLocation(LOCATION_GRAVE)
end
function s.costfilter(c)
	return c:IsType(TYPE_SPELL) and c:IsAbleToGraveAsCost()
end
function s.thcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.costfilter,tp,LOCATION_HAND,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g=Duel.SelectMatchingCard(tp,s.costfilter,tp,LOCATION_HAND,0,1,1,nil)
	Duel.SendtoGrave(g,REASON_COST)
end
function s.thfilter(c)
	return c:IsSetCard(0x702) and c:IsType(TYPE_SPELL) and not c:IsCode(id) and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_REMOVED,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_REMOVED)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_REMOVED,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end