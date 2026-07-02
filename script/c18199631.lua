-- Yanfei, Genshin the Premier Legal Adviser of Liyue
local s,id=GetID()
function s.initial_effect(c)
	-- Fusion/Synchro/Link Summon
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_HAND)
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_MAIN_END)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.spcon)
	e1:SetCost(s.spcost)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)
end
s.listed_series={0x369}

function s.oppfil(c)
	return c:IsFaceup() and c:GetAttack()>=2000
end
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetFieldGroupCount(tp,LOCATION_MZONE,0)==0
		and Duel.IsExistingMatchingCard(s.oppfil,tp,0,LOCATION_MZONE,1,nil)
		and Duel.IsMainPhase()
end
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return not e:GetHandler():IsPublic() end
	Duel.ConfirmCards(1-tp,e:GetHandler())
end

-- Filter Functions
function s.fusfilter(c,mg,hc,tp)
	return c:IsSetCard(0x369) and c:IsType(TYPE_FUSION) and c:CheckFusionMaterial(mg,hc,tp)
end
function s.synfilter(c,hc,mg)
	return c:IsSetCard(0x369) and c:IsType(TYPE_SYNCHRO) and c:IsSynchroSummonable(hc,mg)
end
function s.lnkfilter(c,hc,mg)
	return c:IsSetCard(0x369) and c:IsType(TYPE_LINK) and c:IsLinkSummonable(hc,mg)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		local c=e:GetHandler()
		local mg=Duel.GetFieldGroup(tp,LOCATION_HAND,0)
		local fmg=Duel.GetMatchingGroup(Card.IsCanBeFusionMaterial,tp,LOCATION_HAND,0,nil)
		
		local res1=Duel.IsExistingMatchingCard(s.fusfilter,tp,LOCATION_EXTRA,0,1,nil,fmg,c,tp)
		local res2=Duel.IsExistingMatchingCard(s.synfilter,tp,LOCATION_EXTRA,0,1,nil,c,mg)
		local res3=Duel.IsExistingMatchingCard(s.lnkfilter,tp,LOCATION_EXTRA,0,1,nil,c,mg)
		
		return res1 or res2 or res3
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	
	local mg=Duel.GetFieldGroup(tp,LOCATION_HAND,0)
	local fmg=Duel.GetMatchingGroup(Card.IsCanBeFusionMaterial,tp,LOCATION_HAND,0,nil)
	
	local b1=Duel.IsExistingMatchingCard(s.fusfilter,tp,LOCATION_EXTRA,0,1,nil,fmg,c,tp)
	local b2=Duel.IsExistingMatchingCard(s.synfilter,tp,LOCATION_EXTRA,0,1,nil,c,mg)
	local b3=Duel.IsExistingMatchingCard(s.lnkfilter,tp,LOCATION_EXTRA,0,1,nil,c,mg)
	
	if not (b1 or b2 or b3) then return end
	local ops={}
	local opval={}
	if b1 then table.insert(ops,aux.Stringid(id,1)) table.insert(opval,1) end
	if b2 then table.insert(ops,aux.Stringid(id,2)) table.insert(opval,2) end
	if b3 then table.insert(ops,aux.Stringid(id,3)) table.insert(opval,3) end
	
	local sel=Duel.SelectOption(tp,table.unpack(ops))+1
	local op=opval[sel]
	
	if op==1 then
		-- Fusion Summon: Happens explicitly inside the resolution
		local sg=Duel.SelectMatchingCard(tp,s.fusfilter,tp,LOCATION_EXTRA,0,1,1,nil,fmg,c,tp)
		if #sg>0 then
			local tc=sg:GetFirst()
			local mat=Duel.SelectFusionMaterial(tp,tc,fmg,c,tp)
			tc:SetMaterial(mat)
			Duel.SendtoGrave(mat,REASON_EFFECT+REASON_MATERIAL+REASON_FUSION)
			Duel.BreakEffect()
			Duel.SpecialSummon(tc,SUMMON_TYPE_FUSION,tp,tp,false,false,POS_FACEUP)
			tc:CompleteProcedure()
		end
	elseif op==2 then
		-- Synchro Summon: Core engine handles the "immediately after this effect resolves" timing
		local sg=Duel.SelectMatchingCard(tp,s.synfilter,tp,LOCATION_EXTRA,0,1,1,nil,c,mg)
		if #sg>0 then
			Duel.SynchroSummon(tp,sg:GetFirst(),c,mg)
		end
	elseif op==3 then
		-- Link Summon: Core engine handles the "immediately after this effect resolves" timing
		local sg=Duel.SelectMatchingCard(tp,s.lnkfilter,tp,LOCATION_EXTRA,0,1,1,nil,c,mg)
		if #sg>0 then
			Duel.LinkSummon(tp,sg:GetFirst(),c,mg)
		end
	end
end