-- Brionac, Emperor of the Ice Barrier
local s,id=GetID()
function s.initial_effect(c)
    -- Synchro Summon: 1+ non-Tuner monsters + 1 "Ice Barrier" Tuner monster
    c:EnableReviveLimit()
    Synchro.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsSetCard,0x2f),1,1,Synchro.NonTuner(nil),1,99)

    -- 1. Reveal "Ice Barrier" monsters in hand & Apply 1 of the Bullet effects
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_QUICK_O)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetRange(LOCATION_MZONE)
    e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_MAIN_END)
    e1:SetCountLimit(1,id)
    e1:SetCost(s.eff1cost)
    e1:SetTarget(s.eff1tg)
    e1:SetOperation(s.eff1op)
    c:RegisterEffect(e1)

    -- 2. Prevent opponent from activating cards/effects in hand
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,2))
    e2:SetType(EFFECT_TYPE_QUICK_O)
    e2:SetCode(EVENT_FREE_CHAIN)
    e2:SetRange(LOCATION_MZONE)
    e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_MAIN_END)
    e2:SetCountLimit(1)
    e2:SetCondition(s.eff2con)
    e2:SetOperation(s.eff2op)
    c:RegisterEffect(e2)
end

s.listed_series={0x2f}

-- Filters for Effect 1
function s.revfilter(c)
    return c:IsMonster() and c:IsSetCard(0x2f) and not c:IsPublic()
end
function s.b1filter(c)
    return c:IsAbleToHand()
end
function s.b2filter(c,e,tp)
    return c:IsSetCard(0x2f) and c:IsMonster() and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.eff1cost(e,tp,eg,ep,ev,re,r,rp,chk)
    local g=Duel.GetMatchingGroup(s.revfilter,tp,LOCATION_HAND,0,nil)
    local b1=Duel.IsExistingMatchingCard(s.b1filter,tp,0,LOCATION_ONFIELD+LOCATION_GRAVE+LOCATION_REMOVED,1,nil)
    local b2=Duel.GetLocationCount(tp,LOCATION_MZONE)>0 and Duel.IsExistingMatchingCard(s.b2filter,tp,LOCATION_DECK,0,1,nil,e,tp)
    
    if chk==0 then return #g>0 and (b1 or b2) end
    
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONFIRM)
    local sg=g:Select(tp,1,#g,nil)
    Duel.ConfirmCards(1-tp,sg)
    Duel.ShuffleHand(tp)
    e:SetLabel(#sg)
end

function s.eff1tg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    local ct=e:GetLabel()
    local b1=Duel.IsExistingMatchingCard(s.b1filter,tp,0,LOCATION_ONFIELD+LOCATION_GRAVE+LOCATION_REMOVED,1,nil)
    local b2=Duel.GetLocationCount(tp,LOCATION_MZONE)>0 and Duel.IsExistingMatchingCard(s.b2filter,tp,LOCATION_DECK,0,1,nil,e,tp)
    
    local op=0
    if b1 and b2 then
        op=Duel.SelectOption(tp,aux.Stringid(id,0),aux.Stringid(id,1))
    elseif b1 then
        op=Duel.SelectOption(tp,aux.Stringid(id,0))
    else
        op=Duel.SelectOption(tp,aux.Stringid(id,1))+1
    end
    
    -- Lưu lựa chọn (op) và số lượng bài đã cho xem (ct)
    e:SetLabel(op | (ct << 4))
    
    if op==0 then
        e:SetCategory(CATEGORY_TOHAND)
        Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,1-tp,LOCATION_ONFIELD+LOCATION_GRAVE+LOCATION_REMOVED)
    else
        e:SetCategory(CATEGORY_SPECIAL_SUMMON)
        Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK)
    end
end

function s.eff1op(e,tp,eg,ep,ev,re,r,rp)
    local val=e:GetLabel()
    local op=val & 0xf
    local ct=val >> 4
    
    if op==0 then
        -- Option 1: Return opponent's cards from field/GY/banished to hand
        local g=Duel.GetMatchingGroup(s.b1filter,tp,0,LOCATION_ONFIELD+LOCATION_GRAVE+LOCATION_REMOVED,nil)
        if #g>0 then
            Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RTOHAND)
            local sg=g:Select(tp,1,math.min(ct,#g),nil)
            if #sg>0 then
                Duel.HintSelection(sg)
                Duel.SendtoHand(sg,nil,REASON_EFFECT)
            end
        end
    elseif op==1 then
        -- Option 2: Special Summon "Ice Barrier" monsters with different names from Deck
        local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
        if ft<=0 then return end
        local max_sum=math.min(ct,ft)
        local g=Duel.GetMatchingGroup(s.b2filter,tp,LOCATION_DECK,0,nil,e,tp)
        
        if #g>0 then
            local sg=aux.SelectUnselectGroup(g,e,tp,1,max_sum,aux.dncheck,1,tp,HINTMSG_SPSUMMON)
            if #sg>0 then
                Duel.SpecialSummon(sg,0,tp,tp,false,false,POS_FACEUP)
            end
        end
    end
end

-- E2 Logic: Lock opponent's hand activations
function s.gyfilter(c)
    return c:IsSetCard(0x2f) and c:IsMonster()
end
function s.eff2con(e,tp,eg,ep,ev,re,r,rp)
    return Duel.IsExistingMatchingCard(s.gyfilter,tp,LOCATION_GRAVE,0,1,nil)
end
function s.eff2op(e,tp,eg,ep,ev,re,r,rp)
    -- Apply lock on opponent
    local e1=Effect.CreateEffect(e:GetHandler())
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
    e1:SetCode(EFFECT_CANNOT_ACTIVATE)
    e1:SetTargetRange(0,1)
    e1:SetValue(s.aclimit)
    e1:SetReset(RESET_PHASE+PHASE_END)
    Duel.RegisterEffect(e1,tp)
    
    -- Client hint on opponent
    local e2=Effect.CreateEffect(e:GetHandler())
    e2:SetType(EFFECT_TYPE_FIELD)
    e2:SetCode(EFFECT_FLAG_CLIENT_HINT)
    e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
    e2:SetTargetRange(0,1)
    e2:SetDescription(aux.Stringid(id,2))
    e2:SetReset(RESET_PHASE+PHASE_END)
    Duel.RegisterEffect(e2,tp)
end
function s.aclimit(e,re,tp)
    return re:GetActivateLocation()==LOCATION_HAND
end