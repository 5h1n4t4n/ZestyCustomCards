-- ============================================================
-- Card Name: Icejade Ran Tremora
-- Passcode : 36600004
-- Type     : Monster / Tuner / Effect (Aqua / WATER / Lv 7)
-- Archetype: Icejade (0x16e)
-- ============================================================
-- Effect 1: If this card is added to your hand, except by
--           drawing it: You can Special Summon this card.
-- Effect 2: If this card is Normal or Special Summoned: You can
--           send 1 "Icejade" monster from your Deck to the GY,
--           and if you do, Special Summon 1 "Icejade Token"
--           (Aqua/WATER/Level 3/ATK 0/DEF 0).
-- Effect 3: If a face-up WATER monster(s) you control leave the
--           field by your opponent's card while this card is in
--           your GY: You can Special Summon this card.
-- Reference: c90241276 (Snake-Eyes Poplar) for the "added to
--            hand, except by drawing" trigger; c18494511
--            (Icejade Ran Aegirine) for the "Icejade Token";
--            c55151012 (Icejade Tremora) for the previous-state
--            WATER check; c10698416 (Krawler Ranvier) for the
--            "by your opponent's card" reason.
-- ============================================================

local s,id=GetID()
local ICEJADE_TOKEN=18494512

function s.initial_effect(c)
    -- ============================================================
    -- Effect 1 — Added to hand (not drawn): Special Summon itself
    -- ============================================================
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e1:SetProperty(EFFECT_FLAG_DELAY)
    e1:SetCode(EVENT_TO_HAND)
    e1:SetCountLimit(1,id)
    e1:SetCondition(function(e) return not e:GetHandler():IsReason(REASON_DRAW) end)
    e1:SetTarget(s.sptg)
    e1:SetOperation(s.spop)
    c:RegisterEffect(e1)

    -- ============================================================
    -- Effect 2 — On Summon: mill 1 "Icejade", then make a Token
    -- ============================================================
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_TOGRAVE+CATEGORY_SPECIAL_SUMMON+CATEGORY_TOKEN)
    e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e2:SetProperty(EFFECT_FLAG_DELAY)
    e2:SetCode(EVENT_SUMMON_SUCCESS)
    e2:SetCountLimit(1,{id,1})
    e2:SetTarget(s.tgtg)
    e2:SetOperation(s.tgop)
    c:RegisterEffect(e2)
    local e3=e2:Clone()
    e3:SetCode(EVENT_SPSUMMON_SUCCESS)
    c:RegisterEffect(e3)

    -- ============================================================
    -- Effect 3 — Revive from the GY when the opponent removes WATER
    -- ============================================================
    local e4=Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id,2))
    e4:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e4:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_DAMAGE_STEP)
    e4:SetCode(EVENT_LEAVE_FIELD)
    e4:SetRange(LOCATION_GRAVE)
    e4:SetCountLimit(1,{id,2})
    e4:SetCondition(s.revcon)
    e4:SetTarget(s.sptg)
    e4:SetOperation(s.spop)
    c:RegisterEffect(e4)
end

s.listed_series={SET_ICEJADE}
s.listed_names={ICEJADE_TOKEN}

-- ============================================================
-- Effects 1 & 3 share the self Special Summon
-- ============================================================
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and c:IsCanBeSpecialSummoned(e,0,tp,false,false) end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if c:IsRelateToEffect(e) then
        Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
    end
end

-- ============================================================
-- Effect 2: Mill first; the Token only follows a completed mill
-- ============================================================
function s.tgfilter(c)
    return c:IsSetCard(SET_ICEJADE) and c:IsMonster() and c:IsAbleToGrave()
end

function s.tgtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.tgfilter,tp,LOCATION_DECK,0,1,nil) end
    Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_DECK)
    Duel.SetPossibleOperationInfo(0,CATEGORY_TOKEN,nil,1,tp,0)
    Duel.SetPossibleOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,0)
end

function s.tgop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
    local g=Duel.SelectMatchingCard(tp,s.tgfilter,tp,LOCATION_DECK,0,1,1,nil)
    if #g==0 or Duel.SendtoGrave(g,REASON_EFFECT)==0 then return end
    if not g:GetFirst():IsLocation(LOCATION_GRAVE) then return end
    local cantoken=Duel.IsPlayerCanSpecialSummonMonster(tp,ICEJADE_TOKEN,SET_ICEJADE,TYPES_TOKEN,
        0,0,3,RACE_AQUA,ATTRIBUTE_WATER)
    if Duel.GetLocationCount(tp,LOCATION_MZONE)>0 and cantoken then
        local token=Duel.CreateToken(tp,ICEJADE_TOKEN)
        Duel.SpecialSummon(token,0,tp,tp,false,false,POS_FACEUP)
    end
end

-- ============================================================
-- Effect 3: A face-up WATER monster you controlled left the field
--           because of a card your opponent used. This card has to
--           be in the GY beforehand, so it never counts itself.
-- ============================================================
function s.revconfilter(c,tp)
    return c:IsPreviousControler(tp) and c:IsPreviousLocation(LOCATION_MZONE)
        and c:IsPreviousPosition(POS_FACEUP)
        and (c:GetPreviousAttributeOnField()&ATTRIBUTE_WATER)==ATTRIBUTE_WATER
        and c:IsReason(REASON_EFFECT) and c:GetReasonPlayer()==1-tp
end

function s.revcon(e,tp,eg,ep,ev,re,r,rp)
    return not eg:IsContains(e:GetHandler()) and eg:IsExists(s.revconfilter,1,nil,tp)
end
