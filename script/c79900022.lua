-- ============================================================
-- Card Name: Snivy, The Snake Eye
-- Passcode : 079900022
-- Type     : Monster / Effect
-- Attribute: EARTH
-- Level    : 4
-- ATK/DEF  : 0 / 0
-- Race     : Plant
-- Archetype: Snake Eye (0x205)
-- ============================================================
-- Effect 1 : If you control a Plant monster, you can Special
--            Summon this card (from your hand).
-- Effect 2 : If Normal or Special Summoned: Add 1
--            "Contrary Fusion" from Deck to hand.
-- Effect 3 : Banish 2 Plant monsters from GY; add 1 Plant
--            monster from Deck to hand.
-- Effect 4 : If this card and "Contrary Fusion" are both in
--            GY: Special Summon this card from GY.
-- (Each effect HOPT)
-- ============================================================

local s,id=GetID()

function s.initial_effect(c)
    -- ============================================================
    -- Effect 1 — Special Summon from hand (inherent)
    -- If you control a Plant monster
    -- ============================================================
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetCode(EFFECT_SPSUMMON_PROC)
    e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
    e1:SetRange(LOCATION_HAND)
    e1:SetCountLimit(1,{id,0})
    e1:SetCondition(s.spcon1)
    c:RegisterEffect(e1)

    -- ============================================================
    -- Effect 2 — Trigger: Add 1 "Contrary Fusion" from Deck
    -- ============================================================
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_SEARCH+CATEGORY_TOHAND)
    e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e2:SetCode(EVENT_SUMMON_SUCCESS)
    e2:SetCountLimit(1,{id,1})
    e2:SetTarget(s.schtg)
    e2:SetOperation(s.schop)
    c:RegisterEffect(e2)
    -- Also trigger on Special Summon
    local e2b=Effect.CreateEffect(c)
    e2b:SetDescription(aux.Stringid(id,1))
    e2b:SetCategory(CATEGORY_SEARCH+CATEGORY_TOHAND)
    e2b:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e2b:SetCode(EVENT_SPSUMMON_SUCCESS)
    e2b:SetCountLimit(1,{id,1})
    e2b:SetTarget(s.schtg)
    e2b:SetOperation(s.schop)
    c:RegisterEffect(e2b)

    -- ============================================================
    -- Effect 3 — Ignition: Banish 2 Plant from GY;
    -- add 1 Plant monster from Deck
    -- ============================================================
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,2))
    e3:SetCategory(CATEGORY_SEARCH+CATEGORY_TOHAND)
    e3:SetType(EFFECT_TYPE_IGNITION)
    e3:SetRange(LOCATION_MZONE)
    e3:SetCountLimit(1,{id,2})
    e3:SetCost(s.banishcost)
    e3:SetTarget(s.addtg)
    e3:SetOperation(s.addop)
    c:RegisterEffect(e3)

    -- ============================================================
    -- Effect 4 — Ignition from GY: If "Contrary Fusion" is also
    -- in GY, Special Summon this card
    -- ============================================================
    local e4=Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id,3))
    e4:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e4:SetType(EFFECT_TYPE_IGNITION)
    e4:SetRange(LOCATION_GRAVE)
    e4:SetCountLimit(1,{id,3})
    e4:SetCondition(s.spcon4)
    e4:SetTarget(s.sptg4)
    e4:SetOperation(s.spop4)
    c:RegisterEffect(e4)
end

s.listed_names={79900020}

-- ============================================================
-- Effect 1 Condition — You control a Plant monster
-- ============================================================
function s.plantfilter(c)
    return c:IsFaceup() and c:IsRace(RACE_PLANT)
end

function s.spcon1(e,c)
    if c==nil then return true end
    return Duel.GetLocationCount(c:GetControler(),LOCATION_MZONE)>0
        and Duel.IsExistingMatchingCard(s.plantfilter,
        c:GetControler(),LOCATION_MZONE,0,1,nil)
end

-- ============================================================
-- Effect 2 Filter — "Contrary Fusion" in Deck
-- ============================================================
function s.schfilter(c)
    return c:IsCode(79900020) and c:IsAbleToHand()
end

-- ============================================================
-- Effect 2 Target — Check if "Contrary Fusion" exists in Deck
-- ============================================================
function s.schtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.IsExistingMatchingCard(s.schfilter,tp,
            LOCATION_DECK,0,1,nil)
    end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,
        LOCATION_DECK)
end

-- ============================================================
-- Effect 2 Operation — Add "Contrary Fusion" to hand
-- ============================================================
function s.schop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if not c:IsRelateToEffect(e) then return end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectMatchingCard(tp,s.schfilter,tp,
        LOCATION_DECK,0,1,1,nil)
    if #g>0 then
        Duel.SendtoHand(g,nil,REASON_EFFECT)
        Duel.ConfirmCards(1-tp,g)
    end
end

-- ============================================================
-- Effect 3 Cost — Banish 2 Plant monsters from your GY
-- ============================================================
function s.banfilter(c)
    return c:IsRace(RACE_PLANT) and c:IsAbleToRemoveAsCost()
end

function s.banishcost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.IsExistingMatchingCard(s.banfilter,tp,
            LOCATION_GRAVE,0,2,nil)
    end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
    local g=Duel.SelectMatchingCard(tp,s.banfilter,tp,
        LOCATION_GRAVE,0,2,2,nil)
    Duel.Remove(g,POS_FACEUP,REASON_COST)
end

-- ============================================================
-- Effect 3 Target — Check for Plant monster in Deck
-- ============================================================
function s.addfilter(c)
    return c:IsRace(RACE_PLANT) and c:IsMonster()
        and c:IsAbleToHand()
end

function s.addtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.IsExistingMatchingCard(s.addfilter,tp,
            LOCATION_DECK,0,1,nil)
    end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,
        LOCATION_DECK)
end

-- ============================================================
-- Effect 3 Operation — Add 1 Plant monster from Deck
-- ============================================================
function s.addop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectMatchingCard(tp,s.addfilter,tp,
        LOCATION_DECK,0,1,1,nil)
    if #g>0 then
        Duel.SendtoHand(g,nil,REASON_EFFECT)
        Duel.ConfirmCards(1-tp,g)
        Duel.ShuffleDeck(tp)
    end
end

-- ============================================================
-- Effect 4 Condition — "Contrary Fusion" is in your GY
-- ============================================================
function s.cffilter(c)
    return c:IsCode(79900020)
end

function s.spcon4(e,tp,eg,ep,ev,re,r,rp)
    return Duel.IsExistingMatchingCard(s.cffilter,tp,
        LOCATION_GRAVE,0,1,nil)
end

-- ============================================================
-- Effect 4 Target — Can Special Summon this card from GY
-- ============================================================
function s.sptg4(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
            and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,
            false,false)
    end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,
        e:GetHandler(),1,0,0)
end

-- ============================================================
-- Effect 4 Operation — Special Summon this card from GY
-- ============================================================
function s.spop4(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if c:IsRelateToEffect(e) then
        Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
    end
end
