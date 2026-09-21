-- Qin Shi Huang, Defier of Heaven
-- ID: 99900131
local s,id=GetID()
s.listed_series={0xb4c} -- Mecha Three Kingdoms

function s.initial_effect(c)
	-- XYZ Summon: 3+ Level 12 Monsters (99 nằm ở vị trí maxct thứ 7)
	c:EnableReviveLimit()
	Xyz.AddProcedure(c, nil, 12, 2, nil, nil, Xyz.InfiniteMats)

	-- EFFECT 1: ON SUMMON - LOCK FIELD
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DISABLE)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCondition(s.negcon)
	e1:SetOperation(s.negop)
	c:RegisterEffect(e1)

	-- EFFECT 2: IMMUNITY
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

	-- EFFECT 3: ATK BOOST
	local e6=Effect.CreateEffect(c)
	e6:SetType(EFFECT_TYPE_SINGLE)
	e6:SetCode(EFFECT_SET_ATTACK)
	e6:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e6:SetRange(LOCATION_MZONE)
	e6:SetValue(s.atkval)
	c:RegisterEffect(e6)

	-- EFFECT 4: DECK DESTRUCTION (Detach 1)
	local e7=Effect.CreateEffect(c)
	e7:SetDescription(aux.Stringid(id,1))
	e7:SetCategory(CATEGORY_REMOVE+CATEGORY_DECKDES)
	e7:SetType(EFFECT_TYPE_IGNITION)
	e7:SetRange(LOCATION_MZONE)
	e7:SetCountLimit(1)
	e7:SetCost(s.rmcost)
	e7:SetTarget(s.rmtg)
	e7:SetOperation(s.rmop)
	c:RegisterEffect(e7)

	-- EFFECT 5: DESTRUCTION SUBSTITUTION
	local e8=Effect.CreateEffect(c)
	e8:SetType(EFFECT_TYPE_CONTINUOUS+EFFECT_TYPE_SINGLE)
	e8:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e8:SetCode(EFFECT_DESTROY_REPLACE)
	e8:SetRange(LOCATION_MZONE)
	e8:SetTarget(s.reptg)
	e8:SetOperation(s.repop)
	c:RegisterEffect(e8)
end

--------------------------------------------------------------------------------
-- LOGIC EFFECT 1: FIELD LOCK
--------------------------------------------------------------------------------
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_XYZ)
end

function s.negfilter(c)
	return c:IsFaceup() and not c:IsSetCard(0xb4c)
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	-- Cấm kích hoạt effect trên sân
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CANNOT_ACTIVATE)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e1:SetTargetRange(1,1)
	e1:SetValue(s.aclimit)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
	
	-- Negate các lá bài đang ngửa trên sân (trừ Mecha Three Kingdoms)
	local g=Duel.GetMatchingGroup(s.negfilter,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,nil)
	for tc in aux.Next(g) do
		Duel.NegateRelatedChain(tc,RESET_TURN_SET)
		local e2=Effect.CreateEffect(c)
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetCode(EFFECT_DISABLE)
		e2:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		tc:RegisterEffect(e2)
		local e3=Effect.CreateEffect(c)
		e3:SetType(EFFECT_TYPE_SINGLE)
		e3:SetCode(EFFECT_DISABLE_EFFECT)
		e3:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		tc:RegisterEffect(e3)
	end
end

function s.aclimit(e,re,tp)
	local loc=re:GetActivateLocation()
	return (loc & LOCATION_ONFIELD) ~= 0 and not re:GetHandler():IsSetCard(0xb4c)
end

--------------------------------------------------------------------------------
-- LOGIC EFFECT 2: IMMUNITY
--------------------------------------------------------------------------------
function s.indval(e,re,rp)
	return rp and rp~=e:GetHandlerPlayer()
end

--------------------------------------------------------------------------------
-- LOGIC EFFECT 3: ATK CALCULATION
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
-- LOGIC EFFECT 4: DECK DESTRUCTION
--------------------------------------------------------------------------------
function s.rmcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():CheckRemoveOverlayCard(tp,1,REASON_COST) end
	e:GetHandler():RemoveOverlayCard(tp,1,1,REASON_COST)
end

function s.rmtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local ct=Duel.GetFieldGroupCount(tp,LOCATION_ONFIELD,LOCATION_ONFIELD)
	if chk==0 then return ct>0 and Duel.IsPlayerCanRemove(1-tp) 
		and Duel.GetFieldGroupCount(tp,0,LOCATION_DECK)>=ct end
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,ct,1-tp,LOCATION_DECK)
end

function s.rmop(e,tp,eg,ep,ev,re,r,rp)
	local ct=Duel.GetFieldGroupCount(tp,LOCATION_ONFIELD,LOCATION_ONFIELD)
	if ct>0 then
		local g=Duel.GetDecktopGroup(1-tp,ct)
		if #g>0 then
			Duel.DisableShuffleCheck()
			Duel.Remove(g,POS_FACEDOWN,REASON_EFFECT)
		end
	end
end

--------------------------------------------------------------------------------
-- LOGIC EFFECT 5: DESTRUCTION SUBSTITUTION
--------------------------------------------------------------------------------
function s.repfilter(c,tp)
	return (c:IsLocation(LOCATION_HAND) or c:IsLocation(LOCATION_ONFIELD)) 
		and c:IsAbleToRemove(tp,POS_FACEDOWN,REASON_EFFECT) and not c:IsStatus(STATUS_DESTROY_CONFIRMED)
end

function s.reptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return not c:IsReason(REASON_REPLACE) and c:IsReason(REASON_BATTLE+REASON_EFFECT)
		and Duel.IsExistingMatchingCard(s.repfilter,tp,LOCATION_HAND+LOCATION_ONFIELD,0,1,c,tp) end
	if Duel.SelectEffectYesNo(tp,c,96) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
		local g=Duel.SelectMatchingCard(tp,s.repfilter,tp,LOCATION_HAND+LOCATION_ONFIELD,0,1,1,c,tp)
		e:SetLabelObject(g:GetFirst())
		g:GetFirst():SetStatus(STATUS_DESTROY_CONFIRMED,true)
		return true
	else return false end
end

function s.repop(e,tp,eg,ep,ev,re,r,rp)
	local tc=e:GetLabelObject()
	if tc then
		tc:SetStatus(STATUS_DESTROY_CONFIRMED,false)
		Duel.Remove(tc,POS_FACEDOWN,REASON_EFFECT+REASON_REPLACE)
	end
end