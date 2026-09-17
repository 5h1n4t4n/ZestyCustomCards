-- Red-Eyes Wyvern Metal Dragon
local s,id=GetID()

s.listed_series={0x3b}
s.listed_names={CARD_REDEYES_B_DRAGON, 93969023, 74677422, 89631139}

function s.initial_effect(c)
    --------------------------------------------------
    -- Effect 1: Search "Red-Eyes" monster or "Black Metal Dragon"
    --------------------------------------------------
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
    e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e1:SetProperty(EFFECT_FLAG_DELAY)
    e1:SetCode(EVENT_SUMMON_SUCCESS)
    e1:SetCountLimit(1,id)
    e1:SetTarget(s.thtg)
    e1:SetOperation(s.thop)
    c:RegisterEffect(e1)
    
    local e2=e1:Clone()
    e2:SetCode(EVENT_SPSUMMON_SUCCESS)
    c:RegisterEffect(e2)

    --------------------------------------------------
    -- Effect 2: Tribute to place Continuous S/T & Extra Normal Summon
    --------------------------------------------------
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,1))
    e3:SetType(EFFECT_TYPE_IGNITION)
    e3:SetRange(LOCATION_MZONE)
    e3:SetCountLimit(1,{id,1})
    e3:SetCost(s.plcost)
    e3:SetTarget(s.pltg)
    e3:SetOperation(s.plop)
    c:RegisterEffect(e3)
end

--------------------------------------------------
-- Effect 1 Logic (Search)
--------------------------------------------------
function s.thfilter(c)
    return (c:IsSetCard(0x3b) or c:IsCode(93969023)) and c:IsType(TYPE_MONSTER) and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
    if #g>0 then
        Duel.SendtoHand(g,nil,REASON_EFFECT)
        Duel.ConfirmCards(1-tp,g)
    end
end

--------------------------------------------------
-- Effect 2 Logic (Place Continuous S/T & Extra Summon)
--------------------------------------------------
function s.plcost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return e:GetHandler():IsReleasable() end
    Duel.Release(e:GetHandler(),REASON_COST)
end

function s.is_listed(c, code)
    if c:IsCode(code) then return true end
    if c.listed_names then
        for _,v in pairs(c.listed_names) do
            if v==code then return true end
        end
    end
    return false
end

function s.plfilter(c,tp)
    return (c:IsType(TYPE_CONTINUOUS) and c:IsType(TYPE_SPELL+TYPE_TRAP))
        and (s.is_listed(c,74677422) or s.is_listed(c,89631139) or c:ListsCode(CARD_REDEYES_B_DRAGON)) 
        and not c:IsForbidden() and c:CheckUniqueOnField(tp)
end

function s.pltg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then 
        return Duel.GetLocationCount(tp,LOCATION_SZONE)>0 
            and Duel.IsExistingMatchingCard(s.plfilter,tp,LOCATION_DECK,0,1,nil,tp)
    end
end

function s.plop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then return end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOFIELD)
    local tc=Duel.SelectMatchingCard(tp,s.plfilter,tp,LOCATION_DECK,0,1,1,nil,tp):GetFirst()
    if tc and Duel.MoveToField(tc,tp,tp,LOCATION_SZONE,POS_FACEUP,true) then
        -- Additional Normal Summon
        local e1=Effect.CreateEffect(e:GetHandler())
        e1:SetDescription(aux.Stringid(id,2))
        e1:SetType(EFFECT_TYPE_FIELD)
        e1:SetCode(EFFECT_EXTRA_SUMMON_COUNT)
        e1:SetTargetRange(LOCATION_HAND+LOCATION_MZONE,0)
        e1:SetReset(RESET_PHASE+PHASE_END)
        Duel.RegisterEffect(e1,tp)
    end
end
