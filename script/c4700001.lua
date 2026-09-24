-- ============================================================
-- Card Name: Permafrost of the Ice Barrier
-- Passcode : 4700001
-- Type     : Spell / Field
-- Archetype: Ice Barrier (0x2f)
-- ============================================================
-- Effect 1: When this card is activated: You can add 1 "Ice Barrier"
--           monster from your GY to your hand.
-- Effect 2: "Ice Barrier" Synchro Monsters you control cannot be
--           destroyed by your opponent's card effects.
-- Effect 3: If a face-up "Ice Barrier" monster(s) you control is
--           Tributed by an opponent's card or effect, or is sent
--           to the GY by an opponent's card effect: You can
--           Special Summon 1 "Ice Barrier" monster from your Deck
--           or GY, then, if that monster was a Synchro Monster,
--           you can banish 1 random card from your opponent's hand.
-- ============================================================

local s,id=GetID()

function s.initial_effect(c)
	-- Effect 1: Activate + optional add 1 "Ice Barrier" monster from GY to hand
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_TOHAND)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)

	-- Effect 2: "Ice Barrier" Synchro Monsters cannot be destroyed by opponent's card effects
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e2:SetRange(LOCATION_FZONE)
	e2:SetTargetRange(LOCATION_MZONE,0)
	e2:SetTarget(s.indtg)
	e2:SetValue(aux.indoval)
	c:RegisterEffect(e2)

	-- Effect 3: Trigger when face-up "Ice Barrier" monster is Tributed by opponent or sent to GY by opponent's effect
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_REMOVE)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_TO_GRAVE)
	e3:SetRange(LOCATION_FZONE)
	e3:SetCondition(s.spcon_tg)
	e3:SetTarget(s.sptg)
	e3:SetOperation(s.spop)
	c:RegisterEffect(e3)
	-- Complementary listener for being Tributed but not sent to GY (e.g. banished by Macro Cosmos)
	local e4=e3:Clone()
	e4:SetCode(EVENT_RELEASE)
	e4:SetCondition(s.spcon_rel)
	c:RegisterEffect(e4)
end

s.listed_series={SET_ICE_BARRIER}

-- ============================================================
-- Effect 1 Logic
-- ============================================================
function s.thfilter(c)
	return c:IsSetCard(SET_ICE_BARRIER) and c:IsMonster() and c:IsAbleToHand()
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetPossibleOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_GRAVE)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	if not e:GetHandler():IsRelateToEffect(e) then return end
	local g=Duel.GetMatchingGroup(aux.NecroValleyFilter(s.thfilter),tp,LOCATION_GRAVE,0,nil)
	if #g>0 and Duel.SelectYesNo(tp,aux.Stringid(id,0)) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local sg=g:Select(tp,1,1,nil)
		Duel.SendtoHand(sg,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,sg)
	end
end

-- ============================================================
-- Effect 2 Logic
-- ============================================================
function s.indtg(e,c)
	return c:IsSetCard(SET_ICE_BARRIER) and c:IsType(TYPE_SYNCHRO)
end

-- ============================================================
-- Effect 3 Logic
-- ============================================================
function s.cfilter_tg(c,tp)
	return c:IsPreviousControler(tp) and c:IsPreviousLocation(LOCATION_MZONE) and c:IsPreviousPosition(POS_FACEUP)
		and c:IsPreviousSetCard(SET_ICE_BARRIER) and c:GetReasonPlayer()==1-tp
		and (c:IsReason(REASON_RELEASE) or c:IsReason(REASON_EFFECT))
end

function s.spcon_tg(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.cfilter_tg,1,nil,tp)
end

function s.cfilter_rel(c,tp)
	return c:IsPreviousControler(tp) and c:IsPreviousLocation(LOCATION_MZONE) and c:IsPreviousPosition(POS_FACEUP)
		and c:IsPreviousSetCard(SET_ICE_BARRIER) and c:GetReasonPlayer()==1-tp
		and not c:IsLocation(LOCATION_GRAVE)
end

function s.spcon_rel(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.cfilter_rel,1,nil,tp)
end

function s.spfilter(c,e,tp)
	return c:IsSetCard(SET_ICE_BARRIER) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_DECK|LOCATION_GRAVE,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK|LOCATION_GRAVE)
	Duel.SetPossibleOperationInfo(0,CATEGORY_REMOVE,nil,1,1-tp,LOCATION_HAND)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.spfilter),tp,LOCATION_DECK|LOCATION_GRAVE,0,1,1,nil,e,tp)
	local tc=g:GetFirst()
	if tc and Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)>0 then
		if tc:IsType(TYPE_SYNCHRO) then
			local hg=Duel.GetMatchingGroup(Card.IsAbleToRemove,tp,0,LOCATION_HAND,nil)
			if #hg>0 and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
				Duel.BreakEffect()
				local sg=hg:RandomSelect(tp,1)
				Duel.Remove(sg,POS_FACEUP,REASON_EFFECT)
			end
		end
	end
end
