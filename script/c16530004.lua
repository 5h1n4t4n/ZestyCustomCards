-- ============================================================
-- Card Name: Cyberdarkness Nova
-- Passcode : 16530004
-- Type     : Monster / Effect / Xyz
-- Attribute: DARK
-- Rank     : 4
-- ATK/DEF  : 1000 / 1000
-- Race     : Machine
-- Archetype: Cyberdark (0x4093)
-- Materials: 2+ Level 4 "Cyberdark" monsters
-- ============================================================
-- Effect 1: If Xyz Summoned: Target monsters in either GY up to materials
--           this card has; attach them as material.
-- Effect 2: Gains ATK/DEF equal to total ATK/DEF of attached monsters.
-- Effect 3: (Quick Effect): Detach 1 material; attach opponent's
--           activated card to this card as material.
-- You can only use each effect of "Cyberdarkness Nova" once per turn.
-- ============================================================

local s,id=GetID()

function s.initial_effect(c)
	c:EnableReviveLimit()
	-- Xyz Materials: 2+ Level 4 "Cyberdark" monsters
	Xyz.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsSetCard,SET_CYBERDARK),4,2,nil,nil,Xyz.InfiniteMats)

	-- Attach monsters from either GY on Xyz Summon
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_LEAVE_GRAVE)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCountLimit(1,{id,1})
	e1:SetCondition(s.matcon)
	e1:SetTarget(s.mattg)
	e1:SetOperation(s.matop)
	c:RegisterEffect(e1)

	-- ATK/DEF gain based on attached monsters
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_UPDATE_ATTACK)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetValue(s.atkval)
	c:RegisterEffect(e2)
	local e2b=e2:Clone()
	e2b:SetCode(EFFECT_UPDATE_DEFENSE)
	e2b:SetValue(s.defval)
	c:RegisterEffect(e2b)

	-- Detach 1 material to attach opponent's activated card
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_CHAINING)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,{id,2})
	e3:SetCondition(s.attcon)
	e3:SetCost(s.attcost)
	e3:SetTarget(s.atttg)
	e3:SetOperation(s.attop)
	c:RegisterEffect(e3,false,REGISTER_FLAG_DETACH_XMAT)
end

s.listed_series={SET_CYBERDARK}

function s.matcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_XYZ)
end

function s.mattg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	local c=e:GetHandler()
	local ct=c:GetOverlayCount()
	if chkc then return chkc:IsLocation(LOCATION_GRAVE) and chkc:IsMonster() end
	if chk==0 then return ct>0 and Duel.IsExistingTarget(Card.IsMonster,tp,LOCATION_GRAVE,LOCATION_GRAVE,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_XMATERIAL)
	local g=Duel.SelectTarget(tp,Card.IsMonster,tp,LOCATION_GRAVE,LOCATION_GRAVE,1,ct,nil)
	Duel.SetOperationInfo(0,CATEGORY_LEAVE_GRAVE,g,#g,0,0)
end

function s.matop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	local tg=Duel.GetTargetCards(e)
	if #tg>0 then
		Duel.Overlay(c,tg)
	end
end

function s.atkval(e,c)
	local og=c:GetOverlayGroup():Filter(Card.IsMonster,nil)
	local val=0
	for tc in aux.Next(og) do
		local atk=tc:GetTextAttack()
		if atk>0 then val=val+atk end
	end
	return val
end

function s.defval(e,c)
	local og=c:GetOverlayGroup():Filter(Card.IsMonster,nil)
	local val=0
	for tc in aux.Next(og) do
		local def=tc:GetTextDefense()
		if def>0 then val=val+def end
	end
	return val
end

function s.attcon(e,tp,eg,ep,ev,re,r,rp)
	return rp==1-tp
end

function s.attcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:CheckRemoveOverlayCard(tp,1,REASON_COST) end
	c:RemoveOverlayCard(tp,1,1,REASON_COST)
end

function s.atttg(e,tp,eg,ep,ev,re,r,rp,chk)
	local rc=re:GetHandler()
	if chk==0 then return rc:IsRelateToEffect(re) and rc:IsCanBeXyzMaterial(e:GetHandler(),tp,REASON_EFFECT) end
end

function s.attop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local rc=re:GetHandler()
	if c:IsRelateToEffect(e) and rc:IsRelateToEffect(re) and not rc:IsImmuneToEffect(e)
		and rc:IsCanBeXyzMaterial(c,tp,REASON_EFFECT) then
		rc:CancelToGrave()
		Duel.Overlay(c,rc,true)
	end
end
