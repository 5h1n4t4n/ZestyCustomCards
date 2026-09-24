--Nightbloom - Between Days and Nights
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
	e1:SetCode(EFFECT_CANNOT_SSET)
	c:RegisterEffect(e1)

	--Can activate from hand during opponent's turn
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_QP_ACT_IN_NTPHAND)
	c:RegisterEffect(e2)

	--Activate
	local e3=Effect.CreateEffect(c)
	e3:SetCategory(CATEGORY_TOGRAVE+CATEGORY_HANDES)
	e3:SetType(EFFECT_TYPE_ACTIVATE)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_MAIN_END)
	e3:SetCountLimit(1,id+EFFECT_COUNT_CODE_OATH)
	e3:SetCost(s.cost)
	e3:SetTarget(s.target)
	e3:SetOperation(s.activate)
	c:RegisterEffect(e3)
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

function s.spellfilter(c)
	return c:IsType(TYPE_SPELL) and c:IsAbleToGrave()
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	local is_opp_turn = (Duel.GetTurnPlayer()~=tp)
	if chk==0 then
		if is_opp_turn then
			return Duel.GetFieldGroupCount(tp,0,LOCATION_HAND)>=2
		else
			return Duel.IsExistingMatchingCard(s.spellfilter,tp,LOCATION_DECK,0,2,nil)
		end
	end
	if is_opp_turn then
		Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,2,1-tp,LOCATION_HAND)
	else
		Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,2,tp,LOCATION_DECK)
	end
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local is_opp_turn = (Duel.GetTurnPlayer()~=tp)

	if is_opp_turn then
		--Opponent's turn: Your opponent sends 2 cards from their hand to the GY, of their choice
		local g=Duel.GetFieldGroup(1-tp,LOCATION_HAND,0)
		if #g>=2 then
			Duel.Hint(HINT_SELECTMSG,1-tp,HINTMSG_TOGRAVE)
			local sg=g:Select(1-tp,2,2,nil)
			Duel.SendtoGrave(sg,REASON_EFFECT)
		end
	else
		--Your turn: Send 2 Spell Cards from your Deck to the GY
		local g=Duel.GetMatchingGroup(s.spellfilter,tp,LOCATION_DECK,0,nil)
		if #g>=2 then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
			local sg=g:Select(tp,2,2,nil)
			Duel.SendtoGrave(sg,REASON_EFFECT)
		end
	end
end