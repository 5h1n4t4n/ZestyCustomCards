-- Vessel of the Eternal Cataclysm
-- ID: Custom
local s,id=GetID()
s.listed_series={0xb4c} -- Setcode Mecha Three Kingdoms

function s.initial_effect(c)
	-- Fusion Materials: 3+ "Mecha Three Kingdoms" monsters
	c:EnableReviveLimit()
	Fusion.AddProcMixRep(c, true, true, aux.FilterBoolFunction(Card.IsSetCard,0xb4c), 3, 99)

	-- 1. Draw cards (Trigger khi Summon thành công)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DRAW)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCondition(s.drcon)
	e1:SetTarget(s.drtg)
	e1:SetOperation(s.drop)
	c:RegisterEffect(e1)

	-- 3+ Materials: Tăng 3000 ATK
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCode(EFFECT_UPDATE_ATTACK)
	e3:SetCondition(s.countcon(3))
	e3:SetValue(3000)
	c:RegisterEffect(e3)

	-- 4+ Materials: Search/Set S/T (Quick Effect)
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,1))
	e4:SetCategory(CATEGORY_TODECK+CATEGORY_TOHAND+CATEGORY_SEARCH)
	e4:SetType(EFFECT_TYPE_QUICK_O)
	e4:SetCode(EVENT_FREE_CHAIN)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCountLimit(1)
	e4:SetCondition(s.countcon(4))
	e4:SetTarget(s.sttg)
	e4:SetOperation(s.stop)
	c:RegisterEffect(e4)

	-- 5+ Materials: Immune (Kháng hiệu ứng)
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_SINGLE)
	e5:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e5:SetRange(LOCATION_MZONE)
	e5:SetCode(EFFECT_IMMUNE_EFFECT)
	e5:SetCondition(s.countcon(5))
	e5:SetValue(s.efilter)
	c:RegisterEffect(e5)

	-- 6+ Materials: Control (Cướp quái)
	local e6=Effect.CreateEffect(c)
	e6:SetDescription(aux.Stringid(id,2))
	e6:SetCategory(CATEGORY_CONTROL)
	e6:SetType(EFFECT_TYPE_IGNITION)
	e6:SetRange(LOCATION_MZONE)
	e6:SetCountLimit(1)
	e6:SetCondition(s.countcon(6))
	e6:SetTarget(s.cttg)
	e6:SetOperation(s.ctop)
	c:RegisterEffect(e6)

	-- 7. Revive Effect (Hồi sinh khi bị hủy)
	local e7=Effect.CreateEffect(c)
	e7:SetDescription(aux.Stringid(id,3))
	e7:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e7:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e7:SetProperty(EFFECT_FLAG_DELAY)
	e7:SetCode(EVENT_DESTROYED)
	e7:SetCondition(s.spcon)
	e7:SetCost(s.spcost)
	e7:SetTarget(s.sptg)
	e7:SetOperation(s.spop)
	c:RegisterEffect(e7)
end

--------------------------------------------------------------------------------
-- LOGIC ĐẾM NGUYÊN LIỆU (Dùng trực tiếp API C++ của EDOPro)
--------------------------------------------------------------------------------
function s.countcon(n)
	return function(e)
		local c=e:GetHandler()
		-- Tự động đếm nguyên liệu Fusion trực tiếp từ c:GetMaterial()
		return c:IsSummonType(SUMMON_TYPE_FUSION) and #c:GetMaterial()>=n
	end
end

--------------------------------------------------------------------------------
-- DRAW EFFECT
--------------------------------------------------------------------------------
function s.drcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_FUSION)
end

function s.drtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then 
		local ct=Duel.GetFieldGroupCount(tp,LOCATION_MZONE,LOCATION_MZONE)
		return ct>0 and Duel.IsPlayerCanDraw(tp,ct) 
	end
	local ct=Duel.GetFieldGroupCount(tp,LOCATION_MZONE,LOCATION_MZONE)
	Duel.SetTargetPlayer(tp)
	Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,ct)
end

