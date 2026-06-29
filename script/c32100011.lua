-- ============================================================
-- Card Name: Rikka Bloom
-- Passcode  : 32100011
-- Type      : Monster / Effect
-- Attribute : WATER
-- Level     : 2
-- ATK/DEF   : 0 / 0
-- Race      : Plant
-- Archetype : Rikka (0x141)
-- ============================================================
-- Effect 1  : If a card(s) is Tributed: You can SS this card from your hand.
-- Effect 2  : If Normal/Special Summoned: Add 1 Rikka card from Deck, then you can Tribute 1 monster.
-- Effect 3  : During End Phase, if in GY because it was Tributed this turn, or a Rikka Xyz monster was sent to GY: Add to hand.
-- ============================================================

local s,id=GetID()

function s.initial_effect(c)
    -- ============================================================
    -- Effect 1 — Trigger: If a card is Tributed, SS from hand
    -- ============================================================
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e1:SetProperty(EFFECT_FLAG_DELAY)
    e1:SetCode(EVENT_RELEASE)
    e1:SetRange(LOCATION_HAND)
    e1:SetCountLimit(1,id)
    e1:SetTarget(s.sstg)
    e1:SetOperation(s.ssop)
    c:RegisterEffect(e1)

    -- ============================================================
    -- Effect 2 — Trigger: Add 1 Rikka card, then Tribute 1 monster
    -- ============================================================
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_RELEASE)
    e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e2:SetProperty(EFFECT_FLAG_DELAY)
    e2:SetCode(EVENT_SUMMON_SUCCESS)
    e2:SetCountLimit(1,{id,1})
    e2:SetTarget(s.thtg)
    e2:SetOperation(s.thop)
    c:RegisterEffect(e2)
    local e3=e2:Clone()
    e3:SetCode(EVENT_SPSUMMON_SUCCESS)
    c:RegisterEffect(e3)

    -- ============================================================
    -- Effect 3 — Trigger: Add this card to hand during End Phase
    -- ============================================================
    local e4=Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id,2))
    e4:SetCategory(CATEGORY_TOHAND)
    e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e4:SetCode(EVENT_PHASE+PHASE_END)
    e4:SetRange(LOCATION_GRAVE)
    e4:SetCountLimit(1,{id,2})
    e4:SetCondition(s.epcon)
    e4:SetTarget(s.eptg)
    e4:SetOperation(s.epop)
    c:RegisterEffect(e4)

    -- Global check for Rikka Xyz sent to GY
    if not s.global_check then
        s.global_check=true
        local ge1=Effect.CreateEffect(c)
        ge1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
        ge1:SetCode(EVENT_TO_GRAVE)
        ge1:SetOperation(s.checkop)
        Duel.RegisterEffect(ge1,0)
    end
end

-- ============================================================
-- Global check logic for Rikka Xyz sent to GY
-- ============================================================
function s.checkfilter(c)
    return c:IsSetCard(0x141) and c:IsType(TYPE_XYZ)
end
function s.checkop(e,tp,eg,ep,ev,re,r,rp)
    if eg:IsExists(s.checkfilter,1,nil) then
        Duel.RegisterFlagEffect(0,id,RESET_PHASE+PHASE_END,0,1)
        Duel.RegisterFlagEffect(1,id,RESET_PHASE+PHASE_END,0,1)
    end
end

-- ============================================================
-- Effect 1: SS from hand
-- ============================================================
function s.sstg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false) end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
end
function s.ssop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if c:IsRelateToEffect(e) then
        Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
    end
end

-- ============================================================
-- Effect 2: Add Rikka card, then Tribute 1 monster
-- ============================================================
function s.thfilter(c)
    return c:IsSetCard(0x141) and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
    Duel.SetOperationInfo(0,CATEGORY_RELEASE,nil,1,0,LOCATION_ONFIELD)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
    if #g>0 and Duel.SendtoHand(g,nil,REASON_EFFECT)>0 then
        Duel.ConfirmCards(1-tp,g)
        Duel.ShuffleDeck(tp)
        -- Then tribute 1 card on the field
        if Duel.IsExistingMatchingCard(Card.IsReleasableByEffect,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil) then
            Duel.BreakEffect()
            Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
            local rg=Duel.SelectMatchingCard(tp,Card.IsReleasableByEffect,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,1,nil)
            if #rg>0 then
                Duel.Release(rg,REASON_EFFECT)
            end
        end
    end
end

-- ============================================================
-- Effect 3: End Phase add to hand
-- ============================================================
function s.epcon(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local cond1=(c:GetTurnID()==Duel.GetTurnCount() and c:IsReason(REASON_RELEASE))
    local cond2=(Duel.GetFlagEffect(tp,id)>0)
    return cond1 or cond2
end
function s.eptg(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then return c:IsAbleToHand() end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,c,1,0,0)
end
function s.epop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if c:IsRelateToEffect(e) then
        Duel.SendtoHand(c,nil,REASON_EFFECT)
    end
end
