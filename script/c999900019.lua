-- Homura Akemi the Magica Student
-- ID: 999900019
local s,id=GetID()

local SET_MAGICA		  = 0x654
local SET_SOULGEM		 = 0xc7d
local CARD_HOMURA_MAHOU   = 999900020

s.listed_series={SET_MAGICA, SET_SOULGEM}
s.listed_names={CARD_HOMURA_MAHOU}

function s.initial_effect(c)
	-- 1. Quick Effect (Main Phase): Reveal lá này, gửi 1 Soulgem từ Deck -> SS lá này + Search & Kích hoạt Phép/Bẫy
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_HAND)
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E+TIMING_MAIN_END)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.spcon)
	e1:SetCost(s.spcost)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	-- 2. Quick Effect: Gửi lá này + 1 Soulgem xuống GY -> Ritual SS "Homura the Magica Mahou Shoujo"
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_MZONE)
	e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E)
	e2:SetCost(s.ritcost)
	e2:SetTarget(s.rittg)
	e2:SetOperation(s.ritop)
	c:RegisterEffect(e2)
end

--------------------------------------------------------------------------------
-- EFFECT 1 LOGIC (SPECIAL SUMMON & SEARCH/ACTIVATE S/T)
--------------------------------------------------------------------------------
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	local ph=Duel.GetCurrentPhase()
	return (ph==PHASE_MAIN1 or ph==PHASE_MAIN2) and Duel.GetTurnPlayer()==tp
end

function s.sgfilter(c)
	return c:IsSetCard(SET_SOULGEM) and c:IsAbleToGraveAsCost()
end

function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then 
		return not c:IsPublic() 
			and Duel.IsExistingMatchingCard(s.sgfilter,tp,LOCATION_DECK,0,1,nil) 
	end
	Duel.ConfirmCards(1-tp,c)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g=Duel.SelectMatchingCard(tp,s.sgfilter,tp,LOCATION_DECK,0,1,1,nil)
	Duel.SendtoGrave(g,REASON_COST)
end

function s.stfilter(c)
	return c:IsSetCard(SET_MAGICA) 
		and (c:IsType(TYPE_CONTINUOUS) or c:IsType(TYPE_FIELD))
		and (c:IsType(TYPE_SPELL) or c:IsType(TYPE_TRAP))
		and c:IsAbleToHand()
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then 
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and c:IsCanBeSpecialSummoned(e,0,tp,false,false) 
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) and Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)>0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.stfilter),tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil)
		local tc=g:GetFirst()
		if tc and Duel.SendtoHand(tc,nil,REASON_EFFECT)>0 and tc:IsLocation(LOCATION_HAND) then
			Duel.ConfirmCards(1-tp,tc)
			
			-- Kích hoạt S/T vừa search trực tiếp lên sân
			local te=tc:GetActivateEffect()
			if te and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
				Duel.BreakEffect()
				local zone=tc:IsType(TYPE_FIELD) and LOCATION_FZONE or LOCATION_SZONE
				if tc:IsType(TYPE_FIELD) or Duel.GetLocationCount(tp,LOCATION_SZONE)>0 then
					Duel.MoveToField(tc,tp,tp,zone,POS_FACEUP,true)
					local cost=te:GetCost()
					local tg=te:GetTarget()
					local op=te:GetOperation()
					e:SetProperty(te:GetProperty())
					tc:CreateEffectRelation(te)
					if cost then cost(te,tp,eg,ep,ev,re,r,rp,1) end
					if tg then tg(te,tp,eg,ep,ev,re,r,rp,1) end
					if op then op(te,tp,eg,ep,ev,re,r,rp) end
					tc:ReleaseEffectRelation(te)
				end
			end
		end
	end
end

--------------------------------------------------------------------------------
-- EFFECT 2 LOGIC (RITUAL SUMMON HOMURA MAHOU SHOUJO)
--------------------------------------------------------------------------------
function s.costfilter(c)
	return c:IsSetCard(SET_SOULGEM) and c:IsAbleToGraveAsCost()
end

function s.ritcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then 
		return c:IsFaceup() and c:IsAbleToGraveAsCost()
			and Duel.IsExistingMatchingCard(s.costfilter,tp,LOCATION_HAND+LOCATION_ONFIELD,0,1,c) 
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g=Duel.SelectMatchingCard(tp,s.costfilter,tp,LOCATION_HAND+LOCATION_ONFIELD,0,1,1,c)
	g:AddCard(c)
	Duel.SendtoGrave(g,REASON_COST)
end

function s.rithomurafilter(c,e,tp)
	return c:IsCode(CARD_HOMURA_MAHOU)
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_RITUAL,tp,true,false)
end

function s.rittg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetMZoneCount(tp,e:GetHandler())>0
			and Duel.IsExistingMatchingCard(s.rithomurafilter,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_REMOVED,0,1,nil,e,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_REMOVED)
end

function s.ritop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.rithomurafilter,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_REMOVED,0,1,1,nil,e,tp)
	local tc=g:GetFirst()
	if tc and Duel.SpecialSummon(tc,SUMMON_TYPE_RITUAL,tp,tp,true,false,POS_FACEUP)>0 then
		tc:CompleteProcedure()
	end
end