function s.drop(e,tp,eg,ep,ev,re,r,rp)
	local p=Duel.GetChainInfo(0,CHAININFO_TARGET_PLAYER)
	local ct=Duel.GetFieldGroupCount(tp,LOCATION_MZONE,LOCATION_MZONE)
	if ct>0 then 
		Duel.Draw(p,ct,REASON_EFFECT) 
	end
end

--------------------------------------------------------------------------------
-- SEARCH / SET SPELL & TRAP
--------------------------------------------------------------------------------
function s.shfilter(c) 
	return c:IsSetCard(0xb4c) and c:IsType(TYPE_SPELL+TYPE_TRAP) and c:IsAbleToDeck() 
end

function s.anySTfilter(c) 
	return c:IsType(TYPE_SPELL+TYPE_TRAP) and (c:IsAbleToHand() or c:IsSSetable()) 
end

function s.sttg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then 
		return Duel.IsExistingMatchingCard(s.shfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,nil)
			and Duel.IsExistingMatchingCard(s.anySTfilter,tp,LOCATION_DECK,0,1,nil) 
	end
	Duel.SetOperationInfo(0,CATEGORY_TODECK,nil,1,tp,LOCATION_GRAVE+LOCATION_REMOVED)
end

function s.stop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.shfilter),tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,1,nil)
	if #g>0 and Duel.SendtoDeck(g,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)>0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local sg=Duel.SelectMatchingCard(tp,s.anySTfilter,tp,LOCATION_DECK,0,1,1,nil)
		if #sg>0 then
			local tc=sg:GetFirst()
			local b1=tc:IsAbleToHand()
			local b2=tc:IsSSetable()
			if b1 and (not b2 or Duel.SelectOption(tp,1190,1153)==0) then
				Duel.SendtoHand(tc,nil,REASON_EFFECT)
				Duel.ConfirmCards(1-tp,tc)
			else 
				Duel.SSet(tp,tc) 
			end
		end
	end
end

--------------------------------------------------------------------------------
-- IMMUNE
--------------------------------------------------------------------------------
function s.efilter(e,te) 
	return te:GetOwner()~=e:GetHandler() and not te:GetOwner():IsSetCard(0xb4c) 
end

--------------------------------------------------------------------------------
-- CONTROL (TAKE CONTROL OF OPPONENT'S MONSTERS)
--------------------------------------------------------------------------------
function s.cttg(e,tp,eg,ep,ev,re,r,rp,chk)
	-- Dùng Duel.GetLocationCount thay cho Duel.GetMZoneCount
	local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
	if chk==0 then 
		return ft>0 and Duel.IsExistingMatchingCard(Card.IsControlerCanBeChanged,tp,0,LOCATION_MZONE,1,nil) 
	end
	local g=Duel.GetMatchingGroup(Card.IsControlerCanBeChanged,tp,0,LOCATION_MZONE,nil)
	Duel.SetOperationInfo(0,CATEGORY_CONTROL,g,1,0,0)
end

function s.ctop(e,tp,eg,ep,ev,re,r,rp)
	local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
	if ft<=0 then return end
	local g=Duel.GetMatchingGroup(Card.IsControlerCanBeChanged,tp,0,LOCATION_MZONE,nil)
	if #g>0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONTROL)
		local sg=g:Select(tp,1,ft,nil)
		Duel.GetControl(sg,tp)
	end
end

--------------------------------------------------------------------------------
-- REVIVE EFFECT
--------------------------------------------------------------------------------
function s.spcon(e,tp,eg,ep,ev,re,r,rp) 
	return e:GetHandler():IsPreviousLocation(LOCATION_MZONE) 
end

function s.rmfilter(c) 
	return c:IsSetCard(0xb4c) and c:IsAbleToRemoveAsCost() 
end

function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.rmfilter,tp,LOCATION_GRAVE,0,1,e:GetHandler()) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectMatchingCard(tp,s.rmfilter,tp,LOCATION_GRAVE,0,1,1,e:GetHandler())
	Duel.Remove(g,POS_FACEUP,REASON_COST)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0 
		and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false,POS_FACEUP_DEFENSE) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then 
		Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP_DEFENSE) 
	end
end