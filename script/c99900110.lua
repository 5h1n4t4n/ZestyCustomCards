-- Oath of Steel
local s,id=GetID()
s.listed_series={0xb4c}
s.listed_names={99900105, 99900112} -- Gia Cát Lượng và Chu Du

function s.initial_effect(c)
	-- (1) Kích hoạt: Gọi quái Level 4 từ DECK + Khóa Summon cả trận
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetTarget(s.acttg)
	e1:SetOperation(s.actop)
	c:RegisterEffect(e1)
	
	-- (2) Kháng Target khi kiểm soát từ 3 quái Mecha trở lên
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e2:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE)
	e2:SetRange(LOCATION_SZONE)
	e2:SetTargetRange(LOCATION_MZONE,0)
	e2:SetCondition(s.tgcon)
	e2:SetTarget(s.tgtg)
	e2:SetValue(aux.tgoval)
	c:RegisterEffect(e2)
	
	-- (3) Hiệu ứng kích hoạt mỗi lượt: Gọi từ Mộ / Deck (Không cho đối thủ Chain nếu có Quân Sư)
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_SZONE)
	e3:SetCountLimit(1)
	e3:SetTarget(s.sptg)
	e3:SetOperation(s.spop)
	c:RegisterEffect(e3)
end

-- ==================== LOGIC HIỆU ỨNG 1: ACTIVATE ====================
function s.actfilter(c,e,tp)
	return c:IsSetCard(0xb4c) and c:IsLevel(4) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.acttg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end 
	-- Thay thế SetPossibleOperationInfo bằng SetOperationInfo chuẩn core cũ
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,0,tp,LOCATION_DECK)
end
function s.actop(e,tp,eg,ep,ev,re,r,rp)
	-- Khóa Summon quái khác ngoài Mecha cho đến hết trận đấu (Rest of this duel)
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT)
	e1:SetDescription(aux.Stringid(id,1)) 
	e1:SetTargetRange(1,0)
	e1:SetTarget(s.splimit)
	Duel.RegisterEffect(e1,tp)
	
	-- Thực hiện gọi quái từ Deck
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	local g=Duel.GetMatchingGroup(s.actfilter,tp,LOCATION_DECK,0,nil,e,tp)
	if #g>0 and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local sg=g:Select(tp,1,1,nil)
		Duel.SpecialSummon(sg,0,tp,tp,false,false,POS_FACEUP)
	end
end
function s.splimit(e,c,sump,sumtype,sumpos,targetp,se)
	return not c:IsSetCard(0xb4c)
end

-- ==================== LOGIC HIỆU ỨNG 2: TARGET PROTECTION ====================
function s.cfilter(c)
	return c:IsFaceup() and c:IsSetCard(0xb4c)
end
function s.tgcon(e)
	return Duel.GetMatchingGroupCount(s.cfilter,e:GetHandlerPlayer(),LOCATION_MZONE,0,nil)>=3
end
function s.tgtg(e,c)
	return c:IsSetCard(0xb4c)
end

-- ==================== LOGIC HIỆU ỨNG 3: TURN EFFECT ====================
function s.spfilter1(c,e,tp)
	return c:IsSetCard(0xb4c) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.tactician_filter(c)
	return c:IsFaceup() and (c:IsCode(99900105) or c:IsCode(99900112))
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local has_tactician = Duel.IsExistingMatchingCard(s.tactician_filter,tp,LOCATION_MZONE,0,1,nil)
	if chk==0 then
		local b1 = Duel.GetLocationCount(tp,LOCATION_MZONE)>0 
			and Duel.IsExistingMatchingCard(s.spfilter1,tp,LOCATION_GRAVE,0,1,nil,e,tp)
		local b2 = has_tactician and Duel.GetLocationCount(tp,LOCATION_MZONE)>0 
			and Duel.IsExistingMatchingCard(s.spfilter1,tp,LOCATION_DECK,0,1,nil,e,tp)
		return b1 or b2
	end
	
	-- Khóa Chain nếu có Gia Cát Lượng hoặc Chu Du
	if has_tactician then
		Duel.SetChainLimit(s.chlimit)
	end
	
	-- Thay thế SetPossibleOperationInfo bằng SetOperationInfo chuẩn core cũ
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE+LOCATION_DECK)
end
function s.chlimit(e,ep,tp)
	return tp==ep
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	local has_tactician = Duel.IsExistingMatchingCard(s.tactician_filter,tp,LOCATION_MZONE,0,1,nil)
	
	local b1 = Duel.IsExistingMatchingCard(s.spfilter1,tp,LOCATION_GRAVE,0,1,nil,e,tp)
	local b2 = has_tactician and Duel.IsExistingMatchingCard(s.spfilter1,tp,LOCATION_DECK,0,1,nil,e,tp)
	
	if not b1 and not b2 then return end
	
	local op=0
	if b1 and b2 then
		op=Duel.SelectOption(tp,aux.Stringid(id,3),aux.Stringid(id,4)) 
	elseif b1 then
		op=0
	else
		op=1
	end
	
	local g=nil
	if op==0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		g=Duel.SelectMatchingCard(tp,s.spfilter1,tp,LOCATION_GRAVE,0,1,1,nil,e,tp)
	else
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		g=Duel.SelectMatchingCard(tp,s.spfilter1,tp,LOCATION_DECK,0,1,1,nil,e,tp)
	end
	
	if g and #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
	end
end