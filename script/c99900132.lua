-- Qin Shi Huang, Sovereign Dragon Beyond Heaven
-- ID: 99900132
local s,id=GetID()
s.listed_names={99900131} -- ID của Qin Shi Huang cũ

function s.initial_effect(c)
	-- XYZ SUMMON PROCEDURE (Chồng lên Rank 12 Qin Shi Huang)
	c:EnableReviveLimit()
	Xyz.AddProcedure(c,nil,13,Xyz.InfiniteMats,s.ovfilter,aux.Stringid(id,0))

	-- EFFECT 1: UNAFFECTED (If Xyz Summoned)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_IMMUNE_EFFECT)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCondition(s.immcon)
	e1:SetValue(s.efilter)
	c:RegisterEffect(e1)

	-- EFFECT 2: HARD PROTECTION
	-- Cannot be Tributed
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCode(EFFECT_CANNOT_RELEASE)
	c:RegisterEffect(e2)
	-- Cannot be Banished
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCode(EFFECT_CANNOT_REMOVE)
	e3:SetValue(s.indval)
	c:RegisterEffect(e3)
	-- Cannot be returned to Hand/Deck
	local e4=e3:Clone()
	e4:SetCode(EFFECT_CANNOT_TO_HAND)
	c:RegisterEffect(e4)
	local e5=e3:Clone()
	e5:SetCode(EFFECT_CANNOT_TO_DECK)
	c:RegisterEffect(e5)

	-- EFFECT 3: QUICK BANISH BOARD (Once per chain)
	local e6=Effect.CreateEffect(c)
	e6:SetDescription(aux.Stringid(id,1))
	e6:SetCategory(CATEGORY_REMOVE)
	e6:SetType(EFFECT_TYPE_QUICK_O)
	e6:SetCode(EVENT_FREE_CHAIN)
	e6:SetRange(LOCATION_MZONE)
	e6:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E)
	e6:SetCountLimit(1,EFFECT_COUNT_CODE_CHAIN)
	e6:SetCost(s.rmcost)
	e6:SetTarget(s.rmtg)
	e6:SetOperation(s.rmop)
	c:RegisterEffect(e6)

	-- EFFECT 4: ATK CALCULATION
	local e7=Effect.CreateEffect(c)
	e7:SetType(EFFECT_TYPE_SINGLE)
	e7:SetCode(EFFECT_SET_ATTACK)
	e7:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e7:SetRange(LOCATION_MZONE)
	e7:SetValue(s.atkval)
	c:RegisterEffect(e7)

	-- EFFECT 5: FLOATING (Revive Old Boss + Attach 3)
	local e8=Effect.CreateEffect(c)
	e8:SetDescription(aux.Stringid(id,2))
	e8:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e8:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e8:SetProperty(EFFECT_FLAG_DELAY)
	e8:SetCode(EVENT_TO_GRAVE)
	e8:SetCondition(s.spcon)
	e8:SetTarget(s.sptg)
	e8:SetOperation(s.spop)
	c:RegisterEffect(e8)
	local e9=e8:Clone()
	e9:SetCode(EVENT_REMOVE)
	c:RegisterEffect(e9)

	-- EFFECT 6: SELF-RECYCLE (End Phase)
	local e10=Effect.CreateEffect(c)
	e10:SetDescription(aux.Stringid(id,3))
	e10:SetCategory(CATEGORY_TODECK)
	e10:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e10:SetCode(EVENT_PHASE+PHASE_END)
	e10:SetRange(LOCATION_GRAVE+LOCATION_REMOVED)
	e10:SetCountLimit(1)
	e10:SetCondition(s.tdcon)
	e10:SetTarget(s.tdtg)
	e10:SetOperation(s.tdop)
	c:RegisterEffect(e10)
end

--------------------------------------------------------------------------------
-- XYZ SUMMON FILTER
--------------------------------------------------------------------------------
function s.ovfilter(c,tp,xyzc)
	return c:IsFaceup() and c:IsCode(99900131)
end

--------------------------------------------------------------------------------
-- EFFECT 1 & 2: IMMUNE & PROTECTION LOGIC
--------------------------------------------------------------------------------
function s.immcon(e)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_XYZ)
end

function s.efilter(e,te)
	return te:GetOwnerPlayer()~=e:GetHandlerPlayer()
end

function s.indval(e,re,rp)
	return rp~=e:GetHandlerPlayer()
end

--------------------------------------------------------------------------------
-- EFFECT 3: BANISH BOARD
--------------------------------------------------------------------------------
function s.rmcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():CheckRemoveOverlayCard(tp,1,REASON_COST) end
	e:GetHandler():RemoveOverlayCard(tp,1,1,REASON_COST)
end

function s.rmfilter(c,tp)
	return c:IsAbleToRemove(tp,POS_FACEDOWN)
end

function s.rmtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local g=Duel.GetMatchingGroup(s.rmfilter,tp,0,LOCATION_ONFIELD,nil,tp)
	if chk==0 then return #g>0 end
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,g,#g,0,0)
end

function s.rmop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(s.rmfilter,tp,0,LOCATION_ONFIELD,nil,tp)
	if #g>0 then
		Duel.Remove(g,POS_FACEDOWN,REASON_EFFECT)
	end
end

--------------------------------------------------------------------------------
-- EFFECT 4: ATK CALCULATION
--------------------------------------------------------------------------------
function s.atkval(e,c)
	local tp=e:GetHandlerPlayer()
	local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,LOCATION_MZONE,LOCATION_MZONE,nil)
	local val=0
	for tc in aux.Next(g) do
		if tc:IsType(TYPE_XYZ) then
			val=val+tc:GetRank()
		elseif tc:IsType(TYPE_LINK) then
			val=val+tc:GetLink()
		else
			val=val+tc:GetLevel()
		end
	end
	return val*500
end

--------------------------------------------------------------------------------
-- EFFECT 5: FLOATING LOGIC (REVIVE & ATTACH)
--------------------------------------------------------------------------------
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsPreviousLocation(LOCATION_ONFIELD)
end

function s.spfilter(c,e,tp)
	return c:IsCode(99900131) 
		and (c:IsLocation(LOCATION_GRAVE) or c:IsFaceup()) 
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.attachfilter(c)
	return (c:IsLocation(LOCATION_GRAVE) or (c:IsLocation(LOCATION_REMOVED) and c:IsFaceup())) 
		and not c:IsType(TYPE_TOKEN)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE+LOCATION_REMOVED)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.spfilter),tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,1,nil,e,tp)
	local tc=g:GetFirst()
	
	if tc and Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)>0 then
		local mg=Duel.GetMatchingGroup(aux.NecroValleyFilter(s.attachfilter),tp,LOCATION_GRAVE+LOCATION_REMOVED,0,nil)
		if #mg>0 and tc:IsType(TYPE_XYZ) and Duel.SelectYesNo(tp,aux.Stringid(id,4)) then
			Duel.BreakEffect()
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_XMATERIAL)
			local matg=mg:Select(tp,1,3,nil)
			if #matg>0 then
				Duel.Overlay(tc,matg)
			end
		end
	end
end

--------------------------------------------------------------------------------
-- EFFECT 6: SELF-RECYCLE LOGIC
--------------------------------------------------------------------------------
function s.tdcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:GetTurnID()==Duel.GetTurnCount() 
		and (c:IsLocation(LOCATION_GRAVE) or c:IsFaceup())
end

function s.tdtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsAbleToExtra() end
	Duel.SetOperationInfo(0,CATEGORY_TODECK,e:GetHandler(),1,0,0)
end

function s.tdop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SendtoDeck(c,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
	end
end