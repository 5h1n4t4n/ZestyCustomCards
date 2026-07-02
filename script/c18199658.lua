-- Xingqiu, Genshin the Juvenile Scholar
local s,id=GetID()
function s.initial_effect(c)
	-- Quick Effect Ritual Summon
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_MZONE)
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_MAIN_END)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.ritcon)
	e1:SetTarget(s.rittg)
	e1:SetOperation(s.ritop)
	c:RegisterEffect(e1)
	-- Sent to GY or banished
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e2:SetCode(EVENT_TO_GRAVE)
	e2:SetCountLimit(1,id)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
	local e3=e2:Clone()
	e3:SetCode(EVENT_REMOVE)
	c:RegisterEffect(e3)
end
s.listed_series={0x369}
function s.ritcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsMainPhase()
end
function s.rfilter(c,e,tp,m,c_handler)
	if not (c:IsSetCard(0x369) and c:IsType(TYPE_RITUAL) and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_RITUAL,tp,false,true)) then return false end
	local lv=c:GetLevel()
	if c:IsLocation(LOCATION_HAND) then
		return m:IsExists(s.matfilter,1,nil,m,lv,c_handler,tp,c)
	else
		return m:IsExists(s.matfilter,1,c,m,lv,c_handler,tp,c)
	end
end
function s.matfilter(c,m,lv,c_handler,tp,rc)
	if c_handler and c~=c_handler and not m:IsContains(c_handler) then return false end
	local mg=m:Filter(Card.IsReleasable,rc)
	if rc:IsLocation(LOCATION_GRAVE) then mg:RemoveCard(rc) end
	return mg:IsContains(c_handler) and aux.SelectUnselectGroup(mg,e,tp,1,99,s.rescon(lv,c_handler),0)
end
function s.rescon(lv,c_handler)
	return function(sg,e,tp,mg)
		return sg:IsContains(c_handler) and sg:GetSum(Card.GetLevel)>=lv
	end
end
function s.rittg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		local mg=Duel.GetMatchingGroup(Card.IsReleasable,tp,LOCATION_HAND+LOCATION_MZONE,0,nil)
		if not mg:IsContains(c) then return false end
		local rg=Duel.GetMatchingGroup(aux.NecroValleyFilter(Card.IsType),tp,LOCATION_HAND+LOCATION_GRAVE,0,nil,TYPE_RITUAL)
		return rg:IsExists(s.rfilter,1,nil,e,tp,mg,c)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_GRAVE)
end
function s.ritop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not (c:IsRelateToEffect(e) and c:IsControler(tp) and c:IsReleasable()) then return end
	local mg=Duel.GetMatchingGroup(Card.IsReleasable,tp,LOCATION_HAND+LOCATION_MZONE,0,nil)
	local rg=Duel.GetMatchingGroup(aux.NecroValleyFilter(Card.IsType),tp,LOCATION_HAND+LOCATION_GRAVE,0,nil,TYPE_RITUAL)
	local tg=rg:Filter(s.rfilter,nil,e,tp,mg,c)
	if #tg>0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local tc=tg:Select(tp,1,1,nil):GetFirst()
		if tc then
			mg:RemoveCard(tc)
			local mat=aux.SelectUnselectGroup(mg,e,tp,1,99,s.rescon(tc:GetLevel(),c),1,tp,HINTMSG_RELEASE,s.rescon(tc:GetLevel(),c))
			tc:SetMaterial(mat)
			Duel.Release(mat,REASON_EFFECT+REASON_MATERIAL+REASON_RITUAL)
			Duel.BreakEffect()
			Duel.SpecialSummon(tc,SUMMON_TYPE_RITUAL,tp,tp,false,true,POS_FACEUP)
			tc:CompleteProcedure()
		end
	end
end
function s.thfilter(c)
	return c:IsSetCard(0x369) and c:IsMonster() and not c:IsCode(id) and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_GRAVE) and chkc:IsControler(tp) and s.thfilter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.thfilter,tp,LOCATION_GRAVE,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectTarget(tp,s.thfilter,tp,LOCATION_GRAVE,0,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,g,1,0,0)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		Duel.SendtoHand(tc,nil,REASON_EFFECT)
	end
end
