-- Aether - Genshin the Heroic Traveller
local s,id=GetID()
function s.initial_effect(c)
	-- Link Summon
	Link.AddProcedure(c,s.matfilter1,3,4,s.lcheck)
	c:EnableReviveLimit()
	-- Cannot be targeted
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e1:SetCondition(s.tgcon)
	e1:SetValue(aux.tgoval)
	c:RegisterEffect(e1)
	-- Cannot be destroyed
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e2:SetRange(LOCATION_MZONE)
	e2:SetValue(aux.indoval)
	c:RegisterEffect(e2)
	-- Special Summon from GY
	local e3=Effect.CreateEffect(c)
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_CHAINING)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,{id,1})
	e3:SetCondition(s.spcon)
	e3:SetTarget(s.sptg)
	e3:SetOperation(s.spop)
	c:RegisterEffect(e3)
	e3:SetDescription(aux.Stringid(id,0))
	-- Gains ATK
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE)
	e4:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCode(EFFECT_UPDATE_ATTACK)
	e4:SetValue(s.atkval)
	c:RegisterEffect(e4)
	-- Return to Extra Deck
	local e5=Effect.CreateEffect(c)
	e5:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e5:SetType(EFFECT_TYPE_QUICK_O)
	e5:SetCode(EVENT_FREE_CHAIN)
	e5:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e5:SetRange(LOCATION_MZONE)
	e5:SetCountLimit(1,{id,2})
	e5:SetCost(s.rtcost)
	e5:SetTarget(s.rttg)
	e5:SetOperation(s.rtop)
	c:RegisterEffect(e5)
	e5:SetDescription(aux.Stringid(id,1))
end
s.listed_series={0x369}
function s.matfilter1(c,lc,sumtype,tp)
	return c:IsSetCard(0x369)
end
function s.matfilter2(c,lc,sumtype,tp)
	return c:IsType(TYPE_RITUAL|TYPE_FUSION|TYPE_SYNCHRO|TYPE_XYZ|TYPE_LINK)
end
function s.lcheck(g,lc,sumtype,tp)
	return g:IsExists(s.matfilter2,1,nil,lc,sumtype,tp)
end
function s.tgcon(e)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_LINK)
end
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local lg=c:GetLinkedGroup()
	local rc=re:GetHandler()
	return re:IsActiveType(TYPE_MONSTER) and lg and lg:IsContains(rc)
end
function s.spfilter(c,e,tp)
	return c:IsSetCard(0x369) and c:IsLevel(4) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		local zone=e:GetHandler():GetLinkedZone(tp)
		return zone~=0 and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_GRAVE,0,1,nil,e,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	local zone=c:GetLinkedZone(tp)
	if zone==0 then return end
	local ft=Duel.GetLocationCount(tp,LOCATION_MZONE,tp,LOCATION_REASON_TOFIELD,zone)
	if ft<=0 then return end
	if Duel.IsPlayerAffectedByEffect(tp,CARD_BLUEEYES_SPIRIT) then ft=1 end
	local g=Duel.GetMatchingGroup(aux.NecroValleyFilter(s.spfilter),tp,LOCATION_GRAVE,0,nil,e,tp)
	if #g==0 then return end
	if #g>ft then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		g=g:Select(tp,ft,ft,nil)
	end
	Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP,zone)
end
function s.atkval(e,c)
	local g=c:GetLinkedGroup()
	if not g or #g==0 then return 0 end
	local sum=0
	for tc in aux.Next(g) do
		local batk=tc:GetBaseAttack()
		if batk>0 then
			sum=sum+batk
		end
	end
	return sum
end
function s.rtcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsAbleToExtraAsCost() end
	Duel.SendtoDeck(e:GetHandler(),nil,0,REASON_COST)
end
function s.rtfilter(c,e,tp)
	return c:IsFaceup() and c:IsSetCard(0x369) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.rttg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return false end
	local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
	if e:GetHandler():GetSequence()<5 and e:GetHandler():IsLocation(LOCATION_MZONE) then
		ft=ft+1
	end
	local g=Duel.GetMatchingGroup(s.rtfilter,tp,LOCATION_REMOVED,0,nil,e,tp)
	if chk==0 then
		return ft>0 and aux.SelectUnselectGroup(g,e,tp,1,math.min(ft,3),aux.dncheck,0)
	end
	if Duel.IsPlayerAffectedByEffect(tp,CARD_BLUEEYES_SPIRIT) then ft=1 end
	local tg=aux.SelectUnselectGroup(g,e,tp,1,math.min(ft,3),aux.dncheck,1,tp,HINTMSG_SPSUMMON)
	Duel.SetTargetCard(tg)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,tg,#tg,tp,LOCATION_REMOVED)
end
function s.rtop(e,tp,eg,ep,ev,re,r,rp)
	local tg=Duel.GetTargetCards(e)
	local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
	if ft<=0 or #tg==0 then return end
	if Duel.IsPlayerAffectedByEffect(tp,CARD_BLUEEYES_SPIRIT) then
		if #tg>1 then return end
	end
	Duel.SpecialSummon(tg,0,tp,tp,false,false,POS_FACEUP)
end
