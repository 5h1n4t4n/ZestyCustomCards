-- The Stage of Infinite Delight
local s,id=GetID()
function s.initial_effect(c)
    -- Activate
    local e0=Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE_ACTIVATE)
    e0:SetCode(EVENT_FREE_CHAIN)
    c:RegisterEffect(e0)

    -- Effect 1: Search 1 or 2 "Halovian" cards
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_HANDES)
    e1:SetType(EFFECT_TYPE_IGNITION)
    e1:SetRange(LOCATION_SZONE)
    e1:SetCountLimit(1,id)
    e1:SetTarget(s.thtg)
    e1:SetOperation(s.thop)
    c:RegisterEffect(e1)

    -- Effect 2: Quick Effect - Destroy 1 card
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_DESTROY)
    e2:SetType(EFFECT_TYPE_QUICK_O)
    e2:SetCode(EVENT_FREE_CHAIN)
    e2:SetRange(LOCATION_SZONE)
    e2:SetCountLimit(1,id+1)
    e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E+TIMING_END_PHASE)
    e2:SetCost(s.descost)
    e2:SetTarget(s.destg)
    e2:SetOperation(s.desop)
    c:RegisterEffect(e2)
end

s.listed_series={0x987}
s.listed_names={id}

-- Logic Effect 1 (Search)
function s.thfilter(c)
    return c:IsSetCard(0x987) and c:IsAbleToHand()
end
function s.bonusfilter(c)
    return c:IsFaceup() and c:IsSetCard(0x987) and c:IsRace(RACE_WINGEDBEAST) and c:IsLevel(1) and c:IsAttack(0)
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
    if not e:GetHandler():IsRelateToEffect(e) then return end
    local b1=Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil)
    local b2=Duel.IsExistingMatchingCard(s.bonusfilter,tp,LOCATION_MZONE,0,1,nil) 
        and Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,2,nil)

    if not b1 then return end
    
    local count=1
    -- Nếu thỏa mãn điều kiện, cho phép chọn lấy 2 lá
    if b2 and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
        count=2
    end
    
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,count,count,nil)
    if #g>0 then
        Duel.SendtoHand(g,nil,REASON_EFFECT)
        Duel.ConfirmCards(1-tp,g)
        -- Nếu chọn lấy 2 lá, phải bỏ 1 lá trên tay
        if count==2 then
            Duel.ShuffleHand(tp)
            Duel.BreakEffect()
            Duel.DiscardHand(tp,nil,1,1,REASON_EFFECT+REASON_DISCARD)
        end
    end
end

-- Logic Effect 2 (Quick Effect - Destroy)
function s.cfilter1(c)
    return c:IsSetCard(0x987) and c:IsRace(RACE_WINGEDBEAST) and c:IsLevel(1) and c:IsAttack(0) and not c:IsPublic()
end
function s.cfilter2(c)
    return c:IsSetCard(0x987) and c:IsRace(RACE_WINGEDBEAST) and c:IsLevel(1) and c:IsFaceup() and c:IsAbleToHandAsCost()
end
function s.descost(e,tp,eg,ep,ev,re,r,rp,chk)
    local b1=Duel.IsExistingMatchingCard(s.cfilter1,tp,LOCATION_HAND,0,1,nil)
    local b2=Duel.IsExistingMatchingCard(s.cfilter2,tp,LOCATION_MZONE,0,1,nil)
    if chk==0 then return b1 or b2 end
    
    local op=0
    if b1 and b2 then
        op=Duel.SelectOption(tp,aux.Stringid(id,3),aux.Stringid(id,4))
    elseif b1 then
        op=0
    else
        op=1
    end
    
    if op==0 then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONFIRM)
        local g=Duel.SelectMatchingCard(tp,s.cfilter1,tp,LOCATION_HAND,0,1,1,nil)
        Duel.ConfirmCards(1-tp,g)
        Duel.ShuffleHand(tp)
    else
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RTOHAND)
        local g=Duel.SelectMatchingCard(tp,s.cfilter2,tp,LOCATION_MZONE,0,1,1,nil)
        Duel.SendtoHand(g,nil,REASON_COST)
    end
end
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(aux.TRUE,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil) end
    local g=Duel.GetMatchingGroup(aux.TRUE,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,nil)
    Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
    if not e:GetHandler():IsRelateToEffect(e) then return end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
    local g=Duel.SelectMatchingCard(tp,aux.TRUE,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,1,nil)
    if #g>0 then
        Duel.HintSelection(g)
        Duel.Destroy(g,REASON_EFFECT)
    end
end
