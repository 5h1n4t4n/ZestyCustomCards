--Nightbloom - Moonlight Princess
local s,id=GetID()

function s.initial_effect(c)
	--Always treated as a "Flower Spirit" card
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_ADD_SETCODE)
	e0:SetValue(0x702)
	c:RegisterEffect(e0)

	--Cannot be Set
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_CANNOT_SET)
	c:RegisterEffect(e1)

	--Can activate from hand during opponent's turn
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_QP_ACT_IN_NTPHAND)
	c:RegisterEffect(e2)

	--Activation
	local e3=Effect.CreateEffect(c)
	e3:SetCategory(CATEGORY_DRAW+CATEGORY_HANDES+CATEGORY_TOHAND+CATEGORY_TODECK)
	e3:SetType(EFFECT_TYPE_ACTIVATE)
	e3:SetCode(EVENT_CHAINING)
	e3:SetCountLimit(1,id+EFFECT_COUNT_CODE_OATH)
	e3:SetCost(s.cost)
	e3:SetCondition(s.condition_opp)
	e3:SetTarget(s.target_opp)
	e3:SetOperation(s.activate_opp)
	c:RegisterEffect(e3)

	--Activation during your turn (Free Chain)
	local e4=Effect.CreateEffect(c)
	e4:SetCategory(CATEGORY_DRAW+CATEGORY_TOHAND+CATEGORY_TODECK)
	e4:SetType(EFFECT_TYPE_ACTIVATE)
	e4:SetCode(EVENT_FREE_CHAIN)
	e4:SetCountLimit(1,id+EFFECT_COUNT_CODE_OATH)
	e4:SetCost(s.cost)
	e4:SetCondition(s.condition_self)
	e4:SetTarget(s.target_self)
	e4:SetOperation(s.activate_self)
	c:RegisterEffect(e4)
end

function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	--You cannot use cards in your Deck, except Spell Cards
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e1:SetCode(EFFECT_CANNOT_ACTIVATE)
	e1:SetTargetRange(1,0)
	e1:SetValue(function(e,re)
		local loc=re:GetActivateLocation()
		return loc==LOCATION_DECK and not re:IsActiveType(TYPE_SPELL)
	end)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
end

-------------------------------------------------------
-- NHÁNH 1: Kích hoạt trong lượt đối thủ (Khi có monster effect kích hoạt)
-------------------------------------------------------
function s.condition_opp(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetTurnPlayer()~=tp and re:IsActiveType(TYPE_MONSTER)
end

function s.target_opp(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
end

function s.activate_opp(e,tp,eg,ep,ev,re,r,rp)
	local g=Group.CreateGroup()
	Duel.ChangeTargetCard(ev,g)
	Duel.ChangeChainOperation(ev,s.repop)
end

function s.repop(e,tp,eg,ep,ev,re,r,rp)
	--Effect becomes: "Both players draw 1 card, then discard 1 card."
	local h1=Duel.Draw(0,1,REASON_EFFECT)
	local h2=Duel.Draw(1,1,REASON_EFFECT)
	if h1>0 or h2>0 then
		Duel.BreakEffect()
		if h1>0 then Duel.DiscardHand(0,nil,1,1,REASON_EFFECT+REASON_DISCARD) end
		if h2>0 then Duel.DiscardHand(1,nil,1,1,REASON_EFFECT+REASON_DISCARD) end
	end
end

-------------------------------------------------------
-- NHÁNH 2: Kích hoạt trong lượt của mình
-------------------------------------------------------
function s.condition_self(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetTurnPlayer()==tp
end

function s.target_self(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsPlayerCanDraw(tp,1) end
	Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,1)
end

function s.thfilter(c)
	return c:IsAbleToHand() and not c:IsCode(id)
end

function s.activate_self(e,tp,eg,ep,ev,re,r,rp)
	if Duel.Draw(tp,1,REASON_EFFECT)==0 then return end
	local tc=Duel.GetOperatedGroup():GetFirst()
	if not tc then return end
	Duel.ConfirmCards(1-tp,tc)

	local is_nb = tc:IsSetCard(0xb24)
	local is_fs = tc:IsSetCard(0x702)

	Duel.BreakEffect()
	if is_nb and not is_fs then
		-- ● "Nightbloom": Draw 1 additional card
		Duel.Draw(tp,1,REASON_EFFECT)
	elseif is_fs and not is_nb then
		-- ● "Flower Spirit": Add 1 card from GY or banishment to hand
		local g=Duel.GetMatchingGroup(s.thfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,nil)
		if #g>0 then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
			local sg=g:Select(tp,1,1,nil)
			Duel.SendtoHand(sg,nil,REASON_EFFECT)
			Duel.ConfirmCards(1-tp,sg)
		end
	elseif is_nb and is_fs then
		-- Trường hợp lá rút mang cả 2 archetype: hỏi chọn 1 trong 2 hiệu ứng
		local op=Duel.SelectEffect(tp,
			{true,aux.Stringid(id,0)},
			{Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,nil),aux.Stringid(id,1)})
		if op==1 then
			Duel.Draw(tp,1,REASON_EFFECT)
		else
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
			local sg=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,1,nil)
			if #sg>0 then
				Duel.SendtoHand(sg,nil,REASON_EFFECT)
				Duel.ConfirmCards(1-tp,sg)
			end
		end
	else
		-- ● Neither: Place 1 card from hand on the bottom of the Deck
		if Duel.IsExistingMatchingCard(Card.IsAbleToDeck,tp,LOCATION_HAND,0,1,nil) then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
			local sg=Duel.SelectMatchingCard(tp,Card.IsAbleToDeck,tp,LOCATION_HAND,0,1,1,nil)
			if #sg>0 then
				Duel.SendtoDeck(sg,nil,SEQ_DECKBOTTOM,REASON_EFFECT)
			end
		end
	end
	Duel.ShuffleHand(tp)
end