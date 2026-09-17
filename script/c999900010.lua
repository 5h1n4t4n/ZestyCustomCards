-- Oktavia Von Seckendorffe The Magica Puella Witch
-- ID: 999900010
local s,id=GetID()

local SET_MAGICA		  = 0x654
local SET_PUELLA_WITCH  = 0x1654
local SET_SOULGEM	   = 0xc7d
local COUNTER_NOTE	= 0x1655

local CARD_SAYAKA_STUDENT = 999900008
local CARD_SYMPHONIC	  = 999900011
local TOKEN_GRIEF_SEED  = 999900006

s.listed_series={SET_MAGICA, SET_PUELLA_WITCH, SET_SOULGEM}
s.listed_names={CARD_SAYAKA_STUDENT, CARD_SYMPHONIC, TOKEN_GRIEF_SEED}

function s.initial_effect(c)
	c:EnableReviveLimit()
	c:EnableCounterPermit(COUNTER_NOTE)

	-- Sub-setcode 0x1654 ("Magica Puella Witch")
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_ADD_SETCODE)
	e0:SetValue(SET_PUELLA_WITCH)
	c:RegisterEffect(e0)

	-- ĐIỀU KIỆN SUMMON: Bắt buộc triệu hồi bằng hiệu ứng lá "Magica"
	local e_splim=Effect.CreateEffect(c)
	e_splim:SetType(EFFECT_TYPE_SINGLE)
	e_splim:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e_splim:SetCode(EFFECT_SPSUMMON_CONDITION)
	e_splim:SetValue(s.splimit)
	c:RegisterEffect(e_splim)

	-- 1. BẢO VỆ: Quái thú "Magica" không thể bị tế (Tribute) hoặc dùng làm nguyên liệu Extra Deck bởi đối thủ
	local e_tr=Effect.CreateEffect(c)
	e_tr:SetType(EFFECT_TYPE_FIELD)
	e_tr:SetCode(EFFECT_CANNOT_RELEASE)
	e_tr:SetRange(LOCATION_MZONE)
	e_tr:SetTargetRange(LOCATION_MZONE,0)
	e_tr:SetTarget(s.protg)
	e_tr:SetValue(1)
	c:RegisterEffect(e_tr)

	local e_mat1=Effect.CreateEffect(c)
	e_mat1:SetType(EFFECT_TYPE_FIELD)
	e_mat1:SetCode(EFFECT_CANNOT_BE_FUSION_MATERIAL)
	e_mat1:SetRange(LOCATION_MZONE)
	e_mat1:SetTargetRange(LOCATION_MZONE,0)
	e_mat1:SetTarget(s.protg)
	e_mat1:SetValue(s.matval)
	c:RegisterEffect(e_mat1)

	local e_mat2=e_mat1:Clone()
	e_mat2:SetCode(EFFECT_CANNOT_BE_SYNCHRO_MATERIAL)
	c:RegisterEffect(e_mat2)

	local e_mat3=e_mat1:Clone()
	e_mat3:SetCode(EFFECT_CANNOT_BE_XYZ_MATERIAL)
	c:RegisterEffect(e_mat3)

	local e_mat4=e_mat1:Clone()
	e_mat4:SetCode(EFFECT_CANNOT_BE_LINK_MATERIAL)
	c:RegisterEffect(e_mat4)

	-- 2. ĐẶT COUNTER: Khi SS đặt Note Counter = số quái "Magica" & Cộng Counter khi Magica về tay
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_COUNTER)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.cttg)
	e1:SetOperation(s.ctop)
	c:RegisterEffect(e1)

	local e1b=Effect.CreateEffect(c)
	e1b:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1b:SetCode(EVENT_TO_HAND)
	e1b:SetRange(LOCATION_MZONE)
	e1b:SetOperation(s.rthop)
	c:RegisterEffect(e1b)

	-- 3. QUICK EFFECT: Trừ Note Counter trên sân để chọn 1 trong 3 hiệu ứng (HOPT)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_SPECIAL_SUMMON+CATEGORY_DISABLE)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_MZONE)
	e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E+TIMING_MAIN_END)
	e2:SetCountLimit(1,id+100)
	e2:SetCost(s.optcost)
	e2:SetTarget(s.opttg)
	e2:SetOperation(s.optop)
	c:RegisterEffect(e2)

	-- 4. KHI XUỐNG GY: Triệu hồi Grief Seed Token (HOPT)
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,5))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOKEN)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_TO_GRAVE)
	e3:SetCountLimit(1,id+200)
	e3:SetTarget(s.toktg)
	e3:SetOperation(s.tokop)
	c:RegisterEffect(e3)

	-- 5. RETURN EXTRA DECK: Ở End Phase hoặc ngay sau khi giải quyết hiệu ứng
	local e4a=Effect.CreateEffect(c)
	e4a:SetDescription(aux.Stringid(id,6))
	e4a:SetCategory(CATEGORY_TODECK+CATEGORY_SPECIAL_SUMMON)
	e4a:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e4a:SetCode(EVENT_PHASE+PHASE_END)
	e4a:SetRange(LOCATION_MZONE)
	e4a:SetCountLimit(1,id+300)
	e4a:SetCondition(s.edcon1)
	e4a:SetCost(s.edcost)
	e4a:SetTarget(s.edtg)
	e4a:SetOperation(s.edop)
	c:RegisterEffect(e4a)

	local e4b=Effect.CreateEffect(c)
	e4b:SetDescription(aux.Stringid(id,6))
	e4b:SetCategory(CATEGORY_TODECK+CATEGORY_SPECIAL_SUMMON)
	e4b:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e4b:SetCode(EVENT_CHAIN_SOLVED)
	e4b:SetProperty(EFFECT_FLAG_DELAY)
	e4b:SetRange(LOCATION_MZONE)
	e4b:SetCountLimit(1,id+300)
	e4b:SetCondition(s.edcon2)
	e4b:SetCost(s.edcost)
	e4b:SetTarget(s.edtg)
	e4b:SetOperation(s.edop)
	c:RegisterEffect(e4b)
