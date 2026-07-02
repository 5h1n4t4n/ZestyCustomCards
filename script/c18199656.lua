-- Tighnari, Genshin Chief of Forest Rangers
local s,id=GetID()
function s.initial_effect(c)
	-- Additional Normal Summon
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_EXTRA_SUMMON_COUNT)
	e1:SetRange(LOCATION_MZONE)
	e1:SetTargetRange(LOCATION_HAND+LOCATION_MZONE,0)
	e1:SetTarget(s.extg)
	e1:SetDescription(aux.Stringid(id,0))
	c:RegisterEffect(e1)
	-- Quick Effect Fusion/Synchro/Link from GY
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TODECK)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_MAIN_END)
	e2:SetCountLimit(1,id)
	e2:SetCondition(s.spcon)
	e2:SetCost(s.spcost)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)
end
s.listed_series={0x369}
function s.extg(e,c)
	return c:IsSetCard(0x369)
end
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsMainPhase()
end
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckLPCost(tp,2000) end
	Duel.PayLPCost(tp,2000)
end
function s.mfilter(c)
	return c:IsSetCard(0x369) and c:IsMonster() and c:IsAbleToDeck()
		and (c:IsFaceup() or not c:IsLocation(LOCATION_REMOVED))
end
function s.syngoal(sg,sc,gc)
	if not sg:IsContains(gc) then return false end
	if sg:GetSum(Card.GetLevel)~=sc:GetLevel() then return false end
	local has_tuner=sg:IsExists(Card.IsType,1,nil,TYPE_TUNER)
	local has_nontuner=sg:IsExists(aux.NOT(Card.IsType),1,nil,TYPE_TUNER)
	return has_tuner and has_nontuner
end
function s.synrescon(sc,gc)
	return function(sg,e,tp,mg)
		if sg:GetSum(Card.GetLevel)>sc:GetLevel() then return false end
		if sg:GetSum(Card.GetLevel)==sc:GetLevel() then
			return s.syngoal(sg,sc,gc)
		end
		return true
	end
end
function s.synfinishcon(sc,gc)
	return function(sg,e,tp,mg)
		return s.syngoal(sg,sc,gc)
	end
end
function s.link_sum_match(g,target)
	if #g==0 then return target==0 end
	local tc=g:GetFirst()
	local g2=g:Clone()
	g2:RemoveCard(tc)
	if s.link_sum_match(g2,target-1) then
		g2:DeleteGroup()
		return true
	end
	if tc:IsType(TYPE_LINK) and tc:GetLink()>1 then
		if s.link_sum_match(g2,target-tc:GetLink()) then
			g2:DeleteGroup()
			return true
		end
	end
	g2:DeleteGroup()
	return false
end
function s.linkgoal(sg,sc,gc)
	if not sg:IsContains(gc) then return false end
	if #sg<2 or #sg>sc:GetLink() then return false end
	return s.link_sum_match(sg,sc:GetLink())
end
function s.linkrescon(sc,gc)
	return function(sg,e,tp,mg)
		return #sg<=sc:GetLink()
	end
end
function s.linkfinishcon(sc,gc)
	return function(sg,e,tp,mg)
		return s.linkgoal(sg,sc,gc)
	end
end
function s.subgroup_recurse(cards,idx,sg,minc,maxc,goal_func,sc,gc)
	if #sg>=minc and goal_func(sg,sc,gc) then
		return true
	end
	if #sg>=maxc or idx>#cards then
		return false
	end
	if sc:IsType(TYPE_SYNCHRO) and sg:GetSum(Card.GetLevel)>=sc:GetLevel() then
		return false
	end
	for i=idx,#cards do
		sg:AddCard(cards[i])
		if s.subgroup_recurse(cards,i+1,sg,minc,maxc,goal_func,sc,gc) then
			return true
		end
		sg:RemoveCard(cards[i])
	end
	return false
end
function s.check_subgroup(mg,minc,maxc,goal_func,sc,gc)
	local cards={}
	local tc=mg:GetFirst()
	while tc do
		table.insert(cards,tc)
		tc=mg:GetNext()
	end
	local sg=Group.CreateGroup()
	sg:KeepAlive()
	local res=s.subgroup_recurse(cards,1,sg,minc,maxc,goal_func,sc,gc)
	sg:DeleteGroup()
	return res
end
function s.exfilter(c,e,tp,mg)
	if not (c:IsSetCard(0x369) and (c:IsType(TYPE_FUSION) or c:IsType(TYPE_SYNCHRO) or c:IsType(TYPE_LINK))
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)) then return false end
	local gc=e:GetHandler()
	if c:IsType(TYPE_FUSION) then
		return c:CheckFusionMaterial(mg,gc,tp)
	elseif c:IsType(TYPE_SYNCHRO) then
		return s.check_subgroup(mg,2,6,s.syngoal,c,gc)
	elseif c:IsType(TYPE_LINK) then
		return s.check_subgroup(mg,2,c:GetLink(),s.linkgoal,c,gc)
	end
	return false
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		local mg=Duel.GetMatchingGroup(s.mfilter,tp,LOCATION_HAND+LOCATION_MZONE+LOCATION_GRAVE+LOCATION_REMOVED,0,nil)
		return mg:IsContains(e:GetHandler()) and Duel.IsExistingMatchingCard(s.exfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp,mg)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local mg=Duel.GetMatchingGroup(s.mfilter,tp,LOCATION_HAND+LOCATION_MZONE+LOCATION_GRAVE+LOCATION_REMOVED,0,nil)
	if not mg:IsContains(c) then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local sc=Duel.SelectMatchingCard(tp,s.exfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp,mg):GetFirst()
	if sc then
		local mat=nil
		if sc:IsType(TYPE_FUSION) then
			mat=Duel.SelectFusionMaterial(tp,sc,mg,c,tp)
		elseif sc:IsType(TYPE_SYNCHRO) then
			mat=aux.SelectUnselectGroup(mg,e,tp,2,6,s.synrescon(sc,c),1,tp,HINTMSG_TODECK,s.synfinishcon(sc,c))
		elseif sc:IsType(TYPE_LINK) then
			mat=aux.SelectUnselectGroup(mg,e,tp,2,sc:GetLink(),s.linkrescon(sc,c),1,tp,HINTMSG_TODECK,s.linkfinishcon(sc,c))
		end
		if mat and #mat>0 then
			Duel.SendtoDeck(mat,nil,SEQ_DECKBOTTOM,REASON_EFFECT+REASON_MATERIAL)
			Duel.BreakEffect()
			if sc:IsType(TYPE_FUSION) then
				Duel.SpecialSummon(sc,SUMMON_TYPE_FUSION,tp,tp,false,false,POS_FACEUP)
			elseif sc:IsType(TYPE_SYNCHRO) then
				Duel.SpecialSummon(sc,SUMMON_TYPE_SYNCHRO,tp,tp,false,false,POS_FACEUP)
			else
				Duel.SpecialSummon(sc,SUMMON_TYPE_LINK,tp,tp,false,false,POS_FACEUP)
			end
			sc:CompleteProcedure()
		end
	end
end
