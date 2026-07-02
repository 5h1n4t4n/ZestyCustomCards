-- Chongyun - Genshin Ardor Exorcist
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	-- Multi-Attribute
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetCode(EFFECT_ADD_ATTRIBUTE)
	e1:SetRange(LOCATION_ONFIELD)
	e1:SetValue(ATTRIBUTE_DARK|ATTRIBUTE_LIGHT|ATTRIBUTE_EARTH|ATTRIBUTE_FIRE|ATTRIBUTE_WIND)
	c:RegisterEffect(e1)
	-- Discard to add S/T
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_HAND)
	e2:SetCountLimit(1,{id,1})
	e2:SetCost(s.thcost)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
	-- Quick Summon Extra Deck Monster
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetRange(LOCATION_MZONE)
	e3:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_MAIN_END)
	e3:SetCountLimit(1,{id,2})
	e3:SetCost(s.sscost)
	e3:SetTarget(s.sstg)
	e3:SetOperation(s.ssop)
	c:RegisterEffect(e3)
end
s.listed_series={0x369}
function s.thcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsDiscardable() end
	Duel.SendtoGrave(e:GetHandler(),REASON_COST+REASON_DISCARD)
end
function s.thfilter(c)
	return c:IsSetCard(0x369) and c:IsType(TYPE_SPELL+TYPE_TRAP) and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.thfilter),tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end
function s.fusion_filter(c,e,tp,m,chkf)
	return c:IsType(TYPE_FUSION) and c:IsSetCard(0x369)
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_FUSION,tp,false,false) and c:CheckFusionMaterial(m,e:GetHandler(),chkf)
end
function s.fusion_check(e,tp)
	local chkf=tp
	local c=e:GetHandler()
	local m=Duel.GetMatchingGroup(Card.IsOnField,tp,LOCATION_MZONE,0,nil)
	if not m:IsContains(c) then return false end
	return Duel.IsExistingMatchingCard(s.fusion_filter,tp,LOCATION_EXTRA,0,1,nil,e,tp,m,chkf)
end
function s.sync_xyz_link_filter(c,mc)
	if not c:IsSetCard(0x369) then return false end
	return c:IsSynchroSummonable(nil) or c:IsXyzSummonable(mc) or c:IsLinkSummonable(mc)
end
function s.sscost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckLPCost(tp,1500) end
	Duel.PayLPCost(tp,1500)
end
function s.sstg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.sync_xyz_link_filter,tp,LOCATION_EXTRA,0,1,nil,c) or s.fusion_check(e,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end
function s.ssop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) or c:IsControler(1-tp) then return end
	
	local g=Duel.GetMatchingGroup(s.sync_xyz_link_filter,tp,LOCATION_EXTRA,0,nil,c)
	local can_fusion = s.fusion_check(e,tp)
	
	if #g>0 or can_fusion then
		local ops={}
		local opval={}
		if can_fusion then
			table.insert(ops,aux.Stringid(id,2))
			table.insert(opval,1)
		end
		if #g:Filter(Card.IsSynchroSummonable,nil,nil)>0 then
			table.insert(ops,aux.Stringid(id,3))
			table.insert(opval,2)
		end
		if #g:Filter(Card.IsXyzSummonable,nil,c)>0 then
			table.insert(ops,aux.Stringid(id,4))
			table.insert(opval,3)
		end
		if #g:Filter(Card.IsLinkSummonable,nil,c)>0 then
			table.insert(ops,aux.Stringid(id,5))
			table.insert(opval,4)
		end
		
		local op=Duel.SelectOption(tp,table.unpack(ops))+1
		local sel=opval[op]
		
		if sel==1 then
			local chkf=tp
			local m=Duel.GetMatchingGroup(Card.IsOnField,tp,LOCATION_MZONE,0,nil)
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
			local sg=Duel.SelectMatchingCard(tp,s.fusion_filter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp,m,chkf)
			local tc=sg:GetFirst()
			if tc then
				local mat=Duel.SelectFusionMaterial(tp,tc,m,c,chkf)
				tc:SetMaterial(mat)
				Duel.SendtoGrave(mat,REASON_EFFECT+REASON_MATERIAL+REASON_FUSION)
				Duel.BreakEffect()
				Duel.SpecialSummon(tc,SUMMON_TYPE_FUSION,tp,tp,false,false,POS_FACEUP)
				tc:CompleteProcedure()
			end
		elseif sel==2 then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
			local sg=g:FilterSelect(tp,Card.IsSynchroSummonable,1,1,nil,nil)
			if #sg>0 then
				Duel.SynchroSummon(tp,sg:GetFirst(),c)
			end
		elseif sel==3 then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
			local sg=g:FilterSelect(tp,Card.IsXyzSummonable,1,1,nil,c)
			if #sg>0 then
				Duel.XyzSummon(tp,sg:GetFirst(),c)
			end
		elseif sel==4 then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
			local sg=g:FilterSelect(tp,Card.IsLinkSummonable,1,1,nil,c)
			if #sg>0 then
				Duel.LinkSummon(tp,sg:GetFirst(),c)
			end
		end
	end
end
