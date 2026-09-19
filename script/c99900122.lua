-- Destiny Enforcer - Reversal of Samsara
-- ID: 99900122
local s,id=GetID()
s.listed_series={0xb4c}

function s.initial_effect(c)
	-- Synchro Summon Procedure: 1 Tuner + 1+ non-Tuner "Mecha Three Kingdoms"
	Synchro.AddProcedure(c, nil, 1, 1, Synchro.NonTunerEx(Card.IsSetCard, 0xb4c), 1, 99)
	c:EnableReviveLimit()
	
	-- 1. Target/Destroy Immune
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e1:SetValue(aux.tgoval)
	c:RegisterEffect(e1)
	
	local e2=e1:Clone()
	e2:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e2:SetValue(1)
	c:RegisterEffect(e2)
	
	-- 2. Equip Effect from Hand/Deck
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetCategory(CATEGORY_EQUIP)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1, {id, 0})
	e3:SetTarget(s.eqtg)
	e3:SetOperation(s.eqop)
	c:RegisterEffect(e3)
	
	-- 3. Unaffected by equipped card types
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE)
	e4:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCode(EFFECT_IMMUNE_EFFECT)
	e4:SetValue(s.immval)
	c:RegisterEffect(e4)

	-- 4. Quick Effect: Execute Law
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,1))
	e5:SetType(EFFECT_TYPE_QUICK_O)
	e5:SetCode(EVENT_FREE_CHAIN)
	e5:SetRange(LOCATION_MZONE)
	e5:SetHintTiming(0, TIMINGS_CHECK_MONSTER+TIMING_MAIN_END+TIMING_END_PHASE)
	e5:SetCountLimit(1, {id, 1})
	e5:SetCost(s.lawcost)
	e5:SetTarget(s.lawtg)
	e5:SetOperation(s.lawop)
	c:RegisterEffect(e5)

	-- 5. Revive from GY
	local e6=Effect.CreateEffect(c)
	e6:SetDescription(aux.Stringid(id,2))
	e6:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e6:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e6:SetProperty(EFFECT_FLAG_DELAY)
	e6:SetCode(EVENT_TO_GRAVE)
	e6:SetCountLimit(1, {id, 2})
	e6:SetTarget(s.revtg)
	e6:SetOperation(s.revop)
	c:RegisterEffect(e6)
end

--------------------------------------------------------------------------------
-- (2) EQUIP LOGIC
--------------------------------------------------------------------------------
function s.eqfilter(c,ty)
	return c:IsType(ty) and not c:IsForbidden()
end

function s.eqtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
		and Duel.IsExistingMatchingCard(nil,tp,LOCATION_HAND+LOCATION_DECK,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CARDTYPE)
	local res=Duel.AnnounceType(tp)
	e:SetLabel(res)
	Duel.SetOperationInfo(0,CATEGORY_EQUIP,nil,1,tp,LOCATION_HAND+LOCATION_DECK)
end

function s.eqlimit(e,c)
	return e:GetOwner()==c
end

function s.eqop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local res=e:GetLabel()
	local ty=(res==0 and TYPE_MONSTER) or (res==1 and TYPE_SPELL) or TYPE_TRAP
	if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 or c:IsFacedown() or not c:IsRelateToEffect(e) then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_EQUIP)
	local g=Duel.SelectMatchingCard(tp,s.eqfilter,tp,LOCATION_HAND+LOCATION_DECK,0,1,1,nil,ty)
	local tc=g:GetFirst()
	if tc and Duel.Equip(tp,tc,c) then
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_EQUIP_LIMIT)
		e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e1:SetValue(s.eqlimit)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		tc:RegisterEffect(e1)
	end
end

--------------------------------------------------------------------------------
-- (3) IMMUNITY LOGIC
--------------------------------------------------------------------------------
function s.immval(e,te)
	local c=e:GetHandler()
	local eg=c:GetEquipGroup()
	if #eg==0 or te:GetOwnerPlayer()==e:GetHandlerPlayer() then return false end
	local types=0
	for tc in aux.Next(eg) do
		types = bit.bor(types, tc:GetOriginalType())
	end
	return te:IsActiveType(bit.band(types, TYPE_MONSTER+TYPE_SPELL+TYPE_TRAP))
end

