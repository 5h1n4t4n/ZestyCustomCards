-- ============================================================
-- Card Name: Dark Maverick Hunter - Zero Virus
-- Passcode : 11223325
-- Type     : Monster / Fusion / Effect
-- Attribute: DARK
-- Level    : 4
-- ATK/DEF  : 2000 / 1600
-- Race     : Machine
-- Archetype: Maverick Hunter (0x303), Zero (0x306)
-- Materials: Must be Special Summoned by "Maverick Boost - Virus Affect"
-- ============================================================
-- Effect 1: Must be Special Summoned by the effect of "Maverick
--           Boost - Virus Affect".
-- Effect 2: If this card is Special Summoned and your opponent controls
--           more cards than you do: You can draw cards equal to the
--           number of monsters your opponent controls, and if they
--           control 5 monsters, this effect cannot be negated.
-- Effect 3: If this card is sent to the GY: You can add 1 "Maverick
--           Hunter" or "Maverick Boost" card from your Deck or GY
--           to your hand.
-- You can only use each effect of "Dark Maverick Hunter - Zero Virus" once per turn.
-- ============================================================

Duel.LoadScript("constants.lua")
local s,id=GetID()

function s.initial_effect(c)
	c:EnableReviveLimit()

	-- ============================================================
	-- Summon Condition — Must be Special Summoned by "Maverick Boost - Virus Affect"
	-- ============================================================
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_SPSUMMON_CONDITION)
	e0:SetValue(s.splimit)
	c:RegisterEffect(e0)

	-- ============================================================
	-- Effect 1 — Trigger on Special Summon: Draw cards equal to opponent's monsters
	-- ============================================================
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DRAW)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.drcon)
	e1:SetTarget(s.drtg)
	e1:SetOperation(s.drop)
	c:RegisterEffect(e1)

	-- ============================================================
	-- Effect 2 — Trigger on Sent to GY: Add 1 Hunter or Boost card
	-- ============================================================
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_TO_GRAVE)
	e2:SetCountLimit(1,{id,1})
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
end

s.listed_names={11223318}
s.listed_series={SET_MAVERICK_HUNTER,SET_ZERO,SET_MAVERICK_BOOST}

-- ============================================================
-- Summon Condition Logic
-- ============================================================
function s.splimit(e,se,sp,st)
	return se and se:GetHandler():IsCode(11223318)
end

-- ============================================================
-- Effect 1 Logic
-- ============================================================
function s.drcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetFieldGroupCount(tp,0,LOCATION_ONFIELD)>Duel.GetFieldGroupCount(tp,LOCATION_ONFIELD,0)
end

function s.drtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local ct=Duel.GetMatchingGroupCount(nil,tp,0,LOCATION_MZONE,nil)
	if chk==0 then return ct>0 and Duel.IsPlayerCanDraw(tp,ct) end
	Duel.SetTargetPlayer(tp)
	Duel.SetTargetParam(ct)
	Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,ct)
	if ct>=5 then
		e:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CANNOT_INACTIVATE+EFFECT_FLAG_CANNOT_DISABLE)
		Duel.SetChainLimit(aux.FALSE)
	else
		e:SetProperty(EFFECT_FLAG_DELAY)
	end
end

function s.drop(e,tp,eg,ep,ev,re,r,rp)
	local p=Duel.GetChainInfo(0,CHAININFO_TARGET_PLAYER)
	local ct=Duel.GetMatchingGroupCount(nil,tp,0,LOCATION_MZONE,nil)
	if ct>0 then
		Duel.Draw(p,ct,REASON_EFFECT)
	end
end

-- ============================================================
-- Effect 2 Logic
-- ============================================================
function s.thfilter(c)
	return (c:IsSetCard(SET_MAVERICK_HUNTER) or c:IsSetCard(SET_MAVERICK_BOOST)) and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,c) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.thfilter),tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,c)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end
