-- The Scarlet Claw of Hermos
local s,id=GetID()
function s.initial_effect(c)
	-- Fusion Summon 1 Fusion Monster from Extra Deck that mentions targeted "Red-Eyes Black Dragon"
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TODECK+CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetHintTiming(0,TIMING_STANDBY_PHASE|TIMING_MAIN_END|TIMINGS_CHECK_MONSTER_E)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)
end

s.listed_names={74677422, 46232525} -- Red-Eyes Black Dragon (74677422), The Claw of Hermos (46232525)

function s.tdfilter(c,e,tp)
	return c:IsCode(74677422) and c:IsCanBeFusionMaterial() and c:IsAbleToDeck()
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp,c)
end

function s.spfilter(c,e,tp,mc)
	if Duel.GetLocationCountFromEx(tp,tp,mc,c)<=0 then return false end
	local mustg=aux.GetMustBeMaterialGroup(tp,nil,tp,c,nil,REASON_FUSION)
	-- Kiểm tra quái Fusion trong Extra Deck liệt kê Red-Eyes Black Dragon HOẶC The Claw of Hermos
	return c:IsType(TYPE_FUSION) 
		and (c:ListsCodeAsMaterial(mc:GetCode()) or c:ListsCode(mc:GetCode()) or c:ListsCode(46232525)) 
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_FUSION,tp,true,false)
		and (#mustg==0 or (#mustg==1 and mustg:IsContains(mc)))
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE|LOCATION_GRAVE) and chkc:IsControler(tp) and s.tdfilter(chkc,e,tp) end
	if chk==0 then return Duel.IsExistingTarget(s.tdfilter,tp,LOCATION_MZONE|LOCATION_GRAVE,0,1,nil,e,tp) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FMATERIAL)
	local g=Duel.SelectTarget(tp,s.tdfilter,tp,LOCATION_MZONE|LOCATION_GRAVE,0,1,1,nil,e,tp)
	Duel.SetOperationInfo(0,CATEGORY_TODECK,g,1,tp,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) and tc:IsCanBeFusionMaterial() and not tc:IsImmuneToEffect(e) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local sc=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp,tc):GetFirst()
		if sc then
			if tc:IsFacedown() then Duel.ConfirmCards(1-tp,tc) end
			sc:SetMaterial(Group.FromCards(tc))
			Duel.SendtoDeck(tc,nil,SEQ_DECKSHUFFLE,REASON_EFFECT|REASON_MATERIAL|REASON_FUSION)
			Duel.BreakEffect()
			if Duel.SpecialSummon(sc,SUMMON_TYPE_FUSION,tp,tp,true,false,POS_FACEUP)>0 then
				sc:CompleteProcedure()
				-- Banish ở End Phase của lượt kế tiếp
				local turn_summoned=Duel.GetTurnCount()
				aux.DelayedOperation(sc,PHASE_END,id,e,tp,
					function(sc) Duel.Remove(sc,POS_FACEUP,REASON_EFFECT) end,
					function() return Duel.GetTurnCount()==turn_summoned+1 end,
					nil,2,aux.Stringid(id,1)
				)
			end
		end
	end
end
