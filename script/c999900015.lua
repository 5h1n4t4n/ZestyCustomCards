-- Mami the Magica Puella Witch
-- ID: 999900015
local s,id=GetID()

local SET_MAGICA			   = 0x654
local SET_MAGICA_PUELLA_WITCH  = 0x1654
local SET_SOULGEM			 = 0xc7d
local CARD_MAMI_STUDENT	 = 999900013
local CARD_MAMI_MAHOU		 = 999900014
local CARD_TIRO_FINALE	   = 999900016

s.listed_series={SET_MAGICA, SET_MAGICA_PUELLA_WITCH, SET_SOULGEM}
s.listed_names={CARD_MAMI_STUDENT, CARD_MAMI_MAHOU, CARD_TIRO_FINALE}

function s.initial_effect(c)
	c:EnableReviveLimit()

	-- ĐIỀU KIỆN SUMMON: Bắt buộc gọi bằng hiệu ứng của Mami Tomoe the Magica Mahou Shoujo
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_SPSUMMON_CONDITION)
	e0:SetValue(s.splimit)
	c:RegisterEffect(e0)

	-- 1. Continuous: Bảo vệ bản thân và các quái thú "Magica" không bị phá hủy bởi chiến đấu
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetTargetRange(LOCATION_MZONE,0)
	e1:SetTarget(s.indtg)
	e1:SetValue(1)
	c:RegisterEffect(e1)

	-- 2. Quick Effect: Tăng 3500 ATK/DEF cho toàn bộ quái "Magica" đến hết lượt (HOPT)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_ATKCHANGE+CATEGORY_DEFCHANGE)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_MZONE)
	e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E+TIMING_MAIN_END)
	e2:SetCountLimit(1,id)
	e2:SetTarget(s.atktg)
	e2:SetOperation(s.atkop)
	c:RegisterEffect(e2)

	-- 3. In-hand Effect: Reveal -> Nhận 300 damage -> Search "Magica: TIRO FINALE" (HOPT)
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_DAMAGE+CATEGORY_TOHAND+CATEGORY_SEARCH)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_HAND)
	e3:SetCountLimit(1,id+100)
	e3:SetCost(s.srchcost)
	e3:SetTarget(s.srchtg)
	e3:SetOperation(s.srchop)
	c:RegisterEffect(e3)

	-- 4. Trigger Effect: Khi lá này kích hoạt hiệu ứng -> Thu hồi về tay/ED & Special Summon Mami Student
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,2))
	e4:SetCategory(CATEGORY_TOHAND+CATEGORY_SPECIAL_SUMMON)
	e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e4:SetCode(EVENT_CHAINING)
	e4:SetProperty(EFFECT_FLAG_DELAY)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCountLimit(1,id+200)
	e4:SetCondition(s.thcon)
	e4:SetTarget(s.thtg)
	e4:SetOperation(s.thop)
	c:RegisterEffect(e4)
end

function s.splimit(e,se,sp,st)
	return se and se:GetHandler() and se:GetHandler():IsCode(CARD_MAMI_MAHOU)
end

--------------------------------------------------------------------------------
-- EFFECT 1: BATTLE INDESTRUCTIBILITY
--------------------------------------------------------------------------------
function s.indtg(e,c)
	return c:IsSetCard(SET_MAGICA)
end

--------------------------------------------------------------------------------
-- EFFECT 2: ATK/DEF BOOST
--------------------------------------------------------------------------------
function s.atkfilter(c)
	return c:IsFaceup() and c:IsSetCard(SET_MAGICA)
end

function s.atktg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.atkfilter,tp,LOCATION_MZONE,0,1,nil) end
end

function s.atkop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(s.atkfilter,tp,LOCATION_MZONE,0,nil)
	for tc in aux.Next(g) do
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_ATTACK)
		e1:SetValue(3500)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		tc:RegisterEffect(e1)
		local e2=e1:Clone()
		e2:SetCode(EFFECT_UPDATE_DEFENSE)
		tc:RegisterEffect(e2)
	end
end

--------------------------------------------------------------------------------
-- EFFECT 3: REVEAL IN HAND -> SEARCH TIRO FINALE
--------------------------------------------------------------------------------
function s.srchcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return not c:IsPublic() end
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_PUBLIC)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
	c:RegisterEffect(e1)
end

function s.thfilter(c)
	return c:IsCode(CARD_TIRO_FINALE) and c:IsAbleToHand()
end

function s.srchtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_DAMAGE,nil,0,tp,300)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function s.srchop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.Damage(tp,300,REASON_EFFECT)>0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
		if #g>0 then
			Duel.SendtoHand(g,nil,REASON_EFFECT)
			Duel.ConfirmCards(1-tp,g)
		end
	end
end

--------------------------------------------------------------------------------
-- EFFECT 4: RETURN TO HAND/EXTRA DECK & SPECIAL SUMMON MAMI STUDENT
--------------------------------------------------------------------------------
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	return re:GetHandler()==e:GetHandler() and re~=e
end

function s.spstudentfilter(c,e,tp)
	return c:IsCode(CARD_MAMI_STUDENT) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		return c:IsAbleToHand()
			and Duel.GetMZoneCount(tp,c)>0
			and Duel.IsExistingMatchingCard(s.spstudentfilter,tp,LOCATION_HAND+LOCATION_GRAVE,0,1,nil,e,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,c,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_GRAVE)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) and Duel.SendtoHand(c,nil,REASON_EFFECT)>0 
		and (c:IsLocation(LOCATION_HAND) or c:IsLocation(LOCATION_EXTRA)) then
		if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local g=Duel.SelectMatchingCard(tp,s.spstudentfilter,tp,LOCATION_HAND+LOCATION_GRAVE,0,1,1,nil,e,tp)
		if #g>0 then
			Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
		end
	end
end