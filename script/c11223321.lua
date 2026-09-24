-- ============================================================
-- Card Name: Maverick Hunter - Dive Armor X
-- Passcode : 11223321
-- Type     : Monster / Synchro / Effect
-- Attribute: LIGHT
-- Level    : 8
-- ATK/DEF  : 2800 / 2400
-- Race     : Machine
-- Archetype: Maverick Hunter (0x303), X (0x307)
-- Materials: 1 Tuner + 1+ "X" monsters
-- ============================================================
-- Effect 1: Unaffected by your opponent's monster effects.
-- Effect 2: (Quick Effect): Send 1 "Maverick Boost" card (except
--           Equip Spell Card) that meets its activation conditions
--           from your Deck to the GY; this effect becomes that
--           card's effect when it is activated.
-- You can only use this effect of "Maverick Hunter - Dive Armor X" once per turn.
-- ============================================================

Duel.LoadScript("constants.lua")
local s,id=GetID()

function s.initial_effect(c)
	c:EnableReviveLimit()

	-- ============================================================
	-- Summon Procedure — Synchro: 1 Tuner + 1+ "X" monsters
	-- ============================================================
	Synchro.AddProcedure(c,nil,1,1,Synchro.NonTunerEx(Card.IsSetCard,SET_X),1,99)

	-- ============================================================
	-- Effect 1 — Continuous: Unaffected by opponent's monster effects
	-- ============================================================
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCode(EFFECT_IMMUNE_EFFECT)
	e1:SetValue(s.efilter)
	c:RegisterEffect(e1)

	-- ============================================================
	-- Effect 2 — Quick Effect: Copy "Maverick Boost" activation from Deck
	-- ============================================================
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetCountLimit(1,id)
	e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E+TIMING_MAIN_END)
	e2:SetCost(s.effcost)
	e2:SetTarget(s.efftg)
	e2:SetOperation(s.effop)
	c:RegisterEffect(e2)
end

s.listed_series={SET_MAVERICK_HUNTER,SET_X,SET_MAVERICK_BOOST}

-- ============================================================
-- Effect 1 Logic
-- ============================================================
function s.efilter(e,te)
	return te:IsActiveType(TYPE_MONSTER) and te:GetOwnerPlayer()~=e:GetHandlerPlayer()
end

-- ============================================================
-- Effect 2 Logic (Rafflesia-style copy activation from Deck)
-- ============================================================
function s.copyfilter(c)
	if not (c:IsSetCard(SET_MAVERICK_BOOST) and not c:IsType(TYPE_EQUIP) and c:IsAbleToGraveAsCost()) then return false end
	local te=c:CheckActivateEffect(false,true,true)
	return te and te:GetOperation()~=nil
end

function s.effcost(e,tp,eg,ep,ev,re,r,rp,chk)
	e:SetLabel(-100)
	if chk==0 then
		local g=Duel.GetMatchingGroup(s.copyfilter,tp,LOCATION_DECK,0,nil)
		e:SetLabelObject(g)
		return #g>0
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local sc=e:GetLabelObject():Select(tp,1,1,nil):GetFirst()
	e:SetLabelObject(sc)
	Duel.SendtoGrave(sc,REASON_COST)
end

function s.efftg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		local te,ceg,cep,cev,cre,cr,crp=table.unpack(e:GetLabelObject())
		return te and te:GetTarget() and te:GetTarget()(e,tp,ceg,cep,cev,cre,cr,crp,chk,chkc)
	end
	if chk==0 then
		local res=e:GetLabel()==-100
		e:SetLabel(0)
		return res
	end
	local sc=e:GetLabelObject()
	local te,ceg,cep,cev,cre,cr,crp=sc:CheckActivateEffect(true,true,true)
	e:SetLabel(te:GetLabel())
	e:SetLabelObject(te:GetLabelObject())
	local tg=te:GetTarget()
	if tg then
		e:SetProperty(te:GetProperty())
		tg(e,tp,ceg,cep,cev,cre,cr,crp,1)
		te:SetLabel(e:GetLabel())
		te:SetLabelObject(e:GetLabelObject())
		Duel.ClearOperationInfo(0)
	end
	e:SetLabel(0)
	e:SetLabelObject({te,ceg,cep,cev,cre,cr,crp})
end

function s.effop(e,tp,eg,ep,ev,re,r,rp)
	local te,ceg,cep,cev,cre,cr,crp=table.unpack(e:GetLabelObject())
	if not te then return end
	local op=te:GetOperation()
	if op then
		e:SetLabel(te:GetLabel())
		e:SetLabelObject(te:GetLabelObject())
		op(e,tp,ceg,cep,cev,cre,cr,crp)
	end
	e:SetLabel(0)
	e:SetLabelObject(nil)
end
