--Sima Yi – The Weaver of Fates
local s,id=GetID()
s.listed_series={0xb4c} -- Mecha Three Kingdom

function s.initial_effect(c)
	-- Effect 1: Hand/GY Trigger (Quick Effect)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_CHAINING)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.spcon)
	e1:SetCost(s.spcost)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	-- Effect 2: On Special Summon -> Excavate 5 -> Choose 1 -> Effect based on Type
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_DECKDES+CATEGORY_DISABLE)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetCountLimit(1,id+100)
	e2:SetTarget(s.exctg)
	e2:SetOperation(s.excop)
	c:RegisterEffect(e2)
end

--------------------------------------------------------------------------------
-- EFFECT 1: HAND TRAP / SELF-SS
--------------------------------------------------------------------------------
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	local loc=re:GetActivateLocation()
	return rp==1-tp and re:IsActiveType(TYPE_MONSTER)
		and (loc==LOCATION_HAND or loc==LOCATION_GRAVE)
end

function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return not e:GetHandler():IsPublic() end
	-- SỬA: Dùng ConfirmCards thay cho RevealCard
	Duel.ConfirmCards(1-tp,e:GetHandler())
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) and Duel.SpecialSummonStep(c,0,tp,tp,false,false,POS_FACEUP) then
		-- ATK/DEF become 0
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_SET_ATTACK)
		e1:SetValue(0)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		c:RegisterEffect(e1)
		local e2=e1:Clone()
		e2:SetCode(EFFECT_SET_DEFENSE)
		c:RegisterEffect(e2)
	end
	Duel.SpecialSummonComplete()
end

--------------------------------------------------------------------------------
-- EFFECT 2: EXCAVATE & BRANCHING EFFECTS
--------------------------------------------------------------------------------
function s.exctg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then 
		return Duel.GetFieldGroupCount(tp,0,LOCATION_DECK)>=5 
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,0,tp,LOCATION_DECK)
end

-- Filter: 2 Lv4 Mecha Three Kingdom
function s.spfilter_lv4(c,e,tp)
	return c:IsSetCard(0xb4c) and c:IsLevel(4) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

-- Filter: Spell/Trap Setable
function s.setfilter(c)
	return c:IsType(TYPE_SPELL+TYPE_TRAP) and c:IsSSetable()
end

-- Filter: XYZ Summonable
function s.xyzfilter(c)
	return c:IsType(TYPE_XYZ) and c:IsXyzSummonable(nil)
end

function s.excop(e,tp,eg,ep,ev,re,r,rp)
	-- Yêu cầu Deck đối thủ còn 5 lá
	if Duel.GetFieldGroupCount(tp,0,LOCATION_DECK)<5 then return end
	
	-- Excavate 5 lá
	Duel.ConfirmDecktop(1-tp,5)
	local g=Duel.GetDecktopGroup(1-tp,5)
	
	if #g>0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CARDTYPE)
		-- Chọn 1 lá
		local sg=g:Select(tp,1,1,nil)
		local tc=sg:GetFirst()
		Duel.Hint(HINT_CARD,0,tc:GetCode())
		
		-- XỬ LÝ THEO LOẠI BÀI
		if tc:IsType(TYPE_MONSTER) then
			-- ① Monster: SS 2 Lv4 -> Negate -> XYZ Summon
			if Duel.GetLocationCount(tp,LOCATION_MZONE)>=2 
				and Duel.IsExistingMatchingCard(s.spfilter_lv4,tp,LOCATION_DECK,0,2,nil,e,tp) then
				
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
				local g_ss=Duel.SelectMatchingCard(tp,s.spfilter_lv4,tp,LOCATION_DECK,0,2,2,nil,e,tp)
				
				for sc in aux.Next(g_ss) do
					if Duel.SpecialSummonStep(sc,0,tp,tp,false,false,POS_FACEUP) then
						-- Negate Effects
						local e1=Effect.CreateEffect(e:GetHandler())
						e1:SetType(EFFECT_TYPE_SINGLE)
						e1:SetCode(EFFECT_DISABLE)
						e1:SetReset(RESET_EVENT+RESETS_STANDARD)
						sc:RegisterEffect(e1)
						local e2=Effect.CreateEffect(e:GetHandler())
						e2:SetType(EFFECT_TYPE_SINGLE)
						e2:SetCode(EFFECT_DISABLE_EFFECT)
						e2:SetReset(RESET_EVENT+RESETS_STANDARD)
						sc:RegisterEffect(e2)
					end
				end
				Duel.SpecialSummonComplete()
				
				-- SỬA: Dùng BreakEffect thay AdjustAll
				-- Ngắt chuỗi để game cập nhật lại bàn cờ (thấy 2 quái mới gọi)
				Duel.BreakEffect() 
				
				-- Check và thực hiện XYZ Summon
				local xyzg=Duel.GetMatchingGroup(s.xyzfilter,tp,LOCATION_EXTRA,0,nil)
				if #xyzg>0 and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
					Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
					local xyz=xyzg:Select(tp,1,1,nil):GetFirst()
					Duel.XyzSummon(tp,xyz,nil)
				end
			end

		elseif tc:IsType(TYPE_SPELL) then
			-- ② Spell: Set S/T -> Active this turn
			if Duel.GetLocationCount(tp,LOCATION_SZONE)>0 
				and Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_DECK,0,1,nil) then
				
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
				local g_set=Duel.SelectMatchingCard(tp,s.setfilter,tp,LOCATION_DECK,0,1,1,nil)
				local sc=g_set:GetFirst()
				
				if sc and Duel.SSet(tp,sc)>0 then
					local e1=Effect.CreateEffect(e:GetHandler())
					e1:SetType(EFFECT_TYPE_SINGLE)
					e1:SetCode(EFFECT_TRAP_ACT_IN_SET_TURN)
					e1:SetProperty(EFFECT_FLAG_SET_AVAILABLE)
					e1:SetReset(RESET_EVENT+RESETS_STANDARD)
					sc:RegisterEffect(e1)
					local e2=e1:Clone()
					e2:SetCode(EFFECT_QP_ACT_IN_SET_TURN)
					sc:RegisterEffect(e2)
				end
			end

		elseif tc:IsType(TYPE_TRAP) then
			-- ③ Trap: Negate 1 face-up card
			if Duel.IsExistingMatchingCard(Card.IsFaceup,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil) then
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DISABLE)
				local g_neg=Duel.SelectMatchingCard(tp,Card.IsFaceup,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,1,nil)
				local nc=g_neg:GetFirst()
				if nc then
					Duel.NegateRelatedChain(nc,RESET_TURN_SET)
					local e1=Effect.CreateEffect(e:GetHandler())
					e1:SetType(EFFECT_TYPE_SINGLE)
					e1:SetCode(EFFECT_DISABLE)
					e1:SetReset(RESET_EVENT+RESETS_STANDARD)
					nc:RegisterEffect(e1)
					local e2=Effect.CreateEffect(e:GetHandler())
					e2:SetType(EFFECT_TYPE_SINGLE)
					e2:SetCode(EFFECT_DISABLE_EFFECT)
					e2:SetValue(RESET_TURN_SET)
					e2:SetReset(RESET_EVENT+RESETS_STANDARD)
					nc:RegisterEffect(e2)
				end
			end
		end
	end
	-- Shuffle lại Deck
	Duel.ShuffleDeck(1-tp)
end