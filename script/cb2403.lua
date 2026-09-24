--Little Princess of the Nightbloom
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

	--Activate
	local e3=Effect.CreateEffect(c)
	e3:SetCategory(CATEGORY_DESTROY+CATEGORY_REMOVE+CATEGORY_TOHAND+CATEGORY_SEARCH)
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

function s.fieldfilter(c,tp)
	return c:IsType(TYPE_FIELD) and not c:IsForbidden() and c:CheckUniqueOnField(tp,LOCATION_FZONE)
end

function s.thfilter(c)
	return c:IsSetCard(0xb24) and c:IsType(TYPE_SPELL) and c:IsAbleToHand()
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	local is_opp_turn = (Duel.GetTurnPlayer()~=tp)
	if chk==0 then
		if is_opp_turn then
			return Duel.IsExistingMatchingCard(s.fieldfilter,tp,LOCATION_DECK,0,1,nil,tp)
		else
			return Duel.GetFieldGroupCount(tp,0,LOCATION_EXTRA)>0
		end
	end
	if is_opp_turn then
		Duel.SetPossibleOperationInfo(0,CATEGORY_DESTROY,nil,1,1-tp,LOCATION_ONFIELD)
	else
		Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,1,1-tp,LOCATION_EXTRA)
		Duel.SetPossibleOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
	end
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local is_opp_turn = (Duel.GetTurnPlayer()~=tp)

	if is_opp_turn then
		--Opponent's turn: Place 1 Field Spell from Deck in Field Zone, then destroy 1 card opponent controls
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOFIELD)
		local tc=Duel.SelectMatchingCard(tp,s.fieldfilter,tp,LOCATION_DECK,0,1,1,nil,tp):GetFirst()
		if tc and Duel.MoveToField(tc,tp,tp,LOCATION_FZONE,POS_FACEUP,true) then
			local dg=Duel.GetMatchingGroup(nil,tp,0,LOCATION_ONFIELD,nil)
			if #dg>0 then
				Duel.BreakEffect()
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
				local des=dg:Select(tp,1,1,nil)
				Duel.HintSelection(des,true)
				Duel.Destroy(des,REASON_EFFECT)
			end
		end
	else
		--Your turn: Look at opponent's Extra Deck, banish 1 face-down, then add 1 "Nightbloom" Spell from Deck to hand
		local g=Duel.GetFieldGroup(tp,0,LOCATION_EXTRA)
		if #g==0 then return end
		Duel.ConfirmCards(tp,g)
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
		local sg=g:FilterSelect(tp,Card.IsAbleToRemove,1,1,nil,POS_FACEDOWN)
		if #sg>0 and Duel.Remove(sg,POS_FACEDOWN,REASON_EFFECT)>0 then
			local thg=Duel.GetMatchingGroup(s.thfilter,tp,LOCATION_DECK,0,nil)
			if #thg>0 then
				Duel.BreakEffect()
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
				local hg=thg:Select(tp,1,1,nil)
				Duel.SendtoHand(hg,nil,REASON_EFFECT)
				Duel.ConfirmCards(1-tp,hg)
			end
		end
	end
end