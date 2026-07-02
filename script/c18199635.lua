-- ============================================================
-- Card Name: Lyney, Genshin the Great Magician of Fontaine
-- Passcode : 18199616
-- Type     : Monster / Effect
-- Attribute: FIRE
-- Level    : 7
-- ATK/DEF  : 2200 / 1400
-- Race     : Spellcaster
-- Archetype: Genshin (0x369)
-- ============================================================
-- Effect 1: If a "Genshin" monster you control would be used
--           as Fusion, Synchro or Link Material for a "Genshin"
--           Fusion, Synchro or Link Monster, this card in your
--           hand can also be used as material.
-- Effect 2: If this card is sent from the hand or field to the
--           GY as material for the Fusion, Synchro or Link
--           Summon of a "Genshin" Fusion, Synchro or Link
--           Monster: You can choose 1 unused Main Monster Zone;
--           it cannot be used until the end of the next turn.
-- ============================================================
-- You can only use each effect once per turn.
-- ============================================================
-- Official references:
--   Code Generator (30114823) — EFFECT_EXTRA_MATERIAL from hand
--   Excode Talker   (40669071) — EFFECT_DISABLE_FIELD zone lock
-- ============================================================

local s,id=GetID()
Duel.LoadScript("constants.lua")

function s.initial_effect(c)
	-- ============================================================
	-- Effect 1 — Extra Material from Hand
	-- If a "Genshin" monster you control would be used as
	-- Fusion, Synchro or Link Material for a "Genshin" FSL
	-- Monster, this card in your hand can also be used as material
	-- ============================================================
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e1:SetCode(EFFECT_EXTRA_MATERIAL)
	e1:SetRange(LOCATION_HAND)
	e1:SetTargetRange(1,0)
	e1:SetOperation(s.extracon)
	e1:SetValue(s.extraval)
	c:RegisterEffect(e1)
	if s.flagmap==nil then
		s.flagmap={}
	end
	if s.flagmap[c]==nil then
		s.flagmap[c]={}
	end
	-- ============================================================
	-- Effect 2 — Trigger: Disable 1 Main Monster Zone
	-- If this card is sent from hand/field to GY as material
	-- for a "Genshin" Fusion/Synchro/Link Monster
	-- ============================================================
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_BE_MATERIAL)
	e2:SetCountLimit(1,{id,1})
	e2:SetCondition(s.discon)
	e2:SetTarget(s.distg)
	e2:SetOperation(s.disop)
	c:RegisterEffect(e2)
end

s.listed_series={0x369}

-- ============================================================
-- Effect 1: Extra Material — Condition filter
-- At least 1 "Genshin" monster the player controls must be
-- among the materials already selected
-- ============================================================
function s.extrafilter(c,tp)
	return c:IsLocation(LOCATION_MZONE) and c:IsControler(tp)
end
function s.extracon(c,e,tp,sg,mg,lc,og,chk)
	return (sg+mg):Filter(s.extrafilter,nil,e:GetHandlerPlayer())
		:IsExists(Card.IsSetCard,1,og,0x369)
		and sg:FilterCount(Card.HasFlagEffect,nil,id)<2
end

-- ============================================================
-- Effect 1: Extra Material — Value (summon type check)
-- Only for Fusion, Synchro or Link summon of "Genshin" monster
-- ============================================================
function s.extraval(chk,summon_type,e,...)
	local c=e:GetHandler()
	if chk==0 then
		local tp,sc=...
		local valid_summon=summon_type&SUMMON_TYPE_FUSION==SUMMON_TYPE_FUSION
			or summon_type&SUMMON_TYPE_SYNCHRO==SUMMON_TYPE_SYNCHRO
			or summon_type&SUMMON_TYPE_LINK==SUMMON_TYPE_LINK
		if not valid_summon
			or not sc
			or not sc:IsSetCard(0x369)
			or Duel.GetFlagEffect(tp,id)>0
		then
			return Group.CreateGroup()
		else
			table.insert(s.flagmap[c],
				c:RegisterFlagEffect(id,0,0,1))
			return Group.FromCards(c)
		end
	elseif chk==1 then
		local sg,sc,tp=...
		local used_type=summon_type&SUMMON_TYPE_FUSION==SUMMON_TYPE_FUSION
			or summon_type&SUMMON_TYPE_SYNCHRO==SUMMON_TYPE_SYNCHRO
			or summon_type&SUMMON_TYPE_LINK==SUMMON_TYPE_LINK
		if used_type and #sg>0 then
			Duel.Hint(HINT_CARD,tp,id)
			Duel.RegisterFlagEffect(tp,id,
				RESET_PHASE|PHASE_END,0,1)
		end
	elseif chk==2 then
		for _,eff in ipairs(s.flagmap[c]) do
			eff:Reset()
		end
		s.flagmap[c]={}
	end
end

-- ============================================================
-- Effect 2: Condition — Card sent to GY from hand/field as
-- material for a "Genshin" Fusion/Synchro/Link Monster
-- ============================================================
function s.discon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsLocation(LOCATION_GRAVE) then return false end
	if not c:IsPreviousLocation(LOCATION_HAND+LOCATION_ONFIELD) then
		return false
	end
	local rc=c:GetReasonCard()
	if not rc then return false end
	if not rc:IsSetCard(0x369) then return false end
	return (r&REASON_FUSION)~=0
		or (r&REASON_SYNCHRO)~=0
		or (r&REASON_LINK)~=0
end

-- ============================================================
-- Effect 2: Target — Must have at least 1 unused Main Monster
-- Zone (either player's)
-- ============================================================
function s.distg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)
			+Duel.GetLocationCount(1-tp,LOCATION_MZONE)>0
	end
	local dis=Duel.SelectDisableField(tp,1,LOCATION_MZONE,LOCATION_MZONE,0)
	Duel.Hint(HINT_ZONE,tp,dis)
	e:SetLabel(dis)
end

-- ============================================================
-- Effect 2: Operation — Disable the chosen Main Monster Zone
-- until the end of the next turn
-- ============================================================
function s.disop(e,tp,eg,ep,ev,re,r,rp)
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_DISABLE_FIELD)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e1:SetOperation(s.disopval)
	e1:SetReset(RESET_PHASE+PHASE_END,2)
	e1:SetLabel(e:GetLabel())
	Duel.RegisterEffect(e1,tp)
end
function s.disopval(e,tp)
	return e:GetLabel()
end