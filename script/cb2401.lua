--Into The Nightbloom
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
	e3:SetCategory(CATEGORY_TODECK+CATEGORY_DRAW+CATEGORY_REMOVE)
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

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	local is_opp_turn = (Duel.GetTurnPlayer()~=tp)
	if chk==0 then
		if is_opp_turn then
			return Duel.IsExistingMatchingCard(Card.IsAbleToDeck,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil)
		else
			-- Cần tối thiểu 6 lá trong Deck (1 lá rút + 5 lá banish)
			return Duel.IsPlayerCanDraw(tp,1) and Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)>=6
		end
	end
	if is_opp_turn then
		--Your opponent cannot activate cards or effects in response to this effect
		Duel.SetChainLimit(function(e,ep,tp) return ep==tp end)
		local g=Duel.GetMatchingGroup(Card.IsAbleToDeck,tp,LOCATION_MZONE,LOCATION_MZONE,nil)
		Duel.SetOperationInfo(0,CATEGORY_TODECK,g,1,0,0)
	else
		Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,1)
	end
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local is_opp_turn = (Duel.GetTurnPlayer()~=tp)

	if is_opp_turn then
		--Opponent's turn effect
		local g=Duel.GetMatchingGroup(Card.IsAbleToDeck,tp,LOCATION_MZONE,LOCATION_MZONE,nil)
		if #g==0 then return end
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
		local sg=g:Select(tp,1,#g,nil)
		local ct=#sg
		if ct>0 then
			--Opponent can banish top 3*ct cards of Deck face-down to negate
			local req_count=ct*3
			local deck_ct=Duel.GetFieldGroupCount(1-tp,LOCATION_DECK,0)
			if deck_ct>=req_count and Duel.SelectYesNo(1-tp,aux.Stringid(id,0)) then
				local rg=Duel.GetDecktopGroup(1-tp,req_count)
				Duel.DisableShuffleCheck()
				Duel.Remove(rg,POS_FACEDOWN,REASON_EFFECT)
				return
			end
			Duel.SendtoDeck(sg,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
		end
	else
		--Your turn effect: Draw up to 5, then banish top 5 cards face-down per card drawn
		local max_draw=5
		local deck_count=Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)
		local possible_draw=math.floor(deck_count/6)
		if possible_draw<1 then return end
		if possible_draw>5 then possible_draw=5 end

		local t={}
		for i=1,possible_draw do t[i]=i end
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_NUMBER)
		local num=Duel.AnnounceNumber(tp,table.unpack(t))
		
		local drawn=Duel.Draw(tp,num,REASON_EFFECT)
		if drawn>0 then
			Duel.BreakEffect()
			local bcount=drawn*5
			local rg=Duel.GetDecktopGroup(tp,bcount)
			if #rg>0 then
				Duel.DisableShuffleCheck()
				Duel.Remove(rg,POS_FACEDOWN,REASON_EFFECT)
			end
		end
	end
end