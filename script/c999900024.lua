-- Endstage: Walpurgisnacht the Magica Puella Witch
-- ID: 999900024
local s,id=GetID()

local SET_MAGICA			 = 0x654
local SET_PUELLA_WITCH	 = 0x1654

local CARD_LAST_GRACE	   = 999900004
local CARD_SYMPHONIC_CADENZA = 999900011
local CARD_TIRO_FINALE	 = 999900016
local CARD_HOMURA_MAHOU   = 999900020

s.listed_series={SET_MAGICA, SET_PUELLA_WITCH}
s.listed_names={
	CARD_LAST_GRACE, CARD_SYMPHONIC_CADENZA, CARD_TIRO_FINALE, CARD_HOMURA_MAHOU,
	999900002, -- Madoka The Magica Mahou Shoujo
	999900009, -- Sayaka The Magica Mahou Shoujo
	999900014  -- Mami The Magica Mahou Shoujo
}

function s.initial_effect(c)
	-- Điều kiện triệu hồi Link: 3 quái thú "Magica" (bao gồm ít nhất 1 Ritual hoặc Witch)
	c:EnableReviveLimit()
	Link.AddProcedure(c, s.matfilter, 3, 3, s.lcheck)

	-- Phải được Link Summon trước, hoặc Special Summon bằng hiệu ứng của Homura Mahou Shoujo
	local e0=Effect.CreateEffect(c)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetCode(EFFECT_SPSUMMON_CONDITION)
	e0:SetValue(s.splimit)
	c:RegisterEffect(e0)

	-- 1. Khi Special Summon: Gửi lá này xuống GY -> Target tối đa 3 quái thú "Magica" Level 4 dưới GY -> Special Summon
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOGRAVE+CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCost(s.spcost)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	-- 2. Dưới GY (1 Turn 1 Lần): Xáo lá này + 3 Normal Spell "Magica" vào Deck -> Trả 1 lá về Deck (hoặc kích hoạt 1 Spell từ Deck)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TODECK)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,id)
	e2:SetCost(s.gycost)
	e2:SetTarget(s.gytg)
	e2:SetOperation(s.gyop)
	c:RegisterEffect(e2)
end

--------------------------------------------------------------------------------
-- LINK MATERIAL & SPECIAL SUMMON CONDITION
--------------------------------------------------------------------------------
function s.matfilter(c,lc,sumtype,tp)
	return c:IsSetCard(SET_MAGICA,lc,sumtype,tp)
end

function s.reqfilter(c,lc,sumtype,tp)
	return c:IsType(TYPE_RITUAL,lc,sumtype,tp) or c:IsSetCard(SET_PUELLA_WITCH,lc,sumtype,tp)
end

function s.lcheck(g,lc,sumtype,tp)
	return g:IsExists(s.reqfilter,1,nil,lc,sumtype,tp)
end

function s.splimit(e,se,sp,st)
	return ((st&SUMMON_TYPE_LINK)==SUMMON_TYPE_LINK) or (se and se:GetHandler():IsCode(CARD_HOMURA_MAHOU))
end

--------------------------------------------------------------------------------
-- 1. SPECIAL SUMMON EFFECT LOGIC
--------------------------------------------------------------------------------
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsAbleToGraveAsCost() end
	Duel.SendtoGrave(c,REASON_COST)
end

function s.spfilter(c,e,tp)
	return c:IsLevel(4) and c:IsSetCard(SET_MAGICA) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	local c=e:GetHandler()
	if chkc then return chkc:IsLocation(LOCATION_GRAVE) and chkc:IsControler(tp) and s.spfilter(chkc,e,tp) end
	if chk==0 then
		return Duel.GetMZoneCount(tp,c)>0
			and Duel.IsExistingTarget(s.spfilter,tp,LOCATION_GRAVE,0,1,nil,e,tp)
	end
	local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
	local max=math.min(3,ft)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectTarget(tp,s.spfilter,tp,LOCATION_GRAVE,0,1,max,nil,e,tp)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,g,#g,0,0)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
	if ft<=0 then return end
	local g=Duel.GetChainInfo(0,CHAININFO_TARGET_CARDS):Filter(Card.IsRelateToEffect,nil,e)
	if #g==0 then return end
	if #g>ft then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		g=g:Select(tp,ft,ft,nil)
	end
	Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
