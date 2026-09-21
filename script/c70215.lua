--Flower Spirit – The Flower Corrupted
local s,id=GetID()

function s.initial_effect(c)
	--Activate
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_REMOVE+CATEGORY_TOGRAVE+CATEGORY_TOHAND+CATEGORY_SPECIAL_SUMMON+CATEGORY_DECKDES)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id+EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

function s.rmfilter(c)
	return c:IsSetCard(0x702) and c:IsAbleToRemove()
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.rmfilter,tp,LOCATION_HAND+LOCATION_ONFIELD,0,1,e:GetHandler()) end
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,1,tp,LOCATION_HAND+LOCATION_ONFIELD)
end

function s.tgfilter(c)
	return c:IsSetCard(0x702) and c:IsType(TYPE_SPELL) and c:IsAbleToGrave()
end
function s.setfilter(c)
	return c:IsSetCard(0x702) and c:IsType(TYPE_SPELL) and c:IsSSetable()
end
function s.thfilter(c)
	return c:IsSetCard(0x702) and c:IsType(TYPE_SPELL) and c:IsAbleToHand()
end
function s.spfilter(c,e,tp)
	return c:IsSetCard(0x702) and c:IsType(TYPE_MONSTER) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local g=Duel.GetMatchingGroup(s.rmfilter,tp,LOCATION_HAND+LOCATION_ONFIELD,0,c)
	if #g==0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local sg=g:Select(tp,1,5,nil)
	if #sg==0 or Duel.Remove(sg,POS_FACEUP,REASON_EFFECT)==0 then return end
	local ct=#Duel.GetOperatedGroup()
	
	--1: Send 2 FS Spells from Deck to GY
	if ct==1 then
		if Duel.IsExistingMatchingCard(s.tgfilter,tp,LOCATION_DECK,0,2,nil) then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
			local tg=Duel.SelectMatchingCard(tp,s.tgfilter,tp,LOCATION_DECK,0,2,2,nil)
			Duel.SendtoGrave(tg,REASON_EFFECT)
		end
	--2: Set 1 FS Spell from Deck (cannot be activated this turn)
	elseif ct==2 then
		if Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_DECK,0,1,nil) then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
			local setg=Duel.SelectMatchingCard(tp,s.setfilter,tp,LOCATION_DECK,0,1,1,nil)
			local tc=setg:GetFirst()
			if tc and Duel.SSet(tp,tc)>0 then
				local e1=Effect.CreateEffect(c)
				e1:SetType(EFFECT_TYPE_SINGLE)
				e1:SetCode(EFFECT_CANNOT_TRIGGER)
				e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
				tc:RegisterEffect(e1)
			end
		end
	--3: Add 1 FS Spell from GY/banish to hand
	elseif ct==3 then
		if Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,nil) then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
			local thg=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,1,nil)
			Duel.SendtoHand(thg,nil,REASON_EFFECT)
			Duel.ConfirmCards(1-tp,thg)
		end
	--4: Special Summon 1 FS monster from GY, banish, or face-up Extra Deck
	elseif ct==4 then
		local b1=Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,nil,e,tp)
		local b2=Duel.GetLocationCountFromEx(tp,tp,nil,TYPE_PENDULUM)>0
			and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp)
		if b1 or b2 then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
			local spg=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED+LOCATION_EXTRA,0,1,1,nil,e,tp)
			if #spg>0 then
				Duel.SpecialSummon(spg,0,tp,tp,false,false,POS_FACEUP)
			end
		end
	--5: Banish top 5 cards from Deck, opponent banishes 5 from hand and/or Extra Deck face-down
	elseif ct==5 then
		local td=Duel.GetDecktopGroup(tp,5)
		if #td==5 and Duel.Remove(td,POS_FACEUP,REASON_EFFECT)==5 then
			Duel.BreakEffect()
			local opp_hand=Duel.GetMatchingGroup(Card.IsAbleToRemove,1-tp,LOCATION_HAND,0,nil,1-tp,POS_FACEDOWN)
			local opp_ex=Duel.GetMatchingGroup(Card.IsAbleToRemove,1-tp,LOCATION_EXTRA,0,nil,1-tp,POS_FACEDOWN)
			local total=#opp_hand + #opp_ex
			local ban_ct=math.min(5,total)
			if ban_ct>0 then
				local full_opp_g=Group.CreateGroup()
				full_opp_g:Merge(opp_hand)
				full_opp_g:Merge(opp_ex)
				Duel.Hint(HINT_SELECTMSG,1-tp,HINTMSG_REMOVE)
				local optg=full_opp_g:Select(1-tp,ban_ct,ban_ct,nil)
				Duel.Remove(optg,POS_FACEDOWN,REASON_EFFECT)
			end
		end
	end
end