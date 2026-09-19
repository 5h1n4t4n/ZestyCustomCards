--Cao Cao – Warlord of Ambition
local s,id=GetID()
s.listed_series={0xb4c} -- Mecha Three Kingdom

function s.initial_effect(c)
	--Effect 1: Special Summon itself from hand if you control another "Three Kingdoms" monster
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetRange(LOCATION_HAND)
	e1:SetCondition(s.spcon)
	c:RegisterEffect(e1)

	--Effect 2: When this card is Special Summoned: Special Summon 1 "Three Kingdoms" monster from Deck
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCountLimit(1,id)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)

	--Effect 3: Excavate 5 from opponent's Deck & Gamble (Quick Effect)
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOHAND+CATEGORY_DECKDES)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetRange(LOCATION_HAND)
	e3:SetCountLimit(1,id+1) -- Hard OPT
	e3:SetCost(s.gamblecost)
	e3:SetTarget(s.gambletg)
	e3:SetOperation(s.gambleop)
	c:RegisterEffect(e3)
end

--------------------------------------------------------------------------------
-- EFFECT 1: SS FROM HAND
--------------------------------------------------------------------------------
function s.cfilter(c)
	return c:IsFaceup() and c:IsSetCard(0xb4c)
end
function s.spcon(e,c)
	if c==nil then return true end
	return Duel.IsExistingMatchingCard(s.cfilter,c:GetControler(),LOCATION_MZONE,0,1,nil)
end

--------------------------------------------------------------------------------
-- EFFECT 2: SS FROM DECK
--------------------------------------------------------------------------------
function s.spfilter(c,e,tp)
	return c:IsSetCard(0xb4c) and not c:IsCode(id)
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_DECK,0,1,nil,e,tp) end
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

--------------------------------------------------------------------------------
-- EFFECT 3: EXCAVATE & GAMBLE
--------------------------------------------------------------------------------
function s.gamblecost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return not c:IsPublic() end
	Duel.ConfirmCards(1-tp,c)
end

function s.gambletg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then 
		-- Đảm bảo Deck đối thủ đủ 5 lá và bạn có chỗ để SS Tào Tháo
		return Duel.GetFieldGroupCount(tp,0,LOCATION_DECK)>=5 
			and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end

-- Filter tìm Continuous Spell/Trap của Archetype
function s.actfilter(c,tp)
	return c:IsSetCard(0xb4c) and c:IsType(TYPE_CONTINUOUS) 
		and not c:IsForbidden() and c:CheckUniqueOnField(tp)
end

function s.gambleop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if Duel.GetFieldGroupCount(tp,0,LOCATION_DECK)<5 then return end
	
	-- Lật 5 lá từ Deck đối thủ
	Duel.ConfirmDecktop(1-tp,5)
	local g=Duel.GetDecktopGroup(1-tp,5)
	
	if #g>0 then
		-- Random chọn 1 lá
		local tc=g:RandomSelect(tp,1):GetFirst()
		Duel.Hint(HINT_CARD,0,tc:GetCode()) -- Hiện ảnh lá bài trúng thưởng lên màn hình
		
		-- Kịch bản 1: TRÚNG MONSTER
		if tc:IsType(TYPE_MONSTER) then
			if c:IsRelateToEffect(e) and Duel.GetLocationCount(tp,LOCATION_MZONE)>0 then
				Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
			end
			
		-- Kịch bản 2: TRÚNG SPELL/TRAP
		elseif tc:IsType(TYPE_SPELL+TYPE_TRAP) then
			Duel.DisableShuffleCheck()
			if Duel.SendtoHand(tc,1-tp,REASON_EFFECT)>0 and tc:IsLocation(LOCATION_HAND) then
				Duel.ShuffleHand(1-tp)
				
				-- Khóa không cho đối thủ dùng lá bài đó đến hết lượt tiếp theo
				-- Dùng số "2" ở cuối hàm SetReset để đếm 2 lần End Phase
				local e1=Effect.CreateEffect(c)
				e1:SetType(EFFECT_TYPE_FIELD)
				e1:SetCode(EFFECT_CANNOT_ACTIVATE)
				e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
				e1:SetTargetRange(0,1)
				e1:SetValue(s.aclimit)
				e1:SetLabel(tc:GetCode())
				e1:SetReset(RESET_PHASE+PHASE_END,2) 
				Duel.RegisterEffect(e1,tp)
				
				-- Bạn được phép kích hoạt 1 Continuous S/T "Mecha Three Kingdom" từ Hand/Deck
				if Duel.GetLocationCount(tp,LOCATION_SZONE)>0 
					and Duel.IsExistingMatchingCard(s.actfilter,tp,LOCATION_HAND+LOCATION_DECK,0,1,nil,tp) 
					and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
					
					Duel.BreakEffect()
					Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOFIELD)
					local sc=Duel.SelectMatchingCard(tp,s.actfilter,tp,LOCATION_HAND+LOCATION_DECK,0,1,1,nil,tp):GetFirst()
					if sc then
						-- Đưa lá bài ra sân ở thế ngửa (Kích hoạt trực tiếp)
						Duel.MoveToField(sc,tp,tp,LOCATION_SZONE,POS_FACEUP,true)
						local te=sc:GetActivateEffect()
						if te then
							local tep=sc:GetControler()
							local cost=te:GetCost()
							if cost then cost(te,tep,eg,ep,ev,re,r,rp,1) end
						end
					end
				end
			end
		end
	end
	-- Xào lại bộ bài đối thủ (Sẽ tự động gom các lá không được chọn)
	Duel.ShuffleDeck(1-tp)
end

function s.aclimit(e,re,tp)
	return re:GetHandler():IsCode(e:GetLabel())
end