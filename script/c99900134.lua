-- Sun Quan - Imperial Sovereign of the East
local s,id=GetID()
local ID_SUN_QUAN_MAIN = 99900133 -- ID Sun Quan (Main Deck)

function s.initial_effect(c)
	c:EnableReviveLimit()
	-- XYZ SUMMON PROCEDURE (2 Level 4 Mecha Three Kingdom HOẶC đè lên Sun Quan Main Deck)
	Xyz.AddProcedure(c, aux.FilterBoolFunction(Card.IsSetCard,0xb4c), 4, 2, s.ovfilter, aux.Stringid(id,0))

	-- (1) If XYZ Summon: SS 2 from Deck (Once per turn)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,1))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.spcon)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	-- (2) Replacement Effect: Detach ALL (Once per turn, Quick Effect)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,2))
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_CHAINING)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,id+100)
	e2:SetCondition(s.repcon)
	e2:SetCost(s.repcost)
	e2:SetOperation(s.repop)
	c:RegisterEffect(e2)

	-- (3) Attach Continuous Spell/Trap you control (Once per turn)
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,3))
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,id+200)
	e3:SetTarget(s.att_tg)
	e3:SetOperation(s.att_op)
	c:RegisterEffect(e3)
end

s.listed_series={0xb4c}
s.listed_names={ID_SUN_QUAN_MAIN}

-- =============================================
-- XYZ ĐÈ FILTER
-- =============================================
function s.ovfilter(c,tp,xyzc)
	return c:IsFaceup() and c:IsCode(ID_SUN_QUAN_MAIN)
end

-- =============================================
-- (1) XYZ Summon -> SS 2 từ Deck
-- =============================================
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_XYZ)
end

function s.tgfilter(c)
	return c:IsSetCard(0xb4c) and c:IsType(TYPE_MONSTER) and c:GetLevel()>0
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return false end
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>=2
			and not Duel.IsPlayerAffectedByEffect(tp,CARD_BLUEEYES_SPIRIT)
			and Duel.IsExistingTarget(s.tgfilter,tp,LOCATION_HAND+LOCATION_GRAVE,0,2,nil)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	Duel.SelectTarget(tp,s.tgfilter,tp,LOCATION_HAND+LOCATION_GRAVE,0,2,2,nil)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,2,tp,LOCATION_DECK)
end

function s.spfilter(c,e,tp,lvs)
	return c:IsSetCard(0xb4c) and c:IsType(TYPE_MONSTER) and c:IsLevel(lvs)
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<2 or Duel.IsPlayerAffectedByEffect(tp,CARD_BLUEEYES_SPIRIT) then return end
	local g=Duel.GetChainInfo(0,CHAININFO_TARGET_CARDS):Filter(Card.IsRelateToEffect,nil,e)
	if #g<2 then return end

	local lvs={}
	for tc in aux.Next(g) do
		table.insert(lvs, tc:GetLevel())
	end

	local sg1=Duel.GetMatchingGroup(s.spfilter,tp,LOCATION_DECK,0,nil,e,tp,lvs[1])
	local sg2=Duel.GetMatchingGroup(s.spfilter,tp,LOCATION_DECK,0,nil,e,tp,lvs[2])

	if #sg1==0 or #sg2==0 then return end

	local summon_group=Group.CreateGroup()
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local tc1=sg1:Select(tp,1,1,nil):GetFirst()
	if not tc1 then return end
	summon_group:AddCard(tc1)

	sg2:RemoveCard(tc1)
	if #sg2==0 then return end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local tc2=sg2:Select(tp,1,1,nil):GetFirst()
	if not tc2 then return end
	summon_group:AddCard(tc2)

	for tc in aux.Next(summon_group) do
		if Duel.SpecialSummonStep(tc,0,tp,tp,false,false,POS_FACEUP) then
			local ne1=Effect.CreateEffect(e:GetHandler())
			ne1:SetType(EFFECT_TYPE_SINGLE)
			ne1:SetCode(EFFECT_DISABLE)
			ne1:SetReset(RESET_EVENT+RESETS_STANDARD)
			tc:RegisterEffect(ne1)
			local ne2=ne1:Clone()
			ne2:SetCode(EFFECT_DISABLE_EFFECT)
			tc:RegisterEffect(ne2)
		end
	end
	Duel.SpecialSummonComplete()
end

-- =============================================
-- (2) Quick Effect: Đổi Operation của Effect Destroy
-- =============================================
function s.repcon(e,tp,eg,ep,ev,re,r,rp)
	if not Duel.IsChainDisablable(ev) then return false end
	local ex=Duel.GetOperationInfo(ev,CATEGORY_DESTROY)
	return ex
end

function s.repcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:GetOverlayCount()>0 end
	c:RemoveOverlayCard(tp,c:GetOverlayCount(),c:GetOverlayCount(),REASON_COST)
end

function s.repop(e,tp,eg,ep,ev,re,r,rp)
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CHANGE_CHAIN_OPERATION)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e1:SetLabel(ev)
	e1:SetLabelObject(e:GetHandler())
	e1:SetValue(s.opchange)
	e1:SetReset(RESET_CHAIN)
	Duel.RegisterEffect(e1,tp)
end

function s.opchange(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetLabelObject()
	if not c then return end
	local owner=c:GetControler()
	local g=Duel.GetMatchingGroup(nil,owner,LOCATION_ONFIELD,0,nil)
	if #g>0 then
		Duel.Hint(HINT_SELECTMSG,owner,HINTMSG_DESTROY)
		local sg=g:Select(owner,1,1,nil)
		Duel.Destroy(sg,REASON_EFFECT)
	end
end

-- =============================================
-- (3) Attach Continuous Spell/Trap
-- =============================================
function s.att_filter(c)
	return c:IsFaceup()
		and c:IsType(TYPE_CONTINUOUS)
		and c:IsType(TYPE_SPELL+TYPE_TRAP)
		and c:IsCanOverlay()
end

function s.att_tg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsControler(tp) and chkc:IsLocation(LOCATION_ONFIELD) and s.att_filter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.att_filter,tp,LOCATION_ONFIELD,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_XMATERIAL)
	Duel.SelectTarget(tp,s.att_filter,tp,LOCATION_ONFIELD,0,1,1,nil)
end

function s.att_op(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if tc and c:IsRelateToEffect(e) and tc:IsRelateToEffect(e) and not tc:IsImmuneToEffect(e) then
		Duel.Overlay(c,tc)
	end
end