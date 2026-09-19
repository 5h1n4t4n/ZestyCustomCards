-- Harpie's Pet Feather Storm Dragon
local s,id=GetID()
function s.initial_effect(c)
	-- Xyz Summon Procedure: 2+ Level 7 WIND monsters
	c:EnableReviveLimit()
	if Xyz and Xyz.AddProcedure then
		Xyz.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsAttribute,ATTRIBUTE_WIND),7,2,Xyz.infiniteMats)
	else
		aux.AddXyzProcedure(c,aux.FilterBoolFunction(Card.IsAttribute,ATTRIBUTE_WIND),7,2,nil,nil,Xyz.infiniteMats)
	end
	
	-- Attach cards from field and/or GYs on Xyz Summon
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.atchcon)
	e1:SetTarget(s.atchtg)
	e1:SetOperation(s.atchop)
	c:RegisterEffect(e1)
	
	-- Quick Effect: Target equal cards in each player's field, detach and return to hand
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_MZONE)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E+TIMING_MAIN_END)
	e2:SetCountLimit(1,id+100)
	e2:SetTarget(s.rthtg)
	e2:SetOperation(s.rthop)
	c:RegisterEffect(e2)
	
	-- End Phase: Attach 1 "Harpie" or "Hysteric" card from Deck or GY
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_PHASE+PHASE_END)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,id+200)
	e3:SetTarget(s.endtg)
	e3:SetOperation(s.endop)
	c:RegisterEffect(e3)
end

function s.atchcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_XYZ)
end
function s.atchfilter(c)
	return not c:IsType(TYPE_TOKEN)
end
function s.atchtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	local ct=c:GetOverlayCount()
	if chk==0 then return ct>0 
		and Duel.IsExistingMatchingCard(s.atchfilter,tp,LOCATION_ONFIELD+LOCATION_GRAVE,LOCATION_ONFIELD+LOCATION_GRAVE,1,c) end
	Duel.SetOperationInfo(0,CATEGORY_LEAVE_GRAVE,nil,1,PLAYER_EITHER,LOCATION_GRAVE)
end
function s.atchop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) or c:IsFacedown() then return end
	local ct=c:GetOverlayCount()
	if ct<=0 then return end
	local g=Duel.GetMatchingGroup(s.atchfilter,tp,LOCATION_ONFIELD+LOCATION_GRAVE,LOCATION_ONFIELD+LOCATION_GRAVE,c)
	if #g==0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_XMATERIAL)
	local sg=g:Select(tp,1,ct,nil)
	if #sg>0 then
		Duel.Overlay(c,sg)
	end
end

function s.rthfilter(c)
	return c:IsAbleToHand()
end
function s.rthtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	local c=e:GetHandler()
	local mat_ct=c:GetOverlayCount()
	if chk==0 then
		if mat_ct<=0 then return false end
		local g1=Duel.GetMatchingGroup(Card.IsCanBeEffectTarget,tp,LOCATION_ONFIELD,0,nil,e)
		local g2=Duel.GetMatchingGroup(Card.IsCanBeEffectTarget,tp,0,LOCATION_ONFIELD,nil,e)
		return #g1>0 and #g2>0
	end
	local g1=Duel.GetMatchingGroup(Card.IsCanBeEffectTarget,tp,LOCATION_ONFIELD,0,nil,e)
	local g2=Duel.GetMatchingGroup(Card.IsCanBeEffectTarget,tp,0,LOCATION_ONFIELD,nil,e)
	local max_ct=math.min(#g1,#g2,mat_ct)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RTOHAND)
	local sg1=g1:Select(tp,1,max_ct,nil)
	local sel_ct=#sg1
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RTOHAND)
	local sg2=g2:Select(tp,sel_ct,sel_ct,nil)
	sg1:Merge(sg2)
	Duel.SetTargetCard(sg1)
	e:SetLabel(sel_ct)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,sg1,#sg1,0,0)
end
function s.rthop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local sel_ct=e:GetLabel()
	local tg=Duel.GetTargetCards(e)
	if c:IsRelateToEffect(e) and c:CheckRemoveOverlayCard(tp,sel_ct,REASON_EFFECT) then
		if c:RemoveOverlayCard(tp,sel_ct,sel_ct,REASON_EFFECT)>0 and #tg>0 then
			Duel.SendtoHand(tg,nil,REASON_EFFECT)
		end
	end
end

function s.matfilter2(c)
	return (c:IsSetCard(0x64) or c:IsSetCard(0x2076) or c:IsCode(77778835,56840658,75142032,75142033,75142034,75142035))
		and not c:IsType(TYPE_TOKEN)
end
function s.endtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.matfilter2,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_LEAVE_GRAVE,nil,1,tp,LOCATION_GRAVE)
end
function s.endop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) or c:IsFacedown() then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_XMATERIAL)
	local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.matfilter2),tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil)
	if #g>0 then
		Duel.Overlay(c,g)
	end
end
