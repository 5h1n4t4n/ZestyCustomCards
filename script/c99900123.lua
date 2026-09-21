-- Celestial Octa - Formation
local s,id=GetID()
s.listed_names={99900105}
s.listed_series={0xb4c}

function s.initial_effect(c)
	-- (Activate) Special Summon Zhuge Liang
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	-- (Quick) Double ATK/DEF of 1 Mecha Three Kingdom monster
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_ATKCHANGE+CATEGORY_DEFCHANGE)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_SZONE)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_MAIN_END)
	e2:SetCountLimit(1,{id,1})
	e2:SetTarget(s.atktg)
	e2:SetOperation(s.atkop)
	c:RegisterEffect(e2)

	-- (Quick) Increase Level of Mecha Three Kingdom monsters by 4
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetRange(LOCATION_SZONE)
	e3:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e3:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_MAIN_END)
	e3:SetCountLimit(1,{id,2})
	e3:SetTarget(s.lvtg)
	e3:SetOperation(s.lvop)
	c:RegisterEffect(e3)

	-- HIỆU ỨNG MỚI ĐÃ THAY THẾ: Gọi thêm 1 quái Mecha từ tay mỗi lượt (Không thể bị negate nếu có Gia Cát Lượng)
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,4)) -- Dòng text hiển thị lựa chọn
	e4:SetType(EFFECT_TYPE_FIELD)
	e4:SetCode(EFFECT_EXTRA_SUMMON_COUNT)
	e4:SetRange(LOCATION_SZONE)
	e4:SetTargetRange(LOCATION_HAND+LOCATION_MZONE,0)
	e4:SetTarget(s.sumtg)
	e4:SetValue(0) -- Cho phép thêm 1 lần Normal Summon thường từ tay
	-- Thiết lập điều kiện kháng Vô hiệu hóa linh hoạt dựa vào Gia Cát Lượng
	e4:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e4:SetCondition(s.sumcon)
	c:RegisterEffect(e4)

	-- (Continuous) Allow activating Mecha Three Kingdom Quick-Play Spells from hand during opponent's turn
	local e7=Effect.CreateEffect(c)
	e7:SetType(EFFECT_TYPE_FIELD)
	e7:SetCode(EFFECT_QP_ACT_IN_NTPHAND)
	e7:SetRange(LOCATION_SZONE)
	e7:SetTargetRange(LOCATION_HAND,0)
	e7:SetTarget(s.qpfilter)
	c:RegisterEffect(e7)

	-- (Quick) Xyz Summon when opponent declares attack — only if Zhuge Liang is the only monster you control
	local e8=Effect.CreateEffect(c)
	e8:SetDescription(aux.Stringid(id,3))
	e8:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e8:SetType(EFFECT_TYPE_QUICK_O)
	e8:SetCode(EVENT_ATTACK_ANNOUNCE)
	e8:SetRange(LOCATION_SZONE)
	e8:SetCountLimit(1,{id,3})
	e8:SetCondition(s.xyzcon)
	e8:SetTarget(s.xyztg)
	e8:SetOperation(s.xyzop)
	c:RegisterEffect(e8)
end

-- =============================================
-- HELPER: Zhuge Liang check
-- =============================================
function s.zhugefilter(c)
	return c:IsFaceup() and c:IsCode(99900105)
end

function s.zhugectrl(tp)
	return Duel.IsExistingMatchingCard(s.zhugefilter,tp,LOCATION_MZONE,0,1,nil)
end

-- =============================================
-- LOGIC HIỆU ỨNG MỚI: EXTRA NORMAL SUMMON
-- =============================================
function s.sumtg(e,c)
	-- Chỉ cho phép áp dụng lượt Triệu hồi thêm này cho quái thuộc archetype Mecha Three Kingdoms
	return c:IsSetCard(0xb4c)
end

function s.sumcon(e)
	local tp=e:GetHandlerPlayer()
	local c=e:GetHandler()
	-- Nếu có Gia Cát Lượng trên sân, hiệu ứng được bảo vệ tuyệt đối (Không bị vô hiệu hóa bởi Mystical Space Typhoon lật chuỗi hoặc các card tương tự)
	if s.zhugectrl(tp) then
		e:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	else
		e:SetProperty(0)
	end
	return true
end

-- =============================================
-- (Activate) Special Summon Zhuge Liang
-- =============================================
function s.spfilter(c,e,tp)
	return c:IsCode(99900105) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_DECK+LOCATION_HAND+LOCATION_GRAVE,0,1,nil,e,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK+LOCATION_HAND+LOCATION_GRAVE)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.spfilter),tp,
		LOCATION_DECK+LOCATION_HAND+LOCATION_GRAVE,0,1,1,nil,e,tp)
	if g:GetCount()>0 then
		Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
	end
