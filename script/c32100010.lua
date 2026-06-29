-- ============================================================
-- Card Name: Rikka Beauty
-- Passcode  : 32100010
-- Type      : Monster / Effect
-- Attribute : EARTH
-- Level     : 4
-- ATK/DEF   : 0 / 0
-- Race      : Plant
-- Archetype : Rikka (0x141)
-- ============================================================
-- Effect 1  : If a card is Tributed: SS this card from hand in DEF.
-- Effect 2  : (Quick Effect) Tribute this card; add/set 1 Rikka
--             Spell/Trap from Deck (can activate Set card this turn).
-- Effect 3  : If sent to GY: add to hand, then if Tributed this
--             turn, SS 1 Rikka monster from Deck in DEF.
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
    e1:SetCode(EVENT_RELEASE)
    e1:SetProperty(EFFECT_FLAG_DELAY)
    e1:SetRange(LOCATION_HAND)
    e1:SetCountLimit(1,id)
    e1:SetCondition(s.sscon)
    e1:SetTarget(s.sstg)
    e1:SetOperation(s.ssop)
    c:RegisterEffect(e1)

    -- ============================================================
    -- Effect 2 — Quick Effect: Tribute self, search/set Rikka S/T
    -- ============================================================
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
    e2:SetType(EFFECT_TYPE_QUICK_O)
    e2:SetCode(EVENT_FREE_CHAIN)
    e2:SetRange(LOCATION_MZONE)
    e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E+TIMING_END_PHASE)
    e2:SetCountLimit(1,{id,1})
    e2:SetCost(s.stcost)
    e2:SetTarget(s.sttg)
    e2:SetOperation(s.stop)
    c:RegisterEffect(e2)

    -- ============================================================
    -- Effect 3 — Trigger: If sent to GY, add to hand (+SS if Tributed)
    -- ============================================================
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,2))
    e3:SetCategory(CATEGORY_TOHAND+CATEGORY_SPECIAL_SUMMON)
    e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e3:SetCode(EVENT_TO_GRAVE)
    e3:SetProperty(EFFECT_FLAG_DELAY)
    e3:SetCountLimit(1,{id,2})
    e3:SetTarget(s.thtg)
    e3:SetOperation(s.thop)
    c:RegisterEffect(e3)
end

-- ============================================================
-- Effect 1: Condition — A card was Tributed
-- ============================================================
function s.sscon(e,tp,eg,ep,ev,re,r,rp)
    return true -- EVENT_RELEASE implies a card was tributed
end

-- ============================================================
-- Effect 1: Target — Can SS this card from hand in DEF
-- ============================================================
function s.sstg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
            and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false)
    end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
end

-- ============================================================
-- Effect 1: Operation — Special Summon in DEF position
-- ============================================================
function s.ssop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if c:IsRelateToEffect(e)
        and Duel.GetLocationCount(tp,LOCATION_MZONE)>0 then
        Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP_DEFENSE)
    end
end

-- ============================================================
-- Effect 2: Cost — Tribute this card on the field
-- ============================================================
function s.stcost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return e:GetHandler():IsReleasable() end
    Duel.Release(e:GetHandler(),REASON_COST)
end

-- ============================================================
-- Effect 2: Filter — Rikka Spell/Trap in Deck
-- ============================================================
function s.stfilter(c)
    return c:IsSetCard(0x141) and c:IsSpellTrap()
        and (c:IsAbleToHand() or c:IsSSetable())
end

function s.stfilter_hand(c)
    return c:IsSetCard(0x141) and c:IsSpellTrap() and c:IsAbleToHand()
end

function s.stfilter_set(c)
    return c:IsSetCard(0x141) and c:IsSpellTrap() and c:IsSSetable()
end

-- ============================================================
-- Effect 2: Target — Check for Rikka S/T in Deck
-- ============================================================
function s.sttg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.IsExistingMatchingCard(
            s.stfilter,tp,LOCATION_DECK,0,1,nil)
    end
    Duel.SetOperationInfo(
        0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

-- ============================================================
-- Effect 2: Operation — Add or Set 1 Rikka Spell/Trap
-- ============================================================
function s.stop(e,tp,eg,ep,ev,re,r,rp)
    local can_add=Duel.IsExistingMatchingCard(
        s.stfilter_hand,tp,LOCATION_DECK,0,1,nil)
    local can_set=Duel.IsExistingMatchingCard(
        s.stfilter_set,tp,LOCATION_DECK,0,1,nil)
    if not can_add and not can_set then return end
    local op=0
    if can_add and can_set then
        op=Duel.SelectOption(tp,aux.Stringid(id,3),aux.Stringid(id,4))
    elseif can_add then
        Duel.SelectOption(tp,aux.Stringid(id,3))
        op=0
    else
        Duel.SelectOption(tp,aux.Stringid(id,4))
        op=1
    end
    if op==0 then
        -- Add to hand
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
        local g=Duel.SelectMatchingCard(
            tp,s.stfilter_hand,tp,LOCATION_DECK,0,1,1,nil)
        if #g>0 then
            Duel.SendtoHand(g,nil,REASON_EFFECT)
            Duel.ConfirmCards(1-tp,g)
            Duel.ShuffleDeck(tp)
        end
    else
        -- Set to Spell & Trap Zone
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
        local g=Duel.SelectMatchingCard(
            tp,s.stfilter_set,tp,LOCATION_DECK,0,1,1,nil)
        if #g>0 then
            local sc=g:GetFirst()
            Duel.SSet(tp,sc)
            Duel.ShuffleDeck(tp)
            -- Can activate that card this turn
            local e1=Effect.CreateEffect(e:GetHandler())
            e1:SetType(EFFECT_TYPE_SINGLE)
            e1:SetCode(EFFECT_TRAP_ACT_IN_SET_TURN)
            e1:SetReset(RESET_EVENT+RESETS_STANDARD
                +RESET_PHASE+PHASE_END)
            sc:RegisterEffect(e1)
        end
    end
end

-- ============================================================
-- Effect 3: Target — Can add this card to hand from GY
-- ============================================================
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return e:GetHandler():IsAbleToHand()
    end
    Duel.SetOperationInfo(
        0,CATEGORY_TOHAND,e:GetHandler(),1,0,0)
end

-- ============================================================
-- Effect 3: Operation — Add to hand, then SS if Tributed
-- ============================================================
function s.rkfilter(c,e,tp)
    return c:IsSetCard(0x141) and c:IsMonster()
        and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if not c:IsRelateToEffect(e) then return end
    -- Check if this card was Tributed this turn before it moves locations
    local was_tributed=c:IsReason(REASON_RELEASE)
    if Duel.SendtoHand(c,nil,REASON_EFFECT)==0
        or not c:IsLocation(LOCATION_HAND) then return end
    if was_tributed
        and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and Duel.IsExistingMatchingCard(
            s.rkfilter,tp,LOCATION_DECK,0,1,nil,e,tp) then
        Duel.BreakEffect()
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
        local g=Duel.SelectMatchingCard(
            tp,s.rkfilter,tp,LOCATION_DECK,0,1,1,nil,e,tp)
        if #g>0 then
            Duel.SpecialSummon(
                g,0,tp,tp,false,false,POS_FACEUP_DEFENSE)
        end
    end
end
