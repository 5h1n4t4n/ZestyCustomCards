--Flower Spirit-Lapines' lazy day
local s,id=GetID()

function s.initial_effect(c)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
	--While equipped to a Fusion/Synchro monster: that monster cannot be targeted by
	--your opponent's card effects
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e2:SetRange(LOCATION_SZONE)
	e2:SetTargetRange(0,1)
	e2:SetValue(function(e,c) return c==e:GetHandler():GetEquipTarget() end)
	c:RegisterEffect(e2)
end

function s.sumfilter(c)
	return c:IsSetCard(0x702) and (c:IsType(TYPE_FUSION) or c:IsType(TYPE_SYNCHRO) or c:IsType(TYPE_XYZ))
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.sumfilter,tp,LOCATION_EXTRA,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,0,tp,LOCATION_EXTRA)
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	if not Duel.IsExistingMatchingCard(s.sumfilter,tp,LOCATION_EXTRA,0,1,nil) then return end
	local g=Duel.SelectMatchingCard(tp,s.sumfilter,tp,LOCATION_EXTRA,0,1,1,nil)
	if g:GetCount()==0 then return end
	local tc=g:GetFirst()
	local lv=tc:GetRank()>0 and tc:GetRank() or tc:GetLevel()
	Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
	if tc:IsRelateToEffect(e) and lv>0 then
		Duel.DiscardDeck(tp,lv,REASON_EFFECT)
	end
	local c=e:GetHandler()
	if not (tc:IsRelateToEffect(e) and c:IsRelateToEffect(e)) then return end
	if tc:IsType(TYPE_XYZ) then
		Duel.Overlay(tc,c)
		--Unaffected by opponent's card effects during opponent's turn (approximate;
		--applies while attached, please test if it needs to reset on detach)
		if c:IsRelateToEffect(e) then
			local pe=Effect.CreateEffect(tc)
			pe:SetType(EFFECT_TYPE_SINGLE)
			pe:SetCode(EFFECT_IMMUNE_EFFECT)
			pe:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
			pe:SetRange(LOCATION_MZONE)
			pe:SetTargetRange(1,0)
			pe:SetCondition(function(pe) return Duel.GetTurnPlayer()==1-tp end)
			pe:SetValue(aux.TRUE)
			tc:RegisterEffect(pe)
		end
	else
		Duel.Equip(tp,c,tc,true)
	end
end
