--Flower Spirit-Friendships
local s,id=GetID()
local FLOWER_TOKEN_ID=70213

function s.initial_effect(c)
	--When this card is activated: send any number of "Flower Spirit" cards with different
	--names from your Deck to the GY
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
	--Once per turn: banish any number of Spell Cards from your GY; Special Summon 1
	--"Flower Spirit Token", then Special Summon this card as a Normal Monster
	--(Spellcaster/DARK/Level 1/Tuner/ATK 0/DEF 0) that is also treated as a Continuous
	--Spell Card
	--NOTE: turning a Spell Card into a monster (and keeping it as a Spell Card at the
	--same time) is a very unusual mechanic. This is a best-effort approximation using
	--temporary type/race/attribute/level-granting effects; please test carefully.
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_SZONE)
	e2:SetCountLimit(1,id)
	e2:SetCost(s.tkcost)
	e2:SetTarget(s.tktg)
	e2:SetOperation(s.tkop)
	c:RegisterEffect(e2)
end

function s.deckfilter(c)
	return c:IsSetCard(0x702)
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	if Duel.IsExistingMatchingCard(s.deckfilter,tp,LOCATION_DECK,0,1,nil) then
		local g=Duel.SelectMatchingCard(tp,s.deckfilter,tp,LOCATION_DECK,0,1,99,nil)
		if g:GetCount()>0 then
			Duel.SendtoGrave(g,REASON_EFFECT)
		end
	end
end

function s.spfilter(c)
	return c:IsType(TYPE_SPELL) and c:IsAbleToRemoveAsCost()
end
function s.tkcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_GRAVE,0,1,nil) end
	local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_GRAVE,0,1,99,nil)
	Duel.Remove(g,POS_FACEUP,REASON_COST)
	e:SetLabel(g:GetCount())
end
function s.tktg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
end
function s.tkop(e,tp,eg,ep,ev,re,r,rp)
	local ct=e:GetLabel()
	if ct<=0 then ct=1 end
	if Duel.GetLocationCount(tp,LOCATION_MZONE)>0 then
		local tk=Duel.CreateToken(tp,FLOWER_TOKEN_ID)
		Duel.SpecialSummon(tk,0,tp,tp,true,false,POS_FACEUP)
		if tk:IsRelateToEffect(e) and ct>1 then
			local le=Effect.CreateEffect(e:GetHandler())
			le:SetType(EFFECT_TYPE_SINGLE)
			le:SetCode(EFFECT_UPDATE_LEVEL)
			le:SetValue(ct-1)
			le:SetReset(RESET_EVENT+0x1fe0000)
			tk:RegisterEffect(le)
		end
	end
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) and c:IsLocation(LOCATION_SZONE) and Duel.GetLocationCount(tp,LOCATION_MZONE)>0 then
		Duel.MoveToField(c,tp,tp,LOCATION_MZONE,POS_FACEUP_ATTACK,true)
		local le1=Effect.CreateEffect(c)
		le1:SetType(EFFECT_TYPE_SINGLE)
		le1:SetCode(EFFECT_ADD_TYPE)
		le1:SetValue(TYPE_MONSTER+TYPE_NORMAL+TYPE_TUNER)
		le1:SetReset(RESET_EVENT+0x1fe0000)
		c:RegisterEffect(le1)
		local le2=le1:Clone()
		le2:SetCode(EFFECT_CHANGE_RACE)
		le2:SetValue(RACE_SPELLCASTER)
		c:RegisterEffect(le2)
		local le3=le1:Clone()
		le3:SetCode(EFFECT_CHANGE_ATTRIBUTE)
		le3:SetValue(ATTRIBUTE_DARK)
		c:RegisterEffect(le3)
		local le4=le1:Clone()
		le4:SetCode(EFFECT_UPDATE_LEVEL)
		le4:SetValue(1)
		c:RegisterEffect(le4)
	end
end
