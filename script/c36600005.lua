-- ============================================================
-- Card Name: Icejade Regaining Enion Cradle
-- Passcode : 36600005
-- Type     : Spell / Field
-- Archetype: Icejade (0x16e)
-- ============================================================
-- Always treated as "Icejade Cenote Enion Cradle" — handled by
-- alias=7142724 in card-data/c36600005.json, the same way
-- c295517 (A Legendary Ocean) is always treated as "Umi".
-- Effect 1: During the Main Phase: You can Special Summon 1
--           "Icejade" monster from your hand, Deck or GY.
--           Once per turn.
-- Effect 2: Unaffected by other card effects while you control
--           an "Icejade" Synchro Monster.
-- Effect 3: You cannot Special Summon monsters, except WATER.
-- Effect 4: If a monster(s) is Special Summoned, you can:
--           Immediately after this effect resolves, Synchro
--           Summon 1 Synchro Monster, using monsters you control
--           as material, including an "Icejade" monster.
-- Reference: c41371602 (Stand Up Centur-Ion!) for the Synchro
--            Summon with a required material via
--            Synchro.CheckAdditional; c41554273 (Dinomist Rush)
--            for the self "unaffected" shape; c18494511
--            (Icejade Ran Aegirine) for the Special Summon lock.
-- ============================================================

local s,id=GetID()

function s.initial_effect(c)
    -- ============================================================
    -- Activate
    -- ============================================================
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    c:RegisterEffect(e1)

    -- ============================================================
    -- Effect 1 — Main Phase: Special Summon 1 "Icejade" monster
    -- ============================================================
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,0))
    e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e2:SetType(EFFECT_TYPE_IGNITION)
    e2:SetRange(LOCATION_FZONE)
    e2:SetCountLimit(1,id)
    e2:SetTarget(s.sptg)
    e2:SetOperation(s.spop)
    c:RegisterEffect(e2)

    -- ============================================================
    -- Effect 2 — Unaffected while an "Icejade" Synchro is out
    -- ============================================================
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(3100)
    e3:SetType(EFFECT_TYPE_SINGLE)
    e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE+EFFECT_FLAG_CLIENT_HINT)
    e3:SetCode(EFFECT_IMMUNE_EFFECT)
    e3:SetRange(LOCATION_FZONE)
    e3:SetCondition(s.immcon)
    e3:SetValue(s.efilter)
    c:RegisterEffect(e3)

    -- ============================================================
    -- Effect 3 — You can only Special Summon WATER monsters
    -- ============================================================
    local e4=Effect.CreateEffect(c)
    e4:SetType(EFFECT_TYPE_FIELD)
    e4:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
    e4:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
    e4:SetRange(LOCATION_FZONE)
    e4:SetTargetRange(1,0)
    e4:SetTarget(function(e,c) return not c:IsAttribute(ATTRIBUTE_WATER) end)
    c:RegisterEffect(e4)

    -- ============================================================
    -- Effect 4 — After a Special Summon: Synchro Summon using an
    --            "Icejade" monster among the materials
    -- ============================================================
    local e5=Effect.CreateEffect(c)
    e5:SetDescription(aux.Stringid(id,1))
    e5:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e5:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e5:SetProperty(EFFECT_FLAG_DELAY)
    e5:SetCode(EVENT_SPSUMMON_SUCCESS)
    e5:SetRange(LOCATION_FZONE)
    e5:SetTarget(s.syntg)
    e5:SetOperation(s.synop)
    c:RegisterEffect(e5)
end

s.listed_series={SET_ICEJADE}

-- ============================================================
-- Effect 1: Hand, Deck and GY are all valid sources
-- ============================================================
function s.spfilter(c,e,tp)
    return c:IsSetCard(SET_ICEJADE) and c:IsMonster()
        and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

local SP_LOCATIONS=LOCATION_HAND|LOCATION_DECK|LOCATION_GRAVE

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    local filter=aux.NecroValleyFilter(s.spfilter)
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and Duel.IsExistingMatchingCard(filter,tp,SP_LOCATIONS,0,1,nil,e,tp) end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,SP_LOCATIONS)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local filter=aux.NecroValleyFilter(s.spfilter)
    local g=Duel.SelectMatchingCard(tp,filter,tp,SP_LOCATIONS,0,1,1,nil,e,tp)
    if #g>0 then
        Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
    end
end

-- ============================================================
-- Effect 2: Only effects from other cards are shut out
-- ============================================================
function s.immcon(e)
    local tp=e:GetHandlerPlayer()
    return Duel.IsExistingMatchingCard(s.synfilter,tp,LOCATION_MZONE,0,1,nil)
end

function s.synfilter(c)
    return c:IsFaceup() and c:IsSetCard(SET_ICEJADE) and c:IsType(TYPE_SYNCHRO)
end

function s.efilter(e,te)
    return te:GetOwner()~=e:GetOwner()
end

-- ============================================================
-- Effect 4: Materials must include an "Icejade" monster
-- ============================================================
function s.syncheck(tp,sg,sc)
    return sg:IsExists(Card.IsSetCard,1,nil,SET_ICEJADE)
end

function s.syntg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        Synchro.CheckAdditional=s.syncheck
        local res=Duel.IsExistingMatchingCard(Card.IsSynchroSummonable,tp,LOCATION_EXTRA,0,1,nil)
        Synchro.CheckAdditional=nil
        return res
    end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

function s.synop(e,tp,eg,ep,ev,re,r,rp)
    Synchro.CheckAdditional=s.syncheck
    local g=Duel.GetMatchingGroup(Card.IsSynchroSummonable,tp,LOCATION_EXTRA,0,nil)
    if #g>0 then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
        local sg=g:Select(tp,1,1,nil)
        Duel.SynchroSummon(tp,sg:GetFirst())
    else
        Synchro.CheckAdditional=nil
    end
end
