-- Fire Keeper of the Ashened City
local s,id=GetID()
Duel.LoadScript("constants.lua")

function s.initial_effect(c)
	-- Special Summon this card (from your hand)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetCondition(s.selfspcon)
	c:RegisterEffect(e1)

	-- Place Obsidim or Add 1 "Ashened" or "Veidos" card
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SEARCH+CATEGORY_TOHAND+CATEGORY_LEAVE_GRAVE)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_HAND)
	e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E+TIMING_MAIN_END)
	e2:SetCountLimit(1,{id,1})
	e2:SetCost(s.quickcost)
	e2:SetTarget(s.quicktg)
	e2:SetOperation(s.quickop)
	c:RegisterEffect(e2)

	-- Add this card to hand if a card is destroyed
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_TOHAND)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_DESTROYED)
	e3:SetRange(LOCATION_GRAVE)
	e3:SetCountLimit(1,{id,2})
	e3:SetCondition(s.thcon)
	e3:SetTarget(s.thtg)
	e3:SetOperation(s.thop)
	c:RegisterEffect(e3)
end

s.listed_names={CARD_OBSIDIM_ASHENED_CITY,id}
s.listed_series={SET_ASHENED,SET_VEIDOS}

function s.selfspcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsCode,CARD_OBSIDIM_ASHENED_CITY),
			0,LOCATION_FZONE,LOCATION_FZONE,1,nil)
end

function s.quickcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsDiscardable() end
	Duel.SendtoGrave(c,REASON_COST+REASON_DISCARD)
end

function s.plfilter(c)
	return c:IsCode(CARD_OBSIDIM_ASHENED_CITY) and not c:IsForbidden()
end

function s.thfilter(c)
	return (c:IsSetCard(SET_ASHENED) or c:IsSetCard(SET_VEIDOS) or c:IsCode(78783557,30453613,8540986))
		and c:IsAbleToHand()
end

function s.quicktg(e,tp,eg,ep,ev,re,r,rp,chk)
	local b1=(Duel.CheckLocation(tp,LOCATION_FZONE,0) or Duel.CheckLocation(1-tp,LOCATION_FZONE,0)
		or Duel.GetFieldCard(tp,LOCATION_FZONE,0) or Duel.GetFieldCard(1-tp,LOCATION_FZONE,0))
		and Duel.IsExistingMatchingCard(s.plfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil)
	local obs_on_field=Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsCode,CARD_OBSIDIM_ASHENED_CITY),
		0,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil)
	local b2=obs_on_field and Duel.IsExistingMatchingCard(s.thfilter,tp,
		LOCATION_DECK+LOCATION_GRAVE+LOCATION_REMOVED,0,1,nil)
	if chk==0 then return b1 or b2 end
	Duel.SetPossibleOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE+LOCATION_REMOVED)
	Duel.SetPossibleOperationInfo(0,CATEGORY_LEAVE_GRAVE,nil,1,tp,LOCATION_GRAVE)
end

function s.quickop(e,tp,eg,ep,ev,re,r,rp)
	local b1=(Duel.CheckLocation(tp,LOCATION_FZONE,0) or Duel.CheckLocation(1-tp,LOCATION_FZONE,0)
		or Duel.GetFieldCard(tp,LOCATION_FZONE,0) or Duel.GetFieldCard(1-tp,LOCATION_FZONE,0))
		and Duel.IsExistingMatchingCard(s.plfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil)
	local obs_on_field=Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsCode,CARD_OBSIDIM_ASHENED_CITY),
		0,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil)
	local b2=obs_on_field and Duel.IsExistingMatchingCard(s.thfilter,tp,
		LOCATION_DECK+LOCATION_GRAVE+LOCATION_REMOVED,0,1,nil)
	if not (b1 or b2) then return end
	local op=0
	if b1 and b2 then
		op=Duel.SelectEffect(tp,
			{b1,aux.Stringid(id,3)},
			{b2,aux.Stringid(id,4)})
	elseif b1 then
		op=1
	else
		op=2
	end
	if op==1 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOFIELD)
		local tc=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.plfilter),
			tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil):GetFirst()
		if not tc then return end
		local p1=Duel.CheckLocation(tp,LOCATION_FZONE,0) or Duel.GetFieldCard(tp,LOCATION_FZONE,0)
		local p2=Duel.CheckLocation(1-tp,LOCATION_FZONE,0) or Duel.GetFieldCard(1-tp,LOCATION_FZONE,0)
		local target_player=tp
		if p1 and p2 then
			local sel=Duel.SelectOption(tp,aux.Stringid(id,5),aux.Stringid(id,6))
			if sel==1 then target_player=1-tp end
		elseif p2 then
			target_player=1-tp
		end
		local fc=Duel.GetFieldCard(target_player,LOCATION_FZONE,0)
		if fc then
			Duel.SendtoGrave(fc,REASON_RULE)
			Duel.BreakEffect()
		end
		Duel.MoveToField(tc,tp,target_player,LOCATION_FZONE,POS_FACEUP,true)
	else
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.thfilter),
			tp,LOCATION_DECK+LOCATION_GRAVE+LOCATION_REMOVED,0,1,1,nil)
		if #g>0 then
			Duel.SendtoHand(g,nil,REASON_EFFECT)
			Duel.ConfirmCards(1-tp,g)
		end
	end
end

function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return eg:IsExists(Card.IsReason,1,nil,REASON_DESTROY) and not eg:IsContains(c)
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsAbleToHand() end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,c,1,tp,0)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SendtoHand(c,nil,REASON_EFFECT)
	end
end