end

-- =============================================
-- (Quick) Double ATK/DEF
-- =============================================
function s.mtkfilter(c)
	return c:IsFaceup() and c:IsSetCard(0xb4c) and c:IsType(TYPE_MONSTER)
end

function s.atktg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(tp) and s.mtkfilter(chkc)
	end
	if chk==0 then return Duel.IsExistingTarget(s.mtkfilter,tp,LOCATION_MZONE,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
	Duel.SelectTarget(tp,s.mtkfilter,tp,LOCATION_MZONE,0,1,1,nil)
end

function s.atkop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) and tc:IsFaceup() then
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_SET_ATTACK_FINAL)
		e1:SetValue(tc:GetAttack()*2)
		if s.zhugectrl(tp) then
			e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END+RESET_OPPO_TURN,2)
		else
			e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		end
		tc:RegisterEffect(e1)
		local e2=e1:Clone()
		e2:SetCode(EFFECT_SET_DEFENSE_FINAL)
		e2:SetValue(tc:GetDefense()*2)
		tc:RegisterEffect(e2)
	end
end

-- =============================================
-- (Quick) Increase Level by 4
-- =============================================
function s.lvtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(tp) and s.mtkfilter(chkc)
	end
	local ct=s.zhugectrl(tp) and 3 or 1
	if chk==0 then
		return Duel.IsExistingTarget(s.mtkfilter,tp,LOCATION_MZONE,0,1,nil)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
	local g=Duel.SelectTarget(tp,s.mtkfilter,tp,LOCATION_MZONE,0,1,ct,nil)
	Duel.SetOperationInfo(0,CATEGORY_LVCHANGE,g,g:GetCount(),0,4)
end

function s.lvop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local g=Duel.GetChainInfo(0,CHAININFO_TARGET_CARDS):Filter(Card.IsRelateToEffect,nil,e)
	for tc in aux.Next(g) do
		if tc:IsFaceup() then
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_UPDATE_LEVEL)
			e1:SetValue(4)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD)
			tc:RegisterEffect(e1)
		end
	end
end

-- =============================================
-- (Continuous) Quick-Play Spell from hand
-- =============================================
function s.qpfilter(e,c)
	return c:IsSetCard(0xb4c) and c:IsType(TYPE_QUICKPLAY)
end

-- =============================================
-- (Quick) Xyz Summon during opponent's turn
-- =============================================
function s.xyzcon(e,tp,eg,ep,ev,re,r,rp)
	if not s.zhugectrl(tp) then return false end
	local others=Duel.GetMatchingGroup(
		function(c) return c:IsFaceup() and c:IsType(TYPE_MONSTER) and not c:IsCode(99900105) end,
		tp,LOCATION_MZONE,0,nil)
	return others:GetCount()==0
end

function s.xyzmatfilter(c)
	return c:IsFaceup() and c:IsSetCard(0xb4c)
		and (c:IsType(TYPE_SPELL) or c:IsType(TYPE_TRAP))
end

function s.xyzfilter(c,e,tp)
	return c:IsSetCard(0xb4c) and c:IsType(TYPE_XYZ)
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_XYZ,tp,false,false)
end

function s.xyztg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		local pg=Duel.GetMatchingGroup(s.xyzmatfilter,tp,LOCATION_ONFIELD,0,nil)
		return Duel.GetLocationCountFromEx(tp)>0
			and pg:GetCount()>=2
			and Duel.IsExistingMatchingCard(s.xyzfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

function s.xyzop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCountFromEx(tp)<=0 then return end
	local mg=Duel.GetMatchingGroup(s.xyzmatfilter,tp,LOCATION_ONFIELD,0,nil)
	if mg:GetCount()<2 then return end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMONSTER)
	local sc=Duel.SelectMatchingCard(tp,s.xyzfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp):GetFirst()
	if not sc then return end

	local rank=sc:GetRank()
	if rank==0 then rank=4 end

	local avail=Duel.GetMatchingGroup(s.xyzmatfilter,tp,LOCATION_ONFIELD,0,nil)
	if avail:GetCount()<rank then return end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_XMATERIAL)
	local xyzg=avail:Select(tp,rank,rank,nil)
	if xyzg:GetCount()>0 then
		sc:SetMaterial(xyzg)
		Duel.Overlay(sc,xyzg)
		Duel.SpecialSummon(sc,SUMMON_TYPE_XYZ,tp,tp,false,false,POS_FACEUP)
		sc:CompleteProcedure()
	end
end