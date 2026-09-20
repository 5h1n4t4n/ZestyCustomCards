-- Sky Striker Ace - Kazebuko
-- ID: 90600014
local s,id=GetID()

function s.initial_effect(c)
    -- Xyz Summon: 2 quái thú Level 4 "Sky Striker" HOẶC chồng lên 1 quái thú Link "Sky Striker" bạn điều khiển
    Xyz.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsSetCard,0x115),4,2,s.ovfilter,aux.Stringid(id,0))
    c:EnableReviveLimit()

    -- HIỆU ỨNG 1: Tách 1 nguyên liệu; chọn 1 quái "Sky Striker" trên sân, nó không thể bị phá hủy hoặc chọn làm mục tiêu trong lượt này
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,1))
    e1:SetType(EFFECT_TYPE_IGNITION)
    e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e1:SetRange(LOCATION_MZONE)
    e1:SetCountLimit(1)
    e1:SetCost(s.cost)
    e1:SetTarget(s.target)
    e1:SetOperation(s.operation)
    c:RegisterEffect(e1)

    -- HIỆU ỨNG 2: Trao hiệu ứng cho quái Xyz "Sky Striker" sử dụng lá này làm nguyên liệu
    -- (Đối thủ không thể phản ứng lại khi bạn kích hoạt Phép "Sky Striker")
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
    e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
    e2:SetCode(EVENT_BE_MATERIAL)
    e2:SetCondition(s.matcon)
    e2:SetOperation(s.matop)
    c:RegisterEffect(e2)
end

--------------------------------------------------------------------------------
-- ĐIỀU KIỆN TRIỆU HỒI
--------------------------------------------------------------------------------
function s.ovfilter(c,tp,lc)
    return c:IsFaceup() and c:IsSetCard(0x115) and c:IsType(TYPE_LINK,lc,SUMMON_TYPE_XYZ,tp)
end

--------------------------------------------------------------------------------
-- HIỆU ỨNG 1: BẢO VỆ QUÁI THÚ "SKY STRIKER"
--------------------------------------------------------------------------------
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return e:GetHandler():CheckRemoveOverlayCard(tp,1,REASON_COST) end
    e:GetHandler():RemoveOverlayCard(tp,1,1,REASON_COST)
end

function s.filter(c)
    return c:IsFaceup() and c:IsSetCard(0x115)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(tp) and s.filter(chkc) end
    if chk==0 then return Duel.IsExistingTarget(s.filter,tp,LOCATION_MZONE,0,1,nil) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
    Duel.SelectTarget(tp,s.filter,tp,LOCATION_MZONE,0,1,1,nil)
end

function s.operation(e,tp,eg,ep,ev,re,r,rp)
    local tc=Duel.GetFirstTarget()
    if tc and tc:IsRelateToEffect(e) and tc:IsFaceup() then
        local c=e:GetHandler()
        
        -- Không thể bị phá hủy bởi chiến đấu
        local e1=Effect.CreateEffect(c)
        e1:SetDescription(aux.Stringid(id,2))
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetProperty(EFFECT_FLAG_CLIENT_HINT)
        e1:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
        e1:SetValue(1)
        e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
        tc:RegisterEffect(e1)
        
        -- Không thể bị phá hủy bởi hiệu ứng bài
        local e2=e1:Clone()
        e2:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
        tc:RegisterEffect(e2)
        
        -- Không thể bị chọn làm mục tiêu bởi hiệu ứng bài của đối thủ
        local e3=e1:Clone()
        e3:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
        e3:SetValue(aux.tgoval)
        tc:RegisterEffect(e3)
    end
end

--------------------------------------------------------------------------------
-- HIỆU ỨNG 2: NGĂN ĐỐI THỦ PHẢN ỨNG KHI KÍCH HOẠT PHÉP "SKY STRIKER"
--------------------------------------------------------------------------------
function s.matcon(e,tp,eg,ep,ev,re,r,rp)
    local rc=e:GetHandler():GetReasonCard()
    return r==REASON_XYZ and rc and rc:IsSetCard(0x115)
end

function s.matop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local rc=c:GetReasonCard()
    
    local e1=Effect.CreateEffect(rc)
    e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
    e1:SetCode(EVENT_CHAINING)
    e1:SetRange(LOCATION_MZONE)
    e1:SetOperation(s.actop)
    e1:SetReset(RESET_EVENT+RESETS_STANDARD)
    rc:RegisterEffect(e1)
end

function s.actop(e,tp,eg,ep,ev,re,r,rp)
    if re:IsActiveType(TYPE_SPELL) and re:GetHandler():IsSetCard(0x115) and rp==tp then
        Duel.SetChainLimit(s.chainlm)
    end
end

function s.chainlm(e,rp,tp)
    return tp==rp
end