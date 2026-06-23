-- ============================================================
-- Card Name: Serperior, The Snake Eye Emperor
-- Passcode : 79900021
-- Type     : Monster / Fusion / Effect
-- Attribute: EARTH
-- Level    : 8
-- ATK/DEF  : 0 / 3000
-- Race     : Plant
-- Archetype: N/A
-- Materials: 2 Plant monsters
-- ============================================================
-- Effect 1a: While Fusion Summoned and on field: All monsters
--            you control become Plant-Type.
-- Effect 1b: Neither player can Special Summon more than
--            once per turn.
-- Effect 2 : While you control another Plant monster: Negate
--            opponent's effects that would negate.
-- Effect 3 : (Quick Effect, twice/turn) When opponent
--            activates a card effect: send 1 Plant from field
--            to GY or banish 1 Plant from GY face-down;
--            destroy 1 face-up card on the field.
-- ============================================================

local s,id=GetID()

function s.initial_effect(c)
    Duel.EnableGlobalFlag(GLOBALFLAG_SPSUMMON_COUNT)
    c:EnableReviveLimit()

    -- ============================================================
    -- Fusion Procedure — 2 Plant monsters
    -- ============================================================
    Fusion.AddProcFunRep(c,s.mfilter,2,false)

    -- ============================================================
    -- Summon Restriction — Must be Fusion Summoned by
    -- "Contrary Fusion" (ID: 79900020)
    -- ============================================================
    local e0=Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE_SINGLE)
    e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE
        +EFFECT_FLAG_UNCOPYABLE)
    e0:SetCode(EFFECT_SPSUMMON_CONDITION)
    e0:SetValue(s.splimit)
    c:RegisterEffect(e0)

    -- ============================================================
    -- Effect 1a — Continuous: All your monsters become Plant
    -- (Only while this card is Fusion Summoned and face-up)
    -- ============================================================
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetCode(EFFECT_CHANGE_RACE)
    e1:SetRange(LOCATION_MZONE)
    e1:SetTargetRange(LOCATION_MZONE,0)
    e1:SetCondition(s.fuscon)
    e1:SetTarget(s.racetg)
    e1:SetValue(RACE_PLANT)
    c:RegisterEffect(e1)

    -- ============================================================
    -- Effect 1b — Continuous: Neither player can Special Summon
    -- more than once per turn
    -- ============================================================
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_FIELD)
    e2:SetCode(EFFECT_SPSUMMON_COUNT_LIMIT)
    e2:SetRange(LOCATION_MZONE)
    e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
    e2:SetTargetRange(1,1)
    e2:SetCondition(s.fuscon)
    e2:SetValue(1)
    c:RegisterEffect(e2)

    -- ============================================================
    -- Effect 2 — Continuous: Negate opponent's effects that
    -- have CATEGORY_NEGATE or CATEGORY_DISABLE (effects that would negate)
    -- ============================================================
    local e3=Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
    e3:SetCode(EVENT_CHAIN_SOLVING)
    e3:SetRange(LOCATION_MZONE)
    e3:SetCondition(s.negcon)
    e3:SetOperation(s.negop)
    c:RegisterEffect(e3)

    -- ============================================================
    -- Effect 3 — Quick Effect: When opponent activates effect,
    -- send 1 Plant from field/banish 1 Plant from GY face-down;
    -- destroy 1 face-up card on the field. Twice per turn.
    -- ============================================================
    local e4=Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id,0))
    e4:SetCategory(CATEGORY_DESTROY)
    e4:SetType(EFFECT_TYPE_QUICK_O)
    e4:SetCode(EVENT_CHAINING)
    e4:SetRange(LOCATION_MZONE)
    e4:SetCountLimit(2,id)
    e4:SetCondition(s.descon)
    e4:SetCost(s.descost)
    e4:SetTarget(s.destg)
    e4:SetOperation(s.desop)
    c:RegisterEffect(e4)
end

s.listed_names={79900020}

-- ============================================================
-- Fusion Material filter — Plant monsters
-- ============================================================
function s.mfilter(c)
    return c:IsRace(RACE_PLANT)
end

-- ============================================================
-- Summon restriction — Must be Fusion Summoned
-- (cannot be revived unless properly Fusion Summoned first)
-- Only allows Fusion Summon via the effect of Contrary Fusion
-- ============================================================
function s.splimit(e,se,sp,st,tp)
    return st&SUMMON_TYPE_FUSION==SUMMON_TYPE_FUSION and se and se:GetHandler():IsCode(79900020)
end

