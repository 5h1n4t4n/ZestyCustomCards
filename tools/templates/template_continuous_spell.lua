-- ============================================================
-- Card Name: <<CARD_NAME>>
-- Passcode : <<PASSCODE>>
-- Type     : Spell / Continuous
-- Archetype: <<ARCHETYPE_NAME>> (0x<<SETCODE>>)
-- ============================================================
-- Effect 1: Activate this card.
-- Effect 2: All "<<ARCHETYPE_NAME>>" monsters you control gain
--           <<ATK_VALUE>> ATK.
-- Effect 3: Once per turn: You can add 1 "<<ARCHETYPE_NAME>>"
--           card from your Deck to your hand.
-- ============================================================
-- Continuous Spell ở lại SZONE sau khi activate, nên effect
-- thường trực dùng SetRange(LOCATION_SZONE) (official ref:
-- Ninjitsu Art Notebook c79324191, Karakuri Anatomy c85541675).
-- ============================================================

local s,id=GetID()

function s.initial_effect(c)
    -- ============================================================
    -- Effect 1 — Activation: card chỉ nằm lại trên sân, không làm gì thêm
    -- ============================================================
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_ACTIVATE)                       -- Activation effect of the Spell itself
    e1:SetCode(EVENT_FREE_CHAIN)                           -- No specific timing requirement
    c:RegisterEffect(e1)

    -- ============================================================
    -- Effect 2 — Continuous ATK boost while this card is in the S/T Zone
    -- ============================================================
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_FIELD)                          -- Affects other cards on the field
    e2:SetCode(EFFECT_UPDATE_ATTACK)                       -- Continuous ATK modification
    e2:SetRange(LOCATION_SZONE)                            -- Only while face-up in the S/T Zone
    e2:SetTargetRange(LOCATION_MZONE,0)                    -- Affects your Monster Zones
    e2:SetTarget(s.tg_atkboost)
    e2:SetValue(<<ATK_VALUE>>)                             -- Amount of ATK to add
    c:RegisterEffect(e2)

    -- ============================================================
    -- Effect 3 — Ignition effect from the S/T Zone: search the Deck
    -- ============================================================
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,0))
    e3:SetCategory(CATEGORY_SEARCH+CATEGORY_TOHAND)
    e3:SetType(EFFECT_TYPE_IGNITION)                       -- Kích hoạt tay người chơi trong Main Phase
    e3:SetRange(LOCATION_SZONE)                            -- Phải còn ngửa trong S/T Zone
    e3:SetCountLimit(1)                                    -- Soft once per turn
    e3:SetTarget(s.tg_search)
    e3:SetOperation(s.op_search)
    c:RegisterEffect(e3)
end

-- ============================================================
-- Effect 2: Filter — Only archetype monsters you control
-- ============================================================
function s.tg_atkboost(e,c)
    return c:IsSetCard(0x<<SETCODE>>)
end

-- ============================================================
-- Effect 3: Filter — Valid search targets in Deck
-- ============================================================
function s.filter_search(c)
    return c:IsSetCard(0x<<SETCODE>>) and c:IsAbleToHand()
end

-- ============================================================
-- Effect 3: Target — Check if a valid search target exists
-- ============================================================
function s.tg_search(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.IsExistingMatchingCard(s.filter_search,tp,LOCATION_DECK,0,1,nil)
    end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

-- ============================================================
-- Effect 3: Operation — Select 1 card from Deck, add to hand
-- ============================================================
function s.op_search(e,tp,eg,ep,ev,re,r,rp)
    if not e:GetHandler():IsRelateToEffect(e) then return end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectMatchingCard(tp,s.filter_search,tp,LOCATION_DECK,0,1,1,nil)
    if #g>0 then
        Duel.SendtoHand(g,nil,REASON_EFFECT)
        Duel.ConfirmCards(1-tp,g)
    end
end
