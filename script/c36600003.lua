-- ============================================================
-- Card Name: Icejade Creator
-- Passcode : 36600003
-- Type     : Spell / Continuous
-- Archetype: Icejade (0x16e)
-- ============================================================
-- Effect 1: During the Main Phase: You can add 1 "Icejade" card
--           from your Deck to your hand.
-- Effect 2: While "Icejade Cenote Enion Cradle" is on the field,
--           your opponent cannot activate the effects of monsters
--           that were Summoned that turn. (continuous, not a use)
-- Effect 3: If an "Icejade" monster you control leaves the field
--           by your opponent's card: You can Special Summon 1
--           "Icejade" monster from your Deck or banishment.
-- Reference: c83670388 (Icejade Curse) for the activation lock
--            and the Cenote-on-field check; c10698416 (Krawler
--            Ranvier) for the "by your opponent's card" reason.
-- ============================================================

local s,id=GetID()
local ICEJADE_CRADLE=7142724

function s.initial_effect(c)
    -- ============================================================
    -- Activate
    -- ============================================================
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    c:RegisterEffect(e1)

    -- ============================================================
    -- Effect 1 — Main Phase: search 1 "Icejade" card
    -- ============================================================
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,0))
    e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
    e2:SetType(EFFECT_TYPE_IGNITION)
    e2:SetRange(LOCATION_SZONE)
    e2:SetCountLimit(1,id)
    e2:SetTarget(s.thtg)
    e2:SetOperation(s.thop)
    c:RegisterEffect(e2)

    -- ============================================================
    -- Effect 2 — Lock effects of monsters Summoned this turn
    -- ============================================================
    local e3=Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_FIELD)
    e3:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
    e3:SetCode(EFFECT_CANNOT_ACTIVATE)
    e3:SetRange(LOCATION_SZONE)
    e3:SetTargetRange(0,1)
    e3:SetCondition(s.accon)
    e3:SetValue(s.aclimit)
    c:RegisterEffect(e3)

    -- ============================================================
    -- Effect 3 — Recover when the opponent removes an "Icejade"
    -- ============================================================
    local e4=Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id,1))
    e4:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e4:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_DAMAGE_STEP)
    e4:SetCode(EVENT_LEAVE_FIELD)
    e4:SetRange(LOCATION_SZONE)
    e4:SetCountLimit(1,{id,1})
    e4:SetCondition(s.spcon)
    e4:SetTarget(s.sptg)
    e4:SetOperation(s.spop)
    c:RegisterEffect(e4)
end

s.listed_series={SET_ICEJADE}
s.listed_names={ICEJADE_CRADLE}

-- ============================================================
-- Effect 1: Search any "Icejade" card
-- ============================================================
function s.thfilter(c)
    return c:IsSetCard(SET_ICEJADE) and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
    if #g>0 then
        Duel.SendtoHand(g,nil,REASON_EFFECT)
        Duel.ConfirmCards(1-tp,g)
    end
end

-- ============================================================
-- Effect 2: Only while the Cenote is the field card or on field
-- ============================================================
function s.accon(e)
    if Duel.IsEnvironment(ICEJADE_CRADLE) then return true end
    local cradle=aux.FaceupFilter(Card.IsCode,ICEJADE_CRADLE)
    return Duel.IsExistingMatchingCard(cradle,0,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil)
end

function s.aclimit(e,re,tp)
    local rc=re:GetHandler()
    local status=STATUS_SUMMON_TURN+STATUS_FLIP_SUMMON_TURN+STATUS_SPSUMMON_TURN
    return re:IsMonsterEffect() and rc:IsLocation(LOCATION_MZONE) and rc:IsStatus(status)
end

-- ============================================================
-- Effect 3: An "Icejade" monster you controlled left the field
--           because of a card your opponent used
-- ============================================================
function s.spconfilter(c,tp)
    return c:IsPreviousControler(tp) and c:IsPreviousLocation(LOCATION_MZONE)
        and c:IsPreviousSetCard(SET_ICEJADE)
        and c:IsReason(REASON_EFFECT) and c:GetReasonPlayer()==1-tp
end

function s.spcon(e,tp,eg,ep,ev,re,r,rp)
    return eg:IsExists(s.spconfilter,1,nil,tp)
end

-- Face-down banished cards cannot be picked out of the banish pile
function s.spfilter(c,e,tp)
    return c:IsSetCard(SET_ICEJADE) and c:IsMonster()
        and (not c:IsLocation(LOCATION_REMOVED) or c:IsFaceup())
        and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_DECK|LOCATION_REMOVED,0,1,nil,e,tp) end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK|LOCATION_REMOVED)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_DECK|LOCATION_REMOVED,0,1,1,nil,e,tp)
    if #g>0 then
        Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
    end
end
