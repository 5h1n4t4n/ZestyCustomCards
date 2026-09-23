-- Blue Swordsman of The Red-Eyes
local s,id=GetID()
function s.initial_effect(c)
	-- Link Summon: 2 Dragon monsters OR 2 Warrior monsters
	Link.AddProcedure(c,s.matfilter,2,2,s.lcheck)
	c:EnableReviveLimit()
	
	-- Effect 1: Treated as FIRE-Attribute
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetCode(EFFECT_ADD_ATTRIBUTE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetValue(ATTRIBUTE_FIRE)
	c:RegisterEffect(e1)
	
	-- Effect 2: Gains 100 ATK
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetCode(EFFECT_UPDATE_ATTACK)
	e2:SetRange(LOCATION_MZONE)
	e2:SetValue(s.atkval)
	c:RegisterEffect(e2)
	
	-- Effect 3: Cannot be destroyed by opponent's card effects
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e3:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCondition(s.protcon)
	e3:SetValue(s.indval)
	c:RegisterEffect(e3)
	
	-- Effect 4: Quick Effect (Fusion on your turn, Ritual on opponent's turn)
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,0))
	e4:SetType(EFFECT_TYPE_QUICK_O)
	e4:SetCode(EVENT_FREE_CHAIN)
	e4:SetRange(LOCATION_MZONE)
	e4:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_MAIN_END)
	e4:SetCountLimit(1,id)
	e4:SetTarget(s.qctg)
	e4:SetOperation(s.qcop)
	c:RegisterEffect(e4)
end
s.listed_series={0x3b, 0x2a9}

-- ==========================================================
-- ĐIỀU KIỆN GỌI LINK (2 DRAGON OR 2 WARRIOR)
-- ==========================================================
function s.matfilter(c,lc,sumtype,tp)
	return c:IsRace(RACE_DRAGON|RACE_WARRIOR,lc,sumtype,tp)
end
function s.lcheck(g,lc,sumtype,tp)
	return g:FilterCount(function(tc) return tc:IsRace(RACE_DRAGON,lc,sumtype,tp) end,nil)==#g
		or g:FilterCount(function(tc) return tc:IsRace(RACE_WARRIOR,lc,sumtype,tp) end,nil)==#g
end

-- ==========================================================
-- HIỆU ỨNG TĂNG ATK
-- ==========================================================
function s.atkfilter(c,tp)
	return c:IsFaceup() and c:IsRace(RACE_DRAGON|RACE_WARRIOR) and c:IsControler(tp)
end
function s.atkval(e,c)
	local lg=c:GetLinkedGroup()
	if not lg then return 0 end
	return lg:FilterCount(s.atkfilter,nil,e:GetHandlerPlayer()) * 100
end

-- ==========================================================
-- HIỆU ỨNG BẢO VỆ (KHÔNG THỂ BỊ PHÁ HỦY BỞI HIỆU ỨNG ĐỐI THỦ)
-- ==========================================================
function s.protcon(e)
	local c=e:GetHandler()
	local lg=c:GetLinkedGroup()
	return lg and lg:IsExists(Card.IsControler,1,nil,e:GetHandlerPlayer())
end
function s.indval(e,re,rp)
	return rp == 1 - e:GetHandlerPlayer()
end

-- ==========================================================
-- QUICK EFFECT (TÁCH NHÁNH THEO LƯỢT)
-- ==========================================================
function s.qctg(e,tp,eg,ep,ev,re,r,rp,chk)
	local b1 = (Duel.GetTurnPlayer()==tp and s.fusion_chk(e,tp))
	local b2 = (Duel.GetTurnPlayer()~=tp and s.ritual_chk(e,tp))
	if chk==0 then return b1 or b2 end
	
	if Duel.GetTurnPlayer()==tp then
		e:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON)
		Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
		Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,1,tp,LOCATION_GRAVE)
	else
		e:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TODECK)
		Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_GRAVE)
		Duel.SetOperationInfo(0,CATEGORY_TODECK,nil,1,tp,LOCATION_GRAVE+LOCATION_REMOVED)
	end
end

function s.qcop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetTurnPlayer()==tp then
		s.fusion_op(e,tp)
	else
		s.ritual_op(e,tp)
	end
end

-- ================== LOGIC LƯỢT CỦA BẠN (FUSION) ==================
function s.fmat_filter(c,e)
	-- Thêm c:IsType(TYPE_MONSTER) để chỉ lọc Quái thú làm nguyên liệu Fusion
	return c:IsType(TYPE_MONSTER) and c:IsAbleToRemove() and not c:IsImmuneToEffect(e)
end
function s.spfilter_fusion(c,e,tp,m,f,chkf)
	return c:IsType(TYPE_FUSION) and (c:IsSetCard(0x3b) or c:IsSetCard(0x2a9)) and (not f or f(c))
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_FUSION,tp,false,false) and c:CheckFusionMaterial(m,nil,tp)
end
function s.fusion_chk(e,tp)
	local chkf=tp
	local mg1=Duel.GetMatchingGroup(s.fmat_filter,tp,LOCATION_GRAVE,0,nil,e)
	local res=Duel.IsExistingMatchingCard(s.spfilter_fusion,tp,LOCATION_EXTRA,0,1,nil,e,tp,mg1,nil,chkf)
	if not res then
		local ce=Duel.GetChainMaterial(tp)
		if ce~=nil then
			local fgroup=ce:GetTarget()
			local mg2=fgroup(ce,e,tp)
			local mf=ce:GetValue()
			res=Duel.IsExistingMatchingCard(s.spfilter_fusion,tp,LOCATION_EXTRA,0,1,nil,e,tp,mg2,mf,chkf)
		end
	end
	return res
end
function s.fusion_op(e,tp)
	local chkf=tp
	local mg1=Duel.GetMatchingGroup(s.fmat_filter,tp,LOCATION_GRAVE,0,nil,e)
	local sg1=Duel.GetMatchingGroup(s.spfilter_fusion,tp,LOCATION_EXTRA,0,nil,e,tp,mg1,nil,chkf)
	local mg2=nil
	local sg2=nil
	local ce=Duel.GetChainMaterial(tp)
	if ce~=nil then
		local fgroup=ce:GetTarget()
		mg2=fgroup(ce,e,tp)
		local mf=ce:GetValue()
		sg2=Duel.GetMatchingGroup(s.spfilter_fusion,tp,LOCATION_EXTRA,0,nil,e,tp,mg2,mf,chkf)
	end
	if #sg1>0 or (sg2~=nil and #sg2>0) then
		local sg=sg1:Clone()
		if sg2 then sg:Merge(sg2) end
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local tg=sg:Select(tp,1,1,nil)
		local tc=tg:GetFirst()
		if sg1:IsContains(tc) and (sg2==nil or not sg2:IsContains(tc) or not Duel.SelectYesNo(tp,ce:GetDescription())) then
			local mat1=Duel.SelectFusionMaterial(tp,tc,mg1,nil,chkf)
			tc:SetMaterial(mat1)
			Duel.Remove(mat1,POS_FACEUP,REASON_EFFECT+REASON_MATERIAL+REASON_FUSION)
			Duel.BreakEffect()
			Duel.SpecialSummon(tc,SUMMON_TYPE_FUSION,tp,tp,false,false,POS_FACEUP)
		else
			local mat2=Duel.SelectFusionMaterial(tp,tc,mg2,nil,chkf)
			local fop=ce:GetOperation()
			fop(ce,e,tp,tc,mat2)
		end
		tc:CompleteProcedure()
	end
end

-- ================= LOGIC LƯỢT ĐỐI THỦ (RITUAL) ==================
function s.ritual_mat_filter(c)
	return c:IsType(TYPE_MONSTER) and c:IsAbleToDeck() and (c:IsLocation(LOCATION_GRAVE) or c:IsFaceup())
end
function s.rit_filter(c,e,tp,mg)
	if not c:IsType(TYPE_RITUAL) or not c:IsAttribute(ATTRIBUTE_FIRE|ATTRIBUTE_DARK) then return false end
	if not c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_RITUAL,tp,false,true) then return false end
	local m=mg:Filter(Card.IsAbleToDeck,c) 
	if #m==0 then return false end
	Duel.SetSelectedCard(Group.CreateGroup())
	return m:CheckWithSumGreater(Card.GetRitualLevel,c:GetLevel(),c)
end
function s.ritual_chk(e,tp)
	local mg=Duel.GetMatchingGroup(s.ritual_mat_filter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,nil)
	return Duel.IsExistingMatchingCard(s.rit_filter,tp,LOCATION_HAND+LOCATION_GRAVE,0,1,nil,e,tp,mg)
end
function s.ritual_op(e,tp)
	local mg=Duel.GetMatchingGroup(s.ritual_mat_filter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,nil)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local tg=Duel.SelectMatchingCard(tp,s.rit_filter,tp,LOCATION_HAND+LOCATION_GRAVE,0,1,1,nil,e,tp,mg)
	local tc=tg:GetFirst()
	if tc then
		local m=mg:Filter(Card.IsAbleToDeck,tc)
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
		Duel.SetSelectedCard(Group.CreateGroup())
		local mat=m:SelectWithSumGreater(tp,Card.GetRitualLevel,tc:GetLevel(),tc)
		tc:SetMaterial(mat)
		Duel.SendtoDeck(mat,nil,SEQ_DECKSHUFFLE,REASON_EFFECT+REASON_MATERIAL+REASON_RITUAL)
		Duel.BreakEffect()
		Duel.SpecialSummon(tc,SUMMON_TYPE_RITUAL,tp,tp,false,true,POS_FACEUP)
		tc:CompleteProcedure()
	end
end
