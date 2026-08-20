-- Trishula, Lord of the Blizzard
local s,id=GetID()
function s.initial_effect(c)
    -- Lệnh này đảm bảo lá bài luôn được tính là bài "Ice Barrier" theo text
    c:AddSetcodesRule(id,false,0x2f)
    
    -- Synchro Summon: 1 Tuner + 1+ non-Tuner "Ice Barrier" monsters
    c:EnableReviveLimit()
    Synchro.AddProcedure(c,nil,1,1,Synchro.NonTunerEx(Card.IsSetCard,0x2f),1,99)
    
    -- Must first be Synchro Summoned
    local e0=Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE_SINGLE)
    e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
    e0:SetCode(EFFECT_SPSUMMON_CONDITION)
    e0:SetValue(aux.synlimit)
    c:RegisterEffect(e0)

    -- 1. Opponent cannot target other "Ice Barrier" cards you control
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
    e1:SetRange(LOCATION_MZONE)
    e1:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE)
    e1:SetTargetRange(LOCATION_ONFIELD,0)
    e1:SetTarget(s.tgtg)
    e1:SetValue(aux.tgoval)
    c:RegisterEffect(e1)

    -- 2. Destruction replacement for "Ice Barrier" cards
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
    e2:SetCode(EFFECT_DESTROY_REPLACE)
    e2:SetRange(LOCATION_MZONE)
    e2:SetTarget(s.reptg)
    e2:SetValue(s.repval)
    e2:SetOperation(s.repop)
    c:RegisterEffect(e2)

    -- 3. Negate activation and Banish from Field, Hand, GY (Quick Effect)
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,0))
    e3:SetCategory(CATEGORY_NEGATE+CATEGORY_REMOVE)
    e3:SetType(EFFECT_TYPE_QUICK_O)
    e3:SetCode(EVENT_CHAINING)
    e3:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DAMAGE_CAL)
    e3:SetRange(LOCATION_MZONE)
    e3:SetCountLimit(1,id)
    e3:SetCondition(s.negcon)
    e3:SetTarget(s.negtg)
    e3:SetOperation(s.negop)
    c:RegisterEffect(e3)

    -- 4. Banish self & GY Synchro to Special Summon from Extra Deck (Quick Effect)
    local e4=Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id,1))
    e4:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e4:SetType(EFFECT_TYPE_QUICK_O)
    e4:SetCode(EVENT_FREE_CHAIN)
    e4:SetRange(LOCATION_MZONE)
    e4:SetCountLimit(1,id+1)
    e4:SetHintTiming(0,TIMING_MAIN_END+TIMINGS_CHECK_MONSTER)
    e4:SetCost(s.spcost)
    e4:SetTarget(s.sptg)
    e4:SetOperation(s.spop)
    c:RegisterEffect(e4)
end

s.listed_series={0x2f}

-- Target Protection Logic
function s.tgtg(e,c)
    return c~=e:GetHandler() and c:IsSetCard(0x2f)
end

-- Destruction Replacement Logic
function s.repfilter(c,tp)
    return c:IsControler(tp) and c:IsLocation(LOCATION_ONFIELD) and c:IsSetCard(0x2f)
        and c:IsReason(REASON_EFFECT) and c:GetReasonPlayer()==1-tp and not c:IsReason(REASON_REPLACE)
end
function s.rmfilter(c)
    return c:IsAttribute(ATTRIBUTE_WATER) and c:IsAbleToRemove()
end
function s.reptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return eg:IsExists(s.repfilter,1,nil,tp)
        and Duel.IsExistingMatchingCard(s.rmfilter,tp,LOCATION_GRAVE,0,1,nil) end
    if Duel.SelectEffectYesNo(tp,e:GetHandler(),96) then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
        local g=Duel.SelectMatchingCard(tp,s.rmfilter,tp,LOCATION_GRAVE,0,1,1,nil)
        e:SetLabelObject(g:GetFirst())
        g:GetFirst():SetStatus(STATUS_DESTROY_CONFIRMED,true)
        return true
    end
    return false
end
function s.repval(e,c)
    return s.repfilter(c,e:GetHandlerPlayer())
end
function s.repop(e,tp,eg,ep,ev,re,r,rp)
    local tc=e:GetLabelObject()
    tc:SetStatus(STATUS_DESTROY_CONFIRMED,false)
    Duel.Remove(tc,POS_FACEUP,REASON_EFFECT+REASON_REPLACE)
end

-- Negate & Banish Logic
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
    return rp==1-tp and not e:GetHandler():IsStatus(STATUS_BATTLE_DESTROYED) and Duel.IsChainNegatable(ev)
end
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
    Duel.SetPossibleOperationInfo(0,CATEGORY_REMOVE,nil,1,1-tp,LOCATION_ONFIELD+LOCATION_HAND+LOCATION_GRAVE)
end
function s.negop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.NegateActivation(ev) then
        local g=Group.CreateGroup()
        local g1=Duel.GetMatchingGroup(Card.IsAbleToRemove,tp,0,LOCATION_ONFIELD,nil)
        local g2=Duel.GetMatchingGroup(Card.IsAbleToRemove,tp,0,LOCATION_GRAVE,nil)
        local g3=Duel.GetFieldGroup(tp,0,LOCATION_HAND)
        
        -- Chọn 1 lá trên Sân (Right-click để bỏ qua nếu không muốn trục xuất)
        if #g1>0 then
            Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
            local sg1=g1:Select(tp,0,1,nil)
            if #sg1>0 then
                Duel.HintSelection(sg1)
                g:Merge(sg1)
            end
        end
        -- Chọn 1 lá dưới Mộ (Right-click để bỏ qua nếu không muốn trục xuất)
        if #g2>0 then
            Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
            local sg2=g2:Select(tp,0,1,nil)
            if #sg2>0 then
                Duel.HintSelection(sg2)
                g:Merge(sg2)
            end
        end
        -- Hỏi có muốn trục xuất ngẫu nhiên 1 lá trên Tay không
        if #g3>0 and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
            local sg3=g3:RandomSelect(tp,1)
            g:Merge(sg3)
        end
        
        -- Thực hiện trục xuất cùng lúc
        if #g>0 then
            Duel.BreakEffect()
            Duel.Remove(g,POS_FACEUP,REASON_EFFECT)
        end
    end
end

-- Special Summon Synchro Logic
function s.cfilter(c)
    return c:IsSetCard(0x2f) and c:IsType(TYPE_SYNCHRO) and c:IsAbleToRemoveAsCost()
end
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then return c:IsAbleToRemoveAsCost()
        and Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_GRAVE,0,1,nil) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
    local g=Duel.SelectMatchingCard(tp,s.cfilter,tp,LOCATION_GRAVE,0,1,1,nil)
    g:AddCard(c)
    Duel.Remove(g,POS_FACEUP,REASON_COST)
end
function s.spfilter(c,e,tp,mc)
    return c:IsSetCard(0x2f) and c:IsType(TYPE_SYNCHRO)
        and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_SYNCHRO,tp,false,false)
        and Duel.GetLocationCountFromEx(tp,tp,mc,c)>0
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then return Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp,c) end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local tc=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp,nil):GetFirst()
    if tc and Duel.SpecialSummon(tc,SUMMON_TYPE_SYNCHRO,tp,tp,false,false,POS_FACEUP)>0 then
        tc:CompleteProcedure()
    end
end