end

--------------------------------------------------------------------------------
-- 2. GY EFFECT LOGIC
--------------------------------------------------------------------------------
function s.nspellfilter(c)
	return c:IsSetCard(SET_MAGICA) and c:GetType()==TYPE_SPELL and c:IsAbleToDeckAsCost()
end

function s.gycost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		return c:IsAbleToDeckAsCost()
			and Duel.IsExistingMatchingCard(s.nspellfilter,tp,LOCATION_GRAVE,0,3,c)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	local g=Duel.SelectMatchingCard(tp,s.nspellfilter,tp,LOCATION_GRAVE,0,3,3,c)
	
	local is_combo = g:IsExists(Card.IsCode,1,nil,CARD_LAST_GRACE)
				 and g:IsExists(Card.IsCode,1,nil,CARD_TIRO_FINALE)
				 and g:IsExists(Card.IsCode,1,nil,CARD_SYMPHONIC_CADENZA)
	
	e:SetLabel(is_combo and 1 or 0)
	
	g:AddCard(c)
	Duel.SendtoDeck(g,nil,SEQ_DECKSHUFFLE,REASON_COST)
end

function s.gytg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(Card.IsAbleToDeck,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_TODECK,nil,1,0,LOCATION_ONFIELD)
end

function s.actspellfilter(c,e,tp)
	return c:IsCode(CARD_LAST_GRACE, CARD_TIRO_FINALE, CARD_SYMPHONIC_CADENZA)
end

function s.mahoufilter(c)
	return c:IsFaceup() and c:IsCode(999900002, 999900009, 999900014, CARD_HOMURA_MAHOU)
end

function s.gyop(e,tp,eg,ep,ev,re,r,rp)
	local is_combo=(e:GetLabel()==1)
	local can_act=is_combo 
		and Duel.GetLocationCount(tp,LOCATION_SZONE)>0 
		and Duel.IsExistingMatchingCard(s.actspellfilter,tp,LOCATION_DECK,0,1,nil,e,tp)
	
	if can_act and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RESOLVECARD)
		local g=Duel.SelectMatchingCard(tp,s.actspellfilter,tp,LOCATION_DECK,0,1,1,nil,e,tp)
		local tc=g:GetFirst()
		if tc then
			local has_mahou=Duel.IsExistingMatchingCard(s.mahoufilter,tp,LOCATION_MZONE,0,1,nil)
			
			Duel.MoveToField(tc,tp,tp,LOCATION_SZONE,POS_FACEUP,true)
			local te=tc:GetActivateEffect()
			
			-- Nếu có quái "Magica Mahou Shoujo" trên sân: Kháng Negate + Cấm đối thủ Chain
			if has_mahou then
				local e1=Effect.CreateEffect(e:GetHandler())
				e1:SetType(EFFECT_TYPE_FIELD)
				e1:SetCode(EFFECT_CANNOT_INACTIVATE)
				e1:SetValue(s.effectfilter)
				e1:SetReset(RESET_CHAIN)
				Duel.RegisterEffect(e1,tp)
				
				local e2=Effect.CreateEffect(e:GetHandler())
				e2:SetType(EFFECT_TYPE_FIELD)
				e2:SetCode(EFFECT_CANNOT_DISEFFECT)
				e2:SetValue(s.effectfilter)
				e2:SetReset(RESET_CHAIN)
				Duel.RegisterEffect(e2,tp)
				
				Duel.SetChainLimit(s.chainlm)
			end
			
			local tg=te:GetTarget()
			local op=te:GetOperation()
			tc:CreateEffectRelation(te)
			if tg then tg(te,tp,eg,ep,ev,re,r,rp,1) end
			if op then op(te,tp,eg,ep,ev,re,r,rp) end
			tc:ReleaseEffectRelation(te)
			
			Duel.SendtoGrave(tc,REASON_EFFECT)
		end
	else
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
		local sg=Duel.SelectMatchingCard(tp,Card.IsAbleToDeck,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,1,nil)
		if #sg>0 then
			Duel.HintSelection(sg)
			Duel.SendtoDeck(sg,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
		end
	end
end

function s.effectfilter(e,ct)
	return true
end

function s.chainlm(e,rp,tp)
	return tp==rp
end