--Flower Spirit Fall Down
local s,id=GetID()

function s.initial_effect(c)
	--Activate: banish hand, Special Summon 1 "Flower Spirit" monster from Extra Deck (ignoring conditions)
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_REMOVE+CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id+EFFECT_COUNT_CODE_OATH)
	e1:SetCondition(s.condition)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
	--If this card is banished from GY: shuffle 3 cards from GY into Deck, draw 2
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_TODECK+CATEGORY_DRAW+CATEGORY_REMOVE)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_REMOVE)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetRange(LOCATION_REMOVED)
	e2:SetCondition(s.gcon)
	e2:SetTarget(s.gtg)
	e2:SetOperation(s.gop)
	c:RegisterEffect(e2)
end

function s.condition(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local hand_count=Duel.GetFieldGroupCount(tp,LOCATION_HAND,0)
	--Nếu kích hoạt từ tay: cần ít nhất 2 lá khác trên tay (tổng là 3 tính cả lá này)
	--Nếu kích hoạt từ sân (đã Set): cần ít nhất 3 lá trên tay
	if c:IsLocation(LOCATION_HAND) or c:IsStatus(STATUS_ACT_FROM_HAND) then
		return hand_count>=2
	else
		return hand_count>=3
	end
end

function s.spfilter(c,e,tp)
	return c:IsSetCard(0x702) and c:IsType(TYPE_MONSTER)
		and c:IsCanBeSpecialSummoned(e,0,tp,true,true)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCountFromEx(tp,tp,nil,TYPE_MONSTER)>0
			and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,1,tp,LOCATION_HAND)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local hg=Duel.GetFieldGroup(tp,LOCATION_HAND,0)
	if #hg>0 and Duel.Remove(hg,POS_FACEUP,REASON_EFFECT)>0 then
		if Duel.GetLocationCountFromEx(tp,tp,nil,TYPE_MONSTER)<=0 then return end
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp)
		if #g>0 then
			Duel.SpecialSummon(g,0,tp,tp,true,true,POS_FACEUP)
		end
	end
end

function s.gcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return eg:IsContains(c) and c:IsPreviousLocation(LOCATION_GRAVE)
end

function s.gyfilter(c)
	return c:IsAbleToDeck()
end

function s.spiritfilter(c)
	return c:IsSetCard(0x702)
end

function s.gtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsPlayerCanDraw(tp,2)
			and Duel.IsExistingMatchingCard(s.gyfilter,tp,LOCATION_GRAVE,0,3,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_TODECK,nil,3,tp,LOCATION_GRAVE)
	Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,2)
end

function s.gop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(s.gyfilter,tp,LOCATION_GRAVE,0,nil)
	if #g<3 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	local sg=g:Select(tp,3,3,nil)
	if #sg==3 and Duel.SendtoDeck(sg,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)>0 then
		local og=Duel.GetOperatedGroup()
		if og:IsExists(Card.IsLocation,1,nil,LOCATION_DECK+LOCATION_EXTRA) then
			Duel.ShuffleDeck(tp)
			Duel.BreakEffect()
			if Duel.Draw(tp,2,REASON_EFFECT)==2 then
				local dg=Duel.GetOperatedGroup()
				Duel.ConfirmCards(1-tp,dg)
				if not dg:IsExists(s.spiritfilter,1,nil) then
					local hg=Duel.GetFieldGroup(tp,LOCATION_HAND,0)
					if #hg>0 then
						Duel.Remove(hg,POS_FACEUP,REASON_EFFECT)
					end
				end
				Duel.ShuffleHand(tp)
			end
		end
	end
end
