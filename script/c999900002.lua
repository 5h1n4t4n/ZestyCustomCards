-- Madoka the Magica Mahou Shoujo
-- ID: 999900002
local s,id=GetID()

local SET_MAGICA		  = 0x654
local CARD_MADOKA_STUDENT = 999900001
local CARD_MADOKA_DIVINE  = 999900003

s.listed_series={SET_MAGICA}
s.listed_names={CARD_MADOKA_STUDENT, CARD_MADOKA_DIVINE}

function s.initial_effect(c)
	c:EnableReviveLimit()
	
	-- Điều kiện Triệu hồi: Bắt buộc phải bằng hiệu ứng của "Madoka Kaname the Magica Student"
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_SPSUMMON_CONDITION)
	e0:SetValue(s.splimit)
	c:RegisterEffect(e0)

	-- 1. Reveal trên tay -> Search "Magica" Spell & Kích hoạt (Chỉ 1 lần/Duel)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_DUEL)
	e1:SetCondition(s.eff1con)
	e1:SetCost(s.eff1cost)
	e1:SetTarget(s.eff1tg)
	e1:SetOperation(s.eff1op)
	c:RegisterEffect(e1)

	-- 2. Quick Effect: Trục xuất úp 1 lá -> Xyz Summon "Madoka the Magica Divine" (HOPT)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_REMOVE+CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,id+100)
	e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E+TIMING_MAIN_END)
	e2:SetTarget(s.eff2tg)
	e2:SetOperation(s.eff2op)
	c:RegisterEffect(e2)
end

--------------------------------------------------------------------------------
-- SUMMON CONDITION
--------------------------------------------------------------------------------
function s.splimit(e,se,sp,st)
	return se and se:GetHandler():IsCode(CARD_MADOKA_STUDENT)
end

--------------------------------------------------------------------------------
-- EFFECT 1: REVEAL IN HAND -> SEARCH & ACTIVATE SPELL (ONCE PER DUEL)
--------------------------------------------------------------------------------
function s.eff1con(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetTurnPlayer()==tp
end

function s.eff1cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return not e:GetHandler():IsPublic() end
	Duel.ConfirmCards(1-tp,e:GetHandler())
	Duel.ShuffleHand(tp)
end

function s.thfilter(c)
	return c:IsSetCard(SET_MAGICA) and c:IsType(TYPE_SPELL) and c:IsAbleToHand()
end

function s.studentfilter(c)
	return c:IsFaceup() and c:IsCode(CARD_MADOKA_STUDENT)
end

function s.chainlm(re,rp,tp)
	return false
end

function s.eff1tg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
	
	-- Khóa Chain nếu có "Madoka Kaname the Magica Student" trên sân
	if Duel.IsExistingMatchingCard(s.studentfilter,tp,LOCATION_ONFIELD,0,1,nil) then
		Duel.SetChainLimit(s.chainlm)
	end
end

function s.eff1op(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 and Duel.SendtoHand(g,nil,REASON_EFFECT)>0 then
		Duel.ConfirmCards(1-tp,g)
		local tc=g:GetFirst()
		if tc:IsLocation(LOCATION_HAND) then
			local te=tc:GetActivateEffect()
			if te and te:IsActivatable(tp,true,true) and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
				Duel.BreakEffect()
				-- Xác định vị trí đặt card (FZONE nếu là Field Spell, SZONE nếu là các loại Spell khác)
				local loc = tc:IsType(TYPE_FIELD) and LOCATION_FZONE or LOCATION_SZONE
				
				Duel.MoveToField(tc,tp,tp,loc,POS_FACEUP,true)
				local tg=te:GetTarget()
				local op=te:GetOperation()
				tc:CreateEffectRelation(te)
				if tg then tg(te,tp,eg,ep,ev,re,r,rp,1) end
				if op then op(te,tp,eg,ep,ev,re,r,rp) end
				tc:ReleaseEffectRelation(te)
			end
		end
	end
end

--------------------------------------------------------------------------------
-- EFFECT 2: BANISH FACE-DOWN & XYZ SUMMON
--------------------------------------------------------------------------------
function s.rmfilter(c,tp)
	return c:IsAbleToRemove(tp,POS_FACEDOWN)
end

function s.xyzfilter(c,e,tp,mc)
	return c:IsCode(CARD_MADOKA_DIVINE) and c:IsType(TYPE_XYZ) 
		and Duel.GetLocationCountFromEx(tp,tp,mc,c)>0
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_XYZ,tp,false,false)
end

function s.eff2tg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	local c=e:GetHandler()
	if chkc then return chkc:IsOnField() and s.rmfilter(chkc,tp) end
	if chk==0 then 
		return Duel.IsExistingTarget(s.rmfilter,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil,tp)
			and Duel.IsExistingMatchingCard(s.xyzfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp,c)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectTarget(tp,s.rmfilter,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,1,nil,tp)
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,g,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

function s.eff2op(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) and Duel.Remove(tc,POS_FACEDOWN,REASON_EFFECT)>0 then
		if c:IsRelateToEffect(e) and c:IsFaceup() and not c:IsImmuneToEffect(e) then
			local xyzg=Duel.GetMatchingGroup(s.xyzfilter,tp,LOCATION_EXTRA,0,nil,e,tp,c)
			if #xyzg>0 then
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
				local xyz=xyzg:Select(tp,1,1,nil):GetFirst()
				if xyz then
					Duel.BreakEffect()
					local mg=c:GetOverlayGroup()
					if #mg>0 then
						Duel.Overlay(xyz,mg)
					end
					xyz:SetMaterial(Group.FromCards(c))
					Duel.Overlay(xyz,Group.FromCards(c))
					if Duel.SpecialSummon(xyz,SUMMON_TYPE_XYZ,tp,tp,false,false,POS_FACEUP)>0 then
						xyz:CompleteProcedure()
					end
				end
			end
		end
	end
end