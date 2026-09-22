-- Sky Striker Special Mobilize - Eclipse Blade
-- ID: 90600039
local s,id=GetID()

function s.initial_effect(c)
    -- HIỆU ỨNG 1: Gửi tối đa 2 lá "Sky Striker" từ Deck xuống Mộ, rồi Triệu hồi Đặc biệt 1 quái thú "Sky Striker" từ Deck
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_TOGRAVE+CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetCondition(s.condition)
    e1:SetTarget(s.target)
    e1:SetOperation(s.activate)
    c:RegisterEffect(e1)

    -- HIỆU ỨNG 2: Trong Main Phase, trục xuất chính nó từ Mộ -> Thêm 1 Phép/Bẫy "Sky Striker" từ Deck lên tay, rồi có thể đặt trực tiếp 1 Phép "Sky Striker" từ Deck xuống sân
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
    e2:SetType(EFFECT_TYPE_IGNITION)
    e2:SetRange(LOCATION_GRAVE)
    e2:SetCountLimit(1,{id,1},EFFECT_COUNT_CODE_DUEL)
    e2:SetCost(aux.bfgcost)
    e2:SetTarget(s.thtg)
    e2:SetOperation(s.thop)
    c:RegisterEffect(e2)
end

s.listed_series={0x115}
s.listed_names={id}

--------------------------------------------------------------------------------
-- LOGIC HIỆU ỨNG 1
--------------------------------------------------------------------------------
function s.condition(e,tp,eg,ep,ev,re,r,rp)
    return Duel.GetFieldGroupCount(tp,LOCATION_MMZONE,0)==0
end

function s.tgfilter(c)
    return c:IsSetCard(0x115) and c:IsAbleToGrave()
end

function s.spfilter(c,e,tp)
    return c:IsSetCard(0x115) and c:IsMonster() and c:IsCanBeSpecialSummoned(e,0,tp,true,false)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then 
        return Duel.IsExistingMatchingCard(s.tgfilter,tp,LOCATION_DECK,0,1,nil)
            and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_DECK,0,1,nil,e,tp)
    end
    Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_DECK)
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
    local g=Duel.SelectMatchingCard(tp,s.tgfilter,tp,LOCATION_DECK,0,1,2,nil)
    if #g>0 and Duel.SendtoGrave(g,REASON_EFFECT)>0 then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
        local sg=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_DECK,0,1,1,nil,e,tp)
        if #sg>0 then
            Duel.SpecialSummon(sg,0,tp,tp,true,false,POS_FACEUP)
        end
    end
end

--------------------------------------------------------------------------------
-- LOGIC HIỆU ỨNG 2 (TRONG MỘ)
--------------------------------------------------------------------------------
function s.thfilter(c)
    return c:IsSetCard(0x115) and c:IsType(TYPE_SPELL+TYPE_TRAP) and c:IsAbleToHand()
end

function s.setfilter(c)
    return c:IsSetCard(0x115) and c:IsType(TYPE_SPELL) and c:IsSSetable()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
    if #g>0 and Duel.SendtoHand(g,nil,REASON_EFFECT)>0 then
        Duel.ConfirmCards(1-tp,g)
        -- Kiểm tra nếu có từ 3 Phép thuật trở lên trong Mộ
        if Duel.GetMatchingGroupCount(Card.IsType,tp,LOCATION_GRAVE,0,nil,TYPE_SPELL)>=3 
            and Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_DECK,0,1,nil) 
            and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
            Duel.BreakEffect()
            Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
            local sg=Duel.SelectMatchingCard(tp,s.setfilter,tp,LOCATION_DECK,0,1,1,nil)
            if #sg>0 then
                Duel.SSet(tp,sg:GetFirst())
            end
        end
    end
end