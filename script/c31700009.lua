-- Texas the Omertosa
local s,id=GetID()
function s.initial_effect(c)
	-- Xyz Summon
	c:EnableReviveLimit()
	Xyz.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsRace,RACE_WARRIOR),4,2)
	-- Quick Effect: Additional Attack and send monsters to GY
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOGRAVE)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_MZONE)
	e1:SetHintTiming(0,TIMING_BATTLE_START+TIMING_BATTLE_END)
	e1:SetCondition(s.atkcon)
	e1:SetCost(s.atkcost)
	e1:SetOperation(s.atkop)
	c:RegisterEffect(e1)
	-- Bounce and Search
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_CHAINING)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,id)
	e2:SetCondition(s.chcon)
	e2:SetCost(s.thcost)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
	local e3=e2:Clone()
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_MAIN_END)
	e3:SetCondition(s.fccon)
	c:RegisterEffect(e3)
end
s.listed_series={0x317}
function s.atkcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsBattlePhase()
end
function s.atkcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():CheckRemoveOverlayCard(tp,1,REASON_COST) end
	e:GetHandler():RemoveOverlayCard(tp,1,1,REASON_COST)
end
function s.atkop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) and c:IsFaceup() then
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_EXTRA_ATTACK)
		e1:SetValue(1)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		c:RegisterEffect(e1)
		local g=Duel.GetMatchingGroup(nil,tp,0,LOCATION_MZONE,nil)
		if #g>0 and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
			Duel.BreakEffect()
			Duel.SendtoGrave(g,REASON_EFFECT)
		end
	end
end
function s.chcon(e,tp,eg,ep,ev,re,r,rp)
	return ep==1-tp
end
function s.fccon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():GetAttackedCount()>0
end
function s.thcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsAbleToHandAsCost() end
	local mg=c:GetOverlayGroup()
	if #mg>0 then
		Duel.SendtoHand(mg,nil,REASON_COST)
	end
	Duel.SendtoHand(c,nil,REASON_COST)
end
function s.addfilter(c)
	return c:IsSetCard(0x317) and c:IsMonster() and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.addfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,2,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,2,tp,LOCATION_DECK+LOCATION_GRAVE)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,0,tp,LOCATION_HAND)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.addfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,2,2,nil)
	if #g==2 and Duel.SendtoHand(g,nil,REASON_EFFECT)>0 then
		Duel.ConfirmCards(1-tp,g)
		local sg=g:Filter(Card.IsCanBeSpecialSummoned,nil,e,0,tp,false,false)
		if #sg>0 and Duel.GetLocationCount(tp,LOCATION_MZONE)>0 and Duel.SelectYesNo(tp,aux.Stringid(id,3)) then
			Duel.BreakEffect()
			local count=math.min(#sg,Duel.GetLocationCount(tp,LOCATION_MZONE))
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
			local spg=sg:Select(tp,1,count,nil)
			Duel.SpecialSummon(spg,0,tp,tp,false,false,POS_FACEUP)
		end
	end
	-- skip next Main Phase 1
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_OATH)
	e1:SetCode(EFFECT_SKIP_M1)
	e1:SetTargetRange(1,0)
	if Duel.GetTurnPlayer()==tp and (Duel.GetCurrentPhase()==PHASE_DRAW or Duel.GetCurrentPhase()==PHASE_STANDBY) then
		e1:SetReset(RESET_PHASE+PHASE_MAIN1+RESET_SELF_TURN,1)
	else
		e1:SetReset(RESET_PHASE+PHASE_MAIN1+RESET_SELF_TURN,2)
	end
	Duel.RegisterEffect(e1,tp)
end
