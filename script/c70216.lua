--Flower Spirit - Magical Doll Friend
local s,id=GetID()

function s.initial_effect(c)
	--Activate
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id+EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
	
	--If banished from GY: Special Summon self as normal monster
	local e2=Effect.CreateEffect(c)
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_REMOVE)
	e2:SetCondition(s.spcon)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)
end

function s.filter(c,e,tp)
	return c:IsSetCard(0x702) and c:IsType(TYPE_SPELL)
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_GRAVE) and chkc:IsControler(tp) and s.filter(chkc,e,tp) end
	local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
	if chk==0 then return ft>0 and Duel.IsExistingTarget(s.filter,tp,LOCATION_GRAVE,0,1,nil,e,tp) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectTarget(tp,s.filter,tp,LOCATION_GRAVE,0,1,ft,nil,e,tp)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,g,#g,0,0)
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local g=Duel.GetTargetCards(e)
	local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
	if #g==0 or ft<=0 then return end
	if #g>ft then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOFIELD)
		g=g:Select(tp,ft,ft,nil)
	end
	for tc in aux.Next(g) do
		if Duel.MoveToField(tc,tp,tp,LOCATION_MZONE,POS_FACEUP,true) then
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_ADD_TYPE)
			e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
			e1:SetValue(TYPE_MONSTER+TYPE_NORMAL)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD)
			tc:RegisterEffect(e1)
			local e2=e1:Clone()
			e2:SetCode(EFFECT_CHANGE_LEVEL)
			e2:SetValue(6)
			tc:RegisterEffect(e2)
			local e3=e1:Clone()
			e3:SetCode(EFFECT_CHANGE_RACE)
			e3:SetValue(RACE_ZOMBIE)
			tc:RegisterEffect(e3)
			local e4=e1:Clone()
			e4:SetCode(EFFECT_CHANGE_ATTRIBUTE)
			e4:SetValue(ATTRIBUTE_DARK)
			tc:RegisterEffect(e4)
			local e5=e1:Clone()
			e5:SetCode(EFFECT_SET_BASE_ATTACK)
			e5:SetValue(0)
			tc:RegisterEffect(e5)
			local e6=e1:Clone()
			e6:SetCode(EFFECT_SET_BASE_DEFENSE)
			e6:SetValue(0)
			tc:RegisterEffect(e6)
		end
	end
	--Xyz Summon immediately after
	local xyzg=Duel.GetMatchingGroup(function(xyzc) return xyzc:IsSetCard(0x702) and xyzc:IsXyzSummonable(nil) end,tp,LOCATION_EXTRA,0,nil)
	if #xyzg>0 and Duel.SelectYesNo(tp,aux.Stringid(id,0)) then
		Duel.BreakEffect()
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local sc=xyzg:Select(tp,1,1,nil):GetFirst()
		Duel.XyzSummon(tp,sc,nil)
	end
end

function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsPreviousLocation(LOCATION_GRAVE)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0 end
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) or Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	local opt=Duel.SelectOption(tp,aux.Stringid(id,1),aux.Stringid(id,2))
	if Duel.MoveToField(c,tp,tp,LOCATION_MZONE,POS_FACEUP,true) then
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_ADD_TYPE)
		e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e1:SetValue(TYPE_MONSTER+TYPE_NORMAL)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		c:RegisterEffect(e1)
		local e2=e1:Clone()
		e2:SetCode(EFFECT_CHANGE_LEVEL)
		e2:SetValue(opt==0 and 4 or 6)
		c:RegisterEffect(e2)
		local e3=e1:Clone()
		e3:SetCode(EFFECT_CHANGE_RACE)
		e3:SetValue(opt==0 and RACE_SPELLCASTER or RACE_ZOMBIE)
		c:RegisterEffect(e3)
		local e4=e1:Clone()
		e4:SetCode(EFFECT_CHANGE_ATTRIBUTE)
		e4:SetValue(opt==0 and ATTRIBUTE_LIGHT or ATTRIBUTE_DARK)
		c:RegisterEffect(e4)
		local e5=e1:Clone()
		e5:SetCode(EFFECT_SET_BASE_ATTACK)
		e5:SetValue(0)
		c:RegisterEffect(e5)
		local e6=e1:Clone()
		e6:SetCode(EFFECT_SET_BASE_DEFENSE)
		e6:SetValue(0)
		c:RegisterEffect(e6)
	end
end