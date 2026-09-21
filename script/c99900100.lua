-- Divine Circuit: Zhang Jue
-- ID: 99900100
-- Archetype: Mecha Three Kingdom (SetCode 0xb4c)
local s,id=GetID()

function s.initial_effect(c)
	------------------------------------------------------------
	-- (1) Inherent Special Summon from hand if you control no monsters
	------------------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetRange(LOCATION_HAND)
	e1:SetCondition(s.spcon_hand_empty)
	c:RegisterEffect(e1)

	------------------------------------------------------------
	-- (2) Once per turn: Pay 800 LP; add 1 "Mecha Three Kingdom" monster
	------------------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,id) 
	e2:SetCost(s.thcost)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)

	------------------------------------------------------------
	-- (3) If leaves field by opponent: SS Level 4 or lower from Deck/GY
	------------------------------------------------------------
	local e3=Effect.CreateEffect(c)
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_LEAVE_FIELD)
	e3:SetCondition(s.sscon_leave_opp)
	e3:SetTarget(s.sstg_leave_opp)
	e3:SetOperation(s.ssop_leave_opp)
	c:RegisterEffect(e3)

	------------------------------------------------------------
	-- (4) Hand Trigger (Quick Effect)
	-- "During Main Phase, if opp activates monster effect from hand: Discard this & 1 Spell -> SS Tuner"
	------------------------------------------------------------
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,2))
	e4:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e4:SetType(EFFECT_TYPE_QUICK_O)
	e4:SetCode(EVENT_CHAINING)
	e4:SetRange(LOCATION_HAND)
	e4:SetCountLimit(1,id)
	e4:SetCondition(s.spcon_response)
	e4:SetCost(s.spcost_response)
	e4:SetTarget(s.sptg_response)
	e4:SetOperation(s.spop_response)
	c:RegisterEffect(e4)
end

----------------------------------------------------------------
-- Logic Effect 1, 2, 3
----------------------------------------------------------------
-- (1)
function s.spcon_hand_empty(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	return Duel.GetFieldGroupCount(tp,LOCATION_MZONE,0)==0
		and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
end

-- (2)
function s.thcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckLPCost(tp,800) end
	Duel.PayLPCost(tp,800)
end
function s.thfilter(c)
	return c:IsType(TYPE_MONSTER) and c:IsSetCard(0xb4c)
		and not c:IsCode(id) and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	local tc=g:GetFirst()
	if tc then
		Duel.SendtoHand(tc,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,tc)
	end
end

-- (3)
function s.ssfilter_lv4(c,e,tp)
	return c:IsSetCard(0xb4c) and c:IsType(TYPE_MONSTER) and c:IsLevelBelow(4)
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sscon_leave_opp(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsPreviousLocation(LOCATION_MZONE) and c:GetPreviousControler()==tp
		and (r&REASON_EFFECT)~=0 and rp==1-tp
end
function s.sstg_leave_opp(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.IsExistingMatchingCard(s.ssfilter_lv4,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil,e,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
end
function s.ssop_leave_opp(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.ssfilter_lv4,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil,e,tp)
	local tc=g:GetFirst()
	if tc then
		Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)
	end
end

----------------------------------------------------------------
-- EFFECT (4): Discard Self + Spell -> SS Tuner
----------------------------------------------------------------

-- Condition: Main Phase + Opponent activates Monster Effect from HAND
function s.spcon_response(e,tp,eg,ep,ev,re,r,rp)
	local ph=Duel.GetCurrentPhase()
	local loc=Duel.GetChainInfo(ev,CHAININFO_TRIGGERING_LOCATION) -- Đã sửa lỗi ở đây
	return (ph==PHASE_MAIN1 or ph==PHASE_MAIN2)
		and rp==1-tp
		and re:IsActiveType(TYPE_MONSTER)
		and loc==LOCATION_HAND
end

-- Cost: Discard this card + 1 Spell
function s.cost_spell_filter(c)
	return c:IsType(TYPE_SPELL) and c:IsDiscardable()
end
function s.spcost_response(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsDiscardable() 
		and Duel.IsExistingMatchingCard(s.cost_spell_filter,tp,LOCATION_HAND,0,1,c) end
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DISCARD)
	local g=Duel.SelectMatchingCard(tp,s.cost_spell_filter,tp,LOCATION_HAND,0,1,1,c)
	g:AddCard(c)
	Duel.SendtoGrave(g,REASON_COST+REASON_DISCARD)
end

-- Target: SS Level 4 Tuner Mecha Three Kingdom from Deck
function s.tuner_filter(c,e,tp)
	return c:IsSetCard(0xb4c) and c:IsLevel(4) and c:IsType(TYPE_TUNER)
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.sptg_response(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.tuner_filter,tp,LOCATION_DECK,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK)
end

function s.spop_response(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.tuner_filter,tp,LOCATION_DECK,0,1,1,nil,e,tp)
	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
	end
end