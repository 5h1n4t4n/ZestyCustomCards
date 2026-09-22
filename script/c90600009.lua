-- Sky Striker Ace - Hikari
-- ID: 2772337
local s,id=GetID()

function s.initial_effect(c)
    -- HIỆU ỨNG 1: Special Summon từ tay nếu không có quái thú ở Main Zone hoặc điều khiển quái thú "Sky Striker"
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_IGNITION)
    e1:SetRange(LOCATION_HAND)
    e1:SetCountLimit(1,id)
    e1:SetCondition(s.spcon)
    e1:SetTarget(s.sptg)
    e1:SetOperation(s.spop)
    c:RegisterEffect(e1)

    -- HIỆU ỨNG 2: Thêm 1 lá "Sky Striker" từ Deck lên tay khi được Normal hoặc Special Summon
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
    e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e2:SetProperty(EFFECT_FLAG_DELAY)
    e2:SetCode(EVENT_SUMMON_SUCCESS)
    e2:SetCountLimit(1,{id,1})
    e2:SetTarget(s.thtg)
    e2:SetOperation(s.thop)
    c:RegisterEffect(e2)
    
    local e2_bis=e2:Clone()
    e2_bis:SetCode(EVENT_SPSUMMON_SUCCESS)
    c:RegisterEffect(e2_bis)

    -- HIỆU ỨNG 3: Khi dùng làm nguyên liệu Link hoặc tách làm nguyên liệu Xyz cho hiệu ứng -> Lấy 1 lá "Sky Striker" bị trục xuất về tay
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,2))
    e3:SetCategory(CATEGORY_TOHAND)
    e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e3:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
    e3:SetCode(EVENT_BE_MATERIAL)
    e3:SetCountLimit(1,{id,2})
    e3:SetCondition(s.thcon2)
    e3:SetTarget(s.thtg2)
    e3:SetOperation(s.thop2)
    c:RegisterEffect(e3)
end

--------------------------------------------------------------------------------
-- LOGIC HIỆU ỨNG 1 (SPECIAL SUMMON TỪ TAY)
--------------------------------------------------------------------------------
function s.zone_filter(c)
    return c:IsControler(0) and c:IsLocation(LOCATION_MZONE)
end

function s.spcon(e,tp,eg,ep,ev,re,r,rp)
    return Duel.GetMatchingGroupCount(s.zone_filter,tp,LOCATION_MZONE,0,nil,tp)==0 
        or Duel.IsExistingMatchingCard(aux.FilterBoolFunction(Card.IsSetCard,0x115),tp,LOCATION_MZONE,0,1,nil)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false) end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if c:IsRelateToEffect(e) then
        Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
    end
end

--------------------------------------------------------------------------------
-- LOGIC HIỆU ỨNG 2 (THÊM 1 LÁ "SKY STRIKER" TỪ DECK LÊN TAY)
--------------------------------------------------------------------------------
function s.thfilter(c)
    return c:IsSetCard(0x115) and c:IsAbleToHand()
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

--------------------------------------------------------------------------------
-- LOGIC HIỆU ỨNG 3 (LẤY 1 LÁ BỊ TRỤC XUẤT VỀ TAY KHI LÀM NGUYÊN LIỆU LINK/XYZ)
--------------------------------------------------------------------------------
function s.thcon2(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local rc=c:GetReasonCard()
    return (r==REASON_LINK and rc:IsSetCard(0x115)) or (r==REASON_XYZ and rc:IsSetCard(0x115))
end

function s.rmfilter(c)
    return c:IsSetCard(0x115) and c:IsFaceup() and c:IsAbleToHand()
end

function s.thtg2(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsLocation(LOCATION_REMOVED) and chkc:IsControler(tp) and s.rmfilter(chkc) end
    if chk==0 then return Duel.IsExistingTarget(s.rmfilter,tp,LOCATION_REMOVED,0,1,nil) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectTarget(tp,s.rmfilter,tp,LOCATION_REMOVED,0,1,1,nil)
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,g,1,0,0)
end

function s.thop2(e,tp,eg,ep,ev,re,r,rp)
    local tc=Duel.GetFirstTarget()
    if tc and tc:IsRelateToEffect(e) then
        Duel.SendtoHand(tc,nil,REASON_EFFECT)
        Duel.ConfirmCards(1-tp,tc)
    end
end