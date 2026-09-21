-- RoRo - THE HALOVIAN
local s,id=GetID()
function s.initial_effect(c)
    -- 1. Special Summon procedure from hand (Không tạo chuỗi)
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetCode(EFFECT_SPSUMMON_PROC)
    e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
    e1:SetRange(LOCATION_HAND)
    e1:SetCondition(s.spcon)
    c:RegisterEffect(e1)

    -- 2. Place 1 "The stage of infinite delight"
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e2:SetProperty(EFFECT_FLAG_DELAY)
    e2:SetCode(EVENT_SPSUMMON_SUCCESS)
    e2:SetTarget(s.pltg)
    e2:SetOperation(s.plop)
    c:RegisterEffect(e2)

    -- 3. Quick Effect: Gain 1000 LP for each "The stage of infinite delight"
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,2))
    e3:SetCategory(CATEGORY_RECOVER)
    e3:SetType(EFFECT_TYPE_QUICK_O)
    e3:SetCode(EVENT_FREE_CHAIN)
    e3:SetRange(LOCATION_HAND+LOCATION_MZONE)
    e3:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_END_PHASE)
    e3:SetCountLimit(1,id)
    e3:SetCost(s.excost)
    e3:SetTarget(s.rectg)
    e3:SetOperation(s.recop)
    c:RegisterEffect(e3)
end

s.listed_series={0x987}
s.listed_names={15938,39647} -- The stage of infinite delight, Robin- The star rail summeretto

-- Logic Effect 1 (Special Summon Procedure - Non-Chain)
function s.spfilter(c)
    return c:IsFaceup() and c:IsSetCard(0x987)
end
function s.spcon(e,c)
    if c==nil then return true end
    local tp=c:GetControler()
    return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_MZONE,0,1,nil)
end

-- Logic Effect 2 (Place Spell)
function s.plfilter(c)
    return c:IsCode(15938) and not c:IsForbidden()
end
function s.pltg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
        and Duel.IsExistingMatchingCard(s.plfilter,tp,LOCATION_DECK+LOCATION_HAND+LOCATION_GRAVE,0,1,nil) end
end
function s.plop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then return end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOFIELD)
    local tc=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.plfilter),tp,LOCATION_DECK+LOCATION_HAND+LOCATION_GRAVE,0,1,1,nil):GetFirst()
    if tc then
        Duel.MoveToField(tc,tp,tp,LOCATION_SZONE,POS_FACEUP,true)
    end
end

-- Logic Effect 3 (Gain LP)
function s.robinfilter(c)
    return c:IsCode(39647) and c:IsType(TYPE_XYZ) and c:GetOverlayCount()>0
end
function s.revfilter(c)
    return c:IsSetCard(0x987) and c:IsMonster() and not c:IsPublic()
end
function s.excost(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    local is_hand=c:IsLocation(LOCATION_HAND)
    
    if chk==0 then
        local cost_met=false
        if is_hand then
            cost_met=not c:IsPublic()
        else
            cost_met=Duel.IsExistingMatchingCard(s.revfilter,tp,LOCATION_HAND,0,1,nil)
        end
        return cost_met and Duel.IsExistingMatchingCard(s.robinfilter,tp,LOCATION_MZONE,0,1,nil)
    end
    
    if is_hand then
        Duel.ConfirmCards(1-tp,c)
    else
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONFIRM)
        local g=Duel.SelectMatchingCard(tp,s.revfilter,tp,LOCATION_HAND,0,1,1,nil)
        Duel.ConfirmCards(1-tp,g)
        Duel.ShuffleHand(tp)
    end
    
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DEATTACHFROM)
    local rg=Duel.SelectMatchingCard(tp,s.robinfilter,tp,LOCATION_MZONE,0,1,1,nil)
    rg:GetFirst():RemoveOverlayCard(tp,1,1,REASON_COST)
end
function s.stagefilter(c)
    return c:IsCode(15938) and c:IsFaceup()
end
function s.rectg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.stagefilter,tp,LOCATION_ONFIELD,0,1,nil) end
    local count=Duel.GetMatchingGroupCount(s.stagefilter,tp,LOCATION_ONFIELD,0,nil)
    Duel.SetOperationInfo(0,CATEGORY_RECOVER,nil,0,tp,count*1000)
end
function s.recop(e,tp,eg,ep,ev,re,r,rp)
    local count=Duel.GetMatchingGroupCount(s.stagefilter,tp,LOCATION_ONFIELD,0,nil)
    if count>0 then
        Duel.Recover(tp,count*1000,REASON_EFFECT)
    end
end