--------------------------------------------------------------------------------
-- (4) EXECUTE LAW (QUICK EFFECT)
--------------------------------------------------------------------------------
function s.lawcostfilter(c,tp)
	if not c:IsAbleToGraveAsCost() then return false end
	local ty=c:GetOriginalType()
	if bit.band(ty, TYPE_MONSTER) ~= 0 then
		return Duel.IsExistingMatchingCard(Card.IsFaceup,tp,0,LOCATION_MZONE,1,nil)
	elseif bit.band(ty, TYPE_SPELL) ~= 0 then
		return Duel.IsExistingMatchingCard(nil,tp,0,LOCATION_SZONE,1,nil)
	elseif bit.band(ty, TYPE_TRAP) ~= 0 then
		local ct=Duel.GetMatchingGroupCount(Card.IsType,tp,0,LOCATION_MZONE,nil,TYPE_MONSTER)
		return ct>0 and Duel.IsExistingMatchingCard(Card.IsAbleToDeck,tp,LOCATION_REMOVED,LOCATION_REMOVED,1,nil)
	end
	return false
end

function s.lawcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local g=e:GetHandler():GetEquipGroup()
	if chk==0 then return g:IsExists(s.lawcostfilter,1,nil,tp) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local sg=g:FilterSelect(tp,s.lawcostfilter,1,1,nil,tp)
	local tc=sg:GetFirst()
	local ty=tc:GetOriginalType()
	e:SetLabel(ty)
	Duel.SendtoGrave(sg,REASON_COST)
end

function s.lawtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_REMOVED) and chkc:IsAbleToDeck() end
	local ty=e:GetLabel()
	if chk==0 then return true end
	
	if bit.band(ty, TYPE_MONSTER) ~= 0 then
		local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,0,LOCATION_MZONE,nil)
		Duel.SetOperationInfo(0,CATEGORY_DISABLE,g,#g,0,0)
	elseif bit.band(ty, TYPE_SPELL) ~= 0 then
		local g=Duel.GetMatchingGroup(nil,tp,0,LOCATION_SZONE,nil)
		Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,#g,0,0)
	elseif bit.band(ty, TYPE_TRAP) ~= 0 then
		local ct=Duel.GetMatchingGroupCount(Card.IsType,tp,0,LOCATION_MZONE,nil,TYPE_MONSTER)
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
		local g=Duel.SelectTarget(tp,Card.IsAbleToDeck,tp,LOCATION_REMOVED,LOCATION_REMOVED,1,ct,nil)
		Duel.SetOperationInfo(0,CATEGORY_TODECK,g,#g,0,0)
		Duel.SetOperationInfo(0,CATEGORY_POSITION,nil,1,1-tp,POS_FACEDOWN_DEFENSE)
	end
end

function s.lawop(e,tp,eg,ep,ev,re,r,rp)
	local ty=e:GetLabel()
	local c=e:GetHandler()
	
	if bit.band(ty, TYPE_MONSTER) ~= 0 then
		local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,0,LOCATION_MZONE,nil)
		for tc in aux.Next(g) do
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_DISABLE)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
			tc:RegisterEffect(e1)
			local e2=e1:Clone()
			e2:SetCode(EFFECT_DISABLE_EFFECT)
			tc:RegisterEffect(e2)
		end
	elseif bit.band(ty, TYPE_SPELL) ~= 0 then
		local g=Duel.GetMatchingGroup(nil,tp,0,LOCATION_SZONE,nil)
		if #g>0 then
			Duel.Destroy(g,REASON_EFFECT)
		end
	elseif bit.band(ty, TYPE_TRAP) ~= 0 then
		local g=Duel.GetChainInfo(0,CHAININFO_TARGET_CARDS)
		if g then
			local tg=g:Filter(Card.IsRelateToEffect,nil,e)
			if #tg>0 and Duel.SendtoDeck(tg,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)>0 then
				local og=Duel.GetMatchingGroup(Card.IsCanTurnSet,tp,0,LOCATION_MZONE,nil)
				if #og>0 then
					Duel.BreakEffect()
					Duel.ChangePosition(og,POS_FACEDOWN_DEFENSE)
				end
			end
		end
	end
end

--------------------------------------------------------------------------------
-- (5) REVIVE FROM GY
--------------------------------------------------------------------------------
function s.revtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end

function s.revop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) and Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)>0 then
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_LEAVE_FIELD_REDIRECT)
		e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e1:SetReset(RESET_EVENT+RESETS_REDIRECT)
		e1:SetValue(LOCATION_REMOVED)
		c:RegisterEffect(e1,true)
	end
end