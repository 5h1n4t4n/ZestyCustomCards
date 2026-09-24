local s,id=GetID()
function s.initial_effect(c)
	-- Special Summon if added by effect
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_TO_HAND)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_DUEL)
	e1:SetCondition(s.spcon)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	-- Reveal & apply effect
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCountLimit(1,id+100,EFFECT_COUNT_CODE_DUEL)
	e2:SetOperation(s.revealop)
	c:RegisterEffect(e2)
end

-- ========== Effect 1 ==========
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return (r&REASON_EFFECT)~=0
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
	end
end

-- ========== Effect 2 ==========
function s.revealfilter(c)
	return c:IsAbleToHand() or c:IsAbleToExtra()
end

function s.revealop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetFlagEffect(tp,id)~=0 then return end
	Duel.RegisterFlagEffect(tp,id,0,0,1)

	local g=Duel.SelectMatchingCard(tp,s.revealfilter,tp,
		LOCATION_DECK+LOCATION_EXTRA,0,1,1,nil)
	if #g==0 then return end
	local tc=g:GetFirst()
	Duel.ConfirmCards(1-tp,tc)

	-- Fusion
	if tc:IsType(TYPE_FUSION) then
		local mg=Duel.SelectMatchingCard(tp,Card.IsAbleToHand,tp,LOCATION_DECK,0,1,1,nil)
		if #mg>0 then Duel.SendtoHand(mg,nil,REASON_EFFECT) end

	-- Xyz
	elseif tc:IsType(TYPE_XYZ) then
		local rk=tc:GetRank()
		local xg=Duel.SelectMatchingCard(tp,
			function(c) return c:IsLevel(rk) and c:IsAbleToHand() end,
			tp,LOCATION_DECK,0,1,1,nil)
		if #xg>0 then Duel.SendtoHand(xg,nil,REASON_EFFECT) end

	-- Synchro
	elseif tc:IsType(TYPE_SYNCHRO) then
		local tg=Duel.SelectMatchingCard(tp,Card.IsType,tp,LOCATION_DECK,0,1,1,nil,TYPE_TUNER)
		if #tg>0 then Duel.SendtoHand(tg,nil,REASON_EFFECT) end

	-- Link
	elseif tc:IsType(TYPE_LINK) then
		Duel.Draw(tp,tc:GetLink(),REASON_EFFECT)

	-- Pendulum
	elseif tc:IsType(TYPE_PENDULUM) then
		if Duel.CheckLocation(tp,LOCATION_PZONE,0)
			and Duel.CheckLocation(tp,LOCATION_PZONE,1) then
			local pg=Duel.SelectMatchingCard(tp,Card.IsType,tp,LOCATION_DECK,0,2,2,nil,TYPE_PENDULUM)
			if #pg==2 then
				Duel.MoveToField(pg:GetFirst(),tp,tp,LOCATION_PZONE,POS_FACEUP,true)
				Duel.MoveToField(pg:GetNext(),tp,tp,LOCATION_PZONE,POS_FACEUP,true)
			end
		end

	-- Spell
	elseif tc:IsType(TYPE_SPELL) then
		local fs=Duel.GetMatchingGroup(Card.IsType,tp,LOCATION_FZONE,0,nil,TYPE_FIELD)
		if #fs>0 then
			Duel.SendtoHand(tc,nil,REASON_EFFECT)
		else
			Duel.SendtoGrave(tc,REASON_EFFECT)
		end

	-- Trap
	elseif tc:IsType(TYPE_TRAP) then
		local ct=Duel.GetMatchingGroup(Card.IsType,tp,LOCATION_SZONE,0,nil,TYPE_CONTINUOUS)
		if #ct>0 then
			Duel.SSet(tp,tc)
		else
			Duel.SendtoGrave(tc,REASON_EFFECT)
		end

	-- Effect Monster (Main Deck ONLY)
	elseif tc:IsType(TYPE_EFFECT) and tc:IsType(TYPE_MONSTER)
		and not tc:IsType(TYPE_FUSION+TYPE_SYNCHRO+TYPE_XYZ+TYPE_LINK) then
		Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)
	end
end