--Flower Spirit - Magical Doll Friend
local s,id=GetID()

function s.initial_effect(c)
	--Activate
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

function s.filter(c)
	return c:IsSetCard(0x702) and not c:IsType(TYPE_TOKEN)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_GRAVE) and chkc:IsControler(tp) and s.filter(chkc) end
	local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
	if chk==0 then
		return ft>=2 and not Duel.IsPlayerAffectedByEffect(tp,CARD_BLUEEYES_SPIRIT)
			and Duel.IsExistingTarget(s.filter,tp,LOCATION_GRAVE,0,2,nil)
	end
	local max_count=math.min(ft,2)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	local g=Duel.SelectTarget(tp,s.filter,tp,LOCATION_GRAVE,0,2,max_count,nil)
	Duel.SetOperationInfo(0,CATEGORY_LEAVE_GRAVE,g,#g,0,0)
end

function s.xyzfilter(c)
	return c:IsSetCard(0x702) and c:IsXyzSummonable(nil)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local g=Duel.GetTargetCards(e)
	local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
	
	-- Kiểm tra an toàn: tránh crash nếu g bị nil hoặc rỗng do card rời khỏi GY
	if not g or #g==0 or ft<=0 then return end
	if Duel.IsPlayerAffectedByEffect(tp,CARD_BLUEEYES_SPIRIT) then ft=1 end
	if #g>ft then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOFIELD)
		g=g:Select(tp,ft,ft,nil)
	end

	local moved_count=0
	for tc in aux.Next(g) do
		if Duel.MoveToField(tc,tp,tp,LOCATION_MZONE,POS_FACEUP,true) then
			moved_count=moved_count+1
			-- Coi như Normal Monster
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_ADD_TYPE)
			e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
			e1:SetValue(TYPE_MONSTER+TYPE_NORMAL)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD)
			tc:RegisterEffect(e1)
			-- Level 6
			local e2=e1:Clone()
			e2:SetCode(EFFECT_CHANGE_LEVEL)
			e2:SetValue(6)
			tc:RegisterEffect(e2)
			-- Race: Zombie
			local e3=e1:Clone()
			e3:SetCode(EFFECT_CHANGE_RACE)
			e3:SetValue(RACE_ZOMBIE)
			tc:RegisterEffect(e3)
			-- Attribute: DARK
			local e4=e1:Clone()
			e4:SetCode(EFFECT_CHANGE_ATTRIBUTE)
			e4:SetValue(ATTRIBUTE_DARK)
			tc:RegisterEffect(e4)
			-- ATK 0
			local e5=e1:Clone()
			e5:SetCode(EFFECT_SET_BASE_ATTACK)
			e5:SetValue(0)
			tc:RegisterEffect(e5)
			-- DEF 0
			local e6=e1:Clone()
			e6:SetCode(EFFECT_SET_BASE_DEFENSE)
			e6:SetValue(0)
			tc:RegisterEffect(e6)
		end
	end

	-- Triệu hồi Xyz ngay sau đó (nếu có quái đủ điều kiện)
	if moved_count>0 then
		local xyzg=Duel.GetMatchingGroup(s.xyzfilter,tp,LOCATION_EXTRA,0,nil)
		if #xyzg>0 and Duel.SelectYesNo(tp,aux.Stringid(id,0)) then
			Duel.BreakEffect()
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
			local sc=xyzg:Select(tp,1,1,nil):GetFirst()
			if sc then
				Duel.XyzSummon(tp,sc,nil)
			end
		end
	end
end