end

function s.splimit(e,se,sp,st)
	return se and se:GetHandler():IsSetCard(SET_MAGICA)
end

--------------------------------------------------------------------------------
-- 1. PROTECTION EFFECTS
--------------------------------------------------------------------------------
function s.protg(e,c)
	return c:IsSetCard(SET_MAGICA)
end

function s.matval(e,c)
	return c and c:IsControler(1-e:GetHandlerPlayer())
end

--------------------------------------------------------------------------------
-- 2. COUNTER PLACEMENT EFFECTS
--------------------------------------------------------------------------------
function s.mfilter(c)
	return c:IsFaceup() and c:IsSetCard(SET_MAGICA)
end

function s.ctfilter(c)
	return c:IsFaceup() and c:IsCanAddCounter(COUNTER_NOTE,1)
end

function s.cttg(e,tp,eg,ep,ev,re,r,rp,chk)
	local ct=Duel.GetMatchingGroupCount(s.mfilter,tp,LOCATION_MZONE,0,nil)
	if chk==0 then return ct>0 and Duel.IsExistingMatchingCard(s.ctfilter,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil) end
end

function s.ctop(e,tp,eg,ep,ev,re,r,rp)
	local ct=Duel.GetMatchingGroupCount(s.mfilter,tp,LOCATION_MZONE,0,nil)
	if ct<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
	local g=Duel.SelectMatchingCard(tp,s.ctfilter,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,1,nil)
	if #g>0 then
		g:GetFirst():AddCounter(COUNTER_NOTE,ct)
	end
end

function s.rthfilter(c,tp)
	return c:IsPreviousControler(tp) and c:IsSetCard(SET_MAGICA) and c:IsType(TYPE_MONSTER) and c:IsPreviousLocation(LOCATION_MZONE)
end

function s.rthop(e,tp,eg,ep,ev,re,r,rp)
	if eg:IsExists(s.rthfilter,1,nil,tp) then
		e:GetHandler():AddCounter(COUNTER_NOTE,1)
	end
end

--------------------------------------------------------------------------------
-- 3. QUICK EFFECT (3 OPTIONS)
--------------------------------------------------------------------------------
function s.symfilter(c)
	return c:IsCode(CARD_SYMPHONIC) and c:IsAbleToHand()
end

function s.stdfilter(c,e,tp)
	return c:IsSetCard(SET_MAGICA) and (c:IsCode(CARD_SAYAKA_STUDENT) or c:IsCode(999900001))
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.negfilter(c)
	return c:IsFaceup() and not c:IsDisabled()
end

function s.optcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local b1=Duel.IsCanRemoveCounter(tp,LOCATION_ONFIELD,LOCATION_ONFIELD,COUNTER_NOTE,1,REASON_COST)
		and Duel.IsExistingMatchingCard(s.symfilter,tp,LOCATION_DECK,0,1,nil)
	local b2=Duel.IsCanRemoveCounter(tp,LOCATION_ONFIELD,LOCATION_ONFIELD,COUNTER_NOTE,2,REASON_COST)
		and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.stdfilter,tp,LOCATION_HAND+LOCATION_DECK,0,1,nil,e,tp)
	local b3=Duel.IsCanRemoveCounter(tp,LOCATION_ONFIELD,LOCATION_ONFIELD,COUNTER_NOTE,7,REASON_COST)
		and Duel.IsExistingMatchingCard(s.negfilter,tp,0,LOCATION_ONFIELD,1,nil)

	if chk==0 then return b1 or b2 or b3 end

	local ops={}
	local opval={}
	local off=1
	if b1 then
		ops[off]=aux.Stringid(id,2)
		opval[off]=1
		off=off+1
	end
	if b2 then
		ops[off]=aux.Stringid(id,3)
		opval[off]=2
		off=off+1
	end
	if b3 then
		ops[off]=aux.Stringid(id,4)
		opval[off]=3
		off=off+1
	end

	local op=Duel.SelectOption(tp,table.unpack(ops))+1
	local sel=opval[op]
	e:SetLabel(sel)

	local ct=1
	if sel==2 then ct=2 end
	if sel==3 then ct=7 end

	Duel.RemoveCounter(tp,LOCATION_ONFIELD,LOCATION_ONFIELD,COUNTER_NOTE,ct,REASON_COST)
