-- The Mechanical Singularity
local s,id=GetID()
s.listed_series={0xb4c}

function s.initial_effect(c)
	-- Activate: Fusion Summon
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON+CATEGORY_REMOVE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1, id)
	e1:SetTarget(s.fustg)
	e1:SetOperation(s.fusop)
	c:RegisterEffect(e1)

	-- Grave Effect: Add to hand or Set
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1, {id, 1}) -- Đổi sang {id, 1} để tránh trùng ID bài khác
	e2:SetCondition(s.reccon)
	e2:SetTarget(s.rectg)
	e2:SetOperation(s.recop)
	c:RegisterEffect(e2)
end

function s.deckcheck(tp)
	-- Kiểm tra xem có quái Level/Rank 12 trên sân không để mở khóa Deck Fusion
	return Duel.IsExistingMatchingCard(function(c)
		return c:IsFaceup() and c:IsSetCard(0xb4c) and (c:IsLevel(12) or c:IsRank(12))
	end,tp,LOCATION_MZONE,0,1,nil)
end

function s.matfilter(c)
	return c:IsType(TYPE_MONSTER) and c:IsAbleToRemove() and c:IsCanBeFusionMaterial() and c:IsSetCard(0xb4c)
end

function s.fusfilter(c,e,tp,m,f,chkf)
	return c:IsType(TYPE_FUSION) and c:IsSetCard(0xb4c) and (not f or f(c))
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_FUSION,tp,false,false)
		and c:CheckFusionMaterial(m,nil,chkf)
end

function s.fustg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		local chkf=tp
		local loc=LOCATION_GRAVE
		if s.deckcheck(tp) then loc=loc+LOCATION_DECK end
		
		local mg=Duel.GetMatchingGroup(s.matfilter,tp,loc,0,nil)
		if #mg==0 then return false end

		return Duel.GetLocationCountFromEx(tp,tp,nil,TYPE_FUSION)>0
			and Duel.IsExistingMatchingCard(s.fusfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp,mg,nil,chkf)
	end
	local loc=LOCATION_GRAVE
	if s.deckcheck(tp) then loc=loc+LOCATION_DECK end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,1,tp,loc)
end

function s.fusop(e,tp,eg,ep,ev,re,r,rp)
	local chkf=tp
	local loc=LOCATION_GRAVE
	if s.deckcheck(tp) then loc=loc+LOCATION_DECK end
	
	local mg=Duel.GetMatchingGroup(aux.NecroValleyFilter(s.matfilter),tp,loc,0,nil)
	local sg1=Duel.GetMatchingGroup(s.fusfilter,tp,LOCATION_EXTRA,0,nil,e,tp,mg,nil,chkf)
	
	if #sg1>0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local tg=sg1:Select(tp,1,1,nil)
		local tc=tg:GetFirst()
		
		-- Dùng API chuẩn của EDOPro để chọn nguyên liệu (Xử lý mượt từ 2 đến 99 lá)
		local mat=Duel.SelectFusionMaterial(tp,tc,mg,nil,chkf)
		if #mat>0 then
			tc:SetMaterial(mat)
			Duel.Remove(mat,POS_FACEUP,REASON_EFFECT+REASON_MATERIAL+REASON_FUSION)
			Duel.BreakEffect()
			Duel.SpecialSummon(tc,SUMMON_TYPE_FUSION,tp,tp,false,false,POS_FACEUP)
			tc:CompleteProcedure()
		end
	end
end

--------------------------------------------------------------------------------
-- GRAVE RECOVERY LOGIC
--------------------------------------------------------------------------------
function s.confilter(c)
	return c:IsFaceup() and c:IsSetCard(0xb4c) and c:IsType(TYPE_FUSION)
end

function s.reccon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(s.confilter,tp,LOCATION_MZONE,0,1,nil)
end

function s.rectg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsAbleToHand() or c:IsSSetable() end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,c,1,0,0)
end

function s.recop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	local b1=c:IsAbleToHand()
	local b2=c:IsSSetable()
	local op=0
	if b1 and b2 then
		op=Duel.SelectOption(tp,1190,1153)
	elseif b1 then op=0
	elseif b2 then op=1
	else return end
	
	if op==0 then
		Duel.SendtoHand(c,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,c)
	else
		Duel.SSet(tp,c)
	end
end