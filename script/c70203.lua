--Flower Spirit-Ferral Spring
local s,id=GetID()
local COUNTER_FLOWER=0x702 --custom "Flower Counter" type, reusing this archetype's setcode as the counter id

function s.initial_effect(c)
	c:SetSpsummonOnce(id) --You can only Special Summon this card once per turn
	----------------------------------------
	-- Pendulum Effect (active while in the Pendulum Zone)
	----------------------------------------
	--Each time a "Flower Spirit" Spell Card's effect resolves, place 1 Flower Counter on this card
	local pe1=Effect.CreateEffect(c)
	pe1:SetType(EFFECT_TYPE_FIELD)
	pe1:SetCode(EVENT_CHAIN_SOLVED)
	pe1:SetRange(LOCATION_PZONE)
	pe1:SetCondition(s.ctcon)
	pe1:SetOperation(s.ctop)
	c:RegisterEffect(pe1)
	--Once per turn: remove 10 Flower Counters; draw 2 cards, then destroy this card
	local pe2=Effect.CreateEffect(c)
	pe2:SetDescription(aux.Stringid(id,0))
	pe2:SetType(EFFECT_TYPE_IGNITION)
	pe2:SetRange(LOCATION_PZONE)
	pe2:SetCountLimit(1,id)
	pe2:SetCost(s.rmcost)
	pe2:SetTarget(s.rmtg)
	pe2:SetOperation(s.rmop)
	c:RegisterEffect(pe2)
	----------------------------------------
	-- Monster Effect
	----------------------------------------
	--Cannot be Special Summoned by card effects (only by this card's own procedure below)
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e0:SetRange(LOCATION_MZONE+LOCATION_HAND+LOCATION_GRAVE+LOCATION_REMOVED+LOCATION_EXTRA+LOCATION_DECK+LOCATION_PZONE)
	c:RegisterEffect(e0)
	--Special Summon procedure: shuffle 3 "Flower Spirit" Spells from GY and/or banishment into the Deck
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetRange(LOCATION_EXTRA)
	e1:SetTargetRange(LOCATION_MZONE,0)
	e1:SetCondition(s.spcon)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)
	--If this card is Special Summoned: place "Flower Spirit" Spells from GY in Monster Zones
	--as Normal Monsters (Level 4/Spellcaster/LIGHT/ATK 0/DEF 0)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCondition(s.spscon)
	e2:SetTarget(s.spstg)
	e2:SetOperation(s.spsop)
	c:RegisterEffect(e2)
	--Once per turn: place this card in your Pendulum Zone
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,id+1)
	e3:SetTarget(s.pztg)
	e3:SetOperation(s.pzop)
	c:RegisterEffect(e3)
end

----------------------------------------
-- Pendulum Effect helpers
----------------------------------------
--NOTE: "each time a Spell Card's effect resolves" is approximated via EVENT_CHAIN_SOLVED,
--checking whether the resolved chain link's effect belongs to a "Flower Spirit" Spell Card.
function s.ctcon(e,tp,eg,ep,ev,re,r,rp)
	local rc=re:GetHandler()
	return rc:IsSetCard(0x702) and rc:GetType()&TYPE_SPELL==TYPE_SPELL
end
function s.ctop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsFaceup() then
		Duel.AddCounter(c,COUNTER_FLOWER,1)
	end
end

function s.rmcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():GetCounter(COUNTER_FLOWER)>=10 end
	Duel.RemoveCounter(tp,e:GetHandler(),0,COUNTER_FLOWER,10,REASON_COST)
end
function s.rmtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsPlayerCanDraw(tp,2) end
	Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,2)
end
function s.rmop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Draw(tp,2,REASON_EFFECT)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.Destroy(c,REASON_EFFECT)
	end
end

----------------------------------------
-- Special Summon procedure
----------------------------------------
function s.spfilter(c)
	return c:IsSetCard(0x702) and c:IsType(TYPE_SPELL) and c:IsAbleToDeckAsCost()
end
function s.spcon(e,c)
	return Duel.IsExistingMatchingCard(s.spfilter,c:GetControler(),LOCATION_GRAVE+LOCATION_REMOVED,0,3,nil)
end
function s.spop(e,c)
	local tp=c:GetControler()
	if Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,3,nil) then
		local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,3,3,nil)
		if g:GetCount()>0 then
			Duel.SendtoDeck(g,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
		end
	end
end

----------------------------------------
-- Place "Flower Spirit" Spells from GY as Normal Monsters
-- NOTE: this is the most experimental part of the script (turning Spell Cards into
-- Normal Monsters is a very uncommon mechanic). It works by moving the Spell Card into
-- the Monster Zone and granting it temporary type/race/attribute/level effects.
-- ATK/DEF are left at 0/0, which already matches the default stats stored for Spell
-- Cards, so no ATK/DEF override is needed. Please test this in-client and let me know
-- if the engine needs a different approach.
----------------------------------------
function s.spscon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsContains(e:GetHandler())
end
function s.gyspellfilter(c)
	return c:IsSetCard(0x702) and c:IsType(TYPE_SPELL)
end
function s.spstg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.gyspellfilter,tp,LOCATION_GRAVE,0,1,nil)
		and Duel.GetLocationCount(tp,LOCATION_MZONE)>0 end
end
function s.spsop(e,tp,eg,ep,ev,re,r,rp)
	local mzcount=Duel.GetLocationCount(tp,LOCATION_MZONE)
	if mzcount<=0 then return end
	if not Duel.IsExistingMatchingCard(s.gyspellfilter,tp,LOCATION_GRAVE,0,1,nil) then return end
	local g=Duel.SelectMatchingCard(tp,s.gyspellfilter,tp,LOCATION_GRAVE,0,1,mzcount,nil)
	for tc in aux.Next(g) do
		if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then break end
		Duel.MoveToField(tc,tp,tp,LOCATION_MZONE,POS_FACEUP_ATTACK,true)
		if tc:IsRelateToEffect(e) then
			local le1=Effect.CreateEffect(c)
			le1:SetType(EFFECT_TYPE_SINGLE)
			le1:SetCode(EFFECT_ADD_TYPE)
			le1:SetValue(TYPE_MONSTER+TYPE_NORMAL)
			le1:SetReset(RESET_EVENT+0x1fe0000)
			tc:RegisterEffect(le1)
			local le2=le1:Clone()
			le2:SetCode(EFFECT_CHANGE_RACE)
			le2:SetValue(RACE_SPELLCASTER)
			tc:RegisterEffect(le2)
			local le3=le1:Clone()
			le3:SetCode(EFFECT_CHANGE_ATTRIBUTE)
			le3:SetValue(ATTRIBUTE_LIGHT)
			tc:RegisterEffect(le3)
			local le4=le1:Clone()
			le4:SetCode(EFFECT_UPDATE_LEVEL)
			le4:SetValue(4)
			tc:RegisterEffect(le4)
		end
	end
end

----------------------------------------
-- Once per turn: place this card in the Pendulum Zone
----------------------------------------
function s.pztg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
end
function s.pzop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) and c:IsFaceup() and c:GetControler()==tp then
		Duel.MoveToField(c,tp,tp,LOCATION_PZONE,POS_FACEUP,true)
	end
end
