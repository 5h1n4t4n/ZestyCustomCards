-- ============================================================
-- Card Name: Knight of the Ashened City
-- Passcode : 42100002
-- Type     : Monster / Effect
-- Attribute: DARK
-- Level    : 5
-- ATK/DEF  : 2000 / 1500
-- Race     : Pyro
-- Archetype: Ashened (0x1a5)
-- ============================================================
-- Effect 1: Special Summon from hand if "Obsidim, the Ashened City"
--           is in Field Zone.
-- Effect 2: If Summoned: Immediately Fusion Summon 1 Pyro Fusion
--           Monster using materials from hand, Deck, or field.
-- Effect 3: If used as Fusion material and sent to GY/banished:
--           Add 1 "Ashened" or "Veidos" card from Deck/GY to hand.
-- You can only use each effect of "Knight of the Ashened City" once per turn.
-- ============================================================

local s,id=GetID()
Duel.LoadScript("constants.lua")

function s.initial_effect(c)
	-- Special Summon this card (from your hand)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetCondition(s.selfspcon)
	c:RegisterEffect(e1)

	-- Fusion Summon 1 Pyro Fusion Monster
	local params = {
		fusfilter = aux.FilterBoolFunction(Card.IsRace, RACE_PYRO),
		extrafil = s.fextra,
		extratg = s.extratg
	}
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON+CATEGORY_TOGRAVE)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_SUMMON_SUCCESS)
	e2:SetCountLimit(1,{id,1})
	e2:SetTarget(Fusion.SummonEffTG(params))
	e2:SetOperation(Fusion.SummonEffOP(params))
	c:RegisterEffect(e2)
	local e2b=e2:Clone()
	e2b:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e2b)
	local e2c=e2:Clone()
	e2c:SetCode(EVENT_FLIP_SUMMON_SUCCESS)
	c:RegisterEffect(e2c)

	-- Search 1 "Ashened" or "Veidos" card if used as Fusion material
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_BE_MATERIAL)
	e3:SetCountLimit(1,{id,2})
	e3:SetCondition(s.matcon)
	e3:SetTarget(s.mattg)
	e3:SetOperation(s.matop)
	c:RegisterEffect(e3)
end

s.listed_names={CARD_OBSIDIM_ASHENED_CITY,id}
s.listed_series={SET_ASHENED,SET_VEIDOS}

function s.selfspcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsCode,CARD_OBSIDIM_ASHENED_CITY),
			0,LOCATION_FZONE,LOCATION_FZONE,1,nil)
end

function s.fextra(e,tp,mg)
	return Duel.GetMatchingGroup(Fusion.IsMonsterFilter(Card.IsAbleToGrave),tp,LOCATION_DECK,0,nil)
end

function s.extratg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,0,tp,LOCATION_HAND|LOCATION_MZONE|LOCATION_DECK)
end

function s.matcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsLocation(LOCATION_GRAVE+LOCATION_REMOVED) and (r&REASON_FUSION)~=0
end

function s.thfilter(c)
	return (c:IsSetCard(SET_ASHENED) or c:IsSetCard(SET_VEIDOS) or c:IsCode(78783557,30453613,8540986))
		and c:IsAbleToHand()
end

function s.mattg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
end

function s.matop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.thfilter),tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end
