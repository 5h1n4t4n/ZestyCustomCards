-- Bowang Ambush – Flames of Strategy
-- ID: 99900115
local s,id=GetID()
s.listed_series={0xb4c}

function s.initial_effect(c)
	-- Activate from hand
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	-- Bắt đúng thời điểm Start of Battle Phase
	e1:SetHintTiming(TIMING_BATTLE_START)
	e1:SetCondition(s.condition)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
	
	-- Cho phép kích hoạt từ tay (Nếu là Trap)
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_TRAP_ACT_IN_HAND)
	e2:SetCondition(s.condition)
	c:RegisterEffect(e2)
end

-- Điều kiện: 2+ quái đối phương, 0 card mình, Start of Battle Phase
function s.condition(e,tp,eg,ep,ev,re,r,rp)
	-- Lấy tp trực tiếp từ handler để tránh nil khi check Trap In Hand
	local tp=e:GetHandlerPlayer()
	local opcount=Duel.GetFieldGroupCount(tp,0,LOCATION_MZONE)
	local mycount=Duel.GetFieldGroupCount(tp,LOCATION_ONFIELD,0)
	-- Bắt mốc thời gian Start of Battle Phase
	local ph=Duel.GetCurrentPhase()
	return opcount>=2 and mycount==0 
		and (ph>=PHASE_BATTLE_START and ph<=PHASE_BATTLE)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	local g=Duel.GetMatchingGroup(Card.IsAbleToHand,tp,0,LOCATION_MZONE,nil)
	if chk==0 then return #g>0 end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,g,#g,0,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,0,tp,LOCATION_HAND)
end

function s.spfilter(c,e,tp)
	return c:IsSetCard(0xb4c) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(Card.IsAbleToHand,tp,0,LOCATION_MZONE,nil)
	if #g>0 then
		-- Trả về tay
		local ct=Duel.SendtoHand(g,nil,REASON_EFFECT)
		if ct>0 then
			-- Triệu hồi quái thú từ tay
			if Duel.GetLocationCount(tp,LOCATION_MZONE)>0 
				and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_HAND,0,1,nil,e,tp)
				and Duel.SelectYesNo(tp,aux.Stringid(id,1)) then
				Duel.BreakEffect()
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
				local sc=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_HAND,0,1,1,nil,e,tp):GetFirst()
				if sc then
					Duel.SpecialSummon(sc,0,tp,tp,false,false,POS_FACEUP)
				end
			end
		end
	end
	
	-- Khóa Special Summon ngoài tộc (Restrict)
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT)
	e1:SetDescription(aux.Stringid(id,2))
	e1:SetTargetRange(1,0)
	e1:SetTarget(s.splimit)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
end

function s.splimit(e,c)
	return not c:IsSetCard(0xb4c)
end