end

function s.opttg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	local sel=e:GetLabel()
	if sel==1 then
		Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
	elseif sel==2 then
		Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_DECK)
	elseif sel==3 then
		local g=Duel.GetMatchingGroup(s.negfilter,tp,0,LOCATION_ONFIELD,nil)
		Duel.SetOperationInfo(0,CATEGORY_DISABLE,g,#g,0,0)
	end
end

function s.optop(e,tp,eg,ep,ev,re,r,rp)
	local sel=e:GetLabel()
	if sel==1 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local g=Duel.SelectMatchingCard(tp,s.symfilter,tp,LOCATION_DECK,0,1,1,nil)
		if #g>0 then
			Duel.SendtoHand(g,nil,REASON_EFFECT)
			Duel.ConfirmCards(1-tp,g)
		end
	elseif sel==2 then
		if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local g=Duel.SelectMatchingCard(tp,s.stdfilter,tp,LOCATION_HAND+LOCATION_DECK,0,1,1,nil,e,tp)
		if #g>0 then
			Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
		end
	elseif sel==3 then
		local g=Duel.GetMatchingGroup(s.negfilter,tp,0,LOCATION_ONFIELD,nil)
		for tc in aux.Next(g) do
			Duel.NegateRelatedChain(tc,RESET_TURN_SET) -- Khắc phục lỗi không dập được chain đang chạy
			local e1=Effect.CreateEffect(e:GetHandler())
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_DISABLE)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
			tc:RegisterEffect(e1)
			local e2=Effect.CreateEffect(e:GetHandler())
			e2:SetType(EFFECT_TYPE_SINGLE)
			e2:SetCode(EFFECT_DISABLE_EFFECT)
			e2:SetValue(RESET_TURN_SET)
			e2:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
			tc:RegisterEffect(e2)
		end
	end
end

--------------------------------------------------------------------------------
-- 4. GRIEF SEED TOKEN SUMMON
--------------------------------------------------------------------------------
function s.toktg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.IsPlayerCanSpecialSummonMonster(tp,TOKEN_GRIEF_SEED,0,TYPES_TOKEN+TYPE_MONSTER,300,300,1,RACE_SPELLCASTER,ATTRIBUTE_DARK)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOKEN,nil,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,0)
end

function s.tokop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0
		or not Duel.IsPlayerCanSpecialSummonMonster(tp,TOKEN_GRIEF_SEED,0,TYPES_TOKEN+TYPE_MONSTER,300,300,1,RACE_SPELLCASTER,ATTRIBUTE_DARK) then return end
	local token=Duel.CreateToken(tp,TOKEN_GRIEF_SEED)
	Duel.SpecialSummon(token,0,tp,tp,false,false,POS_FACEUP)
end

--------------------------------------------------------------------------------
-- 5. RETURN EXTRA DECK & SPECIAL SUMMON SAYAKA STUDENT
--------------------------------------------------------------------------------
function s.edcon1(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetTurnPlayer()==tp
end

function s.edcon2(e,tp,eg,ep,ev,re,r,rp)
	return re:GetHandler()==e:GetHandler()
end

function s.sayakafilter(c,e,tp)
	return c:IsCode(CARD_SAYAKA_STUDENT) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.edcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsAbleToDeckAsCost() end 
	e:SetLabel(c:GetCounter(COUNTER_NOTE))
	Duel.SendtoDeck(c,nil,SEQ_DECKSHUFFLE,REASON_COST)
end

function s.edtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetMZoneCount(tp,e:GetHandler())>0
			and Duel.IsExistingMatchingCard(s.sayakafilter,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE,0,1,nil,e,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE)
end

function s.edop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.sayakafilter,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil,e,tp)
	local tc=g:GetFirst()
	if tc and Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)>0 then
		local ct=e:GetLabel()
		if ct>0 and tc:IsCanAddCounter(COUNTER_NOTE,ct) then
			tc:AddCounter(COUNTER_NOTE,ct)
		end
	end
end