-- TIME REWIND: THE MAGICA EVENT HORIZON
-- ID: 999900021
local s,id=GetID()

local SET_MAGICA = 0x654

s.listed_series={SET_MAGICA}

function s.initial_effect(c)
	-- 1. Kích hoạt từ tay/sân: Reveal 10 lá "Magica" khác tên từ Tay/Deck -> Trả toàn bộ bài trên tay, GY, Banishment của đối thủ về Deck, sau đó đối thủ rút (số lá bị trả từ tay + 6)
	-- Giới hạn: 1 lần mỗi Trận đấu (Once per Duel)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TODECK+CATEGORY_DRAW)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id+EFFECT_COUNT_CODE_DUEL)
	e1:SetCost(s.cost)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)

	-- 2. Quick Effect ở GY: Trục xuất lá này từ GY -> Special Summon 1 quái thú "Magica" từ Deck
	-- Giới hạn: Once per turn
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E)
	e2:SetCountLimit(1,id)
	e2:SetCost(aux.bfgcost)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)
end

--------------------------------------------------------------------------------
-- 1. ACTIVATION EFFECT LOGIC
--------------------------------------------------------------------------------
function s.costfilter(c)
	return c:IsSetCard(SET_MAGICA)
end

function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	local g=Duel.GetMatchingGroup(s.costfilter,tp,LOCATION_HAND+LOCATION_DECK,0,nil)
	-- GetClassCount(Card.GetCode) đếm số lượng lá bài có TÊN KHÁC NHAU trong group g
	if chk==0 then return g:GetClassCount(Card.GetCode)>=10 end
	
	local sg=Group.CreateGroup()
	for i=1,10 do
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONFIRM)
		-- Lọc ra những lá chưa có tên trong nhóm sg đã chọn
		local cg=g:Filter(function(c) return not sg:IsExists(Card.IsCode,1,nil,c:GetCode()) end, nil)
		local tc=cg:Select(tp,1,1,nil):GetFirst()
		sg:AddCard(tc)
	end
	Duel.ConfirmCards(1-tp,sg)
	Duel.ShuffleDeck(tp)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then 
		return Duel.IsExistingMatchingCard(nil,tp,0,LOCATION_HAND+LOCATION_GRAVE+LOCATION_REMOVED,1,nil) 
	end
	local g=Duel.GetMatchingGroup(nil,tp,0,LOCATION_HAND+LOCATION_GRAVE+LOCATION_REMOVED,nil)
	Duel.SetOperationInfo(0,CATEGORY_TODECK,g,#g,0,0)
	Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,1-tp,1)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local hg=Duel.GetFieldGroup(tp,0,LOCATION_HAND)
	local hcount=#hg
	local g=Duel.GetMatchingGroup(nil,tp,0,LOCATION_HAND+LOCATION_GRAVE+LOCATION_REMOVED,nil)
	if #g>0 then
		if Duel.SendtoDeck(g,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)>0 then
			Duel.ShuffleDeck(1-tp)
			local draw_ct=hcount+6
			Duel.BreakEffect()
			Duel.Draw(1-tp,draw_ct,REASON_EFFECT)
		end
	end
end

--------------------------------------------------------------------------------
-- 2. GRAVEYARD QUICK EFFECT LOGIC
--------------------------------------------------------------------------------
function s.spfilter(c,e,tp)
	return c:IsSetCard(SET_MAGICA) and c:IsType(TYPE_MONSTER) 
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then 
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_DECK,0,1,nil,e,tp) 
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_DECK,0,1,1,nil,e,tp)
	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
	end
end