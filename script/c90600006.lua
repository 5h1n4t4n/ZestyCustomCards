-- Sky Striker Ace - Kurayami
-- ID: 2772337
local s,id=GetID()

function s.initial_effect(c)
    -- HIỆU ỨNG 1: Special Summon từ tay nếu một quái thú "Sky Striker" được Normal/Special Summon
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e1:SetProperty(EFFECT_FLAG_DELAY)
    e1:SetCode(EVENT_SUMMON_SUCCESS)
    e1:SetRange(LOCATION_HAND)
    e1:SetCountLimit(1,id)
    e1:SetCondition(s.spcon1)
    e1:SetTarget(s.sptg1)
    e1:SetOperation(s.spop1)
    c:RegisterEffect(e1)
    
    local e1_bis=e1:Clone()
    e1_bis:SetCode(EVENT_SPSUMMON_SUCCESS)
    c:RegisterEffect(e1_bis)

    -- HIỆU ỨNG 2: Gửi 1 lá "Sky Striker" từ Deck xuống Mộ khi được Normal hoặc Special Summon
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_TOGRAVE)
    e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e2:SetProperty(EFFECT_FLAG_DELAY)
    e2:SetCode(EVENT_SUMMON_SUCCESS)
    e2:SetCountLimit(1,{id,1})
    e2:SetTarget(s.tgtg)
    e2:SetOperation(s.tgop)
    c:RegisterEffect(e2)
    
    local e2_bis=e2:Clone()
    e2_bis:SetCode(EVENT_SPSUMMON_SUCCESS)
    c:RegisterEffect(e2_bis)

    -- HIỆU ỨNG 3: Khi dùng làm nguyên liệu Link hoặc tách làm nguyên liệu Xyz cho hiệu ứng -> Vô hiệu hóa 1 lá bài ngửa trên sân đối thủ
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,2))
    e3:SetCategory(CATEGORY_DISABLE)
    e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e3:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
    e3:SetCode(EVENT_BE_MATERIAL)
    e3:SetCountLimit(1,{id,2})
    e3:SetCondition(s.discon)
    e3:SetTarget(s.distg)
    e3:SetOperation(s.disop)
    c:RegisterEffect(e3)
end

--------------------------------------------------------------------------------
-- LOGIC HIỆU ỨNG 1 (SPECIAL SUMMON TỪ TAY)
--------------------------------------------------------------------------------
function s.cfilter(c,tp)
    return c:IsControler(tp) and c:IsSetCard(0x115)
end

function s.spcon1(e,tp,eg,ep,ev,re,r,rp)
    return eg:IsExists(s.cfilter,1,nil,tp)
end

function s.sptg1(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false) end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
end

function s.spop1(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if c:IsRelateToEffect(e) then
        Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
    end
end

--------------------------------------------------------------------------------
-- LOGIC HIỆU ỨNG 2 (GỬI 1 LÁ SKYS-STRIKER TỪ DECK XUỐNG MỘ)
--------------------------------------------------------------------------------
function s.tgfilter(c)
    return c:IsSetCard(0x115) and c:IsAbleToGrave()
end

function s.tgtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.tgfilter,tp,LOCATION_DECK,0,1,nil) end
    Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_DECK)
end

function s.tgop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
    local g=Duel.SelectMatchingCard(tp,s.tgfilter,tp,LOCATION_DECK,0,1,1,nil)
    if #g>0 then
        Duel.SendtoGrave(g,REASON_EFFECT)
    end
end

--------------------------------------------------------------------------------
-- LOGIC HIỆU ỨNG 3 (VÔ HIỆU HÓA KHI LÀM NGUYÊN LIỆU LINK/XYZ)
--------------------------------------------------------------------------------
function s.discon(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local rc=c:GetReasonCard()
    return (r==REASON_LINK and rc:IsSetCard(0x115)) or (r==REASON_XYZ and rc:IsSetCard(0x115))
end

function s.distg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsOnField() and chkc:IsControler(1-tp) and chkc:IsFaceup() end
    if chk==0 then return Duel.IsExistingTarget(Card.IsFaceup,tp,0,LOCATION_ONFIELD,1,nil) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_NEGATE)
    local g=Duel.SelectTarget(tp,Card.IsFaceup,tp,0,LOCATION_ONFIELD,1,1,nil)
    Duel.SetOperationInfo(0,CATEGORY_DISABLE,g,1,0,0)
end

function s.disop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local tc=Duel.GetFirstTarget()
    if tc and tc:IsRelateToEffect(e) and tc:IsFaceup() and not tc:IsDisabled() then
        Duel.NegateRelatedChain(tc,RESET_TURN_SET)
        local e1=Effect.CreateEffect(c)
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_DISABLE)
        e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
        tc:RegisterEffect(e1)
        local e2=Effect.CreateEffect(c)
        e2:SetType(EFFECT_TYPE_SINGLE)
        e2:SetCode(EFFECT_DISABLE_EFFECT)
        e2:SetValue(RESET_TURN_SET)
        e2:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
        tc:RegisterEffect(e2)
    end
end