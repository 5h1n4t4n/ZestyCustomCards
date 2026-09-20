-- Sky Striker Ace - Kazebuko
-- ID: 2772337
local s,id=GetID()

function s.initial_effect(c)
    -- Xyz Summon: 2 quái thú Level 4 "Sky Striker"
    Xyz.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsSetCard,0x115),4,2)
    c:EnableReviveLimit()

    -- Triệu hồi Xyz thay thế bằng 1 quái thú Link "Sky Striker" bạn điều khiển
    local e0=Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE)
    e0:SetProperty(EFFECT_FLAG_UNCOPYABLE)
    e0:SetCode(EFFECT_SPSUMMON_PROC)
    e0:SetRange(LOCATION_EXTRA)
    e0:SetCondition(s.xyzcon)
    e0:SetTarget(s.xyztg)
    e0:SetOperation(s.xyzop)
    c:RegisterEffect(e0)

    -- HIỆU ỨNG 1: Tách 1 nguyên liệu; chọn mục tiêu 1 quái thú "Sky Striker" bạn điều khiển, nó không thể bị phá hủy hoặc bị chọn làm mục tiêu bởi hiệu ứng bài của đối thủ trong lượt này
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_ATKCHANGE) -- hoặc đánh dấu bảo vệ
    e1:SetType(EFFECT_TYPE_IGNITION)
    e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e1:SetRange(LOCATION_MZONE)
    e1:SetCountLimit(1)
    e1:SetCost(s.cost)
    e1:SetTarget(s.target)
    e1:SetOperation(s.operation)
    c:RegisterEffect(e1)

    -- HIỆU ỨNG 2: Quái thú Xyz "Sky Striker" sử dụng lá bài này làm nguyên liệu nhận hiệu ứng (Không thể phản ứng lại khi kích hoạt Phép Sky Striker)
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_XMATERIAL+EFFECT_TYPE_FIELD)
    e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
    e2:SetCode(EFFECT_CANNOT_ACTIVATE)
    e2:SetTargetRange(0,1)
    e2:SetValue(s.aclimit)
    e2:SetCondition(s.mateffcon)
    c:RegisterEffect(e2)
end

--------------------------------------------------------------------------------
-- LOGIC HỖ TRỢ & HIỆU ỨNG
--------------------------------------------------------------------------------

-- Thay thế điều kiện Xyz Summon bằng Link Monster
function s.xyzfilter(c,tp,xyzc)
    return c:IsFaceup() and c:IsType(TYPE_LINK) and c:IsSetCard(0x115) and c:IsCanBeXyzMaterial(xyzc,tp)
end
function s.xyzcon(e,c)
    if c==nil then return true end
    local tp=c:GetControler()
    return Duel.CheckXyzMaterial(c,s.xyzfilter,1,1,1,e,tp)
end
function s.xyztg(e,tp,eg,ep,ev,re,r,rp,c)
    local g=Duel.SelectXyzMaterial(tp,c,s.xyzfilter,1,1,1,e,tp)
    if g then
        g:KeepAlive()
        e:SetLabelObject(g)
        return true
    end
    return false
end
function s.xyzop(e,tp,eg,ep,ev,re,r,rp,c)
    local g=e:GetLabelObject()
    if g then
        c:SetMaterial(g)
        Duel.Overlay(c,g)
        g:Delete()
    end
end

-- Hiệu ứng 1
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
        -- Không thể bị phá hủy bởi chiến đấu hoặc hiệu ứng bài
        local e1=Effect.CreateEffect(e:GetHandler())
        e1:SetDescription(aux.Stringid(id,2))
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetProperty(EFFECT_FLAG_CLIENT_HINT)
        e1:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
        e1:SetValue(1)
        e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
        tc:RegisterEffect(e1)
        local e2=e1:Clone()
        e2:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
        tc:RegisterEffect(e2)
        -- Không thể bị chọn làm mục tiêu bởi hiệu ứng của đối thủ
        local e3=e1:Clone()
        e3:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
        e3:SetValue(aux.tgoval)
        tc:RegisterEffect(e3)
    end
end

-- Hiệu ứng 2 (Áp dụng khi đang làm nguyên liệu cho Xyz Monster "Sky Striker")
function s.mateffcon(e)
    local c=e:GetHandler()
    local rc=c:GetReasonCard()
    return rc and rc:IsSetCard(0x115) and rc:IsType(TYPE_XYZ)
end
function s.aclimit(e,re,tp)
    local rc=e:GetHandler():GetReasonCard()
    -- Kiểm tra nếu quái Xyz chứa lá bài này đang ở trên sân và người chơi kích hoạt Spell "Sky Striker"
    return rc and rc:IsOnField() and rc:GetControler()==e:GetHandlerPlayer()
        and re:IsHasType(EFFECT_TYPE_ACTIVATE) and re:IsActiveType(TYPE_SPELL) and re:GetHandler():IsSetCard(0x115)
end