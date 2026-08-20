-- Gungnir, Absolute Zero Citadel Dragon
local s,id=GetID()
function s.initial_effect(c)
    -- Synchro Summon procedure: 1 "Ice Barrier" Tuner + 1+ non-Tuner monsters
    c:EnableReviveLimit()
    Synchro.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsSetCard,0x2f),1,1,Synchro.NonTuner(nil),1,99)

    -- 1. Negate monster, Special Summon from GY, reduce Level, and attach board wipe
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_DISABLE+CATEGORY_SPECIAL_SUMMON+CATEGORY_DESTROY)
    e1:SetType(EFFECT_TYPE_QUICK_O)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e1:SetRange(LOCATION_MZONE)
    e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_MAIN_END)
    e1:SetCountLimit(1,id)
    e1:SetTarget(s.eff1tg)
    e1:SetOperation(s.eff1op)
    c:RegisterEffect(e1)

    -- 2. Quick Synchro Summon during Main Phase
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e2:SetType(EFFECT_TYPE_QUICK_O)
    e2:SetCode(EVENT_FREE_CHAIN)
    e2:SetRange(LOCATION_MZONE)
    e2:SetHintTiming(0,TIMING_MAIN_END)
    e2:SetCountLimit(1,id+1)
    e2:SetCondition(s.syncon)
    e2:SetTarget(s.syntg)
    e2:SetOperation(s.synop)
    c:RegisterEffect(e2)
end

s.listed_series={0x2f}

-- E1 Logic: Target 1 face-up monster on field & 1 "Ice Barrier" monster in GY
function s.spfilter(c,e,tp)
    return c:IsSetCard(0x2f) and c:IsMonster() and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.eff1tg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return false end
    if chk==0 then
        return Duel.IsExistingTarget(aux.NegateMonsterFilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil)
            and Duel.IsExistingTarget(s.spfilter,tp,LOCATION_GRAVE,0,1,nil,e,tp)
            and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
    end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_NEGATE)
    local g1=Duel.SelectTarget(tp,aux.NegateMonsterFilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,1,nil)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local g2=Duel.SelectTarget(tp,s.spfilter,tp,LOCATION_GRAVE,0,1,1,nil,e,tp)
    
    Duel.SetOperationInfo(0,CATEGORY_DISABLE,g1,1,0,0)
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,g2,1,0,0)
end

function s.eff1op(e,tp,eg,ep,ev,re,r,rp)
    local g=Duel.GetTargetCards(e)
    if #g<2 then return end
    
    local tc1=g:Filter(Card.IsLocation,nil,LOCATION_MZONE):GetFirst()
    local tc2=g:Filter(Card.IsLocation,nil,LOCATION_GRAVE):GetFirst()
    if not tc1 or not tc2 then return end

    -- Negate face-up monster's effects
    if tc1:IsFaceup() and tc1:IsRelateToEffect(e) and not tc1:IsDisabled() then
        Duel.NegateRelatedChain(tc1,RESET_TURN_SET)
        local e1=Effect.CreateEffect(e:GetHandler())
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_DISABLE)
        e1:SetReset(RESET_EVENT+RESETS_STANDARD)
        tc1:RegisterEffect(e1)
        
        local e2=Effect.CreateEffect(e:GetHandler())
        e2:SetType(EFFECT_TYPE_SINGLE)
        e2:SetCode(EFFECT_DISABLE_EFFECT)
        e2:SetValue(RESET_TURN_SET)
        e2:SetReset(RESET_EVENT+RESETS_STANDARD)
        tc1:RegisterEffect(e2)

        -- Special Summon target from GY
        if tc2:IsRelateToEffect(e) and Duel.SpecialSummon(tc2,0,tp,tp,false,false,POS_FACEUP)>0 then
            -- Optional Level reduction (min. 1)
            local og_lv=tc2:GetOriginalLevel()
            if tc1:HasLevel() and og_lv>0 and tc1:GetLevel()>1 and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
                Duel.BreakEffect()
                local cur_lv=tc1:GetLevel()
                local reduce=math.min(og_lv, cur_lv-1)
                if reduce>0 then
                    local e3=Effect.CreateEffect(e:GetHandler())
                    e3:SetType(EFFECT_TYPE_SINGLE)
                    e3:SetCode(EFFECT_UPDATE_LEVEL)
                    e3:SetValue(-reduce)
                    e3:SetReset(RESET_EVENT+RESETS_STANDARD)
                    tc1:RegisterEffect(e3)
                end
            end

            -- Destroy all cards opponent controls when the SS monster leaves field
            local e4=Effect.CreateEffect(e:GetHandler())
            e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
            e4:SetCode(EVENT_LEAVE_FIELD)
            e4:SetOwnerPlayer(tp)
            e4:SetOperation(s.desop)
            tc2:RegisterEffect(e4,true)
        end
    end
end

function s.desop(e,tp,eg,ep,ev,re,r,rp)
    local p=e:GetOwnerPlayer()
    local g=Duel.GetMatchingGroup(nil,p,0,LOCATION_ONFIELD,nil)
    if #g>0 then
        Duel.Destroy(g,REASON_EFFECT)
    end
    e:Reset()
end

-- E2 Logic: Synchro Summon using "Ice Barrier" monsters
function s.syncon(e,tp,eg,ep,ev,re,r,rp)
    return Duel.IsMainPhase()
end
function s.matfilter(c)
    return c:IsFaceup() and c:IsSetCard(0x2f)
end
function s.syntg(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    local mg=Duel.GetMatchingGroup(s.matfilter,tp,LOCATION_MZONE,0,nil)
    if chk==0 then
        return mg:IsContains(c)
            and Duel.IsExistingMatchingCard(Card.IsSynchroSummonable,tp,LOCATION_EXTRA,0,1,nil,c,mg)
    end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end
function s.synop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if not c:IsRelateToEffect(e) or c:IsFacedown() then return end
    local mg=Duel.GetMatchingGroup(s.matfilter,tp,LOCATION_MZONE,0,nil)
    if not mg:IsContains(c) then return end
    
    local g=Duel.GetMatchingGroup(Card.IsSynchroSummonable,tp,LOCATION_EXTRA,0,nil,c,mg)
    if #g>0 then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
        local sg=g:Select(tp,1,1,nil)
        Duel.SynchroSummon(tp,sg:GetFirst(),c,mg)
    end
end
