-- ============================================================
-- Card Name: Maverick Hunter - Dive Armor Axl
-- Passcode : 11223320
-- Type     : Monster / Synchro / Effect
-- Attribute: LIGHT
-- Level    : 8
-- ATK/DEF  : 2500 / 2500
-- Race     : Machine
-- Archetype: Maverick Hunter (0x303), Axl (0x308)
-- Materials: 1 Tuner + 1+ "Axl" monsters
-- ============================================================
-- Effect 1: If this card is Synchro Summoned: You can equip
--           appropriate different "Maverick Boost" Equip Spell Cards
--           from your GY to this card.
--           You can only use this effect of "Maverick Hunter - Dive Armor Axl" once per turn.
-- Effect 2: Once while face-up on the field (Quick Effect): You can
--           destroy cards on the field up to the number of Equip
--           Spell Cards you control.
-- ============================================================

Duel.LoadScript("constants.lua")
local s,id=GetID()

function s.initial_effect(c)
	c:EnableReviveLimit()

	-- ============================================================
	-- Summon Procedure — Synchro: 1 Tuner + 1+ "Axl" monsters
	-- ============================================================
	Synchro.AddProcedure(c,nil,1,1,Synchro.NonTunerEx(Card.IsSetCard,SET_AXL),1,99)

	-- ============================================================
	-- Effect 1 — Trigger on Synchro Summon: Equip different Boost Equips from GY
	-- ============================================================
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_EQUIP)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.eqcon)
	e1:SetTarget(s.eqtg)
	e1:SetOperation(s.eqop)
	c:RegisterEffect(e1)

	-- ============================================================
	-- Effect 2 — Quick Effect: Destroy cards up to Equip Spells you control
	-- ============================================================
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_DESTROY)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetProperty(EFFECT_FLAG_NO_TURN_RESET)
	e2:SetRange(LOCATION_MZONE)
	e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E+TIMING_MAIN_END)
	e2:SetCountLimit(1)
	e2:SetTarget(s.destg)
	e2:SetOperation(s.desop)
	c:RegisterEffect(e2)
end

s.listed_series={SET_MAVERICK_HUNTER,SET_AXL,SET_MAVERICK_BOOST}

-- ============================================================
-- Effect 1 Logic
-- ============================================================
function s.eqcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_SYNCHRO)
end

function s.eqfilter(c,tc,tp)
	return c:IsSetCard(SET_MAVERICK_BOOST) and c:IsType(TYPE_EQUIP) and c:CheckEquipTarget(tc)
end

function s.eqtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
		and Duel.IsExistingMatchingCard(s.eqfilter,tp,LOCATION_GRAVE,0,1,nil,c,tp) end
	Duel.SetOperationInfo(0,CATEGORY_EQUIP,nil,1,tp,LOCATION_GRAVE)
end

function s.eqop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local ft=Duel.GetLocationCount(tp,LOCATION_SZONE)
	if ft<=0 or c:IsFacedown() or not c:IsRelateToEffect(e) then return end
	local g=Duel.GetMatchingGroup(s.eqfilter,tp,LOCATION_GRAVE,0,nil,c,tp)
	if #g==0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_EQUIP)
	local sg=aux.SelectUnselectGroup(g,e,tp,1,ft,aux.dncheck,1,tp,HINTMSG_EQUIP)
	if #sg>0 then
		for tc in aux.Next(sg) do
			Duel.Equip(tp,tc,c,true,true)
		end
		Duel.EquipComplete()
	end
end

-- ============================================================
-- Effect 2 Logic
-- ============================================================
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
	local ct=Duel.GetMatchingGroupCount(aux.FaceupFilter(Card.IsType,TYPE_EQUIP),tp,LOCATION_SZONE,0,nil)
	if chk==0 then return ct>0 and Duel.IsExistingMatchingCard(nil,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil) end
	local g=Duel.GetMatchingGroup(nil,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,nil)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
end

function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local ct=Duel.GetMatchingGroupCount(aux.FaceupFilter(Card.IsType,TYPE_EQUIP),tp,LOCATION_SZONE,0,nil)
	local g=Duel.GetMatchingGroup(nil,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,nil)
	if ct>0 and #g>0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
		local sg=g:Select(tp,1,ct,nil)
		Duel.HintSelection(sg,true)
		Duel.Destroy(sg,REASON_EFFECT)
	end
end
