-- Hysteric Harpie Lady
local s,id=GetID()
function s.initial_effect(c)
	-- Name becomes "Harpie Lady" while on field or in GY
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e0:SetCode(EFFECT_CHANGE_CODE)
	e0:SetRange(LOCATION_MZONE+LOCATION_GRAVE)
	e0:SetValue(76812113)
	c:RegisterEffect(e0)
	
	-- Special Summon from hand or GY and match Level
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_HAND+LOCATION_GRAVE)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.sptg1)
	e1:SetOperation(s.spop1)
	c:RegisterEffect(e1)
	
	-- Quick Summon from Extra Deck during Main Phase
	local e2=Effect.CreateEffect(c)
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,id+100)
	e2:SetCondition(s.excon)
	e2:SetTarget(s.extg)
	e2:SetOperation(s.exop)
	c:RegisterEffect(e2)
	
	-- Special Summon from Deck if sent to GY
	local e3=Effect.CreateEffect(c)
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_TO_GRAVE)
	e3:SetCountLimit(1,id+200)
	e3:SetTarget(s.sptg2)
	e3:SetOperation(s.spop2)
	c:RegisterEffect(e3)
end

function s.tgfilter(c)
	return c:IsFaceup() and c:IsSetCard(0x64) and not c:IsCode(id) and c:HasLevel()
end
function s.sptg1(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	local c=e:GetHandler()
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(tp) and s.tgfilter(chkc) end
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
		and Duel.IsExistingTarget(s.tgfilter,tp,LOCATION_MZONE,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	Duel.SelectTarget(tp,s.tgfilter,tp,LOCATION_MZONE,0,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end
function s.spop1(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if c:IsRelateToEffect(e) and Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)>0 then
		if tc and tc:IsRelateToEffect(e) and tc:IsFaceup() and tc:HasLevel() then
			local lv=tc:GetLevel()
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_CHANGE_LEVEL)
			e1:SetValue(lv)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD_DISABLE)
			c:RegisterEffect(e1)
		end
	end
end

function s.excon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsMainPhase()
end
function s.exfilter(c,mg,fmg,tp)
	if not c:IsSetCard(0x64) then return false end
	if c:IsType(TYPE_FUSION) and c:CheckFusionMaterial(fmg,nil,tp) and Duel.GetLocationCountFromEx(tp,tp,nil,c)>0 then return true end
	if c:IsType(TYPE_SYNCHRO) and c:IsSynchroSummonable(nil,mg) then return true end
	if c:IsType(TYPE_XYZ) and c:IsXyzSummonable(nil,mg) then return true end
	if c:IsType(TYPE_LINK) and c:IsLinkSummonable(nil,mg) then return true end
	return false
end
function s.extg(e,tp,eg,ep,ev,re,r,rp,chk)
	local mg=Duel.GetMatchingGroup(Card.IsFaceup,tp,LOCATION_MZONE,0,nil)
	local fmg=Duel.GetMatchingGroup(aux.TRUE,tp,LOCATION_MZONE,0,nil)
	if chk==0 then return Duel.IsExistingMatchingCard(s.exfilter,tp,LOCATION_EXTRA,0,1,nil,mg,fmg,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end
function s.exop(e,tp,eg,ep,ev,re,r,rp)
	local mg=Duel.GetMatchingGroup(Card.IsFaceup,tp,LOCATION_MZONE,0,nil)
	local fmg=Duel.GetMatchingGroup(aux.TRUE,tp,LOCATION_MZONE,0,nil)
	local g=Duel.GetMatchingGroup(s.exfilter,tp,LOCATION_EXTRA,0,nil,mg,fmg,tp)
	if #g==0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local sc=g:Select(tp,1,1,nil):GetFirst()
	if not sc then return end
	if sc:IsType(TYPE_FUSION) and sc:CheckFusionMaterial(fmg,nil,tp) and Duel.GetLocationCountFromEx(tp,tp,nil,sc)>0
		and (not sc:IsType(TYPE_SYNCHRO) or not sc:IsSynchroSummonable(nil,mg))
		and (not sc:IsType(TYPE_XYZ) or not sc:IsXyzSummonable(nil,mg))
		and (not sc:IsType(TYPE_LINK) or not sc:IsLinkSummonable(nil,mg)) then
		local mat=Duel.SelectFusionMaterial(tp,sc,fmg,nil,tp)
		sc:SetMaterial(mat)
		Duel.SendtoGrave(mat,REASON_EFFECT+REASON_MATERIAL+REASON_FUSION)
		Duel.BreakEffect()
		Duel.SpecialSummon(sc,SUMMON_TYPE_FUSION,tp,tp,false,false,POS_FACEUP)
		sc:CompleteProcedure()
	elseif sc:IsType(TYPE_SYNCHRO) and sc:IsSynchroSummonable(nil,mg) then
		Duel.SynchroSummon(tp,sc,nil,mg)
	elseif sc:IsType(TYPE_XYZ) and sc:IsXyzSummonable(nil,mg) then
		Duel.XyzSummon(tp,sc,nil,mg)
	elseif sc:IsType(TYPE_LINK) and sc:IsLinkSummonable(nil,mg) then
		Duel.LinkSummon(tp,sc,nil,mg)
	elseif sc:IsType(TYPE_FUSION) then
		local mat=Duel.SelectFusionMaterial(tp,sc,fmg,nil,tp)
		sc:SetMaterial(mat)
		Duel.SendtoGrave(mat,REASON_EFFECT+REASON_MATERIAL+REASON_FUSION)
		Duel.BreakEffect()
		Duel.SpecialSummon(sc,SUMMON_TYPE_FUSION,tp,tp,false,false,POS_FACEUP)
		sc:CompleteProcedure()
	end
end

function s.spfilter2(c,e,tp)
	return c:IsSetCard(0x64) and c:IsType(TYPE_MONSTER) and not c:IsCode(id)
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sptg2(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.spfilter2,tp,LOCATION_DECK,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK)
end
function s.spop2(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spfilter2,tp,LOCATION_DECK,0,1,1,nil,e,tp)
	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
	end
end