-- ============================================================
-- Condition — This card was Fusion Summoned
-- ============================================================
function s.fuscon(e)
    return e:GetHandler():IsSummonType(SUMMON_TYPE_FUSION)
end

-- ============================================================
-- Effect 1a target — All your other monsters
-- ============================================================
function s.racetg(e,c)
    return c~=e:GetHandler()
end

-- ============================================================
-- Effect 2 Condition — Opponent's chain with CATEGORY_NEGATE or CATEGORY_DISABLE,
-- you must control another Plant monster
-- ============================================================
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
    if not e:GetHandler():IsFaceup() then return false end
    -- Must control another Plant monster
    if not Duel.IsExistingMatchingCard(s.otherplantfilter,tp,
        LOCATION_MZONE,0,1,e:GetHandler()) then return false end
    -- Current chain is opponent's and has CATEGORY_NEGATE or CATEGORY_DISABLE
    return rp~=tp and (re:IsHasCategory(CATEGORY_NEGATE) or re:IsHasCategory(CATEGORY_DISABLE))
end

function s.otherplantfilter(c)
    return c:IsFaceup() and c:IsRace(RACE_PLANT)
end

-- ============================================================
-- Effect 2 Operation — Negate that effect
-- ============================================================
function s.negop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_CARD,0,id)
    Duel.NegateEffect(ev)
end

-- ============================================================
-- Effect 3 Condition — Opponent activates a card effect,
-- you must control another Plant monster
-- ============================================================
function s.descon(e,tp,eg,ep,ev,re,r,rp)
    if not Duel.IsExistingMatchingCard(s.otherplantfilter,tp,
        LOCATION_MZONE,0,1,e:GetHandler()) then return false end
    return rp~=tp and re:IsActiveType(TYPE_MONSTER
        +TYPE_SPELL+TYPE_TRAP)
end

-- ============================================================
-- Effect 3 Cost — Send 1 face-up Plant from field to GY
-- OR banish 1 Plant monster from your GY face-down
-- ============================================================
function s.sendfilter(c)
    return c:IsFaceup() and c:IsRace(RACE_PLANT)
        and c:IsAbleToGrave()
end

function s.banfilter(c)
    return c:IsRace(RACE_PLANT) and c:IsAbleToRemove()
end

function s.descost(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then
        return Duel.IsExistingMatchingCard(s.sendfilter,tp,
            LOCATION_MZONE,LOCATION_MZONE,1,nil)
            or Duel.IsExistingMatchingCard(s.banfilter,tp,
            LOCATION_GRAVE,0,1,nil)
    end
    -- Let player choose: send from field or banish from GY
    local canSend=Duel.IsExistingMatchingCard(s.sendfilter,tp,
        LOCATION_MZONE,LOCATION_MZONE,1,nil)
    local canBanish=Duel.IsExistingMatchingCard(s.banfilter,tp,
        LOCATION_GRAVE,0,1,nil)
    local op=0
    if canSend and canBanish then
        op=Duel.SelectOption(tp,
            aux.Stringid(id,0),aux.Stringid(id,0))
    elseif canSend then
        op=0
    else
        op=1
    end
    if op==0 then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
        local g=Duel.SelectMatchingCard(tp,s.sendfilter,tp,
            LOCATION_MZONE,LOCATION_MZONE,1,1,nil)
        Duel.SendtoGrave(g,REASON_COST)
    else
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
        local g=Duel.SelectMatchingCard(tp,s.banfilter,tp,
            LOCATION_GRAVE,0,1,1,nil)
        Duel.Remove(g,POS_FACEDOWN,REASON_COST)
    end
end

-- ============================================================
-- Effect 3 Target — Destroy 1 face-up card on the field
-- ============================================================
function s.desfilter(c)
    return c:IsFaceup() and c:IsDestructable()
end

function s.destg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then
        return chkc:IsOnField() and s.desfilter(chkc)
    end
    if chk==0 then
        return Duel.IsExistingTarget(s.desfilter,tp,
            LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil)
    end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
    local g=Duel.SelectTarget(tp,s.desfilter,tp,
        LOCATION_ONFIELD,LOCATION_ONFIELD,1,1,nil)
    Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
end

-- ============================================================
-- Effect 3 Operation — Destroy the targeted card
-- ============================================================
function s.desop(e,tp,eg,ep,ev,re,r,rp)
    local tc=Duel.GetFirstTarget()
    if tc and tc:IsRelateToEffect(e) then
        Duel.Destroy(tc,REASON_EFFECT)
    end
end
