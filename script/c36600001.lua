-- ============================================================
-- Card Name: Icejade Awakening
-- Passcode : 36600001
-- Type     : Spell / Quick-Play
-- Archetype: Icejade (0x16e)
-- ============================================================
-- Effect 1: Add 1 Level 4 or lower Aqua monster from your Deck
--           to your hand. If your opponent controls more
--           monsters than you do, you can Special Summon it
--           instead. Hard once per turn.
-- Reference: c7142724 (Icejade Cenote Enion Cradle) for the
--           OATH-style hard once per turn on an activation.
-- ============================================================

local s,id=GetID()

function s.initial_effect(c)
    -- ============================================================
    -- Effect 1 — Activate: search, or Special Summon when behind
    -- ============================================================
    local e1=Effect.CreateEffect(c)
    e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)      -- "You can only use 1 ... once per turn"
    e1:SetTarget(s.target)
    e1:SetOperation(s.activate)
    c:RegisterEffect(e1)
end

-- ============================================================
-- Filters — the same Deck pool, judged for hand vs field
-- ============================================================
function s.thfilter(c)
    return c:IsRace(RACE_AQUA) and c:IsLevelBelow(4) and c:IsAbleToHand()
end

function s.spfilter(c,e,tp)
    return c:IsRace(RACE_AQUA) and c:IsLevelBelow(4)
        and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

-- "If your opponent controls more monsters than you do"
function s.behind(tp)
    return Duel.GetFieldGroupCount(tp,0,LOCATION_MZONE)>Duel.GetFieldGroupCount(tp,LOCATION_MZONE,0)
end

-- Special Summon branch is only offered when the board state allows it
function s.spmode(e,tp)
    return s.behind(tp) and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_DECK,0,1,nil,e,tp)
end

-- ============================================================
-- Effect 1: Target — either branch alone makes the activation legal
-- ============================================================
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) or s.spmode(e,tp)
    end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
    Duel.SetPossibleOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK)
end

-- ============================================================
-- Effect 1: Operation — board state is re-checked at resolution
-- ============================================================
function s.activate(e,tp,eg,ep,ev,re,r,rp)
    if s.spmode(e,tp) and Duel.SelectYesNo(tp,aux.Stringid(id,0)) then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
        local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_DECK,0,1,1,nil,e,tp)
        if #g>0 then
            Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
        end
    else
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
        local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
        if #g>0 then
            Duel.SendtoHand(g,nil,REASON_EFFECT)
            Duel.ConfirmCards(1-tp,g)
        end
    end
end
