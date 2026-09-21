--Diao Chan – Beauty of Betrayal
local s,id=GetID()
s.listed_series={0xb4c}

function s.initial_effect(c)
	--Effect 1: Send to GY (from Hand or Deck), Set 1 Spell/Trap
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOGRAVE)
	e1:SetType(EFFECT_TYPE_IGNITION)
	-- CHO PHÉP KÍCH HOẠT TỪ TAY HOẶC DECK
	e1:SetRange(LOCATION_HAND+LOCATION_DECK)
	e1:SetCountLimit(1,id)
	e1:SetCost(s.setcost)
	e1:SetTarget(s.settg)
	e1:SetOperation(s.setop)
	c:RegisterEffect(e1)
	
	--Effect 2: SS from GY, then Xyz Summon (Giữ nguyên)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,id+100)
	e2:SetTarget(s.xyztg2)
	e2:SetOperation(s.xyzop2)
	c:RegisterEffect(e2)
end

--------------------------------------------------------------------------------
-- EFFECT 1: SEND TO GY -> SET S/T
--------------------------------------------------------------------------------

-- Filter cho Spell/Trap để discard (khi kích hoạt từ Deck)
function s.cost_st_filter(c)
	return c:IsType(TYPE_SPELL+TYPE_TRAP) and c:IsDiscardable()
end

function s.setcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		-- Trường hợp 1: Ở trên tay -> Chỉ cần gửi chính nó xuống mộ
		if c:IsLocation(LOCATION_HAND) then
			return c:IsAbleToGraveAsCost()
		
		-- Trường hợp 2: Ở trong Deck -> Gửi chính nó + Discard 1 S/T
		elseif c:IsLocation(LOCATION_DECK) then
			return c:IsAbleToGraveAsCost() 
				and Duel.IsExistingMatchingCard(s.cost_st_filter,tp,LOCATION_HAND,0,1,nil)
		end
		return false
	end
	
	-- Thực hiện Cost
	if c:IsLocation(LOCATION_DECK) then
		-- Nếu ở Deck, yêu cầu Discard trước
		Duel.ConfirmCards(1-tp,c) -- Cho đối thủ xem lá bài trong Deck (để biết là Điêu Thuyền)
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DISCARD)
		local g=Duel.SelectMatchingCard(tp,s.cost_st_filter,tp,LOCATION_HAND,0,1,1,nil)
		Duel.SendtoGrave(g,REASON_COST+REASON_DISCARD)
	end
	-- Gửi Điêu Thuyền xuống mộ (Cost chung cho cả 2 trường hợp)
	Duel.SendtoGrave(c,REASON_COST)
end

function s.setfilter(c)
	return c:IsSetCard(0xb4c) and c:IsType(TYPE_SPELL+TYPE_TRAP) and c:IsSSetable()
end

function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil) end
end

function s.setop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
	local g=Duel.SelectMatchingCard(tp,s.setfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil)
	if #g>0 then
		local tc=g:GetFirst()
		if Duel.SSet(tp,tc)>0 then
			-- Cho phép kích hoạt ngay trong lượt này (Trap hoặc Quick-Play)
			-- Trap
			local e1=Effect.CreateEffect(e:GetHandler())
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_TRAP_ACT_IN_SET_TURN)
			e1:SetProperty(EFFECT_FLAG_SET_AVAILABLE)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD)
			tc:RegisterEffect(e1)
			-- Quick-Play Spell
			local e2=e1:Clone()
			e2:SetCode(EFFECT_QP_ACT_IN_SET_TURN)
			tc:RegisterEffect(e2)
		end
	end
end

--------------------------------------------------------------------------------
-- EFFECT 2: SS FROM GY -> XYZ SUMMON (GIỮ NGUYÊN)
--------------------------------------------------------------------------------
function s.xyzfilter(c,e,tp,mg)
	return c:IsRank(4) and c:IsType(TYPE_XYZ) 
		and Duel.GetLocationCountFromEx(tp,tp,mg,c)>0
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_XYZ,tp,false,false)
end

function s.stfilter(c)
	return c:IsFacedown() and c:IsType(TYPE_SPELL+TYPE_TRAP)
end

function s.xyztg2(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
			and Duel.IsExistingMatchingCard(s.stfilter,tp,LOCATION_ONFIELD,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end

function s.xyzop2(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) or Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)==0 then return end
	
	--Target 1 Set Spell/Trap
	if not Duel.IsExistingMatchingCard(s.stfilter,tp,LOCATION_ONFIELD,0,1,nil) then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	local g=Duel.SelectMatchingCard(tp,s.stfilter,tp,LOCATION_ONFIELD,0,1,1,nil)
	if #g==0 then return end
	
	local tc=g:GetFirst()
	Duel.HintSelection(g)
	
	--Treat Set card as Level 4 monster for Xyz material
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_ADD_TYPE)
	e1:SetValue(TYPE_MONSTER)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD)
	tc:RegisterEffect(e1)
	
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_CHANGE_LEVEL)
	e2:SetValue(4)
	e2:SetReset(RESET_EVENT+RESETS_STANDARD)
	tc:RegisterEffect(e2)
	
	--Xyz Summon
	if not c:IsLocation(LOCATION_MZONE) or not tc:IsLocation(LOCATION_SZONE) then return end
	
	local mg=Group.FromCards(c,tc)
	local xyzg=Duel.GetMatchingGroup(s.xyzfilter,tp,LOCATION_EXTRA,0,nil,e,tp,mg)
	
	if #xyzg>0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local xyz=xyzg:Select(tp,1,1,nil):GetFirst()
		if xyz then
			xyz:SetMaterial(mg)
			Duel.Overlay(xyz,mg)
			if Duel.SpecialSummon(xyz,SUMMON_TYPE_XYZ,tp,tp,false,false,POS_FACEUP)>0 then
				xyz:CompleteProcedure()
				--Grant indestructible effect
				local e3=Effect.CreateEffect(c)
				e3:SetType(EFFECT_TYPE_SINGLE)
				e3:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
				e3:SetValue(1)
				e3:SetReset(RESET_EVENT+RESETS_STANDARD)
				xyz:RegisterEffect(e3)
				local e4=e3:Clone()
				e4:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
				xyz:RegisterEffect(e4)
			end
		end
	end
end