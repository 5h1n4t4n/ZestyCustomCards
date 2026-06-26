-- ============================================================
-- Card Name: Contrary Fusion
-- Passcode : 79900020
-- Type     : Spell / Normal
-- Archetype: N/A
-- ============================================================
-- Effect 1 : Fusion Summon 1 Plant Fusion monster from Extra Deck
--            using 1 Plant monster from Deck + 1 Plant monster from hand/field,
--            or by banishing 1 Plant monster from GY.
--            The Fusion Summoned monster has its ATK/DEF swapped.
--            Also take control of 1 opponent's monster.
-- ============================================================

local s,id=GetID()

function s.initial_effect(c)
    -- ============================================================
    -- Effect 1 — Activate: Fusion Summon + Swap ATK/DEF + Steal
    -- ============================================================
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON
        +CATEGORY_REMOVE+CATEGORY_CONTROL
        +CATEGORY_ATKCHANGE+CATEGORY_DEFCHANGE)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
    e1:SetTarget(s.fustg)
    e1:SetOperation(s.fusop)
    c:RegisterEffect(e1)
end

-- ============================================================
-- Fusion material filter — Plant Fusion monster from Extra Deck
-- ============================================================
function s.fusfilter(c,e,tp,mg)
    if not (c:IsRace(RACE_PLANT) and c:IsType(TYPE_FUSION)
        and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_FUSION,tp,false,false)
        and Duel.GetLocationCountFromEx(tp,tp,mg,c)>0) then
        return false
    end
    local rescon=function(sg,e,tp,mg)
        return c:CheckFusionMaterial(sg,nil,tp)
            and sg:FilterCount(Card.IsLocation,nil,LOCATION_DECK)==1
            and sg:FilterCount(Card.IsLocation,nil,LOCATION_HAND+LOCATION_MZONE+LOCATION_GRAVE)==1
    end
    return aux.SelectUnselectGroup(mg,e,tp,2,2,rescon,0)
end

-- ============================================================
-- Material filter — Deck materials (1 Plant monster from Deck)
-- ============================================================
function s.deckmatfilter(c)
    return c:IsRace(RACE_PLANT) and c:IsType(TYPE_MONSTER) and c:IsAbleToGrave()
end

-- ============================================================
-- Material filter — Hand/field materials (1 Plant monster)
-- ============================================================
function s.hfmatfilter(c)
    return c:IsRace(RACE_PLANT) and c:IsType(TYPE_MONSTER) and c:IsCanBeFusionMaterial()
end

-- ============================================================
-- Material filter — GY materials (banish 1 Plant monster as alternative)
-- ============================================================
function s.gymatfilter(c)
    return c:IsRace(RACE_PLANT) and c:IsType(TYPE_MONSTER) and c:IsAbleToRemove()
end

-- ============================================================
-- Build material group for Fusion
-- ============================================================
function s.buildmatgroup(tp)
    -- Materials from Deck
    local mg1=Duel.GetMatchingGroup(s.deckmatfilter,tp,
        LOCATION_DECK,0,nil)
    -- Materials from hand/field
    local mg2=Duel.GetMatchingGroup(s.hfmatfilter,tp,
        LOCATION_HAND+LOCATION_MZONE,0,nil)
    -- Materials from GY (banish alternative)
    local mg3=Duel.GetMatchingGroup(s.gymatfilter,tp,
        LOCATION_GRAVE,0,nil)
    -- Combine all
    local mg=mg1:Clone()
    mg:Merge(mg2)
    mg:Merge(mg3)
    return mg
end

-- ============================================================
-- Target — Check if Fusion Summon is possible
-- ============================================================
function s.fustg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        local mg=s.buildmatgroup(tp)
        return Duel.IsExistingMatchingCard(
            s.fusfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp,mg)
    end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,
        LOCATION_EXTRA)
end

-- ============================================================
-- Steal filter — opponent's monster that can change control
-- ============================================================
function s.stealfilter(c)
    return c:IsControlerCanBeChanged()
end

-- ============================================================
-- Operation — Perform Fusion Summon + swap ATK/DEF + steal
-- ============================================================
function s.fusop(e,tp,eg,ep,ev,re,r,rp)
    if not e:GetHandler():IsRelateToEffect(e) then return end
    -- Step 1: Build material group
    local mg=s.buildmatgroup(tp)
    if #mg<2 then return end
    -- Step 2: Select Fusion Monster
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local sg=Duel.SelectMatchingCard(tp,s.fusfilter,tp,
        LOCATION_EXTRA,0,1,1,nil,e,tp,mg)
    local sc=sg:GetFirst()
    if not sc then return end
    -- Step 3: Select Fusion Materials
    local rescon=function(sg,e,tp,mg)
        return sc:CheckFusionMaterial(sg,nil,tp)
            and sg:FilterCount(Card.IsLocation,nil,LOCATION_DECK)==1
            and sg:FilterCount(Card.IsLocation,nil,LOCATION_HAND+LOCATION_MZONE+LOCATION_GRAVE)==1
    end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FMATERIAL)
    local mat=aux.SelectUnselectGroup(mg,e,tp,2,2,rescon,1,tp,HINTMSG_FMATERIAL)
    if not mat or #mat==0 then return end
    sc:SetMaterial(mat)
    -- Step 4: Send materials to GY or banish
    for tc in aux.Next(mat) do
        if tc:IsLocation(LOCATION_GRAVE) then
            -- GY material → banish
            Duel.Remove(tc,POS_FACEUP,REASON_EFFECT
                +REASON_MATERIAL+REASON_FUSION)
        else
            -- Deck/hand/field material → send to GY
            Duel.SendtoGrave(tc,REASON_EFFECT
                +REASON_MATERIAL+REASON_FUSION)
        end
    end
    Duel.BreakEffect()
    -- Step 5: Special Summon the Fusion Monster
    if Duel.SpecialSummon(sc,SUMMON_TYPE_FUSION,tp,tp,
        false,false,POS_FACEUP)==0 then return end
    sc:CompleteProcedure()
    -- Step 6: Swap ATK/DEF on the Fusion Summoned monster
    local e1=Effect.CreateEffect(e:GetHandler())
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetCode(EFFECT_SWAP_AD)
    e1:SetReset(RESET_EVENT+RESETS_STANDARD)
    sc:RegisterEffect(e1)
    -- Step 7: Take control of 1 opponent's monster
    if Duel.IsExistingMatchingCard(s.stealfilter,tp,
        0,LOCATION_MZONE,1,nil)
        and Duel.GetLocationCount(tp,LOCATION_MZONE)>0 then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONTROL)
        local tg=Duel.SelectMatchingCard(tp,s.stealfilter,tp,
            0,LOCATION_MZONE,1,1,nil)
        local tc=tg:GetFirst()
        if tc then
            Duel.GetControl(tc,tp)
        end
    end
end
