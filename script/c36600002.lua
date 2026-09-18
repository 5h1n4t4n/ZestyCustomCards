-- ============================================================
-- Card Name: Icejade Creation Pillar
-- Passcode : 36600002
-- Type     : Monster / Synchro / Effect (Aqua / WATER / Lv 10)
-- Archetype: Icejade (0x16e)
-- ============================================================
-- Materials: 1 WATER Tuner + 1+ non-Tuner monsters
-- Effect 1: If this card is Special Summoned: You can place 1
--           "Icejade" Continuous Spell/Trap from your Deck or GY
--           face-up on your field.
-- Effect 2: When your opponent activates a monster effect
--           (Quick Effect): You can activate this effect; the
--           activated effect becomes "Banish 1 card you control
--           or in the GY" — this card's controller banishes 1 card
--           they control, or 1 card in either player's GY.
-- Effect 3: If a face-up WATER monster(s) you control leave the
--           field by your opponent's card while this card is in
--           your GY: You can Special Summon this card.
-- Reference: c86682165 (Icejade Gymir Aegirine) Synchro procedure
--            and "by your opponent's card" reason check;
--            c71166481 (Number 75: Bamboozling Gossip Shadow)
--            for replacing the activated effect;
--            c41371602 (Stand Up Centur-Ion!) for MoveToField;
--            c55151012 (Icejade Tremora) for the previous-state
--            WATER check; c10698416 (Krawler Ranvier) for the
--            "left by your opponent's card" condition.
-- ============================================================

local s,id=GetID()
local ICEJADE_CRADLE=7142724

function s.initial_effect(c)
    c:EnableReviveLimit()
    -- 1 WATER Tuner + 1+ non-Tuner monsters
    Synchro.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsAttribute,ATTRIBUTE_WATER),1,1,Synchro.NonTuner(nil),1,99)

    -- ============================================================
    -- Effect 1 — On Special Summon: place an "Icejade" Continuous S/T
    -- ============================================================
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e1:SetProperty(EFFECT_FLAG_DELAY)
    e1:SetCode(EVENT_SPSUMMON_SUCCESS)
    e1:SetCountLimit(1,id)
    e1:SetTarget(s.pltg)
    e1:SetOperation(s.plop)
    c:RegisterEffect(e1)

    -- ============================================================
    -- Effect 2 — Replace the opponent's activated monster effect
    -- ============================================================
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_REMOVE)
    e2:SetType(EFFECT_TYPE_QUICK_O)
    e2:SetCode(EVENT_CHAINING)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCountLimit(1,{id,1})
    e2:SetCondition(s.chcon)
    e2:SetTarget(s.chtg)
    e2:SetOperation(s.chop)
    c:RegisterEffect(e2)

    -- ============================================================
    -- Effect 3 — Revive from the GY when the opponent removes WATER
    -- ============================================================
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,2))
    e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e3:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_DAMAGE_STEP)
    e3:SetCode(EVENT_LEAVE_FIELD)
    e3:SetRange(LOCATION_GRAVE)
    e3:SetCountLimit(1,{id,2})
    e3:SetCondition(s.spcon)
    e3:SetTarget(s.sptg)
    e3:SetOperation(s.spop)
    c:RegisterEffect(e3)
end

s.listed_series={SET_ICEJADE}
s.listed_names={ICEJADE_CRADLE}

-- ============================================================
-- Effect 1: Only Continuous Spell/Trap "Icejade" cards qualify
-- ============================================================
function s.plfilter(c)
    return c:IsSetCard(SET_ICEJADE) and c:IsSpellTrap() and c:IsType(TYPE_CONTINUOUS)
        and not c:IsForbidden()
end

function s.pltg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
        and Duel.IsExistingMatchingCard(s.plfilter,tp,LOCATION_DECK|LOCATION_GRAVE,0,1,nil) end
end

function s.plop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then return end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOFIELD)
    local tc=Duel.SelectMatchingCard(tp,s.plfilter,tp,LOCATION_DECK|LOCATION_GRAVE,0,1,1,nil):GetFirst()
    if tc then
        Duel.MoveToField(tc,tp,tp,LOCATION_SZONE,POS_FACEUP,true)
    end
end

-- ============================================================
-- Effect 2: Only the opponent's monster effects can be replaced
-- ============================================================
function s.chcon(e,tp,eg,ep,ev,re,r,rp)
    return re:IsMonsterEffect() and rp==1-tp
end

function s.chtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    Duel.SetPossibleOperationInfo(0,CATEGORY_REMOVE,nil,1,tp,LOCATION_ONFIELD|LOCATION_GRAVE)
end

function s.chop(e,tp,eg,ep,ev,re,r,rp)
    -- Drop the original targets, then swap in the banish operation
    Duel.ChangeTargetCard(ev,Group.CreateGroup())
    Duel.ChangeChainOperation(ev,s.repop)
end

-- Runs in place of the replaced chain, so tp is that effect's controller —
-- the opponent. "You" in the replacement text is this card's controller, 1-tp:
-- their own field plus either player's GY, and they make the choice.
function s.repop(e,tp,eg,ep,ev,re,r,rp)
    local ptp=1-tp
    local g=Duel.GetMatchingGroup(Card.IsAbleToRemove,ptp,LOCATION_ONFIELD|LOCATION_GRAVE,LOCATION_GRAVE,nil)
    if #g==0 then return end
    Duel.Hint(HINT_SELECTMSG,ptp,HINTMSG_REMOVE)
    local sg=g:Select(ptp,1,1,nil)
    Duel.Remove(sg,POS_FACEUP,REASON_EFFECT)
end

-- ============================================================
-- Effect 3: A face-up WATER monster you controlled left the field
--           because of a card your opponent used. This card has to
--           be in the GY beforehand, so it never counts itself.
-- ============================================================
function s.spconfilter(c,tp)
    return c:IsPreviousControler(tp) and c:IsPreviousLocation(LOCATION_MZONE)
        and c:IsPreviousPosition(POS_FACEUP)
        and (c:GetPreviousAttributeOnField()&ATTRIBUTE_WATER)==ATTRIBUTE_WATER
        and c:IsReason(REASON_EFFECT) and c:GetReasonPlayer()==1-tp
end

function s.spcon(e,tp,eg,ep,ev,re,r,rp)
    return not eg:IsContains(e:GetHandler()) and eg:IsExists(s.spconfilter,1,nil,tp)
end

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
