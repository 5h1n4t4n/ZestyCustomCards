-- ============================================================
-- Card Name: Maverick Boost - Black Armor
-- Passcode : 11223310
-- Type     : Spell / Equip
-- Archetype: Maverick Boost (0x304)
-- ============================================================
-- Effect 1: Equip only to a "Zero" monster.
-- Effect 2: If the equipped monster battles a Special Summoned monster,
--           it gains 1000 ATK during damage calculation.
-- Effect 3: When your opponent activates a card or effect: You can
--           activate this effect; immediately after this effect
--           resolves, Xyz Summon 1 Xyz Monster using this card as a
--           Level 4 Machine monster and the equipped monster you
--           control as Materials.
-- Effect 4: If this card is banished: You can add this card to your hand.
-- You can only use this effect of "Maverick Boost - Black Armor" once per turn.
-- ============================================================

Duel.LoadScript("constants.lua")
local s,id=GetID()

function s.initial_effect(c)
	-- ============================================================
	-- Equip Procedure: Equip only to a "Zero" monster
	-- ============================================================
	aux.AddEquipProcedure(c,0,s.eqfilter)

	-- ============================================================
	-- Effect 1 — Continuous: ATK boost during damage calc vs SS monster
	-- ============================================================
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_EQUIP)
	e1:SetCode(EFFECT_UPDATE_ATTACK)
	e1:SetCondition(s.atkcon)
	e1:SetValue(1000)
	c:RegisterEffect(e1)

	-- ============================================================
	-- Effect 2 — Quick Effect: Quick Xyz Summon on opponent's activation
	-- ============================================================
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_CHAINING)
	e2:SetRange(LOCATION_SZONE)
	e2:SetCountLimit(1,id)
	e2:SetCondition(s.xyzcon)
	e2:SetTarget(s.xyztg)
	e2:SetOperation(s.xyzop)
	c:RegisterEffect(e2)

	-- ============================================================
	-- Effect 3 — Trigger on Banish: Add this card to hand
	-- ============================================================
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_TOHAND)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_REMOVE)
	e3:SetCountLimit(1,{id,1})
	e3:SetTarget(s.thtg)
	e3:SetOperation(s.thop)
	c:RegisterEffect(e3)
end

s.listed_series={SET_ZERO,SET_MAVERICK_BOOST}

-- ============================================================
-- Equip Procedure Filter
-- ============================================================
function s.eqfilter(c)
	return c:IsFaceup() and c:IsSetCard(SET_ZERO)
end

-- ============================================================
-- Effect 1 Logic
-- ============================================================
function s.atkcon(e)
	local ec=e:GetHandler():GetEquipTarget()
	if not ec then return false end
	local phase=Duel.GetCurrentPhase()
	if phase~=PHASE_DAMAGE and phase~=PHASE_DAMAGE_CAL then return false end
	local bc=ec:GetBattleTarget()
	return bc and bc:IsSpecialSummoned()
end

-- ============================================================
-- Effect 2 Logic
-- ============================================================
function s.xyzfilter(c,e,tp,ec,eqc)
	if not (c:IsType(TYPE_XYZ) and c:IsRank(4)
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_XYZ,tp,false,false)) then return false end
	local mg=Group.FromCards(ec,eqc)
	if Duel.GetLocationCountFromEx(tp,tp,mg,c)<=0 then return false end
	if c.minxyzct and (c.minxyzct>2 or c.maxxyzct<2) then return false end
	if c.xyz_filter then
		return c.xyz_filter(ec,false,c,tp)
	end
	return true
end

function s.xyzcon(e,tp,eg,ep,ev,re,r,rp)
	local ec=e:GetHandler():GetEquipTarget()
	return rp==1-tp and ec and ec:IsControler(tp) and ec:IsFaceup() and ec:IsLevel(4) and ec:IsRace(RACE_MACHINE)
end

function s.xyztg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	local ec=c:GetEquipTarget()
	if chk==0 then
		if not ec then return false end
		return Duel.IsExistingMatchingCard(s.xyzfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp,ec,c)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

function s.xyzop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local ec=c:GetEquipTarget()
	if not c:IsRelateToEffect(e) or not ec or ec:IsFacedown() or not ec:IsControler(tp) then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.xyzfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp,ec,c)
	local sc=g:GetFirst()
	if sc then
		local mg=Group.FromCards(c,ec)
		Duel.Overlay(sc,mg)
		sc:SetMaterial(mg)
		if Duel.SpecialSummon(sc,SUMMON_TYPE_XYZ,tp,tp,false,false,POS_FACEUP)>0 then
			sc:CompleteProcedure()
		end
	end
end

-- ============================================================
-- Effect 3 Logic
-- ============================================================
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsAbleToHand() end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,c,1,0,0)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SendtoHand(c,nil,REASON_EFFECT)
	end
end
