-- Mami Tomoe The Magica Student
-- ID: 999900013
local s,id=GetID()

local SET_MAGICA			 = 0x654
local SET_SOULGEM			= 0xc7d
local CARD_MAMI_MAHOU_SHOUJO = 999900014
local TOKEN_GRIEF_SEED	   = 999900006

s.listed_series={SET_MAGICA, SET_SOULGEM}
s.listed_names={CARD_MAMI_MAHOU_SHOUJO, TOKEN_GRIEF_SEED}

function s.initial_effect(c)
	-- 1. Normal / Special Summon -> Search "Soulgem" + Restrict SS (Rest of Duel)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SUMMON_SUCCESS)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)

	local e1b=e1:Clone()
	e1b:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e1b)

	-- 2. Quick Effect: Deal 1500 LP damage per Grief Seed token (Max 2) - Once per Duel
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_DAMAGE)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,id+100,EFFECT_COUNT_CODE_DUEL)
	e2:SetTarget(s.damtg)
	e2:SetOperation(s.damop)
	c:RegisterEffect(e2)

	-- 3. Quick Effect: Discard Soulgem -> Ritual SS Mami Mahou Shoujo -> Return to hand (Unrespondable / Unnegatable)
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOHAND)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetProperty(EFFECT_FLAG_CANNOT_INACTIVATE+EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_CANNOT_NEGATE)
	e3:SetRange(LOCATION_MZONE)
	e3:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E+TIMING_MAIN_END)
	e3:SetCountLimit(1,id+200)
	e3:SetCost(s.spcost)
	e3:SetTarget(s.sptg)
	e3:SetOperation(s.spop)
	c:RegisterEffect(e3)
end

--------------------------------------------------------------------------------
-- EFFECT 1: SEARCH SOULGEM & RESTRICT SS
--------------------------------------------------------------------------------
function s.thfilter(c)
	return c:IsSetCard(SET_SOULGEM) and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end

	-- Khóa Special Summon ngoài "Magica" cho đến hết trận đấu
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT)
	e1:SetDescription(aux.Stringid(id,3))
	e1:SetTargetRange(1,0)
	e1:SetTarget(s.splimit)
	Duel.RegisterEffect(e1,tp)
end

function s.splimit(e,c,sump,sumtype,sumpos,targetp,se)
	return not c:IsSetCard(SET_MAGICA)
end

--------------------------------------------------------------------------------
-- EFFECT 2: DAMAGE PER GRIEF SEED TOKEN (OPD)
--------------------------------------------------------------------------------
function s.tokenfilter(c)
	return c:IsType(TYPE_TOKEN) and c:IsCode(TOKEN_GRIEF_SEED)
end

function s.damtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		local ct=Duel.GetMatchingGroupCount(s.tokenfilter,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,nil)
		return ct>0
	end
	local ct=Duel.GetMatchingGroupCount(s.tokenfilter,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,nil)
	if ct>2 then ct=2 end
	Duel.SetOperationInfo(0,CATEGORY_DAMAGE,nil,0,1-tp,ct*1500)
end

function s.damop(e,tp,eg,ep,ev,re,r,rp)
	local ct=Duel.GetMatchingGroupCount(s.tokenfilter,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,nil)
	if ct>2 then ct=2 end
	if ct>0 then
		Duel.Damage(1-tp,ct*1500,REASON_EFFECT)
	end
end

--------------------------------------------------------------------------------
-- EFFECT 3: RITUAL SPECIAL SUMMON MAMI MAHOU SHOUJO (UNRESPONDABLE)
--------------------------------------------------------------------------------
function s.cfilter(c)
	return c:IsSetCard(SET_SOULGEM) and c:IsDiscardable()
end

function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_HAND,0,1,nil) end
	Duel.DiscardHand(tp,s.cfilter,1,1,REASON_COST+REASON_DISCARD)
end

function s.spfilter(c,e,tp)
	return c:IsCode(CARD_MAMI_MAHOU_SHOUJO)
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_RITUAL,tp,true,true)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		local ft=Duel.GetMZoneCount(tp,c)
		return ft>0 and c:IsAbleToHand()
			and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_REMOVED,0,1,nil,e,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_REMOVED)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,c,1,0,0)

	-- Chống chèn chain phản hồi
	Duel.SetChainLimit(s.chainlm)
end

function s.chainlm(e,rp,tp)
	return false
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_REMOVED,0,1,1,nil,e,tp)
	local tc=g:GetFirst()

	if tc then
		tc:SetMaterial(nil)
		if Duel.SpecialSummon(tc,SUMMON_TYPE_RITUAL,tp,tp,true,true,POS_FACEUP)>0 then
			tc:CompleteProcedure()
			if c:IsRelateToEffect(e) and c:IsAbleToHand() then
				Duel.BreakEffect()
				Duel.SendtoHand(c,nil,REASON_EFFECT)
			end
		end
	end
end