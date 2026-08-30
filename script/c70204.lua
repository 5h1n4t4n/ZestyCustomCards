--Flower Spirit-Ghost of Memories
local s,id=GetID()

function s.initial_effect(c)
	--Synchro Summon: 1 Tuner + 1 or more non-Tuner monsters
	--NOTE: the "including a 'Flower Spirit' monster" clause is a text restriction on
	--material choice that is not strictly enforced by this procedure (the material
	--selection UI will not filter for it). Please double-check this manually while
	--testing until a stricter group-level check is added.
	aux.AddSynchroProcedure(c,aux.TRUE,aux.TRUE,1,99)
	--If this card is Synchro Summoned: shuffle all cards in both GYs into the Deck, then
	--each player sends cards from the top of their Deck to the GY equal to the number
	--of cards shuffled into the Deck by this effect
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SYNCHRO_SUMMON)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCondition(s.sscon)
	e1:SetTarget(s.sstg)
	e1:SetOperation(s.ssop)
	c:RegisterEffect(e1)
	--Once per Chain, when a Spell Card is activated and sent to the GY: banish that card
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_CHAINING)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCondition(s.spcon)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)
	--(Quick Effect): When a card or effect is activated: return 3 banished Spell Cards to
	--the Deck, including 2 "Flower Spirit" Spells; negate that effect
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,id+1)
	e3:SetCost(s.negcost)
	e3:SetTarget(s.negtg)
	e3:SetOperation(s.negop)
	c:RegisterEffect(e3)
end

--If Synchro Summoned: shuffle both GYs into the Deck, mill the top of each Deck to the GY
function s.sscon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsContains(e:GetHandler())
end
function s.sstg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
end
function s.ssop(e,tp,eg,ep,ev,re,r,rp)
	local g1=Duel.GetFieldGroup(tp,LOCATION_GRAVE,0)
	local g2=Duel.GetFieldGroup(1-tp,LOCATION_GRAVE,0)
	local c1,c2=g1:GetCount(),g2:GetCount()
	if c1>0 then Duel.SendtoDeck(g1,nil,SEQ_DECKSHUFFLE,REASON_EFFECT) end
	if c2>0 then Duel.SendtoDeck(g2,nil,SEQ_DECKSHUFFLE,REASON_EFFECT) end
	if c1>0 then Duel.DiscardDeck(tp,c1,REASON_EFFECT) end
	if c2>0 then Duel.DiscardDeck(1-tp,c2,REASON_EFFECT) end
end

--Once per Chain: when a Spell Card is activated and sent to the GY, banish it
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	local rc=re:GetHandler()
	if not rc or rc:GetType()&TYPE_SPELL~=TYPE_SPELL then return false end
	if not rc:IsLocation(LOCATION_GRAVE) then return false end
	return e:GetHandler():GetFlagEffect(id)==0
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return re:GetHandler():IsAbleToRemoveAsCost() end
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,re:GetHandler(),1,0,0)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	c:RegisterFlagEffect(id,RESET_CHAIN,0,1)
	local rc=re:GetHandler()
	if rc:IsRelateToEffect(re) and rc:IsAbleToRemoveAsCost() then
		Duel.Remove(rc,POS_FACEUP,REASON_EFFECT)
	end
end

--Quick Effect: return 3 banished Spells (incl. 2 "Flower Spirit" Spells) to the Deck; negate
function s.remfilter(c)
	return c:IsType(TYPE_SPELL) and c:IsAbleToDeckAsCost()
end
function s.spiritremfilter(c)
	return c:IsSetCard(0x702) and c:IsType(TYPE_SPELL) and c:IsAbleToDeckAsCost()
end
function s.negcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.spiritremfilter,tp,LOCATION_REMOVED,0,2,nil)
			and Duel.GetMatchingGroupCount(s.remfilter,tp,LOCATION_REMOVED,0,nil)>=3
	end
	local g1=Duel.SelectMatchingCard(tp,s.spiritremfilter,tp,LOCATION_REMOVED,0,2,2,nil)
	local g2=Duel.SelectMatchingCard(tp,s.remfilter,tp,LOCATION_REMOVED,0,1,1,g1)
	g1:Merge(g2)
	Duel.SendtoDeck(g1,nil,SEQ_DECKSHUFFLE,REASON_COST)
end
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsChainNegatable(ev) end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,nil,0,0,0)
end
function s.negop(e,tp,eg,ep,ev,re,r,rp)
	Duel.NegateEffect(ev)
end
