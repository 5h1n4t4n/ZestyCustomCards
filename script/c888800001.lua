-- Era Nova
-- ID: 888800001
local s,id=GetID()

local SET_CHRYSOS_HEIRS = 0xffa

s.listed_series={SET_CHRYSOS_HEIRS}

function s.initial_effect(c)
	-- Activate (Ritual Summon)
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_RELEASE+CATEGORY_TOGRAVE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCost(s.cost)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

--------------------------------------------------------------------------------
-- COST & FILTERS
--------------------------------------------------------------------------------
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckLPCost(tp,1200) end
	Duel.PayLPCost(tp,1200)
end

function s.matfilter(c)
	return c:IsSetCard(SET_CHRYSOS_HEIRS) 
		and c:IsType(TYPE_MONSTER) 
		and not c:IsType(TYPE_XYZ+TYPE_LINK) 
		and c:GetLevel()>0
		and (c:IsReleasable() or (c:IsLocation(LOCATION_DECK) and c:IsAbleToGrave()))
end

function s.ritfilter(c,e,tp,mg)
	if not (c:IsSetCard(SET_CHRYSOS_HEIRS) and c:IsType(TYPE_RITUAL)
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_RITUAL,tp,false,true)) then return false end
	local lv=c:GetLevel()
	return mg:CheckWithSumEqual(Card.GetLevel,lv,1,#mg)
end

--------------------------------------------------------------------------------
-- TARGET & OPERATION LOGIC
--------------------------------------------------------------------------------
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		local matg=Duel.GetMatchingGroup(s.matfilter,tp,LOCATION_DECK+LOCATION_MZONE,0,nil)
		return Duel.IsExistingMatchingCard(s.ritfilter,tp,LOCATION_HAND+LOCATION_GRAVE,0,1,nil,e,tp,matg)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_GRAVE)
	Duel.SetOperationInfo(0,CATEGORY_RELEASE,nil,1,tp,LOCATION_MZONE)
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_DECK)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local matg=Duel.GetMatchingGroup(s.matfilter,tp,LOCATION_DECK+LOCATION_MZONE,0,nil)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local tg=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.ritfilter),tp,LOCATION_HAND+LOCATION_GRAVE,0,1,1,nil,e,tp,matg)
	local tc=tg:GetFirst()
	if tc then
		local lv=tc:GetLevel()
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
		local mat=matg:SelectWithSumEqual(tp,Card.GetLevel,lv,1,#matg)
		tc:SetMaterial(mat)
		
		-- Phân loại nguyên liệu: Sân/Tay vs Deck
		local mat_rg=mat:Filter(Card.IsLocation,nil,LOCATION_HAND+LOCATION_MZONE)
		local mat_dk=mat:Filter(Card.IsLocation,nil,LOCATION_DECK)
		
		if #mat_rg>0 then
			Duel.ReleaseRitualMaterial(mat_rg)
		end
		if #mat_dk>0 then
			-- Ép gắn cờ REASON_RELEASE cho bài từ Deck
			Duel.SendtoGrave(mat_dk,REASON_EFFECT+REASON_MATERIAL+REASON_RITUAL+REASON_RELEASE)
		end
		
		Duel.BreakEffect()
		if Duel.SpecialSummon(tc,SUMMON_TYPE_RITUAL,tp,tp,false,true,POS_FACEUP)>0 then
			tc:CompleteProcedure()
			
			-- Khóa Triệu hồi Ritual quái thú cùng tên cho đến hết lượt
			local e1=Effect.CreateEffect(e:GetHandler())
			e1:SetType(EFFECT_TYPE_FIELD)
			e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
			e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
			e1:SetTargetRange(1,0)
			e1:SetTarget(s.splimit)
			e1:SetLabel(tc:GetCode())
			e1:SetReset(RESET_PHASE+PHASE_END)
			Duel.RegisterEffect(e1,tp)
		end
	end
end

function s.splimit(e,c,sump,sumtype,sumpos,targetp,se)
	return (sumtype&SUMMON_TYPE_RITUAL)==SUMMON_TYPE_RITUAL and c:IsCode(e:GetLabel())
end