-- Rising Fusion
-- ID: 888700013
local s,id=GetID()

local SET_RISING_HERO = 0xff8
local SET_HERO		= 0x8
local SET_FUSION	  = 0x46

s.listed_series={SET_RISING_HERO, SET_HERO, SET_FUSION}

function s.initial_effect(c)
	-- Kích hoạt hiệu ứng Phép Tốc Độ Nhanh (Quick-Play Fusion)
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON+CATEGORY_REMOVE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetHintTiming(0,TIMING_ATTACK+TIMINGS_CHECK_MONSTER_E)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

--------------------------------------------------------------------------------
-- FUSION LOGIC
--------------------------------------------------------------------------------
function s.mfilter_grave(c)
	return c:IsType(TYPE_MONSTER) and c:IsCanBeFusionMaterial() and c:IsAbleToRemove()
end

-- Lọc quái HERO thông thường (chỉ dùng nguyên liệu từ Tay/Sân)
function s.ffilter1(c,e,tp,m,f,chkf)
	return c:IsType(TYPE_FUSION) and c:IsSetCard(SET_HERO)
		and (not f or f(c))
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_FUSION,tp,false,false)
		and c:CheckFusionMaterial(m,nil,chkf)
end

-- Lọc quái "Rising HERO" (có thể dùng thêm nguyên liệu từ Mộ)
function s.ffilter2(c,e,tp,m,f,chkf)
	return c:IsType(TYPE_FUSION) and c:IsSetCard(SET_RISING_HERO)
		and (not f or f(c))
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_FUSION,tp,false,false)
		and c:CheckFusionMaterial(m,nil,chkf)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		local chkf=tp
		local mg1=Duel.GetFusionMaterial(tp):Filter(Card.IsLocation,nil,LOCATION_HAND+LOCATION_ONFIELD)
		local res=Duel.IsExistingMatchingCard(s.ffilter1,tp,LOCATION_EXTRA,0,1,nil,e,tp,mg1,nil,chkf)
		if not res then
			local mg2=Duel.GetMatchingGroup(s.mfilter_grave,tp,LOCATION_GRAVE,0,nil)
			mg2:Merge(mg1)
			res=Duel.IsExistingMatchingCard(s.ffilter2,tp,LOCATION_EXTRA,0,1,nil,e,tp,mg2,nil,chkf)
		end
		return res
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local chkf=tp
	local mg1=Duel.GetFusionMaterial(tp):Filter(Card.IsLocation,nil,LOCATION_HAND+LOCATION_ONFIELD)
	local mg2=Duel.GetMatchingGroup(s.mfilter_grave,tp,LOCATION_GRAVE,0,nil)
	mg2:Merge(mg1)

	local sg1=Duel.GetMatchingGroup(s.ffilter1,tp,LOCATION_EXTRA,0,nil,e,tp,mg1,nil,chkf)
	local sg2=Duel.GetMatchingGroup(s.ffilter2,tp,LOCATION_EXTRA,0,nil,e,tp,mg2,nil,chkf)
	sg1:Merge(sg2)

	if #sg1>0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local tc=sg1:Select(tp,1,1,nil):GetFirst()
		if tc then
			local mg=mg1
			if tc:IsSetCard(SET_RISING_HERO) then
				mg=mg2
			end
			local mat=Duel.SelectFusionMaterial(tp,tc,mg,nil,chkf)
			tc:SetMaterial(mat)

			local g_grave=mat:Filter(Card.IsLocation,nil,LOCATION_GRAVE)
			local g_other=mat-g_grave

			if #g_other>0 then
				Duel.SendtoGrave(g_other,REASON_EFFECT+REASON_MATERIAL+REASON_FUSION)
			end
			if #g_grave>0 then
				Duel.Remove(g_grave,POS_FACEUP,REASON_EFFECT+REASON_MATERIAL+REASON_FUSION)
			end

			Duel.BreakEffect()
			Duel.SpecialSummon(tc,SUMMON_TYPE_FUSION,tp,tp,false,false,POS_FACEUP)
			tc:CompleteProcedure()
		end
	end
end