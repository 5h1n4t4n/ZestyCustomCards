-- ============================================================
-- Card Name: Cyberdark Assembling
-- Passcode : 16530005
-- Type     : Spell / Quick-Play
-- Archetype: Cyberdark (0x4093)
-- ============================================================
-- Effect 1: Special Summon 1 "Cyberdark" monster from Deck, then if
--           opponent controls more cards, destroy opponent's cards
--           up to the number of "Cyberdark" cards you control.
-- Effect 2: Banish from GY: Fusion Summon 1 "Cyberdark" Fusion Monster
--           from Extra Deck by shuffling materials from hand/field/GY/banish.
-- You can only use each effect of "Cyberdark Assembling" once per turn.
-- ============================================================

local s,id=GetID()

function s.initial_effect(c)
	-- Special Summon 1 "Cyberdark" monster from Deck then optional destroy
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,{id,1})
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)

	-- Fusion Summon 1 "Cyberdark" Fusion Monster by shuffling materials into Deck
	local params = {
		fusfilter = aux.FilterBoolFunction(Card.IsSetCard, SET_CYBERDARK),
		matfilter = Card.IsAbleToDeck,
		extrafil = s.fextra,
		extraop = Fusion.ShuffleMaterial,
		extratg = s.extratg
	}
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON+CATEGORY_TODECK)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,{id,2})
	e2:SetCost(aux.bfgcost)
	e2:SetTarget(Fusion.SummonEffTG(params))
	e2:SetOperation(Fusion.SummonEffOP(params))
	c:RegisterEffect(e2)
end

s.listed_series={SET_CYBERDARK}

function s.spfilter(c,e,tp)
	return c:IsSetCard(SET_CYBERDARK) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_DECK,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK)
	Duel.SetPossibleOperationInfo(0,CATEGORY_DESTROY,nil,1,1-tp,LOCATION_ONFIELD)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_DECK,0,1,1,nil,e,tp)
	if #g>0 and Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)>0 then
		local opp_count=Duel.GetFieldGroupCount(tp,0,LOCATION_ONFIELD)
		local my_count=Duel.GetFieldGroupCount(tp,LOCATION_ONFIELD,0)
		if opp_count>my_count then
			local cyb_count=Duel.GetMatchingGroupCount(aux.FaceupFilter(Card.IsSetCard,SET_CYBERDARK),
				tp,LOCATION_ONFIELD,0,nil)
			local dg=Duel.GetMatchingGroup(nil,tp,0,LOCATION_ONFIELD,nil)
			if cyb_count>0 and #dg>0 and Duel.SelectYesNo(tp,aux.Stringid(id,0)) then
				Duel.BreakEffect()
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
				local sg=dg:Select(tp,1,cyb_count,nil)
				Duel.HintSelection(sg)
				Duel.Destroy(sg,REASON_EFFECT)
			end
		end
	end
end

function s.fextra(e,tp,mg)
	return Duel.GetMatchingGroup(Fusion.IsMonsterFilter(aux.NecroValleyFilter(Card.IsFaceup,Card.IsAbleToDeck)),
		tp,LOCATION_GRAVE|LOCATION_REMOVED,0,nil)
end

function s.extratg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_TODECK,nil,0,tp,LOCATION_HAND|LOCATION_MZONE|LOCATION_GRAVE|LOCATION_REMOVED